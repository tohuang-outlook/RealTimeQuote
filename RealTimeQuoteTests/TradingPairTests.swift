import XCTest
@testable import RealTimeQuote

final class TradingPairTests: XCTestCase {
    func testOKXInstrumentMappingUsesHyphenatedSpotSymbol() {
        XCTAssertEqual(TradingPair.btcUSD.okxInstrumentID, "BTC-USD")
        XCTAssertEqual(TradingPair.ethUSD.okxInstrumentID, "ETH-USD")
    }

    func testTradingPairUsesStablePersistenceAndDisplayIdentity() {
        XCTAssertEqual(TradingPair.btcUSD.id, "btc_usd")
        XCTAssertEqual(TradingPair.btcUSD.displaySymbol, "BTC-USD")
        XCTAssertEqual(TradingPair.btcUSD.coinbaseProductID, "BTC-USD")
        XCTAssertEqual(TradingPair.btcUSD.okxInstrumentID, "BTC-USD")
    }

    func testTradingPairCodableUsesCanonicalPersistenceValue() throws {
        let encoded = try JSONEncoder().encode(TradingPair.btcUSD)
        let decoded = try JSONDecoder().decode(TradingPair.self, from: encoded)

        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "\"btc_usd\"")
        XCTAssertEqual(decoded, .btcUSD)
    }

    func testTradingPairDecodesLegacyDisplaySymbolValue() throws {
        let decoded = try JSONDecoder().decode(TradingPair.self, from: Data(#""BTC-USD""#.utf8))

        XCTAssertEqual(decoded, .btcUSD)
    }

    func testPlaceholderSnapshotUsesTradingPairIdentityAndConnectingState() {
        let snapshot = QuoteSnapshot.placeholder(for: .btcUSD, exchange: .coinbase)

        XCTAssertEqual(snapshot.pair, .btcUSD)
        XCTAssertEqual(snapshot.displaySymbol, "BTC-USD")
        XCTAssertEqual(snapshot.connectionState, .connecting)
    }

    func testSettingsStoreDefaultsToCoinbaseAndBTCUSD() {
        let store = makeSettingsStore()

        XCTAssertEqual(store.selectedExchange, .coinbase)
        XCTAssertEqual(store.selectedPair, .btcUSD)
    }

    func testSettingsStorePersistsSelectedValues() {
        let suiteName = "RealTimeQuoteTests.TradingPairTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let writer = UserDefaultsAppSettingsStore(defaults: defaults)
        writer.selectedExchange = ExchangeID.okx
        writer.selectedPair = TradingPair.ethUSD

        let reader = UserDefaultsAppSettingsStore(defaults: defaults)

        XCTAssertEqual(reader.selectedExchange, ExchangeID.okx)
        XCTAssertEqual(reader.selectedPair, TradingPair.ethUSD)
    }

    func testSettingsStoreReadsLegacyDisplaySymbolValue() {
        let suiteName = "RealTimeQuoteTests.TradingPairTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set("ETH-USD", forKey: "selectedPair")

        let reader = UserDefaultsAppSettingsStore(defaults: defaults)

        XCTAssertEqual(reader.selectedPair, TradingPair.ethUSD)
    }

    func testDisconnectedStateUsesStableDomainReason() {
        XCTAssertEqual(
            ConnectionState.disconnected(ConnectionIssue.networkFailure),
            ConnectionState.disconnected(ConnectionIssue.networkFailure)
        )
    }

    func testConnectionIssueUsesStableRawValues() {
        XCTAssertEqual(ConnectionIssue.networkFailure.rawValue, "network_failure")
        XCTAssertEqual(ConnectionIssue.remoteClosed.rawValue, "remote_closed")
        XCTAssertEqual(ConnectionIssue.unknown.rawValue, "unknown")
    }

    func testConnectionIssueCodableRoundTripPreservesSerializedValue() throws {
        let encoded = try JSONEncoder().encode(ConnectionIssue.networkFailure)
        let decoded = try JSONDecoder().decode(ConnectionIssue.self, from: encoded)

        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "\"network_failure\"")
        XCTAssertEqual(decoded, .networkFailure)
    }

    private func makeSettingsStore() -> UserDefaultsAppSettingsStore {
        let suiteName = "RealTimeQuoteTests.TradingPairTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return UserDefaultsAppSettingsStore(defaults: defaults)
    }
}
