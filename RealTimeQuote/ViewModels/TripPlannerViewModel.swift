import Combine
import Foundation

@MainActor
final class TripPlannerViewModel: ObservableObject {
    @Published private(set) var segments: [TripSegmentInput]
    @Published private(set) var previewState: RoutePreviewState
    @Published private(set) var previewSegments: [ResolvedTripSegment]
    @Published private(set) var previewReplayToken: UInt64
    @Published private(set) var autoPreviewRequestToken: UInt64
    @Published private(set) var isExporting = false
    @Published private(set) var exportedVideoURL: URL?
    @Published private(set) var lastErrorMessage: String?

    var canExport: Bool {
        guard case .ready = previewState else { return false }
        return !isExporting
    }

    var shouldAutoPreview: Bool {
        !segments.isEmpty && segments.allSatisfy(\.isComplete)
    }

    let googleMapsAPIKey: String?
    let googleMapsMapID: String?

    private let routeResolver: TripRouteResolving
    private let exporter: RouteVideoExporting
    private var previewGeneration: UInt64 = 0

    init(
        routeResolver: TripRouteResolving,
        exporter: RouteVideoExporting,
        googleMapsAPIKey: String? = nil,
        googleMapsMapID: String? = nil
    ) {
        self.routeResolver = routeResolver
        self.exporter = exporter
        self.googleMapsAPIKey = googleMapsAPIKey
        self.googleMapsMapID = googleMapsMapID
        self.segments = [TripSegmentInput.empty(order: 0)]
        self.previewState = .idle
        self.previewSegments = []
        self.previewReplayToken = 0
        self.autoPreviewRequestToken = 0
    }

    func addSegment() {
        segments.append(.empty(order: segments.count))
        invalidateDerivedState()
    }

    func removeSegment(id: UUID) {
        segments.removeAll { $0.id == id }
        reindexSegments()
        invalidateDerivedState()
    }

    func updateSegmentCity(id: UUID, keyPath: WritableKeyPath<TripSegmentInput, String>, value: String) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index][keyPath: keyPath] = value
        invalidateDerivedState()
    }

    func updateTransport(id: UUID, transportType: TripTransportType) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index].transportType = transportType
        invalidateDerivedState()
    }

    func generatePreview() async {
        previewGeneration &+= 1
        let generation = previewGeneration
        previewState = .resolving
        previewSegments = []
        lastErrorMessage = nil

        do {
            let resolved = try await routeResolver.resolve(segments: segments)
            guard generation == previewGeneration else { return }
            previewSegments = resolved
            previewState = .resolving
        } catch let error as TripRouteResolutionError {
            guard generation == previewGeneration else { return }
            previewSegments = []
            let message = Self.message(for: error)
            previewState = .failed(message)
            lastErrorMessage = message
        } catch {
            guard generation == previewGeneration else { return }
            previewSegments = []
            previewState = .failed("Preview generation failed")
            lastErrorMessage = "Preview generation failed"
        }
    }

    func handleRendererEvent(_ event: RoutePreviewRendererEvent) {
        switch event {
        case .didBecomeReady:
            guard !previewSegments.isEmpty else { return }
            previewState = .ready(previewSegments)
            lastErrorMessage = nil
        case let .didFail(message):
            previewState = .failed(message)
            lastErrorMessage = message
        }
    }

    func replayPreview() {
        guard !previewSegments.isEmpty else { return }
        previewReplayToken &+= 1
        previewState = .resolving
        lastErrorMessage = nil
    }

    func exportVideo() async {
        guard case let .ready(resolved) = previewState else { return }
        let generation = previewGeneration
        isExporting = true
        exportedVideoURL = nil
        lastErrorMessage = nil
        defer { isExporting = false }

        do {
            let url = try await exporter.export(segments: resolved)
            guard generation == previewGeneration else { return }
            exportedVideoURL = url
        } catch {
            guard generation == previewGeneration else { return }
            lastErrorMessage = Self.message(for: error)
        }
    }

    private func reindexSegments() {
        for index in segments.indices {
            segments[index].order = index
        }
    }

    private func invalidateDerivedState() {
        previewGeneration &+= 1
        previewReplayToken &+= 1
        autoPreviewRequestToken &+= 1
        previewState = .idle
        previewSegments = []
        exportedVideoURL = nil
        lastErrorMessage = nil
    }

    private static func message(for error: TripRouteResolutionError) -> String {
        switch error {
        case let .incompleteSegment(segmentIndex):
            return "Segment \(segmentIndex + 1) is incomplete"
        case let .unresolvedCity(_, cityName):
            return "City not found: \(cityName)"
        }
    }

    private static func message(for error: Error) -> String {
        if let exportError = error as? RouteVideoExportError,
           let description = exportError.errorDescription {
            return description
        }

        return "Video export failed"
    }
}
