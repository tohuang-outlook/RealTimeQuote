import Foundation

struct DefaultTripRouteResolver: TripRouteResolving {
    let cityResolver: CityResolving

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func resolve(segments: [TripSegmentInput]) async throws -> [ResolvedTripSegment] {
        var resolved: [ResolvedTripSegment] = []

        for (index, segment) in segments.sorted(by: { $0.order < $1.order }).enumerated() {
            guard segment.isComplete else {
                throw TripRouteResolutionError.incompleteSegment(segmentIndex: index)
            }

            guard let from = try await cityResolver.resolveCity(named: segment.fromCityName) else {
                throw TripRouteResolutionError.unresolvedCity(segmentIndex: index, cityName: segment.fromCityName)
            }

            guard let to = try await cityResolver.resolveCity(named: segment.toCityName) else {
                throw TripRouteResolutionError.unresolvedCity(segmentIndex: index, cityName: segment.toCityName)
            }

            resolved.append(
                ResolvedTripSegment(
                    id: segment.id,
                    fromCityName: segment.fromCityName,
                    toCityName: segment.toCityName,
                    fromCoordinate: from,
                    toCoordinate: to,
                    transportType: segment.transportType,
                    dateLabel: dateFormatter.string(from: segment.date)
                )
            )
        }

        return resolved
    }
}
