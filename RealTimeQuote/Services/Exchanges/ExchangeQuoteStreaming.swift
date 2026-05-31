import Foundation

protocol ExchangeQuoteStreaming: AnyObject {
    var events: AsyncStream<ExchangeStreamEvent> { get }

    func start(exchange: ExchangeID, pair: TradingPair) async throws
    func stop()
}
