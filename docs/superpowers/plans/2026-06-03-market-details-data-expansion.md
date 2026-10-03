# Market Details Data Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an exchange-first market-details fetch path so the quote panel can replace placeholders with real `Open` and `Prev Close` data, and opportunistically fill `52 Wk High`, `52 Wk Low`, and `Market Cap` only when the selected exchange officially provides them.

**Architecture:** Keep websocket-driven live quote updates unchanged, and introduce a separate REST-fetched `MarketDetailsSnapshot` model owned by the view model. Exchange-specific detail fetchers will populate supported fields on selection change, and the presentation layer will merge quote and market-details snapshots.

**Tech Stack:** Swift, SwiftUI, Foundation `URLSession`, Coinbase / OKX official REST APIs, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Models/MarketDetailsSnapshot.swift`
  - New model for supplemental fields such as open, prev close, 52-week highs/lows, and market cap.
- `RealTimeQuote/Services/Exchanges/ExchangeMarketDetailsLoading.swift`
  - Protocol for exchange-specific market-details loaders.
- `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseMarketDetailsLoader.swift`
  - Coinbase REST-backed loader for market details.
- `RealTimeQuote/Services/Exchanges/OKX/OKXMarketDetailsLoader.swift`
  - OKX REST-backed loader for market details.
- `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
  - Trigger market-details fetches on selection changes and store the latest details snapshot.
- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Merge market details into presentation state.

### Task 1: Introduce the Market Details Model and Loader Interface

**Files:**
- Create: `RealTimeQuote/Models/MarketDetailsSnapshot.swift`
- Create: `RealTimeQuote/Services/Exchanges/ExchangeMarketDetailsLoading.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: Compile-time verification via app build

- [ ] **Step 1: Add a dedicated market-details snapshot model**

```swift
import Foundation

struct MarketDetailsSnapshot: Equatable {
    let open: Decimal?
    let prevClose: Decimal?
    let week52High: Decimal?
    let week52Low: Decimal?
    let marketCap: Decimal?

    static let empty = MarketDetailsSnapshot(
        open: nil,
        prevClose: nil,
        week52High: nil,
        week52Low: nil,
        marketCap: nil
    )
}
```

- [ ] **Step 2: Add an exchange market-details loader protocol**

```swift
import Foundation

protocol ExchangeMarketDetailsLoading {
    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot
}
```

- [ ] **Step 3: Extend `QuoteBoardViewModel` with market-details state**

```swift
@Published private(set) var marketDetails: MarketDetailsSnapshot
```

Initialize it with:

```swift
marketDetails = .empty
```

Reset it on selection changes before loading fresh details:

```swift
marketDetails = .empty
```

- [ ] **Step 4: Build to verify the new model/protocol compile**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-market-details build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the market-details model groundwork**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Models/MarketDetailsSnapshot.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/Exchanges/ExchangeMarketDetailsLoading.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
git commit -m "feat: add market details snapshot model"
```

### Task 2: Implement Exchange-First Loaders for Open and Prev Close

**Files:**
- Create: `RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseMarketDetailsLoader.swift`
- Create: `RealTimeQuote/Services/Exchanges/OKX/OKXMarketDetailsLoader.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: Compile-time verification via app build

- [ ] **Step 1: Implement Coinbase market-details loading with official REST data**

Use Coinbase’s official product stats/product endpoints where available. The first supported goal is `Open` and then derive `Prev Close` only from explicit exchange-provided fields when available; otherwise keep it `nil`.

```swift
import Foundation

final class CoinbaseMarketDetailsLoader: ExchangeMarketDetailsLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot {
        guard exchange == .coinbase else { return .empty }

        let url = URL(string: "https://api.exchange.coinbase.com/products/\(pair.coinbaseProductID)/stats")!
        let (data, _) = try await session.data(from: url)
        let payload = try JSONDecoder().decode(CoinbaseProductStatsResponse.self, from: data)

        return MarketDetailsSnapshot(
            open: Decimal(string: payload.open),
            prevClose: nil,
            week52High: nil,
            week52Low: nil,
            marketCap: nil
        )
    }
}
```

- [ ] **Step 2: Implement OKX market-details loading with official REST data**

Use OKX’s official market endpoints for available ticker/open fields. Only fill fields that are directly provided.

```swift
import Foundation

