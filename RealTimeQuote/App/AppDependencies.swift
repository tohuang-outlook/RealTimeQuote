import Foundation

struct AppBootstrapSelection {
    let exchange: ExchangeID
    let pair: TradingPair
}

enum AppBootstrapSelectionResolver {
    static func resolve(
        settingsStore: AppSettingsStore,
        config: RuntimeConfig?
    ) -> AppBootstrapSelection {
        let fallback = AppBootstrapSelection(exchange: .coinbase, pair: .btcUSD)
        let enabledExchanges = config?.defaults?.enabledExchanges ?? ExchangeID.allCases

        let fallbackExchange = enabledExchanges.contains(.coinbase) ? .coinbase : (enabledExchanges.first ?? .coinbase)
        let fallbackSelection = AppBootstrapSelection(exchange: fallbackExchange, pair: fallback.pair)

        let configSelection = AppBootstrapSelection(
            exchange: config?.defaults?.exchange ?? fallbackSelection.exchange,
            pair: config?.defaults?.pair ?? fallbackSelection.pair
        )

        if let storedSelection = settingsStore.storedSelection, enabledExchanges.contains(storedSelection.exchange) {
            return AppBootstrapSelection(exchange: storedSelection.exchange, pair: storedSelection.pair)
        }

        if enabledExchanges.contains(configSelection.exchange) {
            return configSelection
        }

        return fallbackSelection
    }
}

@MainActor
final class AppDependencies: ObservableObject {
    let quoteBoardViewModel: QuoteBoardViewModel

    init(quoteBoardViewModel: QuoteBoardViewModel) {
        self.quoteBoardViewModel = quoteBoardViewModel
    }

    static func live() -> AppDependencies {
        let settingsStore = UserDefaultsAppSettingsStore()
        let bootstrapConfig = try? RuntimeConfigLoader().load().config
        let selection = AppBootstrapSelectionResolver.resolve(
            settingsStore: settingsStore,
            config: bootstrapConfig
        )
        let quoteEngine = QuoteEngine(
            initialSnapshot: .placeholder(for: selection.pair, exchange: selection.exchange),
            streamFactory: { exchange, _ in
                switch exchange {
                case .coinbase:
                    return CoinbaseQuoteStream(config: bootstrapConfig?.coinbase)
                case .okx:
                    return OKXQuoteStream(config: bootstrapConfig?.okx)
                }
            }
        )
        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: quoteEngine)
        return AppDependencies(quoteBoardViewModel: viewModel)
    }
}
