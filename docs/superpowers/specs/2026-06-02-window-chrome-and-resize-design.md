# Real Time Quote Window Chrome And Resize Design

## Overview

This spec tightens the macOS window presentation for `Real Time Quote`. The current experimental title-bar darkening approach is visually unstable when the window moves between displays, and the current resize range lets the window stretch far beyond the compact quote-terminal feel the app is aiming for.

## Goals

- Keep the top window chrome visually dark and consistent
- Avoid the partial white title-bar reappearance when moving the window across displays
- Restore a compact, quote-widget-like resize behavior
- Preserve native macOS window controls and basic title-bar behavior

## Non-Goals

- Replacing the native macOS title bar entirely
- Creating a custom draggable chrome implementation
- Adding always-on-top behavior
- Making the window completely fixed-size

## User Experience

The app should keep the familiar macOS red/yellow/green controls, but the top strip should visually blend with the black app surface instead of flashing or splitting into white areas. When the user drags the window to another display, the title-bar treatment should remain visually consistent.

The window should also feel like a compact market quote tool again. Users may resize it a little, but not enough to turn it into a wide, awkward dashboard layout.

## Design

### Stable Window Chrome

The current approach relies on transparent title-bar behavior layered over the content background. That appears insufficiently stable across display moves.

The new implementation should use a more explicit `NSWindow` style configuration that favors consistency over cleverness. The preferred outcome is:

- a dark top chrome
- stable rendering when moving between displays
- no dependence on a fragile partial transparency effect that leaves white areas behind

If needed, the implementation may slightly reduce how "merged" the title bar feels in order to gain more consistent black chrome behavior.

### Compact Resize Envelope

The window should return to a constrained resize envelope close to its original quote-card feel:

- small amount of width flexibility
- small amount of height flexibility
- no oversized stretched presentation

The layout should continue to look balanced throughout the allowed size range.

### File Boundaries

- `RealTimeQuote/App/WindowStyler.swift`
  - primary home for the chrome and resize adjustments
- `RealTimeQuote/RealTimeQuoteApp.swift`
  - only touch this if scene-level window configuration is required beyond the existing styler

## Error Handling

- If the window object is not yet attached when styling code runs, the styling logic should safely retry or reapply on updates
- Any styling adjustments must remain harmless for additional windows created later

## Testing

Verification should cover:

- successful project build after the window chrome changes
- manual visual check that the title bar remains dark after moving the window between displays
- manual visual check that the window can resize only a little
- manual visual check that the layout still looks balanced at minimum and maximum allowed sizes

## Risks And Mitigations

- Native macOS chrome behavior may override some styling choices during display changes
  - Mitigation: prefer explicit `NSWindow` configuration over purely visual overlay tricks
- Over-constraining the window could make the UI feel cramped
  - Mitigation: keep a small but non-zero resize range
- Dark chrome changes could accidentally affect window control readability
  - Mitigation: preserve the native traffic-light controls and standard title text behavior
