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

    struct CoinGecko: Decodable, Equatable {
        let apiKey: String?
        let useProAPI: Bool?

        var baseURL: URL {
            if useProAPI == true {
                return URL(string: "https://pro-api.coingecko.com/api/v3")!
            }
            return URL(string: "https://api.coingecko.com/api/v3")!
        }

        var headerName: String {
            if useProAPI == true {
                return "x-cg-pro-api-key"
            }
            return "x-cg-demo-api-key"
        }
    }

    let defaults: Defaults?
    let coinbase: Coinbase?
    let okx: OKX?
    let coinGecko: CoinGecko?
}
