# Mixed-Source Reference Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a third-party reference stats layer so the quote panel can replace the remaining placeholders with real `Market Cap`, `52 Wk High`, and `52 Wk Low` values for supported pairs, while preserving all existing exchange-backed live quote and session-detail behavior.

**Architecture:** Keep the current three responsibilities separate: websocket-driven `QuoteSnapshot` for live movement, exchange REST-backed `MarketDetailsSnapshot` for trading-session fields, and a new `ReferenceStatsSnapshot` for slower-moving asset reference data from a third-party provider. The view model will orchestrate selection-triggered loads and merge all three snapshots into one presentation state.

**Tech Stack:** Swift, SwiftUI, Foundation `URLSession`, Coinbase/OKX official APIs, one third-party market reference API, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Models/ReferenceStatsSnapshot.swift`
  - New model for market cap and 52-week reference fields.
- `RealTimeQuote/Services/ReferenceData/ReferenceStatsLoading.swift`
  - Protocol for loading third-party reference stats.
- `RealTimeQuote/Services/ReferenceData/ThirdPartyReferenceStatsLoader.swift`
  - Concrete reference data loader and pair-to-provider mapping.
- `RealTimeQuote/Models/TradingPair.swift`
  - Extend mapping support if a provider-specific symbol or asset id is needed.
- `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
  - Track and refresh reference stats on selection changes.
- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Merge reference stats into presentation output.

### Task 1: Introduce a Reference Stats Model and Loader Interface

**Files:**
- Create: `RealTimeQuote/Models/ReferenceStatsSnapshot.swift`
- Create: `RealTimeQuote/Services/ReferenceData/ReferenceStatsLoading.swift`
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: Compile-time verification via app build

- [ ] **Step 1: Add a dedicated reference stats snapshot model**

```swift
import Foundation

struct ReferenceStatsSnapshot: Equatable {
    let week52High: Decimal?
    let week52Low: Decimal?
    let marketCap: Decimal?

    static let empty = ReferenceStatsSnapshot(
        week52High: nil,
        week52Low: nil,
        marketCap: nil
    )
}
```

- [ ] **Step 2: Add a reference stats loader protocol**

```swift
import Foundation

protocol ReferenceStatsLoading {
    func loadStats(for pair: TradingPair) async throws -> ReferenceStatsSnapshot
}
```

- [ ] **Step 3: Extend `QuoteBoardViewModel` with reference-stats state**

Add:

```swift
@Published private(set) var referenceStats: ReferenceStatsSnapshot
```

Initialize with:

```swift
referenceStats = .empty
```

Reset it on pair changes before loading fresh data:

```swift
referenceStats = .empty
```

- [ ] **Step 4: Build to verify the new model/protocol compile**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the reference stats groundwork**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Models/ReferenceStatsSnapshot.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/ReferenceData/ReferenceStatsLoading.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
git commit -m "feat: add reference stats snapshot model"
```

### Task 2: Implement a Third-Party Reference Stats Loader for Supported Pairs

**Files:**
- Create: `RealTimeQuote/Services/ReferenceData/ThirdPartyReferenceStatsLoader.swift`
- Modify: `RealTimeQuote/Models/TradingPair.swift`
- Test: Compile-time verification via app build

- [ ] **Step 1: Add provider-specific pair mapping**

Extend `TradingPair` with a provider mapping, for example:

```swift
var referenceSymbol: String {
    switch self {
    case .btcUSD: return "BTC"
    case .ethUSD: return "ETH"
    case .adaUSD: return "ADA"
    case .solUSD: return "SOL"
    }
}
```

If the chosen provider needs a different identifier shape, use that instead.

- [ ] **Step 2: Implement a concrete third-party reference stats loader**

Shape:

```swift
import Foundation

final class ThirdPartyReferenceStatsLoader: ReferenceStatsLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadStats(for pair: TradingPair) async throws -> ReferenceStatsSnapshot {
        let symbol = pair.referenceSymbol
        let url = makeReferenceURL(for: symbol)
        let (data, _) = try await session.data(from: url)
        let payload = try decodePayload(data)

