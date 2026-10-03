# Responsive Quote Board Resize Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the quote board expand gracefully with larger window sizes so the card fills more of the window, the hero price becomes more prominent, and the layout stays polished instead of sitting as a small fixed panel in a large black canvas.

**Architecture:** Keep the change entirely in the SwiftUI view layer. Introduce a small responsive layout model derived from available width/height, then feed that model into the main quote card, responsive hero price, and stat-card spacing so the same UI scales naturally without changing data flow or window lifecycle behavior.

**Tech Stack:** SwiftUI, AppKit-backed macOS window scene, Xcode build tooling

---

## File Structure

- `RealTimeQuote/Views/QuoteBoardView.swift`
  - Own the size-aware layout model and apply responsive padding, spacing, and card sizing.
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
  - Accept a configurable hero price font size so only the main quote scales noticeably.
- `RealTimeQuote/Views/Components/StatsGridView.swift`
  - Accept responsive spacing so the stats row breathes more naturally in wider windows.

### Task 1: Add a Responsive Layout Model

**Files:**
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Add a small responsive metrics type inside `QuoteBoardView.swift`**

```swift
private struct QuoteBoardLayoutMetrics {
    let outerPadding: CGFloat
    let contentHorizontalPadding: CGFloat
    let contentVerticalPadding: CGFloat
    let sectionSpacing: CGFloat
    let controlSpacing: CGFloat
    let statsSpacing: CGFloat
    let heroPriceFontSize: CGFloat

    static func make(for size: CGSize) -> QuoteBoardLayoutMetrics {
        let width = max(size.width, WindowStyler.minimumSize.width)
        let height = max(size.height, WindowStyler.minimumSize.height)
        let widthProgress = min(max((width - 560) / 280, 0), 1)
        let heightProgress = min(max((height - 360) / 180, 0), 1)
        let progress = max(widthProgress, heightProgress)

        return QuoteBoardLayoutMetrics(
            outerPadding: 18 + (10 * progress),
            contentHorizontalPadding: 28 + (14 * progress),
            contentVerticalPadding: 24 + (12 * progress),
            sectionSpacing: 22 + (10 * progress),
            controlSpacing: 14 + (8 * progress),
            statsSpacing: 14 + (10 * progress),
            heroPriceFontSize: 42 + (22 * progress)
        )
    }
}
```

- [ ] **Step 2: Wrap the quote content area in `GeometryReader` so the layout can react to available size**

```swift
GeometryReader { geometry in
    let metrics = QuoteBoardLayoutMetrics.make(for: geometry.size)

    ZStack {
        QuoteBoardTheme.backgroundGradient
            .ignoresSafeArea()

        RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
            .fill(QuoteBoardTheme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                    .stroke(QuoteBoardTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: QuoteBoardTheme.cardShadow, radius: 24, y: 16)
            .padding(metrics.outerPadding)

        // existing VStack content updated in later tasks
    }
}
```

- [ ] **Step 3: Remove fixed theme spacing usage from the main quote board body and route it through `metrics`**

```swift
VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
    HStack(alignment: .top, spacing: metrics.controlSpacing) {
        ExchangePickerView(selection: exchangeSelection)
        TradingPairPickerView(selection: pairSelection)
        Spacer(minLength: 0)
        ConnectionBadgeView(state: presentation.connectionState)
    }

    PriceHeaderView(
        content: presentation.header,
        heroPriceFontSize: metrics.heroPriceFontSize
    )

    StatsGridView(
        items: presentation.stats,
        horizontalSpacing: metrics.statsSpacing
    )

    if let lastSelectionError = presentation.lastSelectionError {
        Text(lastSelectionError)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(QuoteBoardTheme.errorText)
            .lineLimit(2)
    }
}
.padding(.horizontal, metrics.contentHorizontalPadding)
.padding(.vertical, metrics.contentVerticalPadding)
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
```

- [ ] **Step 4: Build to confirm the responsive layout model compiles before moving on**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-responsive-layout build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the layout model groundwork**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "refactor: add responsive quote board layout metrics"
```

### Task 2: Scale the Hero Price Only

**Files:**
- Modify: `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Extend `PriceHeaderView` to accept a hero price font size parameter**

```swift
struct PriceHeaderView: View {
    let content: Content
    let heroPriceFontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(content.symbol)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(QuoteBoardTheme.primaryText)

                Text(content.exchangeName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuoteBoardTheme.tertiaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(QuoteBoardTheme.badgeFill, in: Capsule())
            }

            Text(content.priceText)
                .font(.system(size: heroPriceFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(content.changeText)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(trendColor)

            Text(content.updatedAtText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(QuoteBoardTheme.tertiaryText)
        }
    }
}
```

- [ ] **Step 2: Update the quote board call site to pass the responsive hero size**

```swift
PriceHeaderView(
    content: presentation.header,
    heroPriceFontSize: metrics.heroPriceFontSize
)
```

- [ ] **Step 3: Build to verify the scaled hero price compiles cleanly**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-responsive-layout build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the hero price responsiveness**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/PriceHeaderView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift
git commit -m "feat: scale quote hero price with window size"
```

### Task 3: Let the Card and Stats Row Breathe in Large Windows

**Files:**
- Modify: `RealTimeQuote/Views/Components/StatsGridView.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
- Test: Manual visual verification via app build

- [ ] **Step 1: Allow `StatsGridView` to receive responsive horizontal spacing**

```swift
struct StatsGridView: View {
    struct Item: Equatable {
        let label: String
        let value: String
    }

    let items: [Item]
    let horizontalSpacing: CGFloat

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: horizontalSpacing) {
                statCards
            }

            VStack(spacing: horizontalSpacing) {
                statCards
            }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        ForEach(items, id: \.label) { item in
            statCard(item: item)
        }
    }
}
```

- [ ] **Step 2: Make sure the main card and content truly occupy the larger window space**

```swift
GeometryReader { geometry in
    let metrics = QuoteBoardLayoutMetrics.make(for: geometry.size)

    ZStack {
        QuoteBoardTheme.backgroundGradient
            .ignoresSafeArea()

        RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
            .fill(QuoteBoardTheme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: QuoteBoardTheme.cardCornerRadius, style: .continuous)
                    .stroke(QuoteBoardTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: QuoteBoardTheme.cardShadow, radius: 24, y: 16)
            .padding(metrics.outerPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            // responsive content
        }
        .padding(.horizontal, metrics.contentHorizontalPadding)
        .padding(.vertical, metrics.contentVerticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

- [ ] **Step 3: Rebuild the double-clickable debug app bundle with the responsive resize changes**

Run:

```bash
xcodebuild -project /Users/tonyhuang/Documents/Application/RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-responsive-layout build
mkdir -p /Users/tonyhuang/Documents/Application/Build/Debug
rm -rf /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-responsive-layout/Build/Products/Debug/RealTimeQuote.app /Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app
```

Expected: the app bundle at `/Users/tonyhuang/Documents/Application/Build/Debug/RealTimeQuote.app` is refreshed with the new responsive layout.

- [ ] **Step 4: Manually verify the larger-window behavior**

Check:

```text
1. Small window still looks like the existing compact quote widget.
2. Enlarged window shows a noticeably larger main card, not a tiny centered panel.
3. Main live price grows in larger widths.
4. Stats cards stay clean and equal-width in the larger size.
```

- [ ] **Step 5: Commit the responsive resize implementation**

```bash
git add /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/QuoteBoardView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/PriceHeaderView.swift /Users/tonyhuang/Documents/Application/RealTimeQuote/Views/Components/StatsGridView.swift
git commit -m "feat: make quote board responsive to larger windows"
```
