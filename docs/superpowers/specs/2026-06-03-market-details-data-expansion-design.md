# Market Details Data Expansion Design

## Goal

Replace quote-panel placeholder fields with real market data when that data is available from the selected exchange's official APIs.

This iteration focuses on:

- reliably filling `Open`
- reliably filling `Prev Close`
- only filling `52 Wk High`, `52 Wk Low`, and `Market Cap` if Coinbase or OKX officially provide those values

The design must preserve the existing real-time websocket quote path and avoid destabilizing the current app behavior.

## Current Problem

The reference-style quote panel now has the right structure, but several fields still show `--` placeholders:

- `Open`
- `Prev Close`
- `52 Wk High`
- `52 Wk Low`
- `Market Cap`

The user wants these replaced with real values where possible, while staying exchange-first rather than relying on third-party market-data providers.

## Chosen Direction

Use a dedicated `market details` fetch path alongside the existing websocket quote path.

That means:

- websocket remains the source of live price movement
- REST endpoints provide slower-changing supporting fields
- unsupported fields remain placeholders rather than fake values

## Design

### 1. Separate Live Quote and Market Details

Keep the existing separation of concerns:

- `QuoteSnapshot` remains focused on live quote and ticker-style fields
- new `MarketDetailsSnapshot` will hold supplemental market fields

This prevents REST-fetched details from contaminating the websocket quote pipeline.

### 2. Exchange-First Data Fetching

Each exchange should have its own market-details fetcher.

Examples of fields to populate if available:

- `open`
- `prevClose`
- `week52High`
- `week52Low`
- `marketCap`

Only values officially provided by the active exchange should be filled.

If an exchange does not provide a field, keep `--`.

### 3. First-Class V1 Priority Fields

The first version should prioritize:

- `Open`
- `Prev Close`

These should be the fields we explicitly guarantee to try to populate through exchange APIs first.

### 4. Opportunistic Extended Fields

These fields are optional for V1:

- `52 Wk High`
- `52 Wk Low`
- `Market Cap`

If Coinbase or OKX official APIs expose them cleanly, wire them in.
If not, preserve placeholders and do not infer or synthesize them.

### 5. Fetch Timing

Market details should load:

- when the selected exchange changes
- when the selected trading pair changes
- optionally on initial app launch for the initial selection

They should not be polled at high frequency.

This data changes slowly enough that a one-shot fetch per selection is sufficient for V1.

### 6. UI Integration

The quote panel presentation layer should combine:

- live websocket quote data
- latest fetched market details data

Fields in the quote panel should render:

- real values if present
- `--` if absent

No UI structural change is needed in this iteration; only data quality improves.

## Implementation Shape

Likely new responsibilities:

- `MarketDetailsSnapshot` model
- exchange-specific market-details loaders for Coinbase and OKX
- `QuoteBoardViewModel` orchestration to fetch details on selection change
- quote presentation state combining both snapshots

Primary files likely involved:

- `RealTimeQuote/Models/QuoteSnapshot.swift`
- new market-details model file
- `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- exchange service files for Coinbase and OKX
- `RealTimeQuote/Views/QuoteBoardView.swift`

## Non-Goals

This iteration does not include:

- replacing exchange APIs with third-party market data
- high-frequency REST polling
- inventing missing fields by estimation
- changing the current quote-panel layout

## Success Criteria

The work is successful when:

1. `Open` and `Prev Close` display real values when the active exchange provides them.
2. `52 Wk High`, `52 Wk Low`, and `Market Cap` display real values only if officially available from Coinbase or OKX.
3. Unsupported fields still safely display `--`.
4. Live price updates remain stable and continue to come from websocket streams.
5. Switching exchange/pair refreshes market details correctly.
