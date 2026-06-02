# Terminal Quote Panel Design

## Goal

Redesign the main quote window so it looks much closer to a classic trading terminal quote panel:

- compact and wide
- information-dense
- large live price on the left
- supporting market data arranged as text fields rather than stat cards

The result should feel much closer to the provided reference image and less like a modern widget dashboard.

## Current Problem

The current app has improved typography and window chrome, but the internal information layout still feels like a dashboard or card-based finance widget.

The user wants a layout that more closely resembles a quote terminal panel:

- left side dominated by price
- right and lower areas populated with compact textual metrics
- reduced card-chrome feel

## Chosen Direction

Rebuild the quote body as a `terminal quote panel`, not just a small tweak to the existing card layout.

This means:

- stronger left/right information hierarchy
- removal of stat-box presentation from the main quote body
- more compact information density
- a flatter quote-terminal visual rhythm

## Design

### 1. Quote Header Row

The top of the quote content should show a compact instrument line:

- symbol
- exchange/source

This row should feel tight and informational rather than branded or decorative.

### 2. Large Left-Side Price Block

The left side should contain the primary live quote content:

- large last price
- change amount and percent
- updated/open-mid style supporting timestamp line

This remains the visual anchor of the panel.

### 3. High-Density Metrics Area

The rest of the quote panel should show compact market fields as text, not cards.

Fields should be arranged in a grid-like text layout similar to a trading terminal:

- left label / right value rhythm
- multiple fields visible at once
- compact spacing

### 4. Data Strategy for V1

The layout should include places for the following fields:

- `Open`
- `Prev Close`
- `24H Volume`
- `High`
- `Low`
- `52W High`
- `52W Low`
- `Market Cap`

For the first version:

- fields we already have should show real data
- fields not yet supported by the current snapshot model should keep reserved positions with placeholder output

This allows the panel to visually match the target direction without blocking on a larger data-model expansion.

### 5. Existing Data to Use Now

Current live data already available and ready to display:

- last price
- change
- updated time
- 24H high
- 24H low
- 24H volume

These should be wired into the new quote panel immediately.

### 6. Placeholder Fields

Until the data layer is expanded, these fields may render placeholder values such as `--`:

- open
- prev close
- 52W high
- 52W low
- market cap

The placeholders should be visually consistent with the rest of the panel and clearly read as unavailable rather than broken.

## Implementation Shape

Primary work stays in the view layer:

- `RealTimeQuote/Views/QuoteBoardView.swift`
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- likely replacement or extension of the current stats component

The likely implementation direction:

- replace the current left-plus-stats-rail composition
- add a terminal-style metric grid component
- reduce the remaining card feel inside the quote body
- keep current window chrome, typography direction, and data flow intact

## Non-Goals

This iteration does not include:

- changing websocket or exchange logic
- implementing real market cap / 52W / prev close data
- redesigning the top app controls row
- introducing alternate view modes

## Success Criteria

The work is successful when:

1. The app visually resembles the provided terminal quote reference much more closely.
2. The large live price remains the primary focal point on the left.
3. Supporting market fields appear in a compact text-based layout instead of boxes.
4. Existing available data is shown live in the new layout.
5. Missing fields remain visible as placeholders without breaking the layout.
