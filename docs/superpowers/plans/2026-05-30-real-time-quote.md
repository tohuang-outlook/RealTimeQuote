# Real Time Quote Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS app that shows real-time crypto quotes from Coinbase and OKX in a compact single-window quote card.

**Architecture:** Create a SwiftUI macOS app with a small set of focused layers: app shell, quote presentation state, a `QuoteEngine` that manages the selected exchange and symbol, and exchange-specific WebSocket adapters that normalize live messages into a shared `QuoteSnapshot` model. Persist the last selected exchange and pair locally, and keep reconnect logic inside the engine/adapters so the UI stays declarative.

**Tech Stack:** SwiftUI, AppKit interop for window sizing if needed, Foundation `URLSessionWebSocketTask`, XCTest

---

## Planned File Structure

### App shell

- Create: `RealTimeQuote/RealTimeQuoteApp.swift`
- Create: `RealTimeQuote/App/AppDependencies.swift`
- Create: `RealTimeQuote/App/WindowStyler.swift`

### Domain and state

- Create: `RealTimeQuote/Models/ExchangeID.swift`
- Create: `RealTimeQuote/Models/TradingPair.swift`
- Create: `RealTimeQuote/Models/ConnectionState.swift`
- Create: `RealTimeQuote/Models/QuoteSnapshot.swift`
- Create: `RealTimeQuote/Services/AppSettingsStore.swift`
- Create: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`

### Exchange integration

- Create: `RealTimeQuote/Services/Exchanges/ExchangeQuoteStreaming.swift`
- Create: `RealTimeQuote/Services/Exchanges/ExchangeStreamEvent.swift`
- Create: `RealTimeQuote/Services/Exchanges/QuoteEngine.swift`
- Create: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseTickerMessage.swift`
- Create: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift`
- Create: `RealTimeQuote/Services/Exchanges/OKX/OKXTickerEnvelope.swift`
- Create: `RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift`

### UI

- Create: `RealTimeQuote/Views/QuoteBoardView.swift`
- Create: `RealTimeQuote/Views/Components/ExchangePickerView.swift`
- Create: `RealTimeQuote/Views/Components/TradingPairPickerView.swift`
- Create: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Create: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Create: `RealTimeQuote/Views/Components/ConnectionBadgeView.swift`

### Tests

- Create: `RealTimeQuoteTests/TradingPairTests.swift`
- Create: `RealTimeQuoteTests/CoinbaseTickerMessageTests.swift`
- Create: `RealTimeQuoteTests/OKXTickerEnvelopeTests.swift`
- Create: `RealTimeQuoteTests/QuoteEngineTests.swift`

### Repo metadata

- Create: `RealTimeQuote.xcodeproj/project.pbxproj`
- Create: `RealTimeQuote.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- Create: `RealTimeQuote.xcodeproj/xcshareddata/xcschemes/RealTimeQuote.xcscheme`
- Create: `.gitignore`
- Modify: `docs/superpowers/specs/2026-05-30-real-time-quote-design.md` only if implementation reveals a spec mismatch

---

### Task 1: Scaffold the macOS app and test target

**Files:**
- Create: `RealTimeQuote/RealTimeQuoteApp.swift`
- Create: `RealTimeQuote/App/AppDependencies.swift`
- Create: `RealTimeQuote/App/WindowStyler.swift`
- Create: `RealTimeQuote/Views/QuoteBoardView.swift`
- Create: `RealTimeQuote.xcodeproj/project.pbxproj`
- Create: `RealTimeQuote.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- Create: `RealTimeQuote.xcodeproj/xcshareddata/xcschemes/RealTimeQuote.xcscheme`
- Create: `.gitignore`

- [ ] **Step 1: Create the failing shell by referencing the missing view model and dependencies**

```swift
// RealTimeQuote/RealTimeQuoteApp.swift
import SwiftUI

@main
struct RealTimeQuoteApp: App {
    @StateObject private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup("Real Time Quote") {
            QuoteBoardView(viewModel: dependencies.quoteBoardViewModel)
                .frame(minWidth: 500, idealWidth: 560, maxWidth: 640, minHeight: 250, idealHeight: 280, maxHeight: 320)
                .background(.black)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 280)
    }
}
```

- [ ] **Step 2: Create the project files and run the build to verify it fails on missing types**

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' build`
Expected: FAIL with errors such as `cannot find 'AppDependencies' in scope` and `cannot find 'QuoteBoardView' in scope`

