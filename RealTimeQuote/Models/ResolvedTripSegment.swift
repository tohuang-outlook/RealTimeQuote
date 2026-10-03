import Foundation

struct GeoCoordinate: Equatable, Codable {
    let latitude: Double
    let longitude: Double
}

struct ResolvedTripSegment: Equatable, Identifiable {
    struct RendererCity: Equatable, Codable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    struct RendererPayload: Equatable, Codable {
        let id: UUID
        let from: RendererCity
        let to: RendererCity
        let transport: String
        let dateLabel: String
        let styleToken: String
        let startLabel: String
        let endLabel: String
    }

    let id: UUID
    let fromCityName: String
    let toCityName: String
    let fromCoordinate: GeoCoordinate
    let toCoordinate: GeoCoordinate
    let transportType: TripTransportType
    let dateLabel: String

    var rendererPayload: RendererPayload {
        RendererPayload(
            id: id,
            from: .init(
                name: fromCityName,
                latitude: fromCoordinate.latitude,
                longitude: fromCoordinate.longitude
            ),
            to: .init(
                name: toCityName,
                latitude: toCoordinate.latitude,
                longitude: toCoordinate.longitude
            ),
            transport: transportType.rawValue,
            dateLabel: dateLabel,
            styleToken: transportType.rawValue,
            startLabel: fromCityName,
            endLabel: toCityName
        )
    }
}