final class OKXMarketDetailsLoader: ExchangeMarketDetailsLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadDetails(for exchange: ExchangeID, pair: TradingPair) async throws -> MarketDetailsSnapshot {
        guard exchange == .okx else { return .empty }

        let url = URL(string: "https://www.okx.com/api/v5/market/ticker?instId=\(pair.okxInstrumentID)")!
        let (data, _) = try await session.data(from: url)
        let payload = try JSONDecoder().decode(OKXMarketTickerResponse.self, from: data)
        let ticker = payload.data.first

        return MarketDetailsSnapshot(
            open: ticker?.open24h.flatMap(Decimal.init(string:)),
            prevClose: nil,
            week52High: nil,
            week52Low: nil,
            marketCap: nil
        )
    }
}
```

- [ ] **Step 3: Add view-model orchestration to fetch details on startup and selection changes**

Inject a market-details loader factory or a single orchestrator and call it after successful selection changes:

```swift
private func refreshMarketDetails(exchange: ExchangeID, pair: TradingPair) {
    Task { [weak self] in
        guard let self else { return }
        do {
            let details = try await marketDetailsLoader.loadDetails(for: exchange, pair: pair)
            await MainActor.run {
                if self.selectedExchange == exchange, self.selectedPair == pair {
                    self.marketDetails = details
                }
            }
        } catch {
            await MainActor.run {
                if self.selectedExchange == exchange, self.selectedPair == pair {
                    self.marketDetails = .empty
                }
            }
        }
    }
}
```

- [ ] **Step 4: Build to verify exchange loaders compile and integrate**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-market-details build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the initial exchange-first market-details fetching**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseMarketDetailsLoader.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/Exchanges/OKX/OKXMarketDetailsLoader.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
git commit -m "feat: load exchange market details on selection change"
```

### Task 3: Merge Market Details Into the Quote Panel and Opportunistically Fill Extra Fields

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Modify: exchange loader files as needed
- Test: App build and updated debug bundle

- [ ] **Step 1: Merge `MarketDetailsSnapshot` into `QuoteBoardPresentationState`**

Update the initializer to accept market details:

```swift
init(snapshot: QuoteSnapshot, marketDetails: MarketDetailsSnapshot, lastSelectionError: String?) {
    // existing header setup
    stats = [
        StatsGridView.Item(label: "Open", value: Self.currencyText(marketDetails.open), valueColor: .white),
        StatsGridView.Item(label: "High", value: Self.currencyText(snapshot.high24h), valueColor: QuoteBoardTheme.positive),
        StatsGridView.Item(label: "Low", value: Self.currencyText(snapshot.low24h), valueColor: QuoteBoardTheme.negative),
        StatsGridView.Item(label: "Prev Close", value: Self.currencyText(marketDetails.prevClose), valueColor: .white),
        StatsGridView.Item(label: "52 Wk High", value: Self.currencyText(marketDetails.week52High), valueColor: .white),
        StatsGridView.Item(label: "52 Wk Low", value: Self.currencyText(marketDetails.week52Low), valueColor: .white),
        StatsGridView.Item(label: "24H Volume", value: Self.volumeText(snapshot.volume24h), valueColor: .white),
        StatsGridView.Item(label: "Market Cap", value: Self.marketCapText(marketDetails.marketCap), valueColor: .white)
    ]
}
```

- [ ] **Step 2: Add a formatter helper for market-cap-style values**

```swift
private static func marketCapText(_ value: Decimal?) -> String {
    guard let value else { return "--" }
    return currencyFormatter.string(from: value as NSDecimalNumber) ?? "--"
}
```

If the exchange does not provide market cap, keep `--`.

- [ ] **Step 3: Refresh the app bundle for manual verification**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-market-details build
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-market-details/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the debug bundle includes market-details-backed `Open` and any other officially available values.

- [ ] **Step 4: Manually verify the results**

Check:

```text
1. Open displays a real value for the active exchange when available.
2. Prev Close displays a real value if the exchange explicitly provides it; otherwise it remains --.
3. 52 Wk High / 52 Wk Low / Market Cap only appear if the official exchange API provides them.
4. Live websocket quote updates still work normally.
5. Changing exchange/pair refreshes the details fields.
```

- [ ] **Step 5: Commit the presentation merge and bundle refresh**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/Exchanges/Coinbase/CoinbaseMarketDetailsLoader.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/Exchanges/OKX/OKXMarketDetailsLoader.swift
git commit -m "feat: show exchange-backed market detail fields"
```