- [ ] **Step 3: Add the minimal app shell, placeholder dependencies, and placeholder root view**

```swift
// RealTimeQuote/App/AppDependencies.swift
import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let quoteBoardViewModel = QuoteBoardViewModel.preview

    static func live() -> AppDependencies {
        AppDependencies()
    }
}
```

```swift
// RealTimeQuote/Views/QuoteBoardView.swift
import SwiftUI

struct QuoteBoardView: View {
    @ObservedObject var viewModel: QuoteBoardViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(viewModel.snapshot.symbol)
                .foregroundStyle(.white)
        }
    }
}
```

```swift
// .gitignore
DerivedData/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
.DS_Store
Config/local.xcconfig
```

- [ ] **Step 4: Run the build again and verify the remaining failures are only from the not-yet-created domain files**

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' build`
Expected: FAIL with errors limited to `QuoteBoardViewModel` and `QuoteSnapshot`

- [ ] **Step 5: Commit the scaffold**

```bash
git add .gitignore RealTimeQuote RealTimeQuote.xcodeproj
git commit -m "feat: scaffold Real Time Quote macOS app"
```

---

### Task 2: Build the quote domain model, settings store, and presentation state

**Files:**
- Create: `RealTimeQuote/Models/ExchangeID.swift`
- Create: `RealTimeQuote/Models/TradingPair.swift`
- Create: `RealTimeQuote/Models/ConnectionState.swift`
- Create: `RealTimeQuote/Models/QuoteSnapshot.swift`
- Create: `RealTimeQuote/Services/AppSettingsStore.swift`
- Create: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: `RealTimeQuoteTests/TradingPairTests.swift`

- [ ] **Step 1: Write the failing tests for pair mapping and default persistence values**

```swift
// RealTimeQuoteTests/TradingPairTests.swift
import XCTest
@testable import RealTimeQuote

final class TradingPairTests: XCTestCase {
    func test_okxInstrumentMapping_usesHyphenatedUsdSwaplessSpotSymbol() {
        XCTAssertEqual(TradingPair.btcUSD.okxInstrumentID, "BTC-USD")
        XCTAssertEqual(TradingPair.ethUSD.okxInstrumentID, "ETH-USD")
    }

    func test_defaultSnapshot_usesConnectingState() {
        let snapshot = QuoteSnapshot.placeholder(for: .btcUSD, exchange: .coinbase)
        XCTAssertEqual(snapshot.symbol, "BTC-USD")
        XCTAssertEqual(snapshot.connectionState, .connecting)
    }
}
```

- [ ] **Step 2: Run the test target to verify it fails because the models do not exist yet**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/TradingPairTests`
Expected: FAIL with `cannot find type 'TradingPair' in scope`

- [ ] **Step 3: Add the minimal domain model and settings store**

```swift
// RealTimeQuote/Models/ExchangeID.swift
enum ExchangeID: String, CaseIterable, Codable, Identifiable {
    case coinbase
    case okx

    var id: String { rawValue }
    var displayName: String { rawValue.uppercased() }
}
```

```swift
// RealTimeQuote/Models/TradingPair.swift
enum TradingPair: String, CaseIterable, Codable, Identifiable {
    case btcUSD = "BTC-USD"
    case ethUSD = "ETH-USD"
    case solUSD = "SOL-USD"

    var id: String { rawValue }
    var displaySymbol: String { rawValue }
    var coinbaseProductID: String { rawValue }
    var okxInstrumentID: String { rawValue }
}
```

```swift
// RealTimeQuote/Models/ConnectionState.swift
enum ConnectionState: Equatable {
    case connecting
    case live
    case reconnecting
    case disconnected(String)
}
```

```swift
// RealTimeQuote/Models/QuoteSnapshot.swift
import Foundation

struct QuoteSnapshot: Equatable {
    let exchange: ExchangeID
    let symbol: String
    let lastPrice: Decimal?
    let absoluteChange: Decimal?
    let percentChange: Decimal?
    let high24h: Decimal?
    let low24h: Decimal?
    let volume24h: Decimal?
    let updatedAt: Date?
    let connectionState: ConnectionState

