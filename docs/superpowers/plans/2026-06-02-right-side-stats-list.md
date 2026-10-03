# Right-Side Stats List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `24H HIGH`, `24H LOW`, and `24H VOL` into a right-side vertical `label | value` list beside the main quote area, with a stacked fallback for narrow windows.

**Architecture:** Keep the change in the SwiftUI view layer by splitting the current quote body into a left quote column and a right stats column. Replace the card-based stats presentation in the normal layout with a lighter list-style component that preserves the existing color semantics.

**Tech Stack:** SwiftUI, AppKit-backed macOS window scene, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Own the two-column layout and narrow-window fallback logic.
- `RealTimeQuote/Views/Components/StatsGridView.swift`
  - Replace with or refactor into a list-style stats component suitable for right-side display.

### Task 1: Replace the Stat Cards with a List-Style Stats Component

**Files:**
- Modify: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Rename the responsibility of `StatsGridView` from card row to list-style stats block**

```swift
struct StatsGridView: View {
    struct Item: Equatable {
        let label: String
        let value: String
        let valueColor: Color
    }

    let items: [Item]
    let spacing: CGFloat

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(items, id: \.label) { item in
                statRow(item: item)
            }
        }
    }
}
```

- [ ] **Step 2: Implement a light `label | value` row instead of boxed cards**

```swift
private func statRow(item: Item) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 18) {
        Text(item.label)
            .font(QuoteBoardTheme.boldFont(size: 11))
            .foregroundStyle(QuoteBoardTheme.tertiaryText)

        Spacer(minLength: 12)

        Text(item.value)
            .font(QuoteBoardTheme.regularFont(size: 18))
            .foregroundStyle(item.valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 3: Build to confirm the list-style component compiles cleanly**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-right-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the stats component refactor**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/StatsGridView.swift
git commit -m "refactor: convert stats cards into stats list rows"
```

### Task 2: Split the Quote Body Into Left and Right Columns

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Extract the main quote area into a dedicated left-column view builder**

```swift
@ViewBuilder
private func mainQuoteColumn(
    presentation: QuoteBoardPresentationState,
    metrics: QuoteBoardLayoutMetrics
) -> some View {
    VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
        PriceHeaderView(
            content: presentation.header,
            heroPriceFontSize: metrics.heroPriceFontSize
        )

        if let lastSelectionError = presentation.lastSelectionError {
            Text(lastSelectionError)
                .font(QuoteBoardTheme.regularFont(size: 12))
                .foregroundStyle(QuoteBoardTheme.errorText)
                .lineLimit(2)
        }
    }
}
```

- [ ] **Step 2: Extract the stats area into a dedicated right-column view builder**

```swift
@ViewBuilder
private func statsColumn(
    presentation: QuoteBoardPresentationState,
    metrics: QuoteBoardLayoutMetrics
) -> some View {
    StatsGridView(
        items: presentation.stats,
        spacing: metrics.statsSpacing
    )
    .frame(maxWidth: .infinity, alignment: .topLeading)
}
```

- [ ] **Step 3: Replace the old bottom stats row with a horizontal split under the controls**

```swift
HStack(alignment: .top, spacing: metrics.sectionSpacing) {
    mainQuoteColumn(
        presentation: presentation,
        metrics: metrics
    )
    .frame(maxWidth: .infinity, alignment: .topLeading)

    statsColumn(
        presentation: presentation,
        metrics: metrics
    )
    .frame(width: max(170, geometry.size.width * 0.28), alignment: .topLeading)
}
```

- [ ] **Step 4: Build to confirm the two-column layout compiles**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-right-stats build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the two-column quote layout**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: move quote stats into a right-side rail"
```

### Task 3: Add Narrow-Window Fallback and Refresh the App Bundle

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build and updated bundle

- [ ] **Step 1: Add a simple width-based fallback between side-by-side and stacked layouts**

```swift
let useStackedStatsLayout = geometry.size.width < 760
```

```swift
Group {
    if useStackedStatsLayout {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            mainQuoteColumn(
                presentation: presentation,
                metrics: metrics
            )

            statsColumn(
                presentation: presentation,
                metrics: metrics
            )
        }
    } else {
        HStack(alignment: .top, spacing: metrics.sectionSpacing) {
            mainQuoteColumn(
                presentation: presentation,
                metrics: metrics
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)

            statsColumn(
                presentation: presentation,
                metrics: metrics
            )
            .frame(width: max(170, geometry.size.width * 0.28), alignment: .topLeading)
        }
    }
}
```

- [ ] **Step 2: Rebuild the app and refresh the double-clickable bundle**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-right-stats build
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-right-stats/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the refreshed bundle reflects the new right-side stats list layout.

- [ ] **Step 3: Manually verify the layout behavior**

Check:

```text
1. Normal window size shows the stats on the right side, vertically stacked.
2. No boxed stat cards remain in the normal layout.
3. HIGH stays green, LOW stays red, VOL stays white.
4. Narrow windows stack the stats list below the main quote area cleanly.
```

- [ ] **Step 4: Commit the fallback and app-refresh work**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: add stacked fallback for right-side stats layout"
```
