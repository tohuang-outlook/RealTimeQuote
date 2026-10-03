import Foundation

struct StaticCityResolver: CityResolving {
    private let cities: [String: GeoCoordinate]
    private let airportAliases: [String: String]

    init() {
        let dataset = Self.loadDataset()
        self.cities = dataset.cities.reduce(into: [:]) { partialResult, city in
            partialResult[city.name.normalizedLookupKey] = .init(
                latitude: city.latitude,
                longitude: city.longitude
            )
        }
        self.airportAliases = dataset.airportAliases.reduce(into: [:]) { partialResult, alias in
            partialResult[alias.code.normalizedLookupKey] = alias.city.normalizedLookupKey
        }
    }

    func resolveCity(named name: String) async throws -> GeoCoordinate? {
        let normalizedName = name.normalizedLookupKey
        let canonicalName = airportAliases[normalizedName] ?? normalizedName
        return cities[canonicalName]
    }

    private static func loadDataset() -> TripLocationDataset {
        let candidateBundles = [Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks

        for bundle in candidateBundles {
            if let url = bundle.url(forResource: "trip-location-dataset", withExtension: "json"),
               let dataset = decodeDataset(at: url) {
                return dataset
            }

            if let url = bundle.url(forResource: "trip-location-dataset", withExtension: "json", subdirectory: "Resources"),
               let dataset = decodeDataset(at: url) {
                return dataset
            }
        }

        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("trip-location-dataset.json")

        if let dataset = decodeDataset(at: sourceURL) {
            return dataset
        }

        return .empty
    }

    private static func decodeDataset(at url: URL) -> TripLocationDataset? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(TripLocationDataset.self, from: data)
        } catch {
            return nil
        }
    }

    private final class BundleToken {}
}

private struct TripLocationDataset: Decodable {
    struct City: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    struct AirportAlias: Decodable {
        let code: String
        let city: String
    }

    let cities: [City]
    let airportAliases: [AirportAlias]

    static let empty = TripLocationDataset(cities: [], airportAliases: [])
}

private extension String {
    var normalizedLookupKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
