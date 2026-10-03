# Real Time Quote Window Chrome And Resize Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the top window chrome stay visually dark more reliably and restore a compact, only-slightly-resizable quote window.

**Architecture:** Replace the current fragile title-bar overlay approach with a more explicit `NSWindow` configuration inside `WindowStyler`, then tighten the min/ideal/max size envelope so the window keeps its quote-widget proportions. Keep the changes narrowly scoped to window styling so quote logic and multi-window behavior remain untouched.

**Tech Stack:** SwiftUI macOS app, AppKit `NSWindow`, `xcodebuild`

---

## File Structure

- Modify: `RealTimeQuote/App/WindowStyler.swift`
  - Primary home for dark chrome stabilization and smaller resize range.
- Modify: `RealTimeQuote/RealTimeQuoteApp.swift`
  - Only if scene-level window configuration needs one small adjustment beyond the styler.
- Test: `Build/Debug/RealTimeQuote.app`
  - Updated double-clickable app bundle for manual visual verification.

### Task 1: Stabilize dark window chrome

**Files:**
- Modify: `RealTimeQuote/App/WindowStyler.swift`

- [ ] **Step 1: Inspect the current window styling implementation**

Run:

```bash
sed -n '1,240p' RealTimeQuote/App/WindowStyler.swift
```

Expected: identify the current `NSWindow` styling hooks and any transparent title-bar logic that may be causing white chrome to reappear.

- [ ] **Step 2: Replace the fragile chrome styling with a more explicit window configuration**

Update the window styling code so it uses a stable `NSWindow` configuration instead of relying only on a transparent title bar. The implementation should preserve native traffic-light controls while preferring predictable dark chrome:

```swift
private func applyWindowStyle(for view: NSView) {
    guard let window = view.window else { return }

    window.styleMask.remove(.fullSizeContentView)
    window.titlebarAppearsTransparent = false
    window.backgroundColor = .black
    window.isOpaque = true

    if let titlebarView = window.standardWindowButton(.closeButton)?.superview {
        titlebarView.wantsLayer = true
        titlebarView.layer?.backgroundColor = NSColor.black.cgColor
    }
}
```

If the exact view hierarchy requires a slightly different target than `superview`, keep the goal the same: use explicit dark AppKit chrome configuration rather than a partial transparency trick.

- [ ] **Step 3: Build to verify the chrome change compiles**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-window-chrome build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the chrome stabilization**

```bash
git add RealTimeQuote/App/WindowStyler.swift
git commit -m "fix: stabilize dark window chrome"
```

### Task 2: Tighten the resize envelope back to quote-widget proportions

**Files:**
- Modify: `RealTimeQuote/App/WindowStyler.swift`

- [ ] **Step 1: Write down the current size envelope**

Run:

```bash
sed -n '1,80p' RealTimeQuote/App/WindowStyler.swift
```

Expected: confirm the current `minimumSize`, `idealSize`, and `maximumSize` values before shrinking the range.

- [ ] **Step 2: Narrow the allowed size range**

Adjust the size constants to allow only a small amount of resizing:

```swift
static let minimumSize = CGSize(width: 560, height: 360)
static let idealSize = CGSize(width: 620, height: 390)
static let maximumSize = CGSize(width: 680, height: 430)
static let defaultSize = idealSize
```

If these exact values prove too tight or too loose during visual verification, stay near this envelope and keep the width/height flexibility clearly smaller than the current build.

- [ ] **Step 3: Rebuild after the resize change**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-window-resize build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit the resize tightening**

```bash
git add RealTimeQuote/App/WindowStyler.swift
git commit -m "style: tighten quote window resize range"
```

### Task 3: Refresh the app bundle and manually verify both behaviors

**Files:**
- Test: `Build/Debug/RealTimeQuote.app`

- [ ] **Step 1: Build the final debug app**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/rtq-window-final build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Refresh the double-clickable app bundle**

Run:

```bash
mkdir -p Build/Debug
rm -rf Build/Debug/RealTimeQuote.app
cp -R /private/tmp/rtq-window-final/Build/Products/Debug/RealTimeQuote.app Build/Debug/RealTimeQuote.app
```

Expected: `Build/Debug/RealTimeQuote.app` contains the latest chrome and resize changes.

- [ ] **Step 3: Launch the updated app**

Run:

```bash
open Build/Debug/RealTimeQuote.app
```

Expected: the rebuilt app opens normally.

- [ ] **Step 4: Perform the manual visual checks**

Manual check:

- confirm the top chrome remains dark on the main display
- drag the window to another display and confirm the top strip does not partially turn white
- resize the window and confirm it only grows/shrinks a little
- confirm the layout still looks balanced at the new maximum size

Expected: both issues reported by Tony are resolved.

- [ ] **Step 5: Commit only if a final verification tweak was needed**

```bash
git status --short
```

Expected: no unexpected tracked source changes remain.
