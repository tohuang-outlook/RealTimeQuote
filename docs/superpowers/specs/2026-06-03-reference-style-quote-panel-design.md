# Reference-Style Quote Panel Design

## Goal

Redesign the quote body so it closely matches the latest provided reference panel:

- instrument line at the top-left
- very large live price on the left
- compact change values tucked beside the price
- two right-side stats columns
- a very light lower information line

The goal is to make the app read like a true quote terminal panel rather than a finance widget or a generic app dashboard.

## Current Problem

The current terminal-style iterations moved the app in the right direction, but the layout still does not match the reference closely enough.

Current issues:

- the left quote block is not dominant enough
- the right-side information still feels too much like an app grid
- the lower support row feels like an added layout device rather than a natural quote terminal line

## Chosen Direction

Recompose the quote body to follow the reference much more directly.

The top controls row stays as-is, but the quote body below it should be rebuilt around the reference structure:

- left quote block
- right two-column stats cluster
- minimal lower information line

## Design

### 1. Instrument Line

At the top-left of the quote body, render a compact instrument line.

It should visually correspond to the reference pattern:

- symbol
- exchange/source text

This line should feel like a terse market-instrument identifier, not a decorative header.

### 2. Dominant Price Block

The left side becomes a strong quote anchor:

- very large last price
- smaller change amount and percent positioned close to the price
- a compact secondary line below for updated/open-mid style context

The visual emphasis should be much stronger than in the current layout.

### 3. Right-Side Two-Column Stats Cluster

The right side should render two narrow columns of market fields, arranged similarly to the reference.

#### Left stats column

- `Open`
- `Low`
- `52 Wk High`
- `24H Volume`

#### Right stats column

- `High`
- `Prev Close`
- `52 Wk Low`
- `Market Cap`

The cluster should feel like aligned market readout columns, not like card sections or a sidebar form.

### 4. Placeholder Strategy

Every field should appear in the layout, even if the app does not yet have real data for it.

Use `--` placeholders for unsupported values such as:

- `Open`
- `Prev Close`
- `52 Wk High`
- `52 Wk Low`
- `Market Cap`

This preserves layout fidelity to the reference.

### 5. Real Data to Render Now

The following live values already exist and should render with real data:

- last price
- change amount / percent
- updated time
- `High`
- `Low`
- `24H Volume`

### 6. Minimal Lower Information Line

The lower part of the quote body should be simplified.

Instead of a visible “support row” feeling like a secondary panel, it should behave more like a subtle quote-terminal information line.

The line should be visually light and should not compete with the main quote or the right-side stats columns.

## Implementation Shape

Primary work remains in the view layer:

- `RealTimeQuote/Views/QuoteBoardView.swift`
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- `RealTimeQuote/Views/Components/StatsGridView.swift`

The likely implementation direction:

- keep the outer shell and top controls row
- rebuild the quote body into the reference-style structure
- retune text hierarchy, alignment, and spacing to match the quote-terminal feel more directly

## Non-Goals

This iteration does not include:

- changing the top controls row
- adding new backend market data sources
- implementing real values for unsupported placeholder fields
- redesigning window chrome or app icon

## Success Criteria

The work is successful when:

1. The quote body is visually much closer to the provided reference.
2. The left price block is clearly the primary focal area.
3. The right-side stats appear as two aligned quote-terminal columns.
4. Placeholder values preserve the intended layout without breaking it.
5. Existing live data continues to update correctly.
