import Foundation

enum TradingPair: CaseIterable, Codable, Identifiable {
    case btcUSD
    case ethUSD
    case solUSD

    var id: String { persistenceKey }

    var persistenceKey: String {
        switch self {
        case .btcUSD:
            return "btc_usd"
        case .ethUSD:
            return "eth_usd"
        case .solUSD:
            return "sol_usd"
        }
    }

    var displaySymbol: String {
        switch self {
        case .btcUSD:
            return "BTC-USD"
        case .ethUSD:
            return "ETH-USD"
        case .solUSD:
            return "SOL-USD"
        }
    }

    var coinbaseProductID: String { displaySymbol }
    var okxInstrumentID: String { displaySymbol }

    init?(persistenceKey: String) {
        switch persistenceKey {
        case "btc_usd", "BTC-USD":
            self = .btcUSD
        case "eth_usd", "ETH-USD":
            self = .ethUSD
        case "sol_usd", "SOL-USD":
            self = .solUSD
        default:
            return nil
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let persistenceKey = try container.decode(String.self)
        guard let pair = TradingPair(persistenceKey: persistenceKey) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported trading pair: \(persistenceKey)")
        }
        self = pair
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(persistenceKey)
    }
}
