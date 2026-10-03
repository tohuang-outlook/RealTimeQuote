import XCTest
@testable import RealTimeQuote

final class TripPlannerPresentationTests: XCTestCase {
    @MainActor
    func testTripPlannerViewModelStartsWithSingleEditableSegment() {
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: []),
            exporter: StubRouteVideoExporter()
        )

        XCTAssertEqual(viewModel.segments.count, 1)
        XCTAssertEqual(viewModel.segments[0].transportType, .plane)
    }

    @MainActor
    func testTripPlannerViewModelOnlyAllowsExportWhenPreviewIsReady() async {
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

        XCTAssertFalse(viewModel.canExport)

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "Bologna")
        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "Istanbul")
        await viewModel.generatePreview()

        XCTAssertFalse(viewModel.canExport)

        viewModel.handleRendererEvent(.didBecomeReady)

        XCTAssertTrue(viewModel.canExport)
    }

    @MainActor
    func testTripPlannerViewModelPublishesAutoPreviewSignalForCompleteRouteInput() {
        let viewModel = TripPlannerViewModel(
            routeResolver: StubTripRouteResolver(result: []),
            exporter: StubRouteVideoExporter()
        )

        XCTAssertEqual(viewModel.autoPreviewRequestToken, 0)
        XCTAssertFalse(viewModel.shouldAutoPreview)

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.fromCityName, value: "SFO")

        XCTAssertEqual(viewModel.autoPreviewRequestToken, 1)
        XCTAssertFalse(viewModel.shouldAutoPreview)

        viewModel.updateSegmentCity(id: viewModel.segments[0].id, keyPath: \.toCityName, value: "HND")

        XCTAssertEqual(viewModel.autoPreviewRequestToken, 2)
        XCTAssertTrue(viewModel.shouldAutoPreview)
    }

    func testTripSegmentInputDefaultsToPlaneAndIsIncompleteWithoutCities() {
        let segment = TripSegmentInput.empty(order: 0)

        XCTAssertEqual(segment.transportType, .plane)
        XCTAssertEqual(segment.fromCityName, "")
        XCTAssertEqual(segment.toCityName, "")
        XCTAssertFalse(segment.isComplete)
    }

    func testResolvedTripSegmentExposesRendererPayloadValues() {
        let segment = ResolvedTripSegment(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            fromCityName: "Bologna",
            toCityName: "Istanbul",
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: .plane,
            dateLabel: "2026-07-01"
        )

        XCTAssertEqual(segment.rendererPayload.transport, "plane")
        XCTAssertEqual(segment.rendererPayload.from.name, "Bologna")
        XCTAssertEqual(segment.rendererPayload.from.latitude, 44.4949)
        XCTAssertEqual(segment.rendererPayload.from.longitude, 11.3426)
        XCTAssertEqual(segment.rendererPayload.to.name, "Istanbul")
        XCTAssertEqual(segment.rendererPayload.to.latitude, 41.0082)
        XCTAssertEqual(segment.rendererPayload.to.longitude, 28.9784)
        XCTAssertEqual(segment.rendererPayload.dateLabel, "2026-07-01")
    }

    func testResolvedTripSegmentRendererPayloadEncodesForRendererContract() throws {
        let segment = ResolvedTripSegment(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            fromCityName: "Bologna",
            toCityName: "Istanbul",
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: .plane,
            dateLabel: "2026-07-01"
        )

        let data = try JSONEncoder().encode(segment.rendererPayload)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains(#""transport":"plane""#))
        XCTAssertTrue(json.contains(#""dateLabel":"2026-07-01""#))
        XCTAssertTrue(json.contains(#""styleToken":"plane""#))
        XCTAssertTrue(json.contains(#""startLabel":"Bologna""#))
        XCTAssertTrue(json.contains(#""endLabel":"Istanbul""#))
        XCTAssertTrue(json.contains(#""name":"Bologna""#))
        XCTAssertTrue(json.contains(#""latitude":44.4949"#))
        XCTAssertTrue(json.contains(#""longitude":11.3426"#))
    }

    func testResolvedTripSegmentRendererPayloadIncludesStyleAndExplicitLabels() {
        let segment = ResolvedTripSegment(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            fromCityName: "Bologna",
            toCityName: "Istanbul",
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: .plane,
            dateLabel: "2026-07-01"
        )

        XCTAssertEqual(segment.rendererPayload.styleToken, "plane")
        XCTAssertEqual(segment.rendererPayload.startLabel, "Bologna")
        XCTAssertEqual(segment.rendererPayload.endLabel, "Istanbul")
    }

    func testHTMLBuilderEmbedsResolvedSegmentsAsJSON() throws {
        let html = try RoutePreviewHTMLBuilder.makeHTML(
            segments: [
                ResolvedTripSegment(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    fromCityName: "Bologna",
                    toCityName: "Istanbul",
                    fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
                    toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
                    transportType: .plane,
                    dateLabel: "2026-07-01"
                )
            ]
        )

        XCTAssertTrue(html.contains(#""transport":"plane""#))
        XCTAssertTrue(html.contains("Bologna"))
        XCTAssertTrue(html.contains("Istanbul"))
    }

    func testHTMLBuilderLoadsTemplateAndReplacesPayloadPlaceholder() throws {
        let html = try RoutePreviewHTMLBuilder.makeHTML(segments: [])

        XCTAssertTrue(html.contains(#"<script src="route-preview.js"></script>"#))
        XCTAssertTrue(html.contains(#"<link rel="stylesheet" href="route-preview.css">"#))
        XCTAssertTrue(html.contains(#"data-preview-root="true""#))
        XCTAssertTrue(html.contains(#"window.__ROUTE_SEGMENTS__ = [];"#))
        XCTAssertFalse(html.contains("__ROUTE_SEGMENTS_JSON__"))
    }
}

private struct StubTripRouteResolver: TripRouteResolving {
    var result: [ResolvedTripSegment] = []

    func resolve(segments: [TripSegmentInput]) async throws -> [ResolvedTripSegment] {
        result
    }
}
