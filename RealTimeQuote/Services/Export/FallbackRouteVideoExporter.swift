import Foundation

struct FallbackRouteVideoExporter: RouteVideoExporting {
    let primary: RouteVideoExporting
    let fallback: RouteVideoExporting

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        do {
            return try await primary.export(segments: segments)
        } catch let error as RouteVideoExportError {
            guard Self.shouldFallback(for: error) else {
                throw error
            }
            return try await fallback.export(segments: segments)
        }
    }

    private static func shouldFallback(for error: RouteVideoExportError) -> Bool {
        switch error {
        case .writerFailed, .outputFileMissing:
            return true
        case .rendererLoadFailed, .rendererTimedOut, .rendererFrameFailed, .frameCaptureFailed:
            return false
        }
    }
}
