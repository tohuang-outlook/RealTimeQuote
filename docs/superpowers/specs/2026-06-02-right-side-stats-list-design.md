# Right-Side Stats List Design

## Goal

Move the `24H HIGH`, `24H LOW`, and `24H VOL` metrics from the bottom row of stat cards into a right-side vertical stats list beside the main quote area.

The new layout should feel more like a quote terminal:

- left side for the primary quote
- right side for supporting market stats
- cleaner information hierarchy
- less dashboard-card feeling

## Current Problem

The current design uses three horizontal stat cards under the main price. That works, but it makes the layout feel more like a compact dashboard than a live quote terminal.

The user wants the metrics to sit to the right of the main price area and stack vertically.

## Chosen Direction

Use a two-column quote layout:

- left column for symbol, exchange, main price, change, and timestamp
- right column for a vertical `label | value` stats list

The right side should not use the existing boxed stat-card presentation in the normal layout.

## Design

### 1. Two-Column Quote Body

Below the top controls row, the content area becomes a horizontal split:

- `left column`: main quote presentation
- `right column`: stats list

The left column remains the visual focus and should occupy roughly two-thirds of the width.
The right column should be narrower and behave like a market facts rail.

### 2. Right-Side Vertical Stats List

Replace the bottom stat-card row with a three-row list:

- `24H HIGH`
- `24H LOW`
- `24H VOL`

Each row should have:

- a subdued label on the left
- a right-aligned numeric value on the right

The rows should feel compact and clean, without heavy card chrome.

### 3. Preserve Existing Color Semantics

The values keep the current color treatment:

- `24H HIGH` value: green
- `24H LOW` value: red
- `24H VOL` value: white

Labels remain muted.

### 4. Small-Window Fallback

If the window becomes too narrow for a comfortable side-by-side layout, the quote body should fall back to a vertical stack:

- top: main quote area
- bottom: stats list

The fallback should preserve the new terminal-style list presentation rather than reintroducing the original stat boxes.

## Implementation Shape

Primary changes remain in the view layer:

- `RealTimeQuote/Views/QuoteBoardView.swift`
- `RealTimeQuote/Views/Components/StatsGridView.swift` or a replacement component

The likely direction is:

- split the lower quote content into `mainQuoteColumn` and `statsColumn`
- replace or supersede the current card-based stats layout with a list-style stats component
- use width-aware layout to decide between horizontal and vertical arrangements

No data model, exchange logic, or window-management changes are required.

## Non-Goals

This iteration does not include:

- changing the top controls layout
- changing the widget top bar
- changing number formatting
- changing quote colors beyond the already approved high/low semantics
- introducing a full large-screen dashboard mode

## Success Criteria

The work is successful when:

1. The three stats no longer appear as bottom horizontal boxes in the normal layout.
2. The stats appear to the right of the main price area in a vertical list.
3. The values preserve green/red/white semantics.
4. The layout feels more like a quote terminal and less like a dashboard.
5. Narrow windows still remain readable through a stacked fallback.
