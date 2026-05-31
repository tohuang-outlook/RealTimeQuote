import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let quoteBoardViewModel: QuoteBoardViewModel

    init(quoteBoardViewModel: QuoteBoardViewModel) {
        self.quoteBoardViewModel = quoteBoardViewModel
    }

    static func live() -> AppDependencies {
        let settingsStore = UserDefaultsAppSettingsStore()
        let selectedExchange = settingsStore.selectedExchange
        let selectedPair = settingsStore.selectedPair
        let quoteEngine = QuoteEngine(
            initialSnapshot: .placeholder(for: selectedPair, exchange: selectedExchange),
            streamFactory: { _, _ in LiveExchangeQuoteStream() }
        )
        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: quoteEngine)
        return AppDependencies(quoteBoardViewModel: viewModel)
    }
}

private final class LiveExchangeQuoteStream: ExchangeQuoteStreaming {
    let events = AsyncStream<ExchangeStreamEvent> { _ in }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {}

    func stop() {}
}
