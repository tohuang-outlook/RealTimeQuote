import XCTest
@testable import RealTimeQuote

final class RoutePreviewBridgeTests: XCTestCase {
    func testHTMLBuilderInjectsRendererBridgeBootstrapScript() throws {
        let html = try RoutePreviewHTMLBuilder.makeHTML(
            segments: [],
            googleMapsAPIKey: "maps-key",
            googleMapsMapID: "map-id"
        )

        XCTAssertTrue(html.contains("window.__ROUTE_SEGMENTS__ = [];"))
        XCTAssertTrue(html.contains("window.__ROUTE_PREVIEW_BRIDGE__"))
        XCTAssertTrue(html.contains("window.__GOOGLE_MAPS_API_KEY__ = \"maps-key\""))
        XCTAssertTrue(html.contains("window.__GOOGLE_MAPS_MAP_ID__ = \"map-id\""))
        XCTAssertTrue(html.contains("route-preview.css"))
    }

    func testRendererEventParsingMapsReadyAndFailureMessages() {
        XCTAssertEqual(
            RoutePreviewWebView.Coordinator.parseEvent(["type": "ready"]),
            .didBecomeReady
        )
        XCTAssertEqual(
            RoutePreviewWebView.Coordinator.parseEvent(["type": "error", "message": "Renderer crashed"]),
            .didFail("Renderer crashed")
        )
    }

    func testRendererResourcesIncludeChapterAndProgressPresentationHooks() throws {
        let baseURL = try XCTUnwrap(RoutePreviewHTMLBuilder.resourceBaseURL())
        let script = try String(
            contentsOf: baseURL.appendingPathComponent("route-preview.js"),
            encoding: .utf8
        )
        let stylesheet = try String(
            contentsOf: baseURL.appendingPathComponent("route-preview.css"),
            encoding: .utf8
        )

        XCTAssertTrue(script.contains("preview-chapter"))
        XCTAssertTrue(script.contains("preview-progress-fill"))
        XCTAssertTrue(script.contains("setProgressState"))

        XCTAssertTrue(stylesheet.contains(".preview-chapter"))
        XCTAssertTrue(stylesheet.contains(".preview-progress"))
        XCTAssertTrue(stylesheet.contains(".preview-progress-fill"))
    }

    func testRendererResourcesIncludeVideoMapPresentationHooks() throws {
        let baseURL = try XCTUnwrap(RoutePreviewHTMLBuilder.resourceBaseURL())
        let script = try String(
            contentsOf: baseURL.appendingPathComponent("route-preview.js"),
            encoding: .utf8
        )
        let stylesheet = try String(
            contentsOf: baseURL.appendingPathComponent("route-preview.css"),
            encoding: .utf8
        )

        XCTAssertTrue(script.contains("CITY_FLAGS"))
        XCTAssertTrue(script.contains("SEA_PATCHES"))
        XCTAssertTrue(script.contains("decorateLabelText"))
        XCTAssertTrue(script.contains("ocean-gradient"))
        XCTAssertTrue(script.contains("terrain-gradient"))
        XCTAssertTrue(script.contains("initializeGoogleMap"))
        XCTAssertTrue(script.contains("Map3DElement"))
        XCTAssertTrue(script.contains("setGoogle3DCameraForExportFrame"))
        XCTAssertTrue(script.contains("MapTypeId.SATELLITE"))

        XCTAssertTrue(stylesheet.contains(".map-label-card"))
        XCTAssertTrue(stylesheet.contains(".route-icon"))
        XCTAssertTrue(stylesheet.contains(".google-map"))
    }
}
