import Foundation

protocol RouteVideoExporting {
    func export(segments: [ResolvedTripSegment]) async throws -> URL
}
