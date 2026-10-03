import AppKit
import CoreGraphics
import XCTest
@testable import RealTimeQuote

@MainActor
final class FallbackRouteVideoExporterTests: XCTestCase {
    func testFallsBackWhenPrimaryExporterFailsWithWriterError() async throws {
        let primary = RecordingRouteVideoExporter(result: .failure(.writerFailed("encoder unavailable")))
        let fallback = RecordingRouteVideoExporter(result: .success(makeOutputURL()))
        let exporter = FallbackRouteVideoExporter(primary: primary, fallback: fallback)

        let outputURL = try await exporter.export(segments: [makeSegment()])

        XCTAssertEqual(primary.exportCallCount, 1)
        XCTAssertEqual(fallback.exportCallCount, 1)
        XCTAssertEqual(outputURL, fallback.outputURL)
    }

    func testDoesNotFallBackForRendererFailures() async {
        let primary = RecordingRouteVideoExporter(result: .failure(.rendererTimedOut))
        let fallback = RecordingRouteVideoExporter(result: .success(makeOutputURL()))
        let exporter = FallbackRouteVideoExporter(primary: primary, fallback: fallback)

        await XCTAssertThrowsErrorAsync(try await exporter.export(segments: [makeSegment()])) { error in
            XCTAssertEqual(error as? RouteVideoExportError, .rendererTimedOut)
        }

        XCTAssertEqual(primary.exportCallCount, 1)
        XCTAssertEqual(fallback.exportCallCount, 0)
    }

    func testFFmpegExporterRendersFramesAndInvokesRunner() async throws {
        let rendererHost = SpyRouteVideoRendererHost()
        let runner = SpyFFmpegCommandRunner()
        let exporter = FFmpegRouteVideoExporter(
            configuration: RouteVideoExportConfiguration(
                renderSize: CGSize(width: 320, height: 180),
                framesPerSecond: 12
            ),
            rendererHostFactory: { _, _, _ in rendererHost },
            commandRunner: runner
        )

        let outputURL = try await exporter.export(segments: [makeSegment()])

        XCTAssertEqual(rendererHost.prepareCallCount, 1)
        XCTAssertEqual(rendererHost.tearDownCallCount, 1)
        XCTAssertEqual(rendererHost.renderedTimes.count, 72)
        XCTAssertEqual(runner.invocations.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(outputURL.pathExtension, "mp4")
        XCTAssertTrue(runner.invocations[0].contains("-framerate"))
        XCTAssertTrue(runner.invocations[0].contains("12"))
        XCTAssertTrue(runner.invocations[0].contains("-i"))
        XCTAssertTrue(runner.invocations[0].contains("-c:v"))
        XCTAssertTrue(runner.invocations[0].contains("libx264"))
    }

    func testFFmpegExporterIncludesDebugPathsWhenRunnerFails() async {
        let rendererHost = SpyRouteVideoRendererHost()
        let runner = FailingFFmpegCommandRunner()
        let exporter = FFmpegRouteVideoExporter(
            configuration: RouteVideoExportConfiguration(
                renderSize: CGSize(width: 320, height: 180),
                framesPerSecond: 12
            ),
            rendererHostFactory: { _, _, _ in rendererHost },
            commandRunner: runner
        )

        await XCTAssertThrowsErrorAsync(try await exporter.export(segments: [makeSegment()])) { error in
            guard case let .writerFailed(message) = error as? RouteVideoExportError else {
                return XCTFail("Expected writerFailed error")
            }

            XCTAssertTrue(message.contains("simulated ffmpeg stderr"))
            XCTAssertTrue(message.contains("Frames preserved at:"))
            XCTAssertTrue(message.contains("Output target:"))
            XCTAssertTrue(message.contains("route-video-"))
            XCTAssertTrue(message.contains(".mp4"))
        }

        XCTAssertEqual(rendererHost.prepareCallCount, 1)
        XCTAssertEqual(rendererHost.tearDownCallCount, 1)
        XCTAssertEqual(runner.invocations.count, 1)
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

    private func makeOutputURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
    }
}

private final class RecordingRouteVideoExporter: RouteVideoExporting {
    private let result: Result<URL, RouteVideoExportError>
    private(set) var exportCallCount = 0

    var outputURL: URL? {
        try? result.get()
    }

    init(result: Result<URL, RouteVideoExportError>) {
        self.result = result
    }

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        exportCallCount += 1
        return try result.get()
    }
}

@MainActor
private final class SpyRouteVideoRendererHost: RouteVideoRendererHosting {
    private(set) var prepareCallCount = 0
    private(set) var tearDownCallCount = 0
    private(set) var renderedTimes: [TimeInterval] = []

    func prepare() async throws {
        prepareCallCount += 1
    }

    func renderFrame(at time: TimeInterval) async throws -> CGImage {
        renderedTimes.append(time)
        return solidImage(size: CGSize(width: 320, height: 180))
    }

    func tearDown() async {
        tearDownCallCount += 1
    }
}

private final class SpyFFmpegCommandRunner: FFmpegCommandRunning {
    private(set) var invocations: [[String]] = []

    func run(arguments: [String]) async throws {
        invocations.append(arguments)

        guard let outputPath = arguments.last else {
            throw RouteVideoExportError.writerFailed("Missing ffmpeg output path")
        }

        FileManager.default.createFile(atPath: outputPath, contents: Data("mp4".utf8))
    }
}

private final class FailingFFmpegCommandRunner: FFmpegCommandRunning {
    private(set) var invocations: [[String]] = []

    func run(arguments: [String]) async throws {
        invocations.append(arguments)
        throw RouteVideoExportError.writerFailed("simulated ffmpeg stderr")
    }
}

private func solidImage(size: CGSize) -> CGImage {
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
    context.setFillColor(NSColor.systemBlue.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    return context.makeImage()!
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ verification: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw", file: file, line: line)
    } catch {
        verification(error)
    }
}
