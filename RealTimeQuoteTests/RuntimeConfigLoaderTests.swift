import XCTest
@testable import RealTimeQuote

final class RuntimeConfigLoaderTests: XCTestCase {
    func test_runtimeConfig_decodesDefaultsAndCredentialBlocks() throws {
        let payload = Data(
            #"""
            {
              "defaults": {
                "exchange": "coinbase",
                "pair": "btc_usd",
                "enabledExchanges": ["coinbase", "okx"]
              },
              "coinbase": {
                "apiKey": "cb-key",
                "apiSecret": "cb-secret",
                "passphrase": "cb-pass",
                "useAuthenticatedFeed": true
              },
              "okx": {
                "apiKey": "okx-key",
                "apiSecret": "okx-secret",
                "passphrase": "okx-pass",
                "useAuthenticatedFeed": false
              }
            }
            """#.utf8
        )

        let config = try JSONDecoder().decode(RuntimeConfig.self, from: payload)

        XCTAssertEqual(config.defaults?.exchange, .coinbase)
        XCTAssertEqual(config.defaults?.pair, .btcUSD)
        XCTAssertEqual(config.defaults?.enabledExchanges, [.coinbase, .okx])
        XCTAssertEqual(config.coinbase?.apiKey, "cb-key")
        XCTAssertEqual(config.coinbase?.useAuthenticatedFeed, true)
        XCTAssertEqual(config.okx?.apiSecret, "okx-secret")
        XCTAssertEqual(config.okx?.useAuthenticatedFeed, false)
    }

    func test_runtimeConfig_decodesWithoutOptionalCredentialBlocks() throws {
        let payload = Data(
            #"""
            {
              "defaults": {
                "exchange": "okx",
                "pair": "eth_usd"
              }
            }
            """#.utf8
        )

        let config = try JSONDecoder().decode(RuntimeConfig.self, from: payload)

        XCTAssertEqual(config.defaults?.exchange, .okx)
        XCTAssertEqual(config.defaults?.pair, .ethUSD)
        XCTAssertNil(config.coinbase)
        XCTAssertNil(config.okx)
    }
}
