import AppKit
import CoreGraphics
import Foundation
import WebKit

@MainActor
final class WebKitRouteVideoRendererHost: NSObject, RouteVideoRendererHosting {
    private enum Constants {
        static let handlerName = "routePreview"
        // Allow WebGL tiles and the frame-driven 3D camera to settle before
        // snapshotting each video frame.
        static let renderDelayNanoseconds: UInt64 = 120_000_000
        static let timeoutNanoseconds: UInt64 = 10_000_000_000
    }

    private let segments: [ResolvedTripSegment]
    private let timeline: RouteVideoTimeline
    private let configuration: RouteVideoExportConfiguration
    private let googleMapsAPIKey: String?
    private let googleMapsMapID: String?
    private let webView: WKWebView

    private var prepareContinuation: CheckedContinuation<Void, Error>?
    private var loadError: RouteVideoExportError?
    private var didBecomeReady = false

    init(
        segments: [ResolvedTripSegment],
        timeline: RouteVideoTimeline,
        configuration: RouteVideoExportConfiguration,
        googleMapsAPIKey: String? = nil,
        googleMapsMapID: String? = nil
    ) {
        self.segments = segments
        self.timeline = timeline
        self.configuration = configuration
        self.googleMapsAPIKey = googleMapsAPIKey
        self.googleMapsMapID = googleMapsMapID

        let contentController = WKUserContentController()
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        self.webView = WKWebView(
            frame: CGRect(origin: .zero, size: configuration.renderSize),
            configuration: webConfiguration
        )

        super.init()

        contentController.add(self, name: Constants.handlerName)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
    }

    func prepare() async throws {
        let exportContext = RoutePreviewHTMLBuilder.ExportContext(
            frame: .init(
                width: configuration.renderSize.width,
                height: configuration.renderSize.height,
                fps: configuration.framesPerSecond
            ),
            totalDuration: timeline.totalDuration,
            segmentTimings: timeline.segmentTimings.map {
                .init(segmentID: $0.segmentID, startTime: $0.startTime, endTime: $0.endTime)
            }
        )

        let html = try RoutePreviewHTMLBuilder.makeHTML(
            segments: segments,
            exportContext: exportContext,
            googleMapsAPIKey: googleMapsAPIKey,
            googleMapsMapID: googleMapsMapID
        )
        let baseURL = RoutePreviewHTMLBuilder.resourceBaseURL()

        let readyTask = Task {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                prepareContinuation = continuation
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: Constants.timeoutNanoseconds)
            throw RouteVideoExportError.rendererTimedOut
        }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await readyTask.value }
                group.addTask { try await timeoutTask.value }
                try await group.next()
                group.cancelAll()
            }
        } catch {
            prepareContinuation?.resume(throwing: error)
            prepareContinuation = nil
            throw error
        }
    }

    func renderFrame(at time: TimeInterval) async throws -> CGImage {
        guard didBecomeReady else {
            throw RouteVideoExportError.rendererLoadFailed
        }

        let script = "window.__ROUTE_EXPORT_BRIDGE__ && window.__ROUTE_EXPORT_BRIDGE__.renderFrameAtTime(\(time))"
        _ = try await evaluateJavaScript(script)
        try await Task.sleep(nanoseconds: Constants.renderDelayNanoseconds)

        let snapshotConfiguration = WKSnapshotConfiguration()
        snapshotConfiguration.rect = CGRect(origin: .zero, size: configuration.renderSize)

        guard let image = try await takeSnapshot(configuration: snapshotConfiguration),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw RouteVideoExportError.frameCaptureFailed
        }

        return cgImage
    }

    func tearDown() async {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constants.handlerName)
        prepareContinuation = nil
        loadError = nil
        didBecomeReady = false
    }

    private func evaluateJavaScript(_ script: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { value, error in
                if error != nil {
                    continuation.resume(throwing: RouteVideoExportError.rendererFrameFailed)
                } else {
                    continuation.resume(returning: value)
                }
            }
        }
    }

    private func takeSnapshot(configuration: WKSnapshotConfiguration) async throws -> NSImage? {
        try await withCheckedThrowingContinuation { continuation in
            webView.takeSnapshot(with: configuration) { image, error in
                if error != nil {
                    continuation.resume(throwing: RouteVideoExportError.frameCaptureFailed)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private func finishPrepare(with result: Result<Void, Error>) {
        guard let continuation = prepareContinuation else { return }
        prepareContinuation = nil
        switch result {
        case .success:
            didBecomeReady = true
            continuation.resume()
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

extension WebKitRouteVideoRendererHost: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let loadError {
            finishPrepare(with: .failure(loadError))
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishPrepare(with: .failure(RouteVideoExportError.rendererLoadFailed))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishPrepare(with: .failure(RouteVideoExportError.rendererLoadFailed))
    }
}

extension WebKitRouteVideoRendererHost: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Constants.handlerName,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }

        switch type {
        case "ready":
            finishPrepare(with: .success(()))
        case "error":
            let _ = body["message"] as? String
            loadError = .rendererLoadFailed
            finishPrepare(with: .failure(RouteVideoExportError.rendererLoadFailed))
        default:
            break
        }
    }
}
