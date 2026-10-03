import AppKit
import CoreGraphics
import XCTest
@testable import RealTimeQuote

@MainActor
final class RealRouteVideoExporterTests: XCTestCase {
    func testExporterPassesTimelineTimestampsToRendererAndWriter() async throws {
        let rendererHost = SpyRouteVideoRendererHost()
        let frameWriter = SpyRouteVideoFrameWriter()
        let exporter = RealRouteVideoExporter(
            configuration: .default,
            rendererHostFactory: { _, _, _ in rendererHost },
            frameWriterFactory: { _, _, _ in frameWriter }
        )

        let outputURL = try await exporter.export(
            segments: [makeSegment(from: "Bologna", to: "Istanbul", transport: .plane)]
        )

        XCTAssertEqual(rendererHost.renderedTimes, frameWriter.appendedTimes)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testExporterThrowsRendererTimeoutAndCleansUpOutputURL() async {
        let rendererHost = FailingRouteVideoRendererHost(error: .rendererTimedOut)
        let frameWriter = SpyRouteVideoFrameWriter()
        let exporter = RealRouteVideoExporter(
            configuration: .default,
            rendererHostFactory: { _, _, _ in rendererHost },
            frameWriterFactory: { _, _, _ in frameWriter }
        )

        await XCTAssertThrowsErrorAsync(try await exporter.export(
            segments: [makeSegment(from: "Bologna", to: "Istanbul", transport: .plane)]
        )) { error in
            XCTAssertEqual(error as? RouteVideoExportError, .rendererTimedOut)
            XCTAssertFalse(FileManager.default.fileExists(atPath: frameWriter.outputURL.path))
        }
    }

    private func makeSegment(from: String, to: String, transport: TripTransportType) -> ResolvedTripSegment {
        ResolvedTripSegment(
            id: UUID(),
            fromCityName: from,
            toCityName: to,
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: transport,
            dateLabel: "2026-07-01"
        )
    }
}

@MainActor
private final class SpyRouteVideoRendererHost: RouteVideoRendererHosting {
    private(set) var renderedTimes: [TimeInterval] = []

    func prepare() async throws {}

    func renderFrame(at time: TimeInterval) async throws -> CGImage {
        renderedTimes.append(time)
        return solidImage(size: .init(width: 4, height: 4))
    }

    func tearDown() async {}
}

@MainActor
private final class FailingRouteVideoRendererHost: RouteVideoRendererHosting {
    let error: RouteVideoExportError

    init(error: RouteVideoExportError) {
        self.error = error
    }

    func prepare() async throws {
        throw error
    }

    func renderFrame(at time: TimeInterval) async throws -> CGImage {
        throw error
    }

    func tearDown() async {}
}

private final class SpyRouteVideoFrameWriter: RouteVideoFrameWriting {
    let outputURL: URL
    private(set) var appendedTimes: [TimeInterval] = []

    init() {
        self.outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
    }

    func start() throws {}

    func append(image: CGImage, at time: TimeInterval) async throws {
        appendedTimes.append(time)
    }

    func finish() async throws -> URL {
        FileManager.default.createFile(atPath: outputURL.path, contents: Data("mp4".utf8))
        return outputURL
    }

    func cancel() {
        try? FileManager.default.removeItem(at: outputURL)
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