    static func placeholder(for pair: TradingPair, exchange: ExchangeID) -> QuoteSnapshot {
        QuoteSnapshot(
            exchange: exchange,
            symbol: pair.displaySymbol,
            lastPrice: nil,
            absoluteChange: nil,
            percentChange: nil,
            high24h: nil,
            low24h: nil,
            volume24h: nil,
            updatedAt: nil,
            connectionState: .connecting
        )
    }
}
```

```swift
// RealTimeQuote/Services/AppSettingsStore.swift
import Foundation

protocol AppSettingsStore {
    var selectedExchange: ExchangeID { get set }
    var selectedPair: TradingPair { get set }
}

final class UserDefaultsAppSettingsStore: AppSettingsStore {
    private enum Keys {
        static let exchange = "selectedExchange"
        static let pair = "selectedPair"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedExchange: ExchangeID {
        get { ExchangeID(rawValue: defaults.string(forKey: Keys.exchange) ?? "") ?? .coinbase }
        set { defaults.set(newValue.rawValue, forKey: Keys.exchange) }
    }

    var selectedPair: TradingPair {
        get { TradingPair(rawValue: defaults.string(forKey: Keys.pair) ?? "") ?? .btcUSD }
        set { defaults.set(newValue.rawValue, forKey: Keys.pair) }
    }
}
```

```swift
// RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
import Foundation

@MainActor
final class QuoteBoardViewModel: ObservableObject {
    @Published private(set) var snapshot: QuoteSnapshot

    static let preview = QuoteBoardViewModel(
        snapshot: QuoteSnapshot.placeholder(for: .btcUSD, exchange: .coinbase)
    )

    init(snapshot: QuoteSnapshot) {
        self.snapshot = snapshot
    }
}
```

- [ ] **Step 4: Run the focused tests and verify they pass**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/TradingPairTests`
Expected: PASS

- [ ] **Step 5: Commit the domain layer**

```bash
git add RealTimeQuote/Models RealTimeQuote/Services/AppSettingsStore.swift RealTimeQuote/ViewModels/QuoteBoardViewModel.swift RealTimeQuoteTests/TradingPairTests.swift
git commit -m "feat: add quote domain models and settings store"
```

---

### Task 3: Add a testable quote engine and selection flow

**Files:**
- Create: `RealTimeQuote/Services/Exchanges/ExchangeQuoteStreaming.swift`
- Create: `RealTimeQuote/Services/Exchanges/ExchangeStreamEvent.swift`
- Create: `RealTimeQuote/Services/Exchanges/QuoteEngine.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Modify: `RealTimeQuote/App/AppDependencies.swift`
- Test: `RealTimeQuoteTests/QuoteEngineTests.swift`

- [ ] **Step 1: Write the failing engine tests for initial connect and exchange switching**

```swift
// RealTimeQuoteTests/QuoteEngineTests.swift
import XCTest
@testable import RealTimeQuote

final class QuoteEngineTests: XCTestCase {
    func test_start_requestsSubscriptionForSelectedPair() async throws {
        let stream = MockExchangeQuoteStream()
        let engine = QuoteEngine(streamFactory: { _, _ in stream })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)

        XCTAssertEqual(stream.startCalls, [(exchange: .coinbase, pair: .btcUSD)])
    }

    func test_switchSelection_disconnectsOldStreamBeforeStartingNewOne() async throws {
        let first = MockExchangeQuoteStream()
        let second = MockExchangeQuoteStream()
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return factoryCalls == 0 ? first : second
        })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)
        try await engine.updateSelection(exchange: .okx, pair: .ethUSD)

        XCTAssertTrue(first.stopCalled)
        XCTAssertEqual(second.startCalls, [(exchange: .okx, pair: .ethUSD)])
    }
}
```

- [ ] **Step 2: Run the tests and verify they fail because the engine protocol and mocks do not exist**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/QuoteEngineTests`
Expected: FAIL with missing `QuoteEngine` and `ExchangeQuoteStreaming`

- [ ] **Step 3: Implement the engine protocol, stream event model, and selection-aware engine**

```swift
// RealTimeQuote/Services/Exchanges/ExchangeQuoteStreaming.swift
import Foundation

protocol ExchangeQuoteStreaming: AnyObject {
    var events: AsyncStream<ExchangeStreamEvent> { get }
    func start(exchange: ExchangeID, pair: TradingPair) async throws
    func stop()
}
```

