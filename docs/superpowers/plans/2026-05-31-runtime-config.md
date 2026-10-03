# Runtime Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local JSON runtime config system that can supply startup defaults and optional Coinbase/OKX credentials without hard-coding secrets in the app.

**Architecture:** Introduce a small runtime-config subsystem with typed config models and a loader that resolves `~/.real-time-quote/config.json` before `Config/local.json`, then inject the loaded defaults and optional exchange config into `AppDependencies`. Keep `UserDefaults` as the highest-priority remembered selection, use config only for first-run/default bootstrap, and keep all file-system and JSON parsing outside the views.

**Tech Stack:** Swift, Foundation, SwiftUI bootstrap integration, XCTest, JSONDecoder/JSONEncoder

---

## Planned File Structure

### Runtime config models and loading

- Create: `RealTimeQuote/Config/RuntimeConfig.swift`
- Create: `RealTimeQuote/Config/RuntimeConfigLoader.swift`
- Create: `RealTimeQuote/Config/RuntimeConfigSource.swift`

### Bootstrap integration

- Modify: `RealTimeQuote/App/AppDependencies.swift`
- Modify: `RealTimeQuote/Services/AppSettingsStore.swift`
- Modify: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift`
- Modify: `RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift`

### Sample config and ignore rules

- Create: `Config/local.sample.json`
- Modify: `.gitignore`

### Tests

- Create: `RealTimeQuoteTests/RuntimeConfigLoaderTests.swift`
- Create: `RealTimeQuoteTests/AppDependenciesConfigTests.swift`
- Modify: `RealTimeQuote.xcodeproj/project.pbxproj`

---

### Task 1: Add typed runtime config models and decoding tests

**Files:**
- Create: `RealTimeQuote/Config/RuntimeConfig.swift`
- Create: `RealTimeQuote/Config/RuntimeConfigSource.swift`
- Test: `RealTimeQuoteTests/RuntimeConfigLoaderTests.swift`
- Modify: `RealTimeQuote.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the failing config decode tests**

```swift
// RealTimeQuoteTests/RuntimeConfigLoaderTests.swift
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
```

- [ ] **Step 2: Run the focused tests to verify the missing config types fail**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-runtime-config-red -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests`
Expected: FAIL with missing `RuntimeConfig` and related types

- [ ] **Step 3: Implement the config models and source enum**

```swift
// RealTimeQuote/Config/RuntimeConfig.swift
import Foundation

struct RuntimeConfig: Decodable, Equatable {
    struct Defaults: Decodable, Equatable {
        let exchange: ExchangeID?
        let pair: TradingPair?
        let enabledExchanges: [ExchangeID]?
    }

    struct Coinbase: Decodable, Equatable {
        let apiKey: String?
        let apiSecret: String?
        let passphrase: String?
        let useAuthenticatedFeed: Bool?
    }

    struct OKX: Decodable, Equatable {
        let apiKey: String?
        let apiSecret: String?
        let passphrase: String?
        let useAuthenticatedFeed: Bool?
    }

    let defaults: Defaults?
    let coinbase: Coinbase?
    let okx: OKX?
}
```

```swift
// RealTimeQuote/Config/RuntimeConfigSource.swift
import Foundation

enum RuntimeConfigSource: Equatable {
    case homeDirectory(URL)
    case projectLocal(URL)
    case fallback
}
```

- [ ] **Step 4: Run the focused tests again and verify they pass**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-runtime-config-green -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests`
Expected: PASS

- [ ] **Step 5: Commit the typed config layer**

```bash
git add RealTimeQuote/Config/RuntimeConfig.swift RealTimeQuote/Config/RuntimeConfigSource.swift RealTimeQuoteTests/RuntimeConfigLoaderTests.swift RealTimeQuote.xcodeproj/project.pbxproj
git commit -m "feat: add runtime config models"
```

---

### Task 2: Add config file resolution, precedence, and failure handling

**Files:**
- Create: `RealTimeQuote/Config/RuntimeConfigLoader.swift`
- Modify: `RealTimeQuoteTests/RuntimeConfigLoaderTests.swift`

- [ ] **Step 1: Add failing loader tests for location precedence and invalid JSON fallback**

