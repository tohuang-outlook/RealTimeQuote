import Foundation
import ImageIO
import UniformTypeIdentifiers

protocol FFmpegCommandRunning {
    func run(arguments: [String]) async throws
}

struct FFmpegRouteVideoExporter: RouteVideoExporting {
    let configuration: RouteVideoExportConfiguration
    let rendererHostFactory: @MainActor ([ResolvedTripSegment], RouteVideoTimeline, RouteVideoExportConfiguration) -> RouteVideoRendererHosting
    let commandRunner: FFmpegCommandRunning
    let fileManager: FileManager

    init(
        configuration: RouteVideoExportConfiguration = .default,
        rendererHostFactory: @escaping @MainActor ([ResolvedTripSegment], RouteVideoTimeline, RouteVideoExportConfiguration) -> RouteVideoRendererHosting,
        commandRunner: FFmpegCommandRunning = ProcessFFmpegCommandRunner(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.rendererHostFactory = rendererHostFactory
        self.commandRunner = commandRunner
        self.fileManager = fileManager
    }

    @MainActor
    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        let timeline = RouteVideoTimeline.make(segments: segments, configuration: configuration)
        let outputURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        let framesDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("route-video-\(UUID().uuidString)", isDirectory: true)
        let rendererHost = rendererHostFactory(segments, timeline, configuration)

        do {
            try fileManager.createDirectory(at: framesDirectory, withIntermediateDirectories: true)
            try await rendererHost.prepare()

            for (index, time) in timeline.frameTimestamps().enumerated() {
                let image = try await rendererHost.renderFrame(at: time)
                let frameURL = framesDirectory.appendingPathComponent(String(format: "frame-%05d.png", index))
                try writePNG(image: image, to: frameURL)
            }

            try await commandRunner.run(arguments: ffmpegArguments(framesDirectory: framesDirectory, outputURL: outputURL))

            guard fileManager.fileExists(atPath: outputURL.path) else {
                throw RouteVideoExportError.outputFileMissing
            }

            await rendererHost.tearDown()
            try? fileManager.removeItem(at: framesDirectory)
            return outputURL
        } catch let error as RouteVideoExportError {
            await rendererHost.tearDown()
            try? fileManager.removeItem(at: outputURL)
            throw debugWrapped(error, framesDirectory: framesDirectory, outputURL: outputURL)
        } catch {
            await rendererHost.tearDown()
            try? fileManager.removeItem(at: outputURL)
            throw debugWrapped(
                RouteVideoExportError.writerFailed(error.localizedDescription),
                framesDirectory: framesDirectory,
                outputURL: outputURL
            )
        }
    }

    private func ffmpegArguments(framesDirectory: URL, outputURL: URL) -> [String] {
        [
            "-y",
            "-loglevel", "error",
            "-framerate", "\(configuration.framesPerSecond)",
            "-i", framesDirectory.appendingPathComponent("frame-%05d.png").path,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-movflags", "+faststart",
            outputURL.path
        ]
    }

    private func writePNG(image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw RouteVideoExportError.writerFailed("Unable to create PNG destination")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw RouteVideoExportError.writerFailed("Unable to write PNG frame")
        }
    }

    private func debugWrapped(
        _ error: RouteVideoExportError,
        framesDirectory: URL,
        outputURL: URL
    ) -> RouteVideoExportError {
        switch error {
        case let .writerFailed(message):
            return .writerFailed("""
            \(message)
            Frames preserved at: \(framesDirectory.path)
            Output target: \(outputURL.path)
            """)
        case .outputFileMissing:
            return .writerFailed("""
            Export finished without producing a video file
            Frames preserved at: \(framesDirectory.path)
            Output target: \(outputURL.path)
            """)
        case .rendererLoadFailed, .rendererTimedOut, .rendererFrameFailed, .frameCaptureFailed:
            return error
        }
    }
}

struct ProcessFFmpegCommandRunner: FFmpegCommandRunning {
    private let executableURL: URL

    init(executableURL: URL? = FFmpegExecutableLocator.defaultURL()) {
        self.executableURL = executableURL ?? URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
    }

    func run(arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stderrPipe = Pipe()

                process.executableURL = executableURL
                process.arguments = arguments
                process.standardOutput = Pipe()
                process.standardError = stderrPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrMessage = String(data: stderrData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    guard process.terminationStatus == 0 else {
                        let message = stderrMessage?.isEmpty == false
                            ? "ffmpeg failed: \(stderrMessage!)"
                            : "ffmpeg exited with status \(process.terminationStatus)"
                        continuation.resume(throwing: RouteVideoExportError.writerFailed(message))
                        return
                    }

                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(
                        throwing: RouteVideoExportError.writerFailed("Unable to launch ffmpeg: \(error.localizedDescription)")
                    )
                }
            }
        }
    }
}

enum FFmpegExecutableLocator {
    static func defaultURL(fileManager: FileManager = .default) -> URL? {
        let candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg"
        ]

        return candidates
            .map(URL.init(fileURLWithPath:))
            .first(where: { fileManager.isExecutableFile(atPath: $0.path) })
    }
}
