import XCTest
@testable import RealTimeQuote

final class AppDependenciesConfigTests: XCTestCase {
    func test_bootstrap_usesConfigDefaultsWhenSettingsStoreHasNoSelection() {
        let settingsStore = InMemoryEmptySettingsStore()
        let config = RuntimeConfig(
            defaults: .init(exchange: .okx, pair: .ethUSD, enabledExchanges: [.coinbase, .okx]),
            coinbase: nil,
            okx: nil
        )

        let resolved = AppBootstrapSelectionResolver.resolve(
            settingsStore: settingsStore,
            config: config
        )

        XCTAssertEqual(resolved.exchange, .okx)
        XCTAssertEqual(resolved.pair, .ethUSD)
    }

    func test_bootstrap_fallsBackWhenPersistedExchangeIsDisabledByConfig() {
        let settingsStore = InMemorySelectionSettingsStore(exchange: .okx, pair: .ethUSD)
        let config = RuntimeConfig(
            defaults: .init(exchange: .coinbase, pair: .btcUSD, enabledExchanges: [.coinbase]),
            coinbase: nil,
            okx: nil
        )

        let resolved = AppBootstrapSelectionResolver.resolve(
            settingsStore: settingsStore,
            config: config
        )

        XCTAssertEqual(resolved.exchange, .coinbase)
        XCTAssertEqual(resolved.pair, .btcUSD)
    }
}

private final class InMemoryEmptySettingsStore: AppSettingsStore {
    var selectedExchange: ExchangeID {
        get { storedSelection?.exchange ?? .coinbase }
        set { setSelection(exchange: newValue, pair: selectedPair) }
    }

    var selectedPair: TradingPair {
        get { storedSelection?.pair ?? .btcUSD }
        set { setSelection(exchange: selectedExchange, pair: newValue) }
    }

    var storedSelection: AppSelection?

    func setSelection(exchange: ExchangeID, pair: TradingPair) {
        storedSelection = AppSelection(exchange: exchange, pair: pair)
    }
}

private final class InMemorySelectionSettingsStore: AppSettingsStore {
    var storedSelection: AppSelection?

    init(exchange: ExchangeID, pair: TradingPair) {
        storedSelection = AppSelection(exchange: exchange, pair: pair)
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
