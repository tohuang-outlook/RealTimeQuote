import SwiftUI
import WebKit

struct RoutePreviewWebView: NSViewRepresentable {
    let segments: [ResolvedTripSegment]
    let googleMapsAPIKey: String?
    let googleMapsMapID: String?
    var onRendererEvent: (RoutePreviewRendererEvent) -> Void = { _ in }
    var replayToken: UInt64 = 0

    func makeCoordinator() -> Coordinator {
        Coordinator(onRendererEvent: onRendererEvent)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: Coordinator.handlerName)
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let renderedDocument = makeRenderedDocument()
        let shouldReload =
            context.coordinator.lastHTML != renderedDocument.html ||
            context.coordinator.lastReplayToken != replayToken

        guard shouldReload else {
            return
        }

        context.coordinator.lastHTML = renderedDocument.html
        context.coordinator.lastReplayToken = replayToken
        let baseURL = renderedDocument.baseURL
        webView.loadHTMLString(renderedDocument.html, baseURL: baseURL)
    }

    private func makeRenderedDocument() -> RenderedDocument {
        do {
            return RenderedDocument(
                html: try RoutePreviewHTMLBuilder.makeHTML(
                    segments: segments,
                    googleMapsAPIKey: googleMapsAPIKey
                    , googleMapsMapID: googleMapsMapID
                ),
                baseURL: RoutePreviewHTMLBuilder.resourceBaseURL()
            )
        } catch {
            return RenderedDocument(
                html: RoutePreviewHTMLBuilder.fallbackHTML(message: "Unable to load route preview."),
                baseURL: nil
            )
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        static let handlerName = "routePreview"

        var lastHTML: String?
        var lastReplayToken: UInt64 = 0
        private let onRendererEvent: (RoutePreviewRendererEvent) -> Void

        init(onRendererEvent: @escaping (RoutePreviewRendererEvent) -> Void) {
            self.onRendererEvent = onRendererEvent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.handlerName,
                  let body = message.body as? [String: String],
                  let event = Self.parseEvent(body) else { return }
            onRendererEvent(event)
        }

        static func parseEvent(_ body: [String: String]) -> RoutePreviewRendererEvent? {
            switch body["type"] {
            case "ready":
                return .didBecomeReady
            case "error":
                return .didFail(body["message"] ?? "Preview renderer failed")
            default:
                return nil
            }
        }
    }

    private struct RenderedDocument {
        let html: String
        let baseURL: URL?
    }
}
