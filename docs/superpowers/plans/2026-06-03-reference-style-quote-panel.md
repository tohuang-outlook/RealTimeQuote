# Reference-Style Quote Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the quote body so it closely follows the latest reference image, with a dominant left quote block, compact change values, and two aligned right-side stats columns.

**Architecture:** Keep the existing top controls row, window behavior, and data flow, but replace the quote body composition in SwiftUI. Reshape the left quote block and right-side field cluster so the UI reads like a reference-style quote terminal rather than a grid-based app panel.

**Tech Stack:** SwiftUI, AppKit-backed macOS window scene, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Own the overall reference-style quote-body composition and placeholder field arrangement.
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
  - Reshape the left quote block to match the reference hierarchy more closely.
- `RealTimeQuote/Views/Components/StatsGridView.swift`
  - Rework the stats cluster into two aligned terminal columns.

### Task 1: Rebuild the Right-Side Stats Cluster Into Reference Columns

**Files:**
- Modify: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Adjust the stats model ordering to match the reference column grouping**

```swift
stats = [
    StatsGridView.Item(label: "Open", value: "--", valueColor: .white),
    StatsGridView.Item(label: "High", value: Self.currencyText(snapshot.high24h), valueColor: QuoteBoardTheme.positive),
    StatsGridView.Item(label: "Low", value: Self.currencyText(snapshot.low24h), valueColor: QuoteBoardTheme.negative),
    StatsGridView.Item(label: "Prev Close", value: "--", valueColor: .white),
    StatsGridView.Item(label: "52 Wk High", value: "--", valueColor: .white),
    StatsGridView.Item(label: "52 Wk Low", value: "--", valueColor: .white),
    StatsGridView.Item(label: "24H Volume", value: Self.volumeText(snapshot.volume24h), valueColor: .white),
    StatsGridView.Item(label: "Market Cap", value: "--", valueColor: .white)
]
```

- [ ] **Step 2: Make the stats renderer behave like two aligned terminal columns**

```swift
let columns = [
    GridItem(.flexible(minimum: 120), spacing: spacing, alignment: .leading),
    GridItem(.flexible(minimum: 120), spacing: spacing, alignment: .leading)
]
```

```swift
private func marketField(item: Item) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(item.label)
            .font(QuoteBoardTheme.regularFont(size: 12))
            .foregroundStyle(QuoteBoardTheme.secondaryText)

        Spacer(minLength: 8)

        Text(item.value)
            .font(QuoteBoardTheme.regularFont(size: 16))
            .foregroundStyle(item.valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
```

- [ ] **Step 3: Build to verify the reference-style stats cluster compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-panel build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the reference stats cluster groundwork**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/StatsGridView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "refactor: align quote stats with reference columns"
```

### Task 2: Reshape the Left Quote Block and Main Body Composition

**Files:**
- Modify: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Rework the left price block so change values tuck closer to the main price**

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

    HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(content.priceText)
            .font(QuoteBoardTheme.heavyFont(size: heroPriceFontSize))
            .foregroundStyle(trendColor)

        VStack(alignment: .leading, spacing: 2) {
            Text(changeAmountText)
                .font(QuoteBoardTheme.regularFont(size: 14))
                .foregroundStyle(trendColor)

            Text(changePercentText)
                .font(QuoteBoardTheme.regularFont(size: 14))
                .foregroundStyle(trendColor)
        }
    }

    Text(content.updatedAtText)
        .font(QuoteBoardTheme.regularFont(size: 12))
        .foregroundStyle(QuoteBoardTheme.secondaryText)
}
```

If implementation splits `changeText` into amount/percent display fields, keep that split local to the view-model/presentation layer and do not change exchange logic.

- [ ] **Step 2: Recompose the quote body to match the reference structure more directly**

```swift
VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
    HStack(alignment: .top, spacing: metrics.controlSpacing) {
        ExchangePickerView(selection: exchangeSelection)
        TradingPairPickerView(selection: pairSelection)
        Spacer(minLength: 0)
        ConnectionBadgeView(state: presentation.connectionState)
    }

    HStack(alignment: .top, spacing: metrics.sectionSpacing) {
        referenceQuoteColumn(
            presentation: presentation,
            metrics: metrics
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)

        referenceStatsColumns(
            presentation: presentation,
            metrics: metrics
        )
        .frame(width: metrics.statsColumnWidth, alignment: .topLeading)
    }
}
```

- [ ] **Step 3: Remove the extra support-row feel so the body stays closer to the reference**

```swift
// Delete the current terminalSupportRow call from the main quote body.
```

If an updated/open-mid line remains, it should stay inside the left quote block and not as a separate visible lower strip.

- [ ] **Step 4: Build to verify the new quote body compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-panel build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the reference-style quote body**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/PriceHeaderView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: rebuild quote body toward reference panel"
```

### Task 3: Tune Width Behavior and Refresh the App Bundle

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build and updated bundle

- [ ] **Step 1: Keep a narrow-window fallback, but prioritize the reference layout at normal widths**

```swift
let useStackedReferenceLayout = geometry.size.width < 760
```

```swift
if useStackedReferenceLayout {
    VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
        referenceQuoteColumn(
            presentation: presentation,
            metrics: metrics
        )

        referenceStatsColumns(
            presentation: presentation,
            metrics: metrics
        )
    }
} else {
    HStack(alignment: .top, spacing: metrics.sectionSpacing) {
        referenceQuoteColumn(
            presentation: presentation,
            metrics: metrics
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)

        referenceStatsColumns(
            presentation: presentation,
            metrics: metrics
        )
        .frame(width: metrics.statsColumnWidth, alignment: .topLeading)
    }
}
```

- [ ] **Step 2: Rebuild the app and refresh the double-clickable bundle**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-reference-panel build
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-reference-panel/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the refreshed bundle reflects the new reference-style quote body.

- [ ] **Step 3: Manually verify the final layout**

Check:

```text
1. The left quote block dominates visually.
2. Change values sit close to the main price like the reference.
3. The right-side stats appear as two aligned columns, not a sidebar form.
4. Placeholder fields preserve the intended layout.
5. Narrow windows still degrade cleanly.
```

- [ ] **Step 4: Commit the fallback tuning and bundle refresh**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: tune reference-style quote layout fallback"
```
