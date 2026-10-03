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

    struct GoogleMaps: Decodable, Equatable {
        let apiKey: String?
        let mapId: String?
    }

    let defaults: Defaults?
    let coinbase: Coinbase?
    let okx: OKX?
    let coinGecko: CoinGecko?
    let googleMaps: GoogleMaps?

    init(
        defaults: Defaults?,
        coinbase: Coinbase?,
        okx: OKX?,
        coinGecko: CoinGecko?,
        googleMaps: GoogleMaps? = nil
    ) {
        self.defaults = defaults
        self.coinbase = coinbase
        self.okx = okx
        self.coinGecko = coinGecko
        self.googleMaps = googleMaps
    }

    private enum CodingKeys: String, CodingKey {
        case defaults
        case coinbase
        case okx
        case coinGecko
        case googleMaps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Each integration is optional. A stale quote-provider setting must not
        // prevent Travel Map from loading an otherwise valid Google Maps key.
        defaults = try? container.decodeIfPresent(Defaults.self, forKey: .defaults)
        coinbase = try? container.decodeIfPresent(Coinbase.self, forKey: .coinbase)
        okx = try? container.decodeIfPresent(OKX.self, forKey: .okx)
        coinGecko = try? container.decodeIfPresent(CoinGecko.self, forKey: .coinGecko)
        googleMaps = try? container.decodeIfPresent(GoogleMaps.self, forKey: .googleMaps)
    }
}
