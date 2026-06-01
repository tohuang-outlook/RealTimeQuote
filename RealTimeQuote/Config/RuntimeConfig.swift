import Foundation

struct RuntimeConfig: Decodable, Equatable {
    struct Defaults: Decodable, Equatable {
        let exchange: ExchangeID?
        let pair: TradingPair?
        let enabledExchanges: [ExchangeID]?
    }

    struct Coinbase: Decodable, Equatable {
        let apiKey: String?
        let apiSecret: String?
        let passphrase: String?
        let useAuthenticatedFeed: Bool?
    }

    struct OKX: Decodable, Equatable {
        let apiKey: String?
        let apiSecret: String?
        let passphrase: String?
        let useAuthenticatedFeed: Bool?
    }

    let defaults: Defaults?
    let coinbase: Coinbase?
    let okx: OKX?
}
