import Foundation

enum RoutePreviewState: Equatable {
    case idle
    case resolving
    case ready([ResolvedTripSegment])
    case failed(String)
}
