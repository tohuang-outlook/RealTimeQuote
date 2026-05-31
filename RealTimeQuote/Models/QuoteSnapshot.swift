import Foundation

struct QuoteSnapshot: Equatable {
    let exchange: ExchangeID
    let pair: TradingPair
    let lastPrice: Decimal?
    let absoluteChange: Decimal?
    let percentChange: Decimal?
    let high24h: Decimal?
    let low24h: Decimal?
    let volume24h: Decimal?
    let updatedAt: Date?
    let connectionState: ConnectionState

    var displaySymbol: String {
        pair.displaySymbol
    }

    static func placeholder(for pair: TradingPair, exchange: ExchangeID) -> QuoteSnapshot {
        QuoteSnapshot(
            exchange: exchange,
            pair: pair,
            lastPrice: nil,
            absoluteChange: nil,
            percentChange: nil,
            high24h: nil,
            low24h: nil,
            volume24h: nil,
            updatedAt: nil,
            connectionState: .connecting
        )
    }
}