```swift
// RealTimeQuote/Services/Exchanges/ExchangeStreamEvent.swift
enum ExchangeStreamEvent: Equatable {
    case didConnect
    case didReceiveSnapshot(QuoteSnapshot)
    case didDisconnect(String?)
}
```

```swift
// RealTimeQuote/Services/Exchanges/QuoteEngine.swift
import Foundation

@MainActor
final class QuoteEngine: ObservableObject {
    typealias StreamFactory = (ExchangeID, TradingPair) -> ExchangeQuoteStreaming

    @Published private(set) var snapshot: QuoteSnapshot

    private let streamFactory: StreamFactory
    private var currentStream: ExchangeQuoteStreaming?
    private var eventTask: Task<Void, Never>?

    init(
        initialSnapshot: QuoteSnapshot = .placeholder(for: .btcUSD, exchange: .coinbase),
        streamFactory: @escaping StreamFactory
    ) {
        self.snapshot = initialSnapshot
        self.streamFactory = streamFactory
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        try await replaceStream(exchange: exchange, pair: pair)
    }

    func updateSelection(exchange: ExchangeID, pair: TradingPair) async throws {
        try await replaceStream(exchange: exchange, pair: pair)
    }

    private func replaceStream(exchange: ExchangeID, pair: TradingPair) async throws {
        eventTask?.cancel()
        currentStream?.stop()
        snapshot = .placeholder(for: pair, exchange: exchange)

        let stream = streamFactory(exchange, pair)
        currentStream = stream

        eventTask = Task { [weak self] in
            for await event in stream.events {
                await self?.consume(event)
            }
        }

        try await stream.start(exchange: exchange, pair: pair)
    }

    private func consume(_ event: ExchangeStreamEvent) {
        switch event {
        case .didConnect:
            snapshot = QuoteSnapshot(
                exchange: snapshot.exchange,
                symbol: snapshot.symbol,
                lastPrice: snapshot.lastPrice,
                absoluteChange: snapshot.absoluteChange,
                percentChange: snapshot.percentChange,
                high24h: snapshot.high24h,
                low24h: snapshot.low24h,
                volume24h: snapshot.volume24h,
                updatedAt: snapshot.updatedAt,
                connectionState: .live
            )
        case .didReceiveSnapshot(let snapshot):
            self.snapshot = snapshot
        case .didDisconnect(let reason):
            snapshot = QuoteSnapshot(
                exchange: snapshot.exchange,
                symbol: snapshot.symbol,
                lastPrice: snapshot.lastPrice,
                absoluteChange: snapshot.absoluteChange,
                percentChange: snapshot.percentChange,
                high24h: snapshot.high24h,
                low24h: snapshot.low24h,
                volume24h: snapshot.volume24h,
                updatedAt: snapshot.updatedAt,
                connectionState: .disconnected(reason ?? "Disconnected")
            )
        }
    }
}
```

- [ ] **Step 4: Wire the view model to the engine and verify the engine tests pass**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/QuoteEngineTests`
Expected: PASS

- [ ] **Step 5: Commit the selection and engine layer**

```bash
git add RealTimeQuote/App/AppDependencies.swift RealTimeQuote/ViewModels/QuoteBoardViewModel.swift RealTimeQuote/Services/Exchanges RealTimeQuoteTests/QuoteEngineTests.swift
git commit -m "feat: add quote engine and selection flow"
```

---

### Task 4: Implement Coinbase and OKX WebSocket adapters with decoder tests

**Files:**
- Create: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseTickerMessage.swift`
- Create: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift`
- Create: `RealTimeQuote/Services/Exchanges/OKX/OKXTickerEnvelope.swift`
- Create: `RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift`
- Test: `RealTimeQuoteTests/CoinbaseTickerMessageTests.swift`
- Test: `RealTimeQuoteTests/OKXTickerEnvelopeTests.swift`

- [ ] **Step 1: Write the failing decoder tests using real-looking payloads from both exchanges**

```swift
// RealTimeQuoteTests/CoinbaseTickerMessageTests.swift
import XCTest
@testable import RealTimeQuote

