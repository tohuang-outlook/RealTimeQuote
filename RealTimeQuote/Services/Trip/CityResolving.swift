import Foundation

protocol CityResolving {
    func resolveCity(named name: String) async throws -> GeoCoordinate?
}
