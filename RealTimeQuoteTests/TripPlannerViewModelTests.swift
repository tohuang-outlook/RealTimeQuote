import XCTest
@testable import RealTimeQuote

@MainActor
final class TripPlannerViewModelTests: XCTestCase {
    func testPreviewResolvesSegmentsAndPublishesReadyState() async throws {
        let resolvedSegments = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let resolver = StubTripRouteResolver(
            error: .unresolvedCity(segmentIndex: 0, cityName: "Atlantis"),
            result: resolvedSegments
        )
        let exporter = StubRouteVideoExporter()
        let viewModel = TripPlannerViewModel(routeResolver: resolver, exporter: exporter)

        await viewModel.generatePreview()

        XCTAssertEqual(viewModel.previewState, .failed("City not found: Atlantis"))
        XCTAssertEqual(viewModel.lastErrorMessage, "City not found: Atlantis")

        resolver.error = nil
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()

        XCTAssertEqual(viewModel.previewState, .resolving)
        XCTAssertEqual(viewModel.previewSegments, resolvedSegments)

        viewModel.handleRendererEvent(.didBecomeReady)

        XCTAssertEqual(viewModel.previewState, .ready(resolvedSegments))
        XCTAssertNil(viewModel.lastErrorMessage)
        XCTAssertEqual(resolver.receivedSegmentsHistory.last?.first?.fromCityName, "Bologna")
        XCTAssertEqual(resolver.receivedSegmentsHistory.last?.first?.toCityName, "Istanbul")
    }

    func testPreviewFailurePublishesReadableMessage() async {
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(error: .unresolvedCity(segmentIndex: 0, cityName: "Atlantis")),
            exporter: StubRouteVideoExporter()
        )

        await viewModel.generatePreview()

        XCTAssertEqual(viewModel.previewState, .failed("City not found: Atlantis"))
        XCTAssertEqual(viewModel.lastErrorMessage, "City not found: Atlantis")
    }

    func testEditingTripAfterSuccessfulPreviewInvalidatesDerivedPreviewState() async {
        let resolvedSegments = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let resolver = StubTripRouteResolver(result: resolvedSegments)
        let viewModel = TripPlannerViewModel(routeResolver: resolver, exporter: StubRouteVideoExporter())

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()

        viewModel.handleRendererEvent(.didBecomeReady)
        XCTAssertEqual(viewModel.previewState, .ready(resolvedSegments))

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Moscow")

        XCTAssertEqual(viewModel.previewState, .idle)
        XCTAssertNil(viewModel.exportedVideoURL)
    }

    func testExportDoesNotUseStalePreviewAfterTripEdit() async {
        let resolvedSegments = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let resolver = StubTripRouteResolver(result: resolvedSegments)
        let exporter = SpyRouteVideoExporter()
        let viewModel = TripPlannerViewModel(routeResolver: resolver, exporter: exporter)

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)
        viewModel.updateTransport(id: viewModel.segments[0].id, transportType: .train)

        await viewModel.exportVideo()

        XCTAssertTrue(exporter.exportedSegmentsHistory.isEmpty)
        XCTAssertNil(viewModel.exportedVideoURL)
    }

    func testExportVideoStoresReturnedURL() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let exporter = StubRouteVideoExporter(resultURL: URL(fileURLWithPath: "/tmp/fly.mp4"))
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: exporter
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)
        await viewModel.exportVideo()

        XCTAssertEqual(viewModel.exportedVideoURL?.path, "/tmp/fly.mp4")
    }

    func testExportIgnoresCompletionAfterTripChangesDuringExport() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let exporter = ControlledRouteVideoExporter()
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: exporter
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)

        async let export: Void = viewModel.exportVideo()
        await exporter.waitForExportCount(1)

        viewModel.updateTransport(id: viewModel.segments[0].id, transportType: .train)
        exporter.completeExport(at: 0, with: .success(URL(fileURLWithPath: "/tmp/stale.mp4")))
        _ = await export

        XCTAssertNil(viewModel.exportedVideoURL)
        XCTAssertNil(viewModel.lastErrorMessage)
    }

    func testFailedReExportClearsPreviousExportedURL() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let exporter = ControlledRouteVideoExporter(
            queuedResults: [
                .success(URL(fileURLWithPath: "/tmp/fly.mp4")),
                .failure(ExportTestError.failed)
            ]
        )
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: exporter
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)
        await viewModel.exportVideo()

        XCTAssertEqual(viewModel.exportedVideoURL?.path, "/tmp/fly.mp4")

        await viewModel.exportVideo()

        XCTAssertNil(viewModel.exportedVideoURL)
        XCTAssertEqual(viewModel.lastErrorMessage, "Video export failed")
    }

    func testExportVideoPublishesRendererTimeoutMessage() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let exporter = FailingRouteVideoExporter(error: .rendererTimedOut)
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: exporter
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)

        await viewModel.exportVideo()

        XCTAssertNil(viewModel.exportedVideoURL)
        XCTAssertEqual(viewModel.lastErrorMessage, "Preview renderer timed out during export")
    }

    func testExportVideoPublishesVideoWriterFailureMessage() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let exporter = FailingRouteVideoExporter(error: .writerFailed("Disk full"))
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: exporter
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)

        await viewModel.exportVideo()

        XCTAssertEqual(viewModel.lastErrorMessage, "Video writer failed during export: Disk full")
    }

    func testPreviewOnlyPublishesNewestOverlappingResult() async {
        let firstResolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Old",
                toCityName: "Route",
                fromCoordinate: .init(latitude: 1, longitude: 1),
                toCoordinate: .init(latitude: 2, longitude: 2),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let secondResolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-02"
            )
        ]
        let resolver = StubTripRouteResolver()
        let viewModel = TripPlannerViewModel(routeResolver: resolver, exporter: StubRouteVideoExporter())

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Old")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Route")
        async let firstPreview: Void = viewModel.generatePreview()
        await resolver.waitForRequestCount(1)

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        async let secondPreview: Void = viewModel.generatePreview()
        await resolver.waitForRequestCount(2)

        resolver.completeRequest(at: 1, with: .success(secondResolved))
        _ = await secondPreview

        viewModel.handleRendererEvent(.didBecomeReady)
        XCTAssertEqual(viewModel.previewState, .ready(secondResolved))

        resolver.completeRequest(at: 0, with: .success(firstResolved))
        _ = await firstPreview

        XCTAssertEqual(viewModel.previewState, .ready(secondResolved))
    }

    func testPreviewRemainsResolvingUntilRendererReportsReady() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: StubRouteVideoExporter()
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()

        XCTAssertEqual(viewModel.previewState, .resolving)
        XCTAssertEqual(viewModel.previewSegments, resolved)

        viewModel.handleRendererEvent(.didBecomeReady)

        XCTAssertEqual(viewModel.previewState, .ready(resolved))
    }

    func testRendererFailurePublishesFailedPreviewState() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: StubRouteVideoExporter()
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didFail("Renderer crashed"))

        XCTAssertEqual(viewModel.previewState, .failed("Renderer crashed"))
        XCTAssertEqual(viewModel.lastErrorMessage, "Renderer crashed")
    }

    func testTripEditsInvalidateReadyRendererStateAndReplayToken() async {
        let resolved = [
            ResolvedTripSegment(
                id: UUID(),
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                transportType: .plane,
                dateLabel: "2026-07-01"
            )
        ]
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: resolved),
            exporter: StubRouteVideoExporter()
        )

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()
        viewModel.handleRendererEvent(.didBecomeReady)
        let firstReplayToken = viewModel.previewReplayToken

        viewModel.updateTransport(id: viewModel.segments[0].id, transportType: .train)

        XCTAssertEqual(viewModel.previewState, .idle)
        XCTAssertTrue(viewModel.previewReplayToken > firstReplayToken)
    }
}

