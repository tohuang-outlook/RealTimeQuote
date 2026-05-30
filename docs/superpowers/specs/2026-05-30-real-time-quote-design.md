# Real Time Quote Design

Date: 2026-05-30
Project: `Real Time Quote`
Platform: macOS native app

## Goal

Build a small macOS app that shows real-time cryptocurrency quotes in a compact desktop window. The app should visually resemble a market quote terminal card: dark background, large live price, clear up/down movement, and a compact block of 24h stats.

The first version should prioritize:

- low-latency live updates
- a polished single-window quote experience
- support for both Coinbase and OKX
- simple switching between a small set of trading pairs

The first version will not include trading, alerts, historical charts, or account login.

## Product Summary

`Real Time Quote` is a macOS SwiftUI app with one primary window. The window displays one selected trading pair at a time, such as `BTC-USD` or `ETH-USD`, with real-time updates delivered through WebSocket connections.

Users can:

- choose the exchange source: Coinbase or OKX
- switch between a small predefined list of trading pairs
- see the current price update in real time
- see derived market fields such as price change, change percentage, 24h high, 24h low, and 24h volume
- see connection status when the live feed is connected or reconnecting

## Architecture

The app will be split into three layers:

1. `UI Layer`
   SwiftUI views render the quote card, exchange selector, pair selector, and connection state. This layer does not parse exchange messages or manage socket lifecycle directly.

2. `Quote Engine Layer`
   A shared app-level service coordinates the selected exchange and trading pair, opens the appropriate WebSocket stream, transforms incoming exchange payloads into app-native models, and publishes state to the UI.

3. `Exchange Adapter Layer`
   Each exchange has its own adapter implementation for subscribe messages, message decoding, heartbeat handling, and reconnect behavior. Adapters expose a shared interface so the Quote Engine can switch exchanges without special-case UI logic.

This structure keeps exchange-specific logic isolated and makes it easy to add a third exchange later.

## UI Design

The main window should visually follow the example provided by the user:

- black or near-black background
- large live price as the visual focal point
- green styling when price movement is positive
- red styling when price movement is negative
- instrument label at the top left
- exchange label visible near the instrument name
- a compact stats grid beneath or to the right of the main price

The window content should include:

- selected trading pair
- selected exchange
- current price
- absolute change
- percentage change
- 24h high
- 24h low
- 24h volume
- connection status
- last update timestamp if available

The first version should stay focused on a single quote card rather than a multi-row dashboard.

## Data Model

The app will normalize exchange payloads into one shared model.

### QuoteSnapshot

- `exchange`: current source, such as `coinbase` or `okx`
- `symbol`: app-level display symbol, such as `BTC-USD`
- `lastPrice`: latest traded or best quote price used for display
- `absoluteChange`: current period change value
- `percentChange`: current period change percentage
- `high24h`: 24h high
- `low24h`: 24h low
- `volume24h`: 24h volume
- `updatedAt`: timestamp of the last accepted update
- `connectionState`: `connecting`, `live`, `reconnecting`, or `disconnected`

### App Settings

The first version should also keep lightweight local state for:

- selected exchange
- selected trading pair
- available trading pairs list

Persistence can be simple local storage so the app restores the last viewed pair and exchange on next launch.

## Exchange Integration

The app should support both Coinbase and OKX through WebSocket feeds.

### Coinbase

Use the user-provided Coinbase API setup where needed, but prefer public or minimally privileged quote endpoints if available for market data. The adapter should:

- open a WebSocket connection to the Coinbase market feed
- subscribe to the selected pair
- parse the live message stream into `QuoteSnapshot`
- map Coinbase symbols into the app display format

### OKX

Use the user-provided OKX API setup where needed, but again prefer market-data WebSocket channels rather than account-scoped channels. The adapter should:

- open a WebSocket connection to the OKX market feed
- subscribe to the selected instrument
- parse live ticker updates into `QuoteSnapshot`
- map OKX instrument identifiers into the app display format

## Symbol Handling

The app should present a user-friendly symbol format regardless of exchange naming differences.

Example:

- app display: `BTC-USD`
- Coinbase source: `BTC-USD`
- OKX source: exchange-specific instrument string mapped internally

The mapping should be defined in one place so UI code never needs exchange-specific symbol rules.

## Real-Time Flow

The normal update flow is:

1. App launches
2. Last-used exchange and pair are restored
3. Quote Engine creates the adapter for the selected exchange
4. Adapter opens the WebSocket connection
5. Adapter subscribes to the selected pair
6. Incoming messages are decoded and normalized into `QuoteSnapshot`
7. SwiftUI observes the published snapshot and redraws the window
8. If the user switches pair or exchange, the current subscription is replaced cleanly

## Reconnection Strategy

The app should automatically recover from network or feed interruptions.

Expected behavior:

- detect disconnects or invalid socket state
- update UI to `Reconnecting...`
- retry with backoff
- resubscribe to the current pair after reconnect
- avoid duplicate subscriptions when switching exchanges or pairs quickly

The app should not require the user to manually refresh.

## API Key and Configuration Handling

API credentials must not be hard-coded into source files.

The first version should read exchange credentials and related settings from local configuration, such as:

- environment variables during development
- an app-local configuration file excluded from version control
- a future secure storage path if needed

If market data for the chosen channels does not require privileged credentials, the app should still keep the configuration path ready so the user can plug in their existing API setup cleanly.

## Error Handling

The first version should handle:

- failed socket connection
- malformed or partial payloads
- unsupported symbol mapping
- exchange-specific heartbeat timeouts
- empty data state before first tick arrives

User-facing error handling should stay lightweight:

- keep the window visible
- show connection state clearly
- continue retrying where appropriate

## Testing Strategy

The first version should cover:

- unit tests for exchange payload decoding
- unit tests for symbol mapping
- unit tests for Quote Engine state transitions
- a small integration-style test path for switching exchange and pair

Manual verification should include:

- launch app and see a default quote
- switch from Coinbase to OKX
- switch between supported trading pairs
- verify reconnect behavior by simulating disconnect
- verify positive and negative color states

## V1 Scope

Included in V1:

- native macOS app
- SwiftUI-based single primary window
- Coinbase support
- OKX support
- 2 to 4 predefined trading pairs
- live WebSocket updates
- display of current price and market stats
- connection status display
- automatic reconnect
- local persistence of last selected pair and exchange

Excluded from V1:

- order entry or trading actions
- price alerts
- push notifications
- historical charting
- watchlists
- login or synced cloud settings
- menu bar mode

## Recommended Initial Trading Pairs

To keep the first version focused, start with:

- `BTC-USD`
- `ETH-USD`
- `SOL-USD`

The exact final set can be adjusted during implementation based on clean support across both exchanges.

## Open Implementation Notes

- Prefer `SwiftUI` for the main interface and app lifecycle.
- Use small targeted `AppKit` interop only if needed for tighter control of window style or behavior.
- Keep the exchange adapter protocol narrow and testable.
- Keep the first version visually polished, but avoid introducing extra panels or charting until the base quote experience is stable.

## Success Criteria

The first version is successful when:

- the app launches into a compact native macOS window
- the user can switch between a few pairs and between Coinbase and OKX
- the displayed price updates in real time through WebSocket
- the UI clearly shows quote movement and market stats
- disconnects recover automatically without manual action
- the code structure is clean enough to add more exchanges or quote surfaces later
