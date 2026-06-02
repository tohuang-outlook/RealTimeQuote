# Responsive Quote Board Resize Design

## Goal

When the `Real Time Quote` window is resized larger, the quote board should grow with it instead of staying as a small fixed card centered inside a large black canvas.

The resized experience should feel intentional and polished:

- the main card expands to use the available space
- the overall layout becomes more spacious
- the main live price grows with the window
- supporting text remains comparatively stable so the UI does not become bulky

## Current Problem

The current widget-window work fixed the white title bar issue, but the quote board layout still behaves like a fixed-size panel:

- the outer window can become much larger
- the content card remains visually small
- large empty black areas appear around the card
- the layout looks disconnected from the window size

This creates a mismatch between the resizing affordance and the visual result.

## Chosen Direction

Use a responsive layout rather than constraining the window back down.

The quote board should scale as a larger-format version of the same widget, not switch into a different dashboard product and not remain a tiny centered module.

## Design

### 1. Expanding Card

The rounded main quote card should expand to fill the available content area with sensible outer margins.

Behavior:

- the card width should track the window width
- the card height should track the available height under the widget top bar
- the card should remain visually inset from the window edges
- the card should preserve its rounded-corner, dark-terminal feel

### 2. Responsive Spacing

Internal spacing should scale modestly with the available size.

This includes:

- outer padding around the card
- internal horizontal and vertical padding
- spacing between controls, price header, and stat cards

The scaling should be subtle. The UI should feel more breathable in a larger window, not dramatically re-laid out.

### 3. Responsive Hero Price

Only the main live price should noticeably scale with window size.

Behavior:

- the price font should grow as width increases
- growth should be clamped to a safe min/max range
- the price should remain on one line when practical

Supporting text such as the symbol, exchange badge, 24h change line, update time, and stat values should stay near their current sizes, with only small layout breathing-room improvements around them.

### 4. Stable Stats Row

The 24h stats section should remain clean and structured:

- in wider windows, the three stats cards stay in one horizontal row
- each card remains equal-width
- spacing between cards can grow slightly with available width
- narrow windows can still fall back to the current fitting behavior

This keeps the resized board looking like a refined quote terminal rather than a stretched phone layout.

## Implementation Shape

Primary work stays in the view layer:

- `RealTimeQuote/Views/QuoteBoardView.swift`
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- `RealTimeQuote/Views/Components/StatsGridView.swift`

The likely implementation approach is:

- use `GeometryReader` or equivalent size-aware layout measurement at the quote board level
- derive a small responsive layout model from available width/height
- feed the responsive values into card padding, section spacing, and hero price font size

No data-flow, exchange, or multi-window state logic changes are needed for this work.

## Non-Goals

This iteration does not include:

- a full breakpoint system
- a second large-window dashboard mode
- changes to the widget top bar
- changes to window dragging behavior
- changes to exchange streaming or quote data

## Success Criteria

The work is successful when:

1. Enlarging the window makes the main card visibly grow with it.
2. The large empty black margins are substantially reduced.
3. The main live price becomes more prominent in larger windows.
4. The layout still looks like the same product, just more spacious.
5. Smaller window sizes still preserve the current compact widget feel.