private final class SpyRouteVideoExporter: RouteVideoExporting {
    private(set) var exportedSegmentsHistory: [[ResolvedTripSegment]] = []

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        exportedSegmentsHistory.append(segments)
        return URL(fileURLWithPath: "/tmp/route-preview.mp4")
    }
}

private final class FailingRouteVideoExporter: RouteVideoExporting {
    let error: RouteVideoExportError

    init(error: RouteVideoExportError) {
        self.error = error
    }

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        throw error
    }
}

private enum ExportTestError: Error {
    case failed
}

private final class ControlledRouteVideoExporter: RouteVideoExporting {
    private(set) var exportedSegmentsHistory: [[ResolvedTripSegment]] = []
    private var queuedResults: [Result<URL, Error>]
    private var pendingExports: [CheckedContinuation<URL, Error>] = []
    private var exportCountContinuations: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(queuedResults: [Result<URL, Error>] = []) {
        self.queuedResults = queuedResults
    }

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        exportedSegmentsHistory.append(segments)
        resumeExportWaitersIfNeeded()

        if !queuedResults.isEmpty {
            let result = queuedResults.removeFirst()
            return try result.get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            pendingExports.append(continuation)
        }
    }

    func waitForExportCount(_ count: Int) async {
        if exportedSegmentsHistory.count >= count {
            return
        }

        await withCheckedContinuation { continuation in
            exportCountContinuations.append((count, continuation))
        }
    }

    func completeExport(at index: Int, with result: Result<URL, Error>) {
        let continuation = pendingExports.remove(at: index)
        switch result {
        case let .success(url):
            continuation.resume(returning: url)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    private func resumeExportWaitersIfNeeded() {
        var remaining: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []
        for waiter in exportCountContinuations {
            if exportedSegmentsHistory.count >= waiter.target {
                waiter.continuation.resume()
            } else {
                remaining.append(waiter)
            }
        }
        exportCountContinuations = remaining
    }
}

private final class StubTripRouteResolver: TripRouteResolving {
    var error: TripRouteResolutionError?
    var result: [ResolvedTripSegment]
    private(set) var receivedSegmentsHistory: [[TripSegmentInput]] = []
    private var pendingRequests: [CheckedContinuation<[ResolvedTripSegment], Error>] = []
    private var requestCountContinuations: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(error: TripRouteResolutionError? = nil, result: [ResolvedTripSegment] = []) {
        self.error = error
        self.result = result
    }

    func resolve(segments: [TripSegmentInput]) async throws -> [ResolvedTripSegment] {
        receivedSegmentsHistory.append(segments)
        resumeRequestWaitersIfNeeded()

        if let error {
            throw error
        }

        if !result.isEmpty {
            return result
        }

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests.append(continuation)
        }
    }

    func waitForRequestCount(_ count: Int) async {
        if receivedSegmentsHistory.count >= count {
            return
        }

        await withCheckedContinuation { continuation in
            requestCountContinuations.append((count, continuation))
        }
    }

    func completeRequest(at index: Int, with result: Result<[ResolvedTripSegment], Error>) {
        let continuation = pendingRequests.remove(at: index)
        switch result {
        case let .success(segments):
            continuation.resume(returning: segments)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    private func resumeRequestWaitersIfNeeded() {
        var remaining: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []
        for waiter in requestCountContinuations {
            if receivedSegmentsHistory.count >= waiter.target {
                waiter.continuation.resume()
            } else {
                remaining.append(waiter)
            }
        }
        requestCountContinuations = remaining
    }
}
