# Real Time Quote Widget Top Bar Window Design

## Overview

This spec replaces the unstable native-looking title-bar styling experiment with a deliberate widget-style top bar. The goal is to stop fighting macOS title-bar materials and instead give `Real Time Quote` a thin black top strip that feels like a compact trading widget, while preserving drag behavior and a constrained resize range.

## Goals

- Remove the visible white native title-bar look
- Add a thin black widget-style top bar
- Keep the window draggable
- Hide the app title text from the top bar
- Preserve a compact, only-slightly-resizable quote window

## Non-Goals

- Recreating the full native macOS title-bar appearance
- Custom-drawing replacement traffic-light controls
- Making the window borderless
- Adding always-on-top behavior

## User Experience

The app should feel more like a dedicated quote widget than a generic document window. The top edge should become a slim black control strip with no title text, matching the rest of the app’s dark visual language.

Dragging the window should still feel straightforward, and the resize range should stay compact enough that the layout never turns into a wide, awkward dashboard.

## Design

### Top Bar Strategy

Instead of trying to recolor the system title bar, the app should visually suppress the native title-bar look and introduce its own widget-style top bar.

The top bar should:

- be black
- be thin
- contain no app title text
- provide a drag region

This avoids the macOS material mismatch that causes the top strip to turn partially white during display changes.

### Native Controls

The implementation may keep native window controls available if they can coexist cleanly with the widget treatment, but visual consistency takes priority over preserving the exact previous title-bar look.

If the native controls visually clash too much with the widget bar, the implementation may reduce their emphasis or placement impact, but should not replace them with custom clones in this iteration.

### Window Size Envelope

The window should continue using a compact size envelope:

- only a small amount of width flexibility
- only a small amount of height flexibility
- no oversized wide-window presentation

### File Boundaries

- `RealTimeQuote/App/WindowStyler.swift`
  - primary implementation home for the top bar and drag-region adjustments
- `RealTimeQuote/Views/QuoteBoardView.swift`
  - only if a dedicated top-bar visual component is easier to express in the content layer
- `RealTimeQuote/RealTimeQuoteApp.swift`
  - only if scene-level window behavior requires a small supporting change

## Error Handling

- Window styling should safely reapply if the `NSWindow` is not yet attached when the view first renders
- The top-bar treatment should work consistently for multiple open windows

## Testing

Verification should cover:

- successful project build
- manual visual check that no white title-bar strip remains
- manual visual check that dragging still works
- manual visual check that the resize range remains compact
- manual visual check that moving the window between displays no longer reintroduces white chrome

## Risks And Mitigations

- Mixing a custom top strip with native window controls can look awkward
  - Mitigation: keep the bar minimal and bias toward a clean widget look
- Removing too much native chrome could make the window harder to use
  - Mitigation: preserve straightforward dragging and standard window behavior
- A content-layer top bar might affect layout spacing
  - Mitigation: keep the bar thin and verify the quote card still feels balanced
