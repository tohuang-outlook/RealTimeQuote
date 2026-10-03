import AppKit
import CoreGraphics
import CoreMedia
import XCTest
@testable import RealTimeQuote

final class AVAssetRouteVideoFrameWriterTests: XCTestCase {
    func testPresentationTimesRemainStrictlyIncreasingAcrossFullTimeline() {
        let configuration = RouteVideoExportConfiguration.default
        let timeline = RouteVideoTimeline.make(
            segments: [makeSegment()],
            configuration: configuration
        )

        var previousValue: Int64?
        for (index, time) in timeline.frameTimestamps().enumerated() {
            let presentationTime = AVAssetRouteVideoFrameWriter.presentationTime(
                for: time,
                framesPerSecond: configuration.framesPerSecond
            )
            if let previousValue {
                XCTAssertGreaterThan(
                    presentationTime.value,
                    previousValue,
                    "frame \(index) produced a non-increasing presentation time"
                )
            }
            previousValue = presentationTime.value
        }
    }

    func testWriterProducesMP4FileFromFrames() async throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        let timeline = RouteVideoTimeline.make(
            segments: [makeSegment()],
            configuration: .default
        )
        let writer = AVAssetRouteVideoFrameWriter(
            timeline: timeline,
            configuration: .default,
            outputURL: outputURL
        )

        try writer.start()
        try await writer.append(image: solidImage(color: .systemBlue), at: 0)
        try await writer.append(image: solidImage(color: .systemPink), at: timeline.frameDuration)
        let finalURL = try await writer.finish()

        XCTAssertTrue(FileManager.default.fileExists(atPath: finalURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: finalURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        XCTAssertGreaterThan(fileSize, 0)

        try? FileManager.default.removeItem(at: finalURL)
    }

    func testWriterProducesMP4FileForFullThreeSecondTimeline() async throws {
        try await assertWriterProducesVideoFile(
            configuration: .default,
            fileExtension: "mp4",
            minimumExpectedFileSize: 1_000
        )
    }

    func testWriterProducesMP4FileForFullThreeSecondTimelineAtLowerResolution() async throws {
        let configuration = RouteVideoExportConfiguration(
            renderSize: CGSize(width: 640, height: 360),
            framesPerSecond: 30
        )
        try await assertWriterProducesVideoFile(
            configuration: configuration,
            fileExtension: "mp4",
            minimumExpectedFileSize: 500
        )
    }

    func testWriterProducesMOVFileForFullThreeSecondTimeline() async throws {
        try await assertWriterProducesVideoFile(
            configuration: .default,
            fileExtension: "mov",
            minimumExpectedFileSize: 1_000
        )
    }

    private func assertWriterProducesVideoFile(
        configuration: RouteVideoExportConfiguration,
        fileExtension: String,
        minimumExpectedFileSize: Int
    ) async throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
        let timeline = RouteVideoTimeline.make(
            segments: [makeSegment()],
            configuration: configuration
        )
        let writer = AVAssetRouteVideoFrameWriter(
            timeline: timeline,
            configuration: configuration,
            outputURL: outputURL
        )

        try writer.start()
        for (index, time) in timeline.frameTimestamps().enumerated() {
            let color: NSColor = index.isMultiple(of: 2) ? .systemBlue : .systemPink
            do {
                try await writer.append(image: solidImage(color: color), at: time)
            } catch {
                XCTFail("append failed at frame \(index): \(error)")
                return
            }
        }
        let finalURL = try await writer.finish()

        XCTAssertTrue(FileManager.default.fileExists(atPath: finalURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: finalURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        XCTAssertGreaterThan(fileSize, minimumExpectedFileSize)

        try? FileManager.default.removeItem(at: finalURL)
    }

    private func makeSegment() -> ResolvedTripSegment {
        ResolvedTripSegment(
            id: UUID(),
            fromCityName: "Bologna",
            toCityName: "Istanbul",
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: .plane,
            dateLabel: "2026-07-01"
        )
    }

    private func solidImage(color: NSColor) -> CGImage {
        let size = CGSize(width: 1280, height: 720)
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )!
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return context.makeImage()!
    }
}
