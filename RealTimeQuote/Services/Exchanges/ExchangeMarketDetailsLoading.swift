import Foundation

protocol ExchangeMarketDetailsLoading {
    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot
}

struct NoOpExchangeMarketDetailsLoader: ExchangeMarketDetailsLoading {
    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot {
        .empty
    }
}

struct DefaultExchangeMarketDetailsLoader: ExchangeMarketDetailsLoading {
    private let coinbaseLoader: CoinbaseMarketDetailsLoader
    private let okxLoader: OKXMarketDetailsLoader

    init(
        coinbaseLoader: CoinbaseMarketDetailsLoader = CoinbaseMarketDetailsLoader(),
        okxLoader: OKXMarketDetailsLoader = OKXMarketDetailsLoader()
    ) {
        self.coinbaseLoader = coinbaseLoader
        self.okxLoader = okxLoader
    }

    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot {
        switch exchange {
        case .coinbase:
            return try await coinbaseLoader.loadDetails(for: exchange, pair: pair)
        case .okx:
            return try await okxLoader.loadDetails(for: exchange, pair: pair)
        }
    }
}

enum MarketDetailsLoaderError: Error {
    case invalidRequest
    case invalidResponse
    case missingData
}

enum MarketDetailsCalendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()
}