        return ReferenceStatsSnapshot(
            week52High: payload.week52High,
            week52Low: payload.week52Low,
            marketCap: payload.marketCap
        )
    }
}
```

Important:

- support `BTC-USD`, `ETH-USD`, `ADA-USD`, `SOL-USD`
- decode only the fields we need
- leave missing values as `nil`

- [ ] **Step 3: Keep failure behavior quiet**

If the provider returns incomplete data, treat unavailable fields as `nil` rather than throwing fatal UI errors whenever possible.

- [ ] **Step 4: Build to verify the loader and mapping compile**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the reference-loader implementation**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Services/ReferenceData/ThirdPartyReferenceStatsLoader.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Models/TradingPair.swift
git commit -m "feat: add third-party reference stats loader"
```

### Task 3: Orchestrate Reference Stats Refreshes in the View Model

**Files:**
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: Compile-time verification via app build

- [ ] **Step 1: Inject or construct the reference stats loader**

Add a dependency for:

```swift
private let referenceStatsLoader: ReferenceStatsLoading
```

- [ ] **Step 2: Refresh reference stats on initial load and pair changes**

Add orchestration similar to market-details loading:

```swift
private func refreshReferenceStats(pair: TradingPair) {
    Task { [weak self] in
        guard let self else { return }
        do {
            let stats = try await referenceStatsLoader.loadStats(for: pair)
            await MainActor.run {
                if self.selectedPair == pair {
                    self.referenceStats = stats
                }
            }
        } catch {
            await MainActor.run {
                if self.selectedPair == pair {
                    self.referenceStats = .empty
                }
            }
        }
    }
}
```

Call it:

- after initial selection bootstrap
- after successful pair changes

- [ ] **Step 3: Make sure stale async results do not overwrite a newer selection**

Guard updates by comparing the current `selectedPair` before assigning published state.

- [ ] **Step 4: Build to verify orchestration compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the orchestration**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/ViewModels/QuoteBoardViewModel.swift
git commit -m "feat: refresh reference stats on pair changes"
```

### Task 4: Merge Reference Stats Into the Quote Panel

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: App build and updated debug bundle

- [ ] **Step 1: Extend `QuoteBoardPresentationState` to accept reference stats**

Update initializer shape to take:

```swift
init(
    snapshot: QuoteSnapshot,
    marketDetails: MarketDetailsSnapshot,
    referenceStats: ReferenceStatsSnapshot,
    lastSelectionError: String?
)
```

- [ ] **Step 2: Route the correct fields to the correct source**

Use:

- `Open` from `marketDetails.open`
- `Prev Close` from `marketDetails.prevClose`
- `52 Wk High` from `referenceStats.week52High`
- `52 Wk Low` from `referenceStats.week52Low`
- `Market Cap` from `referenceStats.marketCap`

Keep all live quote fields sourced exactly as they are today.

- [ ] **Step 3: Preserve fallback rendering**

If reference stats are absent, continue rendering `--` with no structural UI changes.

- [ ] **Step 4: Build to verify the quote panel compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Refresh the debug app bundle for manual verification**

```bash
cp -R /private/tmp/rtq-reference-stats/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

- [ ] **Step 6: Commit the UI wiring**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: show mixed-source reference stats"
```

### Task 5: Manual Verification and Push Preparation

**Files:**
- No source changes required unless issues are found

- [ ] **Step 1: Verify supported pairs are covered**

Manually confirm that:

- `BTC-USD`
- `ETH-USD`
- `ADA-USD`
- `SOL-USD`

all attempt to load reference stats without breaking the current app flow.

- [ ] **Step 2: Verify degradation behavior**

If the third-party provider does not return a field:

- the app still loads
- the field renders as `--`
- no exchange-backed values regress

- [ ] **Step 3: Run a final build**

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-stats-final build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit any follow-up fixes**

```bash
git add <any follow-up files>
git commit -m "fix: polish reference stats integration"
```

- [ ] **Step 5: Push when ready**

```bash
git push origin main
```

## Verification Checklist

- [ ] `Market Cap` renders a real value when the provider supports the pair.
- [ ] `52 Wk High` renders a real value when available.
- [ ] `52 Wk Low` renders a real value when available.
- [ ] `Open` and `Prev Close` continue to come from exchange-backed data.
- [ ] Unsupported or failed reference stats safely render `--`.
- [ ] Pair switching refreshes reference stats correctly without overwriting newer selections.
- [ ] `xcodebuild build` succeeds.

## Notes

- Keep the third-party integration narrow and replaceable.
- Do not let provider-specific assumptions leak into quote rendering logic more than necessary.
- Prefer explicit symbol mapping in `TradingPair` over ad-hoc string munging inside service code.
