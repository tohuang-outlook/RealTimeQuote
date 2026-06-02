import XCTest
@testable import RealTimeQuote

@MainActor
final class AppDependenciesFactoryTests: XCTestCase {
    func testFactoryCreatesDistinctViewModelsForDifferentWindows() {
        let suiteName = "AppDependenciesFactoryTests.\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = UserDefaultsAppSettingsStore(defaults: defaults)
        let dependencies = AppDependencies(
            settingsStore: settingsStore,
            config: nil
        )

        let first = dependencies.makeQuoteBoardViewModel()
        let second = dependencies.makeQuoteBoardViewModel()

        XCTAssertFalse(first === second)
    }

    func testViewModelUsesExplicitInitialSelectionInsteadOfReadingSharedStoreState() {
        let settingsStore = InMemoryAppSettingsStore(
            selection: AppSelection(exchange: .coinbase, pair: .btcUSD)
        )
        let quoteEngine = QuoteEngine(
            initialSnapshot: .placeholder(for: .ethUSD, exchange: .coinbase),
            streamFactory: { _, _ in TestExchangeQuoteStream() }
        )

        let viewModel = QuoteBoardViewModel(
            initialSelection: AppBootstrapSelection(exchange: .coinbase, pair: .ethUSD),
            settingsStore: settingsStore,
            quoteEngine: quoteEngine,
            startupRetryAttempts: 1,
            startupRetryDelayNanoseconds: 0
        )

        XCTAssertEqual(viewModel.selectedPair, .ethUSD)
        XCTAssertEqual(viewModel.selectedExchange, .coinbase)
    }
}

private final class InMemoryAppSettingsStore: AppSettingsStore {
    var storedSelection: AppSelection?

    init(selection: AppSelection?) {
        self.storedSelection = selection
    }

    var selectedExchange: ExchangeID {
        get { storedSelection?.exchange ?? .coinbase }
        set { setSelection(exchange: newValue, pair: selectedPair) }
    }

    var selectedPair: TradingPair {
        get { storedSelection?.pair ?? .btcUSD }
        set { setSelection(exchange: selectedExchange, pair: newValue) }
    }

    func setSelection(exchange: ExchangeID, pair: TradingPair) {
        storedSelection = AppSelection(exchange: exchange, pair: pair)
    }
}

private final class TestExchangeQuoteStream: ExchangeQuoteStreaming {
    let events = AsyncStream<ExchangeStreamEvent> { _ in }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {}

    func stop() {}
}
