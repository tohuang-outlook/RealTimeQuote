import Foundation

enum TripTransportType: String, CaseIterable, Codable, Identifiable {
    case plane
    case train
    case car

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .plane:
            return "Plane"
        case .train:
            return "Train"
        case .car:
            return "Car"
        }
    }
}