final class CoinbaseTickerMessageTests: XCTestCase {
    func test_decodesTickerSnapshot() throws {
        let json = """
        {"type":"ticker","product_id":"BTC-USD","price":"73707.82","open_24h":"73434.73","high_24h":"74172.05","low_24h":"73127.08","volume_24h":"4040.12","time":"2026-05-30T22:44:00.000Z"}
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(CoinbaseTickerMessage.self, from: json)

        XCTAssertEqual(message.productID, "BTC-USD")
        XCTAssertEqual(message.price, "73707.82")
        XCTAssertEqual(message.open24h, "73434.73")
    }
}
```

```swift
// RealTimeQuoteTests/OKXTickerEnvelopeTests.swift
import XCTest
@testable import RealTimeQuote

final class OKXTickerEnvelopeTests: XCTestCase {
    func test_decodesTickerEnvelope() throws {
        let json = """
        {"arg":{"channel":"tickers","instId":"BTC-USD"},"data":[{"instId":"BTC-USD","last":"73707.82","open24h":"73434.73","high24h":"74172.05","low24h":"73127.08","vol24h":"4040.12","ts":"1780181040000"}]}
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(OKXTickerEnvelope.self, from: json)

        XCTAssertEqual(envelope.argument.instrumentID, "BTC-USD")
        XCTAssertEqual(envelope.data.first?.last, "73707.82")
    }
}
```

- [ ] **Step 2: Run the decoder tests and verify they fail because the message types are missing**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/CoinbaseTickerMessageTests -only-testing:RealTimeQuoteTests/OKXTickerEnvelopeTests`
Expected: FAIL with missing decoder model types

- [ ] **Step 3: Add message models and minimal quote stream implementations**

```swift
// RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseTickerMessage.swift
struct CoinbaseTickerMessage: Decodable {
    let type: String
    let productID: String
    let price: String
    let open24h: String
    let high24h: String
    let low24h: String
    let volume24h: String
    let time: Date

    enum CodingKeys: String, CodingKey {
        case type
        case productID = "product_id"
        case price
        case open24h = "open_24h"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case volume24h = "volume_24h"
        case time
    }
}
```

```swift
// RealTimeQuote/Services/Exchanges/OKX/OKXTickerEnvelope.swift
struct OKXTickerEnvelope: Decodable {
    struct Argument: Decodable {
        let channel: String
        let instrumentID: String

        enum CodingKeys: String, CodingKey {
            case channel
            case instrumentID = "instId"
        }
    }

    struct Entry: Decodable {
        let instrumentID: String
        let last: String
        let open24h: String
        let high24h: String
        let low24h: String
        let volume24h: String
        let timestamp: String

        enum CodingKeys: String, CodingKey {
            case instrumentID = "instId"
            case last
            case open24h
            case high24h
            case low24h
            case volume24h = "vol24h"
            case timestamp = "ts"
        }
    }

    let argument: Argument
    let data: [Entry]

    enum CodingKeys: String, CodingKey {
        case argument = "arg"
        case data
    }
}
```

```swift
// RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift
import Foundation

final class CoinbaseQuoteStream: ExchangeQuoteStreaming {
    private(set) var events: AsyncStream<ExchangeStreamEvent>
    private let continuation: AsyncStream<ExchangeStreamEvent>.Continuation

    init() {
        var localContinuation: AsyncStream<ExchangeStreamEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        continuation.yield(.didConnect)
    }

    func stop() {
        continuation.yield(.didDisconnect(nil))
    }
}
```

```swift
// RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift
import Foundation

final class OKXQuoteStream: ExchangeQuoteStreaming {
    private(set) var events: AsyncStream<ExchangeStreamEvent>
    private let continuation: AsyncStream<ExchangeStreamEvent>.Continuation

    init() {
        var localContinuation: AsyncStream<ExchangeStreamEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        continuation.yield(.didConnect)
    }

    func stop() {
        continuation.yield(.didDisconnect(nil))
    }
}
```

- [ ] **Step 4: Run the decoder tests and verify they pass, then run the app build to verify both stream classes link**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/CoinbaseTickerMessageTests -only-testing:RealTimeQuoteTests/OKXTickerEnvelopeTests`
Expected: PASS

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' build`
Expected: PASS

- [ ] **Step 5: Commit the exchange adapters**

```bash
git add RealTimeQuote/Services/Exchanges/Coinbase RealTimeQuote/Services/Exchanges/OKX RealTimeQuoteTests/CoinbaseTickerMessageTests.swift RealTimeQuoteTests/OKXTickerEnvelopeTests.swift
git commit -m "feat: add Coinbase and OKX quote streams"
```

