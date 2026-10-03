# Terminal Horizontal Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the quote body so it reads as a flatter horizontal terminal quote panel with a dominant left price block, a tighter right-side two-column stats cluster, and a better horizontal information rhythm.

**Architecture:** Keep the top controls row and current data flow unchanged. Recompose only the quote content area in SwiftUI by introducing a flatter horizontal body structure and retuning the market-field cluster so it behaves like terminal data, not a sidebar form.

**Tech Stack:** SwiftUI, AppKit-backed macOS window scene, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Own the revised horizontal terminal body and fallback behavior.
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
  - Tighten the left price block rhythm where needed.
- `RealTimeQuote/Views/Components/StatsGridView.swift`
  - Tune the market-field cluster so it reads as a compact horizontal field block.

### Task 1: Tighten the Stats Cluster Into a More Terminal-Like Field Group

**Files:**
- Modify: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Reduce the visual looseness of the field cells**

```swift
private func marketField(item: Item) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(item.label)
            .font(QuoteBoardTheme.regularFont(size: 12))
            .foregroundStyle(QuoteBoardTheme.secondaryText)

        Spacer(minLength: 6)

        Text(item.value)
            .font(QuoteBoardTheme.regularFont(size: 17))
            .foregroundStyle(item.valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
```

- [ ] **Step 2: Tune the grid so the stats feel like a compact cluster instead of a wide sidebar**

```swift
let columns = Array(
    repeating: GridItem(.flexible(minimum: 110), spacing: spacing, alignment: .leading),
    count: numberOfColumns
)
```

- [ ] **Step 3: Build to verify the tuned field cluster compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-horizontal-flow build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the stats-cluster tightening**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/StatsGridView.swift
git commit -m "style: tighten terminal market field cluster"
```

### Task 2: Recompose the Quote Body Into a Flatter Horizontal Flow

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Modify: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Tighten the left price block spacing so it supports a flatter horizontal composition**

```swift
VStack(alignment: .leading, spacing: 6) {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(content.symbol)
            .font(QuoteBoardTheme.regularFont(size: 14))
            .foregroundStyle(QuoteBoardTheme.primaryText)

        Text(content.exchangeName)
            .font(QuoteBoardTheme.regularFont(size: 14))
            .foregroundStyle(QuoteBoardTheme.primaryText)
    }

    Text(content.priceText)
        .font(QuoteBoardTheme.heavyFont(size: heroPriceFontSize))
        .foregroundStyle(trendColor)

    Text(content.changeText)
        .font(QuoteBoardTheme.regularFont(size: 15))
        .foregroundStyle(trendColor)

    Text(content.updatedAtText)
        .font(QuoteBoardTheme.regularFont(size: 12))
        .foregroundStyle(QuoteBoardTheme.secondaryText)
}
```

- [ ] **Step 2: Split the quote body into a flatter top band and lower support row**

```swift
VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
    HStack(alignment: .top, spacing: metrics.controlSpacing) {
        ExchangePickerView(selection: exchangeSelection)
        TradingPairPickerView(selection: pairSelection)
        Spacer(minLength: 0)
        ConnectionBadgeView(state: presentation.connectionState)
    }

    HStack(alignment: .top, spacing: metrics.sectionSpacing) {
        terminalQuoteColumn(
            presentation: presentation,
            metrics: metrics
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)

        terminalFieldsColumn(
            presentation: presentation,
            metrics: metrics
        )
        .frame(width: metrics.statsColumnWidth, alignment: .topLeading)
    }

    terminalSupportRow(
        presentation: presentation,
        metrics: metrics
    )
}
```

- [ ] **Step 3: Add a simple lower support row that improves horizontal rhythm without inventing fake data**

```swift
@ViewBuilder
private func terminalSupportRow(
    presentation: QuoteBoardPresentationState,
    metrics: QuoteBoardLayoutMetrics
) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: metrics.controlSpacing) {
        Text(presentation.header.updatedAtText)
            .font(QuoteBoardTheme.regularFont(size: 12))
            .foregroundStyle(QuoteBoardTheme.secondaryText)

        Spacer(minLength: 0)

        if let lastSelectionError = presentation.lastSelectionError {
            Text(lastSelectionError)
                .font(QuoteBoardTheme.regularFont(size: 12))
                .foregroundStyle(QuoteBoardTheme.errorText)
                .lineLimit(1)
        }
    }
}
```

- [ ] **Step 4: Build to verify the flatter horizontal body compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-horizontal-flow build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the horizontal-flow quote body revision**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/PriceHeaderView.swift
git commit -m "feat: revise quote body to terminal horizontal flow"
```

### Task 3: Tune Fallback Behavior and Refresh the App Bundle

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build and updated bundle

- [ ] **Step 1: Keep the stacked fallback, but make the horizontal layout preferred for normal desktop widths**

```swift
let useStackedTerminalLayout = geometry.size.width < 780
```

- [ ] **Step 2: Rebuild the app and refresh the double-clickable bundle**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-horizontal-flow build
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-horizontal-flow/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the debug bundle reflects the flatter horizontal quote layout.

- [ ] **Step 3: Manually verify the revised layout**

Check:

```text
1. The left price block remains dominant.
2. The right-side market fields feel like a compact quote cluster instead of a form rail.
3. The body reads more horizontally and more closely matches the provided reference.
4. Existing live data still updates correctly.
5. Narrower windows still fall back cleanly.
```

- [ ] **Step 4: Commit the fallback tuning and bundle refresh**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: tune terminal horizontal fallback"
```
