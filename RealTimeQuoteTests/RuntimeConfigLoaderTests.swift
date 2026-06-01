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

    func test_loader_prefersHomeConfigOverProjectConfig() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let homeRoot = root.appendingPathComponent("home", isDirectory: true)
        let projectRoot = root.appendingPathComponent("project", isDirectory: true)
        try fileManager.createDirectory(
            at: homeRoot.appendingPathComponent(".real-time-quote", isDirectory: true),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: projectRoot.appendingPathComponent("Config", isDirectory: true),
            withIntermediateDirectories: true
        )

        try Data(#"{"defaults":{"exchange":"okx","pair":"eth_usd"}}"#.utf8)
            .write(to: homeRoot.appendingPathComponent(".real-time-quote/config.json"))
        try Data(#"{"defaults":{"exchange":"coinbase","pair":"btc_usd"}}"#.utf8)
            .write(to: projectRoot.appendingPathComponent("Config/local.json"))

        let loader = RuntimeConfigLoader(
            fileManager: fileManager,
            homeDirectoryURL: homeRoot,
            projectDirectoryURL: projectRoot
        )

        let result = try loader.load()

        XCTAssertEqual(
            result.source,
            .homeDirectory(homeRoot.appendingPathComponent(".real-time-quote/config.json"))
        )
        XCTAssertEqual(result.config?.defaults?.exchange, .okx)
        XCTAssertEqual(result.config?.defaults?.pair, .ethUSD)
    }

    func test_loader_returnsErrorForInvalidProjectConfigWithoutCrashing() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let projectRoot = root.appendingPathComponent("project", isDirectory: true)
        try fileManager.createDirectory(
            at: projectRoot.appendingPathComponent("Config", isDirectory: true),
            withIntermediateDirectories: true
        )

        try Data(#"{"defaults":{"exchange":"coinbase""#.utf8)
            .write(to: projectRoot.appendingPathComponent("Config/local.json"))

        let loader = RuntimeConfigLoader(
            fileManager: fileManager,
            homeDirectoryURL: root.appendingPathComponent("missing-home", isDirectory: true),
            projectDirectoryURL: projectRoot
        )

        let result = try loader.load()

        XCTAssertEqual(
            result.source,
            .projectLocal(projectRoot.appendingPathComponent("Config/local.json"))
        )
        XCTAssertNil(result.config)
        XCTAssertNotNil(result.error)
    }

    func test_sampleConfig_decodesWithPlaceholderValues() throws {
        let sampleURL = URL(fileURLWithPath: #filePath, isDirectory: false)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Config/local.sample.json")
        let data = try Data(contentsOf: sampleURL)

        let config = try JSONDecoder().decode(RuntimeConfig.self, from: data)

        XCTAssertEqual(config.defaults?.exchange, .coinbase)
        XCTAssertEqual(config.defaults?.pair, .btcUSD)
        XCTAssertEqual(config.defaults?.enabledExchanges, [.coinbase, .okx])
    }
}