```swift
// Add to RealTimeQuoteTests/RuntimeConfigLoaderTests.swift
func test_loader_prefersHomeConfigOverProjectConfig() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let homeRoot = root.appendingPathComponent("home", isDirectory: true)
    let projectRoot = root.appendingPathComponent("project", isDirectory: true)
    try fileManager.createDirectory(at: homeRoot.appendingPathComponent(".real-time-quote", isDirectory: true), withIntermediateDirectories: true)
    try fileManager.createDirectory(at: projectRoot.appendingPathComponent("Config", isDirectory: true), withIntermediateDirectories: true)

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

    XCTAssertEqual(result.source, .homeDirectory(homeRoot.appendingPathComponent(".real-time-quote/config.json")))
    XCTAssertEqual(result.config?.defaults?.exchange, .okx)
    XCTAssertEqual(result.config?.defaults?.pair, .ethUSD)
}

func test_loader_returnsErrorForInvalidProjectConfigWithoutCrashing() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectRoot = root.appendingPathComponent("project", isDirectory: true)
    try fileManager.createDirectory(at: projectRoot.appendingPathComponent("Config", isDirectory: true), withIntermediateDirectories: true)

    try Data(#"{"defaults":{"exchange":"coinbase""#.utf8)
        .write(to: projectRoot.appendingPathComponent("Config/local.json"))

    let loader = RuntimeConfigLoader(
        fileManager: fileManager,
        homeDirectoryURL: root.appendingPathComponent("missing-home", isDirectory: true),
        projectDirectoryURL: projectRoot
    )

    let result = try loader.load()

    XCTAssertNil(result.config)
    XCTAssertNotNil(result.error)
}
```

- [ ] **Step 2: Run the focused tests to verify the loader API is still missing**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-runtime-loader-red -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests`
Expected: FAIL with missing `RuntimeConfigLoader` and `load()`

- [ ] **Step 3: Implement the loader and result model**

```swift
// RealTimeQuote/Config/RuntimeConfigLoader.swift
import Foundation

struct RuntimeConfigLoadResult {
    let source: RuntimeConfigSource
    let config: RuntimeConfig?
    let error: Error?
}

struct RuntimeConfigLoader {
    private let fileManager: FileManager
    private let homeDirectoryURL: URL
    private let projectDirectoryURL: URL
    private let decoder = JSONDecoder()

    init(
        fileManager: FileManager = .default,
        homeDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        projectDirectoryURL: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) {
        self.fileManager = fileManager
        self.homeDirectoryURL = homeDirectoryURL
        self.projectDirectoryURL = projectDirectoryURL
    }

    func load() throws -> RuntimeConfigLoadResult {
        let homeURL = homeDirectoryURL.appendingPathComponent(".real-time-quote/config.json")
        if fileManager.fileExists(atPath: homeURL.path) {
            return decodeConfig(at: homeURL, source: .homeDirectory(homeURL))
        }

        let projectURL = projectDirectoryURL.appendingPathComponent("Config/local.json")
        if fileManager.fileExists(atPath: projectURL.path) {
            return decodeConfig(at: projectURL, source: .projectLocal(projectURL))
        }

        return RuntimeConfigLoadResult(source: .fallback, config: nil, error: nil)
    }

    private func decodeConfig(at url: URL, source: RuntimeConfigSource) -> RuntimeConfigLoadResult {
        do {
            let data = try Data(contentsOf: url)
            let config = try decoder.decode(RuntimeConfig.self, from: data)
            return RuntimeConfigLoadResult(source: source, config: config, error: nil)
        } catch {
            return RuntimeConfigLoadResult(source: source, config: nil, error: error)
        }
    }
}
```

- [ ] **Step 4: Run the loader tests and verify they pass**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-runtime-loader-green -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests`
Expected: PASS

- [ ] **Step 5: Commit the config loader**

```bash
git add RealTimeQuote/Config/RuntimeConfigLoader.swift RealTimeQuoteTests/RuntimeConfigLoaderTests.swift
git commit -m "feat: add runtime config loader"
```

---

### Task 3: Inject config defaults into app bootstrap and preserve selection precedence

**Files:**
- Modify: `RealTimeQuote/App/AppDependencies.swift`
- Modify: `RealTimeQuote/Services/AppSettingsStore.swift`
- Create: `RealTimeQuoteTests/AppDependenciesConfigTests.swift`

- [ ] **Step 1: Add failing tests for bootstrap precedence and invalid persisted selection fallback**

```swift
// RealTimeQuoteTests/AppDependenciesConfigTests.swift
import XCTest
@testable import RealTimeQuote

final class AppDependenciesConfigTests: XCTestCase {
    func test_bootstrap_usesConfigDefaultsWhenUserDefaultsHasNoSelection() {
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
```

