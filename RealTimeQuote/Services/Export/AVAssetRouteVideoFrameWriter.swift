import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

final class AVAssetRouteVideoFrameWriter: RouteVideoFrameWriting {
    private enum Constants {
        static let readinessPollNanoseconds: UInt64 = 5_000_000
        static let readinessTimeoutNanoseconds: UInt64 = 2_000_000_000
    }

    let outputURL: URL

    private let timeline: RouteVideoTimeline
    private let configuration: RouteVideoExportConfiguration
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let queue = DispatchQueue(label: "com.tonyhuang.RealTimeQuote.AVAssetRouteVideoFrameWriter")

    init(
        timeline: RouteVideoTimeline,
        configuration: RouteVideoExportConfiguration,
        outputURL: URL
    ) {
        self.timeline = timeline
        self.configuration = configuration
        self.outputURL = outputURL

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let useMOVContainer = outputURL.pathExtension.lowercased() == "mov"
        let fileType: AVFileType = useMOVContainer ? .mov : .mp4
        let codec: AVVideoCodecType = useMOVContainer ? .jpeg : .h264
        writer = try! AVAssetWriter(outputURL: outputURL, fileType: fileType)
        input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: codec,
                AVVideoWidthKey: Int(configuration.renderSize.width),
                AVVideoHeightKey: Int(configuration.renderSize.height)
            ]
        )
        input.expectsMediaDataInRealTime = false

        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: nil
        )

        if writer.canAdd(input) {
            writer.add(input)
        }
    }

    func start() throws {
        guard writer.canAdd(input) || writer.inputs.contains(input) else {
            throw RouteVideoExportError.writerFailed("Unable to add video input")
        }
        guard writer.startWriting() else {
            throw RouteVideoExportError.writerFailed("Unable to start writer: \(writerDebugDescription())")
        }
        writer.startSession(atSourceTime: .zero)
    }

    func append(image: CGImage, at time: TimeInterval) async throws {
        try await performOnQueue { [self] in
            let deadline = ContinuousClock.now + .nanoseconds(Int(Constants.readinessTimeoutNanoseconds))
            while !self.input.isReadyForMoreMediaData {
                guard ContinuousClock.now < deadline else {
                    throw RouteVideoExportError.writerFailed("Writer input timed out")
                }
                Thread.sleep(forTimeInterval: Double(Constants.readinessPollNanoseconds) / 1_000_000_000)
            }

            let presentationTime = Self.presentationTime(
                for: time,
                framesPerSecond: self.configuration.framesPerSecond
            )
            var appendError: Error?
            autoreleasepool {
                guard let pixelBuffer = self.makePixelBuffer(from: image) else {
                    appendError = RouteVideoExportError.frameCaptureFailed
                    return
                }

                guard self.adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    appendError = RouteVideoExportError.writerFailed("Unable to append frame: \(self.writerDebugDescription())")
                    return
                }
            }

            if let appendError {
                throw appendError
            }
        }
    }

    func finish() async throws -> URL {
        try await performOnQueue { [self] in
            self.input.markAsFinished()
        }

        let writer = self.writer
        let writerDebugDescription = self.writerDebugDescription
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writer.finishWriting {
                if writer.error != nil {
                    continuation.resume(throwing: RouteVideoExportError.writerFailed("Unable to finish writing: \(writerDebugDescription())"))
                } else {
                    continuation.resume()
                }
            }
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw RouteVideoExportError.outputFileMissing
        }

        return outputURL
    }

    func cancel() {
        input.markAsFinished()
        writer.cancelWriting()
        try? FileManager.default.removeItem(at: outputURL)
    }

    private func performOnQueue<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func makePixelBuffer(from image: CGImage) -> CVPixelBuffer? {
        let width = Int(configuration.renderSize.width)
        let height = Int(configuration.renderSize.height)
        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ] as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess,
              let pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }

    private func writerDebugDescription() -> String {
        let statusDescription: String
        switch writer.status {
        case .unknown:
            statusDescription = "unknown"
        case .writing:
            statusDescription = "writing"
        case .completed:
            statusDescription = "completed"
        case .failed:
            statusDescription = "failed"
        case .cancelled:
            statusDescription = "cancelled"
        @unknown default:
            statusDescription = "unknown-default"
        }

        if let error = writer.error as NSError? {
            let failureReason = error.localizedFailureReason ?? "nil"
            let recoverySuggestion = error.localizedRecoverySuggestion ?? "nil"
            let underlyingDescription: String
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                underlyingDescription = "domain=\(underlyingError.domain), code=\(underlyingError.code), message=\(underlyingError.localizedDescription)"
            } else {
                underlyingDescription = "nil"
            }

            return """
            status=\(statusDescription), domain=\(error.domain), code=\(error.code), \
            message=\(error.localizedDescription), failureReason=\(failureReason), \
            recoverySuggestion=\(recoverySuggestion), underlying=\(underlyingDescription)
            """
        }

        return "status=\(statusDescription), error=nil"
    }

    static func presentationTime(for time: TimeInterval, framesPerSecond: Int32) -> CMTime {
        let frameNumber = Int64((time * Double(framesPerSecond)).rounded(.toNearestOrAwayFromZero))
        return CMTime(value: frameNumber, timescale: framesPerSecond)
    }
}
