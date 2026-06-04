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

    func testNewWindowCopiesLatestPersistedSelectionWhileExistingWindowKeepsItsOwnState() async {
        let settingsStore = InMemoryAppSettingsStore(
            selection: AppSelection(exchange: .coinbase, pair: .btcUSD)
        )

        let first = makeViewModel(
            initialSelection: AppBootstrapSelection(exchange: .coinbase, pair: .btcUSD),
            settingsStore: settingsStore
        )
        first.selectPair(.ethUSD)

        await waitUntil { settingsStore.selectedPair == .ethUSD }

        let second = makeViewModel(
            initialSelection: AppBootstrapSelectionResolver.resolve(settingsStore: settingsStore, config: nil),
            settingsStore: settingsStore
        )

        XCTAssertEqual(first.selectedPair, .ethUSD)
        XCTAssertEqual(second.selectedPair, .ethUSD)

        second.selectPair(.btcUSD)

        await waitUntil { settingsStore.selectedPair == .btcUSD }

        XCTAssertEqual(first.selectedPair, .ethUSD)
        XCTAssertEqual(second.selectedPair, .btcUSD)
    }

    func testFactoryUsesResolvedBootstrapSelectionForNewWindow() {
        let settingsStore = InMemoryAppSettingsStore(selection: nil)
        let config = RuntimeConfig(
            defaults: .init(exchange: .okx, pair: .ethUSD, enabledExchanges: [.coinbase, .okx]),
            coinbase: nil,
            okx: nil
        )
        let dependencies = AppDependencies(settingsStore: settingsStore, config: config)

        let viewModel = dependencies.makeQuoteBoardViewModel()

        XCTAssertEqual(viewModel.selectedExchange, .okx)
        XCTAssertEqual(viewModel.selectedPair, .ethUSD)
    }

    func testViewModelStartsWithEmptyMarketDetails() {
        let viewModel = makeViewModel(
            initialSelection: AppBootstrapSelection(exchange: .coinbase, pair: .btcUSD),
            settingsStore: InMemoryAppSettingsStore(selection: nil)
        )

        XCTAssertEqual(viewModel.marketDetails, .empty)
    }

    private func makeViewModel(
        initialSelection: AppBootstrapSelection,
        settingsStore: AppSettingsStore
    ) -> QuoteBoardViewModel {
        let quoteEngine = QuoteEngine(
            initialSnapshot: .placeholder(for: initialSelection.pair, exchange: initialSelection.exchange),
            streamFactory: { _, _ in TestExchangeQuoteStream() }
        )

        return QuoteBoardViewModel(
            initialSelection: initialSelection,
            settingsStore: settingsStore,
            quoteEngine: quoteEngine,
            startupRetryAttempts: 1,
            startupRetryDelayNanoseconds: 0
        )
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int(timeoutNanoseconds))
        while ContinuousClock.now < deadline {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Timed out waiting for condition")
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
