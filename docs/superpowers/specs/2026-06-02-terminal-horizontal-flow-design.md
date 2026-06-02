# Terminal Horizontal Flow Design

## Goal

Refine the terminal quote panel layout so the quote body reads more like a horizontal information flow and less like a form or side-rail split.

The design should move closer to the provided trading-terminal reference by:

- keeping the top controls row as-is
- making the main quote body feel flatter and wider
- strengthening the large left price zone
- arranging stats in a more horizontal terminal rhythm

## Current Problem

The current terminal-panel iteration improved the general direction, but the quote body still feels too much like:

- a left block plus a right rail
- a clean app layout
- a structured form

It does not yet feel like the tighter horizontal market-information flow shown in the reference.

## Chosen Direction

Keep the controls row unchanged and only revise the quote content area below it.

The quote body should be decomposed into:

- a large left price block
- a right-side two-column stats area
- a flatter lower support row that helps the layout read like a quote terminal rather than a settings panel

## Design

### 1. Preserve the Top Controls Row

The existing row with:

- exchange selector
- pair selector
- live badge

should remain unchanged in this iteration.

This keeps interaction stable while we focus on quote-body presentation.

### 2. Strong Left Price Block

The left side remains the visual anchor and contains:

- symbol
- exchange/source
- large last price
- change amount and percent
- updated line

This block should visually dominate the quote body.

### 3. Right-Side Two-Column Stats Region

The right side should present market fields in a tighter two-column arrangement, not a vertical rail and not boxed cards.

The region should feel like a compact market readout area rather than a sidebar.

Candidate fields:

- `Open`
- `Prev Close`
- `High`
- `Low`
- `24H Volume`
- `52W High`
- `52W Low`
- `Market Cap`

### 4. Flatter Lower Support Row

Below the main left/right quote split, add a flatter support row that helps the panel read horizontally.

This row should primarily support layout rhythm rather than introduce new fake information.

It can be used for:

- a supporting timestamp / open-mid style line
- a secondary market-data line
- reserved future field placement

The first version should keep this simple and use it mainly to improve the information flow.

### 5. Placeholder Strategy

Fields we do not yet support with real data should remain in place with `--` placeholders.

That includes likely placeholders such as:

- `Open`
- `Prev Close`
- `52W High`
- `52W Low`
- `Market Cap`

### 6. Existing Real Data

Current live data that should continue to render:

- last price
- change
- updated time
- high
- low
- 24H volume

## Implementation Shape

Primary work remains in the view layer:

- `RealTimeQuote/Views/QuoteBoardView.swift`
- `RealTimeQuote/Views/Components/PriceHeaderView.swift`
- `RealTimeQuote/Views/Components/StatsGridView.swift`

The likely implementation direction is:

- keep the current outer shell
- replace the current left/right quote-body arrangement with a flatter horizontal composition
- tune spacing and grouping so the stats read as a quote-terminal field block rather than as a right-side form

## Non-Goals

This iteration does not include:

- changing the top controls row
- adding real data for unsupported placeholder fields
- redesigning the window chrome
- adding alternative view modes

## Success Criteria

The work is successful when:

1. The quote body reads more like a horizontal terminal quote panel.
2. The left price block remains the dominant visual anchor.
3. The stats area feels like a compact market-data field cluster, not a sidebar form.
4. The overall layout is visibly closer to the provided reference image.
5. Existing live data continues to render correctly.