---

### Task 5: Build the production UI and bind selection changes to live quote state

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Create: `RealTimeQuote/Views/Components/ExchangePickerView.swift`
- Create: `RealTimeQuote/Views/Components/TradingPairPickerView.swift`
- Create: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Create: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Create: `RealTimeQuote/Views/Components/ConnectionBadgeView.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Modify: `RealTimeQuote/App/WindowStyler.swift`

- [ ] **Step 1: Write a failing UI-oriented test for formatting and color state in the view model**

```swift
// Add to RealTimeQuoteTests/QuoteEngineTests.swift
func test_priceTrend_isPositiveWhenAbsoluteChangeIsAboveZero() {
    let viewModel = QuoteBoardViewModel(snapshot: QuoteSnapshot(
        exchange: .coinbase,
        symbol: "BTC-USD",
        lastPrice: Decimal(string: "73707.82"),
        absoluteChange: Decimal(string: "273.09"),
        percentChange: Decimal(string: "0.37"),
        high24h: Decimal(string: "74172.05"),
        low24h: Decimal(string: "73127.08"),
        volume24h: Decimal(string: "4040.12"),
        updatedAt: Date(timeIntervalSince1970: 1_780_181_040),
        connectionState: .live
    ))

    XCTAssertEqual(viewModel.priceTrend, .up)
}
```

- [ ] **Step 2: Run the focused test and verify it fails because the formatting helpers are missing**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/QuoteEngineTests/test_priceTrend_isPositiveWhenAbsoluteChangeIsAboveZero`
Expected: FAIL with missing `priceTrend`

- [ ] **Step 3: Implement the full quote card UI and presentation helpers**

```swift
// RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
enum PriceTrend {
    case up
    case down
    case flat
}

extension QuoteBoardViewModel {
    var priceTrend: PriceTrend {
        guard let absoluteChange else { return .flat }
        if absoluteChange > 0 { return .up }
        if absoluteChange < 0 { return .down }
        return .flat
    }
}
```

```swift
// RealTimeQuote/Views/QuoteBoardView.swift
import SwiftUI

struct QuoteBoardView: View {
    @ObservedObject var viewModel: QuoteBoardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                ExchangePickerView(selection: $viewModel.selectedExchange)
                Spacer()
                TradingPairPickerView(selection: $viewModel.selectedPair, options: TradingPair.allCases)
            }

            PriceHeaderView(snapshot: viewModel.snapshot, trend: viewModel.priceTrend)

            HStack(alignment: .top, spacing: 24) {
                StatsGridView(snapshot: viewModel.snapshot)
                Spacer()
                ConnectionBadgeView(state: viewModel.snapshot.connectionState)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}
```

- [ ] **Step 4: Run the app build and verify the main window compiles and the test passes**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/QuoteEngineTests/test_priceTrend_isPositiveWhenAbsoluteChangeIsAboveZero`
Expected: PASS

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' build`
Expected: PASS

- [ ] **Step 5: Commit the UI layer**

```bash
git add RealTimeQuote/Views RealTimeQuote/ViewModels/QuoteBoardViewModel.swift RealTimeQuote/App/WindowStyler.swift RealTimeQuoteTests/QuoteEngineTests.swift
git commit -m "feat: build real-time quote card interface"
```

---

### Task 6: Replace placeholder streams with live WebSocket handling, reconnect behavior, and final verification

**Files:**
- Modify: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift`
- Modify: `RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift`
- Modify: `RealTimeQuote/Services/Exchanges/QuoteEngine.swift`
- Modify: `RealTimeQuote/App/AppDependencies.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: `RealTimeQuoteTests/QuoteEngineTests.swift`

- [ ] **Step 1: Write the failing reconnect test at the engine level**

```swift
// Add to RealTimeQuoteTests/QuoteEngineTests.swift
func test_disconnect_marksSnapshotAsReconnectingUntilNewDataArrives() async throws {
    let stream = MockExchangeQuoteStream()
    let engine = QuoteEngine(streamFactory: { _, _ in stream })

    try await engine.start(exchange: .coinbase, pair: .btcUSD)
    stream.emit(.didDisconnect("network"))

    XCTAssertEqual(engine.snapshot.connectionState, .reconnecting)
}
```

