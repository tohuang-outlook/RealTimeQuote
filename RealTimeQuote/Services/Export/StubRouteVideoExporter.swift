import Foundation

struct StubRouteVideoExporter: RouteVideoExporting {
    let resultURL: URL

    init(resultURL: URL = URL(fileURLWithPath: "/tmp/route-preview.mp4")) {
        self.resultURL = resultURL
    }

    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        resultURL
    }
}