- [ ] **Step 2: Run the focused bootstrap tests to verify the resolver path does not exist yet**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-bootstrap-red -only-testing:RealTimeQuoteTests/AppDependenciesConfigTests`
Expected: FAIL with missing `AppBootstrapSelectionResolver`

- [ ] **Step 3: Implement bootstrap resolution and integrate it into AppDependencies**

```swift
// RealTimeQuote/App/AppDependencies.swift
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

        let configDefaults = AppBootstrapSelection(
            exchange: config?.defaults?.exchange ?? fallback.exchange,
            pair: config?.defaults?.pair ?? fallback.pair
        )

        let persisted = AppBootstrapSelection(
            exchange: settingsStore.selectedExchange,
            pair: settingsStore.selectedPair
        )

        let enabledExchanges = Set(config?.defaults?.enabledExchanges ?? ExchangeID.allCases)
        guard enabledExchanges.contains(persisted.exchange) else {
            return enabledExchanges.contains(configDefaults.exchange) ? configDefaults : fallback
        }

        return persisted
    }
}
```

- [ ] **Step 4: Run the focused bootstrap tests and app build**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-bootstrap-green -only-testing:RealTimeQuoteTests/AppDependenciesConfigTests`
Expected: PASS

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-bootstrap-build build`
Expected: PASS

- [ ] **Step 5: Commit the bootstrap integration**

```bash
git add RealTimeQuote/App/AppDependencies.swift RealTimeQuote/Services/AppSettingsStore.swift RealTimeQuoteTests/AppDependenciesConfigTests.swift RealTimeQuote.xcodeproj/project.pbxproj
git commit -m "feat: inject runtime config into app bootstrap"
```

---

### Task 4: Pass optional exchange config into stream factories and add sample config

**Files:**
- Modify: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift`
- Modify: `RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift`
- Create: `Config/local.sample.json`
- Modify: `.gitignore`
- Modify: `RealTimeQuoteTests/RuntimeConfigLoaderTests.swift`

- [ ] **Step 1: Add failing tests for sample config decode and legacy-safe local ignore behavior**

```swift
// Add to RealTimeQuoteTests/RuntimeConfigLoaderTests.swift
func test_sampleConfig_decodesWithPlaceholderValues() throws {
    let sampleURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("Config/local.sample.json")
    let data = try Data(contentsOf: sampleURL)

    let config = try JSONDecoder().decode(RuntimeConfig.self, from: data)

    XCTAssertEqual(config.defaults?.exchange, .coinbase)
    XCTAssertEqual(config.defaults?.pair, .btcUSD)
    XCTAssertEqual(config.defaults?.enabledExchanges, [.coinbase, .okx])
}
```

- [ ] **Step 2: Run the focused config tests to verify the sample file does not exist yet**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-sample-red -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests`
Expected: FAIL with missing `Config/local.sample.json`

- [ ] **Step 3: Add the sample config file and stream-constructor config inputs**

```json
// Config/local.sample.json
{
  "defaults": {
    "exchange": "coinbase",
    "pair": "btc_usd",
    "enabledExchanges": ["coinbase", "okx"]
  },
  "coinbase": {
    "apiKey": "your-coinbase-key",
    "apiSecret": "your-coinbase-secret",
    "passphrase": "your-coinbase-passphrase",
    "useAuthenticatedFeed": false
  },
  "okx": {
    "apiKey": "your-okx-key",
    "apiSecret": "your-okx-secret",
    "passphrase": "your-okx-passphrase",
    "useAuthenticatedFeed": false
  }
}
```

```text
// .gitignore
Config/local.json
```

- [ ] **Step 4: Run the focused config tests and final build-for-testing**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-sample-green -only-testing:RealTimeQuoteTests/RuntimeConfigLoaderTests -only-testing:RealTimeQuoteTests/AppDependenciesConfigTests`
Expected: PASS

Run: `xcodebuild build-for-testing -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-runtime-final-bft`
Expected: PASS

- [ ] **Step 5: Commit the sample config and exchange-config wiring**

```bash
git add .gitignore Config/local.sample.json RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift RealTimeQuoteTests/RuntimeConfigLoaderTests.swift
git commit -m "feat: add local runtime config support"
```

---

## Spec Coverage Check

- typed JSON config model: Task 1
- home-path and project-path config lookup: Task 2
- structured config load result and graceful decode failure: Task 2
- startup precedence of `UserDefaults` over config over fallback: Task 3
- invalid or disabled persisted selection fallback: Task 3
- optional exchange credentials/config injection path: Task 4
- sample config file and local ignore rules: Task 4

## Self-Review Notes

- The plan stays focused on one subsystem: runtime config and bootstrap wiring.
- Each spec requirement maps to at least one concrete task.
- No placeholder text remains in steps; every task includes concrete files and exact commands.
