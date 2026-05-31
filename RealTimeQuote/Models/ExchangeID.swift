import Foundation

enum ExchangeID: String, CaseIterable, Codable, Identifiable {
    case coinbase
    case okx

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coinbase:
            return "Coinbase"
        case .okx:
            return "OKX"
        }
    }
}
