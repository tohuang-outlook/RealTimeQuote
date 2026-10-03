import Foundation

enum RoutePreviewHTMLBuilder {
    struct ExportContext: Equatable, Encodable {
        struct SegmentTiming: Equatable, Encodable {
            let segmentID: UUID
            let startTime: TimeInterval
            let endTime: TimeInterval
        }

        struct Frame: Equatable, Encodable {
            let width: Double
            let height: Double
            let fps: Int32
        }

        let frame: Frame
        let totalDuration: TimeInterval
        let segmentTimings: [SegmentTiming]
    }

    enum Error: Swift.Error {
        case templateNotFound
        case templateUnreadable
        case payloadEncodingFailed
        case payloadPlaceholderMissing
    }

    private static let payloadPlaceholder = "__ROUTE_SEGMENTS_JSON__"
    private static let exportPlaceholder = "__ROUTE_EXPORT_JSON__"
    private static let bridgePlaceholder = "__ROUTE_PREVIEW_BRIDGE__"
    private static let googleMapsAPIKeyPlaceholder = "__GOOGLE_MAPS_API_KEY_JSON__"
    private static let googleMapsMapIDPlaceholder = "__GOOGLE_MAPS_MAP_ID_JSON__"

    static func makeHTML(
        segments: [ResolvedTripSegment],
        exportContext: ExportContext? = nil,
        googleMapsAPIKey: String? = nil,
        googleMapsMapID: String? = nil
    ) throws -> String {
        let template = try loadTemplateHTML()
        let json = try makePayloadJSON(segments: segments)
        let exportJSON = try makeExportJSON(exportContext: exportContext)
        let googleMapsAPIKeyJSON = try makeOptionalStringJSON(googleMapsAPIKey)
        let googleMapsMapIDJSON = try makeOptionalStringJSON(googleMapsMapID)

        guard template.contains(payloadPlaceholder) else {
            throw Error.payloadPlaceholderMissing
        }

        return template
            .replacingOccurrences(of: payloadPlaceholder, with: json)
            .replacingOccurrences(of: exportPlaceholder, with: exportJSON)
            .replacingOccurrences(of: googleMapsAPIKeyPlaceholder, with: googleMapsAPIKeyJSON)
            .replacingOccurrences(of: googleMapsMapIDPlaceholder, with: googleMapsMapIDJSON)
            .replacingOccurrences(of: bridgePlaceholder, with: makeBridgeBootstrapScript())
    }

    static func resourceBaseURL() -> URL? {
        try? templateURL().deletingLastPathComponent()
    }

    static func fallbackHTML(message: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <style>
            html, body { margin: 0; height: 100%; background: #04070b; color: white; font-family: -apple-system; }
            body { display: flex; align-items: center; justify-content: center; padding: 24px; text-align: center; }
            p { margin: 0; font-size: 14px; color: rgba(255,255,255,0.82); }
          </style>
        </head>
        <body>
          <p>\(message)</p>
        </body>
        </html>
        """
    }

    private static func makePayloadJSON(segments: [ResolvedTripSegment]) throws -> String {
        let payload = segments.map(\.rendererPayload)
        guard let data = try? JSONEncoder().encode(payload) else {
            throw Error.payloadEncodingFailed
        }

        return String(decoding: data, as: UTF8.self)
    }

    private static func makeExportJSON(exportContext: ExportContext?) throws -> String {
        guard let exportContext else {
            return "null"
        }

        guard let data = try? JSONEncoder().encode(exportContext) else {
            throw Error.payloadEncodingFailed
        }

        return String(decoding: data, as: UTF8.self)
    }

    private static func makeOptionalStringJSON(_ value: String?) throws -> String {
        guard let data = try? JSONEncoder().encode(value) else {
            throw Error.payloadEncodingFailed
        }

        return String(decoding: data, as: UTF8.self)
    }

    private static func loadTemplateHTML() throws -> String {
        let url = try templateURL()

        guard let html = try? String(contentsOf: url, encoding: .utf8) else {
            throw Error.templateUnreadable
        }

        return html
    }

    private static func makeBridgeBootstrapScript() -> String {
        """
        window.__ROUTE_PREVIEW_BRIDGE__ = {
          ready() {
            window.webkit?.messageHandlers?.routePreview?.postMessage({ type: "ready" });
          },
          fail(message) {
            window.webkit?.messageHandlers?.routePreview?.postMessage({ type: "error", message });
          }
        };
        """
    }

    private static func templateURL() throws -> URL {
        let candidateBundles = [Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks

        for bundle in candidateBundles {
            if let url = bundle.url(forResource: "route-preview", withExtension: "html") {
                return url
            }

            if let url = bundle.url(forResource: "route-preview", withExtension: "html", subdirectory: "RoutePreview") {
                return url
            }
        }

        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("RoutePreview")
            .appendingPathComponent("route-preview.html")

        if FileManager.default.fileExists(atPath: sourceURL.path) {
            return sourceURL
        }

        throw Error.templateNotFound
    }

    private final class BundleToken {}
}
