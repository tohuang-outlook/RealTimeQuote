# Terminal Quote Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the main quote body into a classic terminal-style quote panel with a large left-side live price and a compact text-based market field layout instead of stat boxes.

**Architecture:** Keep the current data flow, window behavior, and typography direction, but replace the quote-body composition in the SwiftUI view layer. Introduce a compact market-field model and a terminal-style metric grid that can render live values where available and placeholders where data is not yet supported.

**Tech Stack:** SwiftUI, AppKit-backed macOS window scene, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Own the overall terminal quote layout and field data preparation.
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
  - Continue rendering the primary quote block, possibly with tighter spacing to match the terminal panel rhythm.
- `RealTimeQuote/Views/Components/StatsGridView.swift`
  - Replace or refactor into a terminal-style market fields component.

### Task 1: Create a Terminal Market Fields Model and Renderer

**Files:**
- Modify: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Refactor the stats component to represent generic terminal-style market fields**

```swift
struct StatsGridView: View {
    struct Item: Equatable {
        let label: String
        let value: String
        let valueColor: Color
    }

    let items: [Item]
    let spacing: CGFloat
    let numberOfColumns: Int

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 120), spacing: spacing, alignment: .leading),
            count: numberOfColumns
        )

        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            ForEach(items, id: \.label) { item in
                marketField(item: item)
            }
        }
    }
}
```

- [ ] **Step 2: Implement a compact terminal-style market field cell**

```swift
private func marketField(item: Item) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(item.label)
            .font(QuoteBoardTheme.regularFont(size: 12))
            .foregroundStyle(QuoteBoardTheme.secondaryText)

        Spacer(minLength: 8)

        Text(item.value)
            .font(QuoteBoardTheme.regularFont(size: 18))
            .foregroundStyle(item.valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
```

- [ ] **Step 3: Expand `QuoteBoardPresentationState` so the field list includes live data plus placeholders**

```swift
stats = [
    StatsGridView.Item(label: "Open", value: "--", valueColor: .white),
    StatsGridView.Item(label: "Prev Close", value: "--", valueColor: .white),
    StatsGridView.Item(label: "24H Volume", value: Self.volumeText(snapshot.volume24h), valueColor: .white),
    StatsGridView.Item(label: "High", value: Self.currencyText(snapshot.high24h), valueColor: QuoteBoardTheme.positive),
    StatsGridView.Item(label: "Low", value: Self.currencyText(snapshot.low24h), valueColor: QuoteBoardTheme.negative),
    StatsGridView.Item(label: "52W High", value: "--", valueColor: .white),
    StatsGridView.Item(label: "52W Low", value: "--", valueColor: .white),
    StatsGridView.Item(label: "Market Cap", value: "--", valueColor: .white)
]
```

- [ ] **Step 4: Build to verify the field model and compact renderer compile**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-terminal-panel build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the terminal market fields groundwork**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/StatsGridView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "refactor: add terminal market field model"
```

### Task 2: Rebuild the Quote Body as a Terminal Panel

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Modify: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Tighten the price header spacing to feel more like a terminal quote block**

```swift
VStack(alignment: .leading, spacing: 8) {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(content.symbol)
            .font(QuoteBoardTheme.regularFont(size: 15))
            .foregroundStyle(QuoteBoardTheme.primaryText)

        Text(content.exchangeName)
            .font(QuoteBoardTheme.regularFont(size: 14))
            .foregroundStyle(QuoteBoardTheme.primaryText)
    }

    Text(content.priceText)
        .font(QuoteBoardTheme.heavyFont(size: heroPriceFontSize))
        .foregroundStyle(trendColor)

    Text(content.changeText)
        .font(QuoteBoardTheme.regularFont(size: 16))
        .foregroundStyle(trendColor)

    Text(content.updatedAtText)
        .font(QuoteBoardTheme.regularFont(size: 12))
        .foregroundStyle(QuoteBoardTheme.secondaryText)
}
```

- [ ] **Step 2: Replace the current quote-body layout with a flatter terminal-style body**

```swift
VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
    HStack(alignment: .top, spacing: metrics.controlSpacing) {
        ExchangePickerView(selection: exchangeSelection)
        TradingPairPickerView(selection: pairSelection)
        Spacer(minLength: 0)
        ConnectionBadgeView(state: presentation.connectionState)
    }

    HStack(alignment: .top, spacing: metrics.sectionSpacing) {
        PriceHeaderView(
            content: presentation.header,
            heroPriceFontSize: metrics.heroPriceFontSize
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)

        StatsGridView(
            items: presentation.stats,
            spacing: metrics.statsSpacing,
            numberOfColumns: 2
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
```

- [ ] **Step 3: Remove the remaining card-heavy composition inside the quote body while keeping the outer shell**

```swift
RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
    .fill(QuoteBoardTheme.cardFill)
    .overlay(
        RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
            .stroke(QuoteBoardTheme.cardStroke, lineWidth: 1)
    )
    .padding(metrics.outerPadding)
```

Keep the outer shell, but do not reintroduce internal stat-card boxes.

- [ ] **Step 4: Build to verify the terminal panel layout compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-terminal-panel build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the terminal quote body layout**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/PriceHeaderView.swift
git commit -m "feat: rebuild quote body as terminal panel"
```

### Task 3: Add Responsive Fallback and Refresh the App Bundle

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build and updated bundle

- [ ] **Step 1: Add a simple compact fallback when the window gets too narrow**

```swift
let useStackedTerminalLayout = geometry.size.width < 820
```

```swift
Group {
    if useStackedTerminalLayout {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            PriceHeaderView(
                content: presentation.header,
                heroPriceFontSize: metrics.heroPriceFontSize
            )

            StatsGridView(
                items: presentation.stats,
                spacing: metrics.statsSpacing,
                numberOfColumns: 1
            )
        }
    } else {
        HStack(alignment: .top, spacing: metrics.sectionSpacing) {
            PriceHeaderView(
                content: presentation.header,
                heroPriceFontSize: metrics.heroPriceFontSize
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)

            StatsGridView(
                items: presentation.stats,
                spacing: metrics.statsSpacing,
                numberOfColumns: 2
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
```

- [ ] **Step 2: Rebuild the app and refresh the double-clickable bundle**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-terminal-panel build
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-terminal-panel/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the updated app bundle reflects the terminal-style quote panel.

- [ ] **Step 3: Manually verify the terminal layout behavior**

Check:

```text
1. Large live price remains the dominant element on the left.
2. Market fields appear as compact text fields, not boxes.
3. Real data appears for price, change, high, low, and volume.
4. Placeholder fields show as `--` without breaking the layout.
5. Narrower windows stack the terminal fields cleanly.
```

- [ ] **Step 4: Commit the fallback and bundle refresh**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: add terminal panel fallback layout"
```
