# Mixed-Source Reference Stats Design

## Goal

Fill the remaining placeholder fields in the quote panel with real values by combining:

- exchange official APIs for live and trading-session data
- a third-party reference-data provider for asset-level reference stats

This iteration focuses on completing:

- `Market Cap`
- `52 Wk High`
- `52 Wk Low`

while preserving the current exchange-backed behavior for:

- `last price`
- `change`
- `open`
- `prev close`
- `24h high / low`
- `24h volume`

## Current Problem

The quote panel now has a strong terminal-style layout and already shows real exchange-backed values for:

- `Open`
- `Prev Close`

However, these fields still show `--`:

- `52 Wk High`
- `52 Wk Low`
- `Market Cap`

The user wants these replaced with real values, even if that requires a mixed-source strategy rather than exchange-only data.

## Chosen Direction

Use a dedicated third-party `reference stats` fetch path alongside the existing exchange quote and market-details paths.

That means:

- exchange websocket remains the source of real-time quote movement
- exchange REST remains the source of session/trading fields like `Open` and `Prev Close`
- third-party reference data becomes the source of slower-moving asset metadata like `Market Cap` and `52 Wk` ranges

## Design

### 1. Three Data Layers

The app should now treat quote data as three separate layers:

- `Live quote layer`
  - websocket-backed
  - fast-moving fields

- `Exchange market-details layer`
  - exchange REST-backed
  - trading-session fields

- `Reference stats layer`
  - third-party backed
  - slower-moving asset reference fields

This keeps each source responsible for the kind of data it is best suited to provide.

### 2. Field Ownership

Field ownership should be explicit:

- exchange-owned:
  - `last price`
  - `change`
  - `open`
  - `prev close`
  - `24h high`
  - `24h low`
  - `24h volume`

- third-party owned:
  - `market cap`
  - `52 wk high`
  - `52 wk low`

Third-party values must not overwrite live quote or session fields that are already exchange-backed.

### 3. Pair Mapping

The reference stats layer should support the currently exposed pairs:

- `BTC-USD`
- `ETH-USD`
- `ADA-USD`
- `SOL-USD`

Each app `TradingPair` should map cleanly to the corresponding symbol or asset identifier required by the third-party provider.

### 4. Fetch Timing

Reference stats should load:

- on initial app launch for the initial selection
- whenever the selected trading pair changes
- optionally when the exchange changes if the orchestration path is already shared

This data should not be polled aggressively.

For V1, a one-shot fetch per selection is sufficient.

### 5. Failure Behavior

If the third-party provider fails, rate-limits, or returns incomplete data:

- the app must remain fully functional
- exchange-backed fields must continue working normally
- missing reference fields should continue rendering as `--`

This should be a quiet degradation, not a user-blocking error state.

### 6. UI Integration

The presentation layer should combine:

- `QuoteSnapshot`
- `MarketDetailsSnapshot`
- a new reference-stats snapshot model

The quote panel should render:

- real values when present
- `--` when unavailable

No quote-panel structural redesign is needed in this iteration.

## Implementation Shape

Likely new responsibilities:

- a `ReferenceStatsSnapshot` model
- a third-party reference stats loader
- symbol mapping from `TradingPair` to third-party identifiers
- `QuoteBoardViewModel` orchestration for loading reference stats on selection changes
- quote presentation state merging all three snapshot types

Primary files likely involved:

- `RealTimeQuote/Models/TradingPair.swift`
- new reference-stats model file
- `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- new reference-data service file(s)
- `RealTimeQuote/Views/QuoteBoardView.swift`

## Non-Goals

This iteration does not include:

- replacing exchange live prices with third-party quote data
- high-frequency background polling for reference stats
- caching UI or cache freshness indicators
- redesigning the current quote-panel layout
- adding new user-facing settings for choosing a stats provider

## Success Criteria

The work is successful when:

1. `Market Cap` displays a real value for supported pairs when the third-party provider returns one.
2. `52 Wk High` and `52 Wk Low` display real values for supported pairs when the provider returns them.
3. Existing exchange-backed fields continue behaving exactly as they do now.
4. Missing or failed reference stats safely fall back to `--`.
5. Switching pairs refreshes the reference stats correctly.
