# Real Time Quote Multi-Window Independent Quotes Design

## Overview

This spec adds proper multi-window behavior to `Real Time Quote`. Today, every window shares the same `QuoteBoardViewModel` and persisted selection, so changing the quote in one window changes every open window. The new behavior should let each window run its own live quote stream while still using one app-level "last selection" as the starting point for newly created windows.

## Goals

- Allow two or more open windows to display different crypto pairs at the same time
- Make each window own its own `QuoteBoardViewModel` and `QuoteEngine`
- Ensure a newly opened window starts from the app's last successful selection
- Keep the existing persisted "last selection" behavior for app relaunch and new-window bootstrap

## Non-Goals

- Restoring multiple windows after app relaunch
- Giving each window a persistent identity
- Persisting a separate selection for every window
- Synchronizing selections across windows

## User Experience

When Tony opens a second `Real Time Quote` window, the new window should start with the most recently successful exchange and pair selection. After it opens, it should behave independently. For example:

- Window A can stay on `Coinbase + BTC-USD`
- Window B can switch to `Coinbase + ETH-USD`
- Window A should remain on `BTC-USD`

If one window fails to connect or fails while changing selection, only that window should show the error or rollback. Other open windows should continue running normally.

## Design

### Window Ownership Model

The app should move from a single shared `QuoteBoardViewModel` to a per-window ownership model.

Each `WindowGroup` content instance should receive its own fresh view model. That view model should own:

- its own `QuoteEngine`
- its own selected exchange state
- its own selected pair state
- its own connection lifecycle

This isolates live feeds between windows and matches the mental model of independent quote terminals.

### App-Level Bootstrap Context

The app still needs one shared bootstrap layer to decide how a new window should start. That shared layer should:

- read runtime config once
- keep access to the shared `AppSettingsStore`
- resolve the bootstrap selection for new windows using the current persisted "last selection" behavior

This means the shared app-level object should become a factory, not a shared quote state container.

### Selection Persistence

`UserDefaults` remains app-level and stores only the most recent successful selection.

Behavior rules:

1. On first app launch, the first window uses persisted selection if present, otherwise config defaults, otherwise hardcoded fallback
2. When any window successfully switches exchange or pair, that selection becomes the new app-level last selection
3. When a new window opens, it copies the current app-level last selection as its initial state
4. Once created, that window no longer follows later changes made by other windows

### File Responsibilities

- `RealTimeQuoteApp.swift`
  - stop injecting one shared quote board view model into every window
  - request a fresh view model for each window scene instance
- `AppDependencies.swift`
  - become a factory / bootstrap container
  - provide a method to create a new `QuoteBoardViewModel` from the current bootstrap selection
- `QuoteBoardViewModel.swift`
  - accept an explicit initial selection for window-local startup instead of always deriving startup state from the shared store
- `AppSettingsStore.swift`
  - keep its current schema and app-level persistence role

## Error Handling

- If a newly created window fails its initial connection, that error should stay local to that window
- If one window fails during a selection change, only that window should rollback
- Persisted last selection should update only after a successful selection change, preserving the current safety behavior

## Testing

The implementation should add focused coverage for:

- creating two window-local view models from the same app dependencies factory
- verifying they can start from the same initial selection and then diverge independently
- verifying one view model updating selection does not mutate the already-created state of another view model
- verifying the shared settings store still captures the most recent successful selection for future windows

## Risks And Mitigations

- Shared mutable state may still leak through the bootstrap layer
  - Mitigation: keep only config and settings store shared; create a new `QuoteEngine` per window
- Refactoring the current app root may accidentally break startup bootstrap behavior
  - Mitigation: preserve the existing selection resolver and add targeted tests for fallback order
- New windows may accidentally read live shared state instead of a copied initial selection
  - Mitigation: resolve selection at window creation time and pass concrete values into the new view model