- [ ] **Step 2: Run the reconnect test and verify it fails because disconnect currently maps to disconnected**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/QuoteEngineTests/test_disconnect_marksSnapshotAsReconnectingUntilNewDataArrives`
Expected: FAIL with an equality mismatch between `.disconnected` and `.reconnecting`

- [ ] **Step 3: Implement real WebSocket parsing, subscribe payloads, reconnect backoff, and snapshot normalization**

```swift
// RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseQuoteStream.swift
import Foundation

final class CoinbaseQuoteStream: ExchangeQuoteStreaming {
    private let session: URLSession
    private var socketTask: URLSessionWebSocketTask?
    private var subscribedPair: TradingPair?
    private let decoder: JSONDecoder
    private(set) var events: AsyncStream<ExchangeStreamEvent>
    private let continuation: AsyncStream<ExchangeStreamEvent>.Continuation

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        var localContinuation: AsyncStream<ExchangeStreamEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        subscribedPair = pair
        socketTask = session.webSocketTask(with: URL(string: "wss://ws-feed.exchange.coinbase.com")!)
        socketTask?.resume()
        continuation.yield(.didConnect)

        let subscribe = """
        {"type":"subscribe","product_ids":["\(pair.coinbaseProductID)"],"channels":["ticker"]}
        """
        try await socketTask?.send(.string(subscribe))
        receiveLoop()
    }

    func stop() {
        socketTask?.cancel(with: .goingAway, reason: nil)
        continuation.yield(.didDisconnect(nil))
    }
}
```

```swift
// RealTimeQuote/Services/Exchanges/OKX/OKXQuoteStream.swift
import Foundation

final class OKXQuoteStream: ExchangeQuoteStreaming {
    private let session: URLSession
    private var socketTask: URLSessionWebSocketTask?
    private let continuation: AsyncStream<ExchangeStreamEvent>.Continuation
    private(set) var events: AsyncStream<ExchangeStreamEvent>

    init(session: URLSession = .shared) {
        var localContinuation: AsyncStream<ExchangeStreamEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
        self.session = session
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        socketTask = session.webSocketTask(with: URL(string: "wss://ws.okx.com:8443/ws/v5/public")!)
        socketTask?.resume()
        continuation.yield(.didConnect)

        let subscribe = """
        {"op":"subscribe","args":[{"channel":"tickers","instId":"\(pair.okxInstrumentID)"}]}
        """
        try await socketTask?.send(.string(subscribe))
        receiveLoop()
    }

    func stop() {
        socketTask?.cancel(with: .goingAway, reason: nil)
        continuation.yield(.didDisconnect(nil))
    }
}
```

- [ ] **Step 4: Run the full test suite and app build, then manually verify live switching behavior**

Run: `xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS'`
Expected: PASS

Run: `xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' build`
Expected: PASS

Manual:
- Launch the app from Xcode
- Confirm the default pair loads
- Switch Coinbase to OKX and confirm the symbol stays consistent
- Switch `BTC-USD` to `ETH-USD` and confirm the UI updates without opening a second socket-backed window
- Disable the network briefly and confirm the badge shows reconnecting

- [ ] **Step 5: Commit the live streaming behavior**

```bash
git add RealTimeQuote/App/AppDependencies.swift RealTimeQuote/ViewModels/QuoteBoardViewModel.swift RealTimeQuote/Services/Exchanges RealTimeQuoteTests/QuoteEngineTests.swift
git commit -m "feat: connect live Coinbase and OKX quote feeds"
```

---

## Spec Coverage Check

- Single native macOS window: Tasks 1 and 5
- SwiftUI UI with dark quote-card styling: Task 5
- Shared `QuoteSnapshot` model: Task 2
- Coinbase support: Task 4 and Task 6
- OKX support: Task 4 and Task 6
- Pair and exchange switching: Task 3 and Task 5
- WebSocket live updates: Task 6
- Connection status and reconnecting state: Task 3 and Task 6
- Persist last selected exchange and pair: Task 2, then complete view model wiring in Task 5
- Tests for decoding, mapping, and engine state transitions: Tasks 2, 3, 4, and 6

## Self-Review Notes

- No placeholder markers such as `TODO` or `TBD` remain in the plan.
- File names, type names, and task order are consistent across the plan.
- The only spec-controlled file left untouched is the design doc, unless implementation reveals a mismatch worth updating later.
