import Foundation

enum TripRouteResolutionError: Error, Equatable {
    case incompleteSegment(segmentIndex: Int)
    case unresolvedCity(segmentIndex: Int, cityName: String)
}

protocol TripRouteResolving {
    func resolve(segments: [TripSegmentInput]) async throws -> [ResolvedTripSegment]
}
