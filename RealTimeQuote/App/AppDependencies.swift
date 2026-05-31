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
            streamFactory: { exchange, _ in
                switch exchange {
                case .coinbase:
                    return CoinbaseQuoteStream()
                case .okx:
                    return OKXQuoteStream()
                }
            }
        )
        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: quoteEngine)
        return AppDependencies(quoteBoardViewModel: viewModel)
    }
}
