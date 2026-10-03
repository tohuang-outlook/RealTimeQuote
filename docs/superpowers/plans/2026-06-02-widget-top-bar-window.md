# Real Time Quote Widget Top Bar Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the unstable native-looking white title bar with a thin black widget-style top bar, keep dragging intuitive, and preserve a compact quote-window resize range.

**Architecture:** Stop trying to recolor native macOS title-bar materials and instead hide their visual presence behind a content-level top strip that belongs to the app UI. The window itself stays standard enough to remain draggable and usable, while `WindowStyler` and the root layout coordinate a compact, widget-like chrome treatment and a narrow resize envelope.

**Tech Stack:** SwiftUI macOS app, AppKit `NSWindow`, `xcodebuild`

---

## File Structure

- Modify: `RealTimeQuote/App/WindowStyler.swift`
  - Configure the window for a widget-style top edge and compact resize behavior.
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`
  - Add a thin black top bar / drag region if the content layer is the cleanest place to express it.
- Modify: `RealTimeQuote/RealTimeQuoteApp.swift`
  - Only if scene-level window settings need a small supporting change.
- Test: `Build/Debug/RealTimeQuote.app`
  - Updated double-clickable app bundle for manual visual verification.

### Task 1: Introduce a thin widget-style top bar and drag region

**Files:**
- Modify: `RealTimeQuote/App/WindowStyler.swift`
- Modify: `RealTimeQuote/Views/QuoteBoardView.swift`

- [ ] **Step 1: Inspect the current window and root-view structure**

Run:

```bash
sed -n '1,240p' RealTimeQuote/App/WindowStyler.swift
sed -n '1,260p' RealTimeQuote/Views/QuoteBoardView.swift
```

Expected: identify the cleanest layer to add a thin top strip without disturbing the quote card layout.

- [ ] **Step 2: Replace title-bar recoloring with widget-style chrome**

Update `RealTimeQuote/App/WindowStyler.swift` so the window stops depending on the native title-bar look:

```swift
window.titleVisibility = .hidden
window.titlebarAppearsTransparent = true
window.styleMask.insert(.fullSizeContentView)
window.backgroundColor = .black
window.isOpaque = true
```

The goal is to let the app content own the top visual strip rather than fighting system title-bar material.

- [ ] **Step 3: Add a thin black top bar that supports dragging**

If `QuoteBoardView.swift` is the cleanest place, add a very small top strip above the quote content:

```swift
private let widgetTopBarHeight: CGFloat = 18

VStack(spacing: 0) {
    Rectangle()
        .fill(Color.black)
        .frame(height: widgetTopBarHeight)
        .overlay(alignment: .topLeading) {
            EmptyView()
        }
    existingContent
}
```

If needed, host a tiny `NSViewRepresentable` inside that strip and set:

```swift
view.window?.isMovableByWindowBackground = true
```

Expected: the app shows a deliberate black top strip with no title text and still drags naturally.

- [ ] **Step 4: Build to verify the widget chrome compiles**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-widget-bar build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit the top-bar chrome change**

```bash
git add RealTimeQuote/App/WindowStyler.swift RealTimeQuote/Views/QuoteBoardView.swift RealTimeQuote/RealTimeQuoteApp.swift
git commit -m "style: add widget top bar chrome"
```

### Task 2: Restore the compact resize envelope

**Files:**
- Modify: `RealTimeQuote/App/WindowStyler.swift`

- [ ] **Step 1: Confirm the current size constants**

Run:

```bash
sed -n '1,80p' RealTimeQuote/App/WindowStyler.swift
```

Expected: capture the current `minimumSize`, `idealSize`, and `maximumSize` values before tightening them.

- [ ] **Step 2: Set a compact quote-widget range**

Use a narrow resize range such as:

```swift
static let minimumSize = CGSize(width: 560, height: 360)
static let idealSize = CGSize(width: 620, height: 390)
static let maximumSize = CGSize(width: 680, height: 430)
static let defaultSize = idealSize
```

If the top bar slightly changes perceived spacing, keep the envelope close to these values and preserve the "only a little" resize feel.

- [ ] **Step 3: Rebuild after the resize adjustment**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-widget-resize build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the compact resize behavior**

```bash
git add RealTimeQuote/App/WindowStyler.swift
git commit -m "style: restore compact widget resize range"
```

### Task 3: Refresh the app bundle and manually verify behavior

**Files:**
- Test: `Build/Debug/RealTimeQuote.app`

- [ ] **Step 1: Build the final debug app**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-widget-final build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Refresh the double-clickable app bundle**

Run:

```bash
mkdir -p Build/Debug
rm -rf Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-widget-final/Build/Products/Debug/RealTimeQuote.app Build/Debug/RealTimeQuote.app
```

Expected: `Build/Debug/RealTimeQuote.app` contains the latest widget top-bar treatment.

- [ ] **Step 3: Launch the updated app**

Run:

```bash
open Build/Debug/RealTimeQuote.app
```

Expected: the app opens normally from the refreshed bundle.

- [ ] **Step 4: Perform the manual visual checks**

Manual check:

- confirm the top white strip is gone
- confirm the new top bar is thin, black, and titleless
- drag the window and confirm movement still feels natural
- move it between displays and confirm the white title-bar problem does not return
- confirm the window only resizes a little and still looks balanced

Expected: the widget-style chrome resolves the cross-display white strip problem and the oversized-window problem together.

- [ ] **Step 5: Commit only if a final verification tweak was needed**

```bash
git status --short
```

Expected: no unexpected tracked source changes remain.
