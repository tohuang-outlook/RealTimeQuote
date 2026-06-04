import Foundation

protocol ExchangeMarketDetailsLoading {
    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot
}

struct NoOpExchangeMarketDetailsLoader: ExchangeMarketDetailsLoading {
    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot {
        .empty
    }
}
