# Real Time Quote Runtime Config Design

Date: 2026-05-31
Project: `Real Time Quote`
Feature: local runtime config and API credential loading

## Goal

Add a local configuration system so `Real Time Quote` can load optional Coinbase and OKX API credentials plus app startup defaults from disk, without hard-coding secrets in source files.

The first version should:

- support a user-home config path and a project-local fallback path
- load typed config models from JSON
- inject config defaults into app startup
- allow optional exchange credential blocks
- keep `UserDefaults` as the highest-priority source for the user's last in-app selection

The first version will not include a settings screen or Keychain storage.

## Product Summary

`Real Time Quote` already has:

- native macOS app shell
- persisted in-app selection state via `UserDefaults`
- quote engine and exchange adapters
- quote-card UI

This feature adds a runtime config layer between app bootstrap and exchange construction. The app should look for a config file, decode it, and use it to provide:

- default exchange and trading pair
- enabled exchange list
- optional Coinbase credentials/settings
- optional OKX credentials/settings

If no config file exists, the app should still launch with safe built-in defaults.

## Architecture

The feature should add a focused runtime-config subsystem with three responsibilities:

1. `Config Model Layer`
   Typed structs represent the JSON schema: app defaults, Coinbase config, OKX config, and the full runtime config document.

2. `Config Loading Layer`
   A loader resolves config file paths in priority order, reads JSON, decodes typed config, and reports whether the result came from the home path, project path, or fallback.

3. `Bootstrap Integration Layer`
   `AppDependencies` uses the resolved config to decide:
   - startup default exchange/pair if `UserDefaults` has no prior selection
   - which exchanges are enabled
   - what credentials/settings should be passed into exchange stream construction

This keeps config concerns out of the views and prevents exchange-specific secret handling from leaking into UI code.

## Config File Locations

The app should search for config files in this order:

1. `~/.real-time-quote/config.json`
2. `Config/local.json`
3. app-internal fallback defaults if neither file exists

The first successfully loaded file wins.

The project-local file exists to make development easy inside the repo. The home-directory path exists to support longer-term personal use outside the repo.

## Config Schema

The runtime config should be JSON and should decode into one top-level document with three sections:

### `defaults`

Fields:

- `exchange`: app startup default exchange, such as `coinbase` or `okx`
- `pair`: app startup default trading pair, such as `btc_usd`, `eth_usd`, or another app-level pair key
- `enabledExchanges`: optional list of enabled exchanges

Purpose:

- defines first-launch or no-history startup behavior
- limits exchange choices if the user wants to disable one source locally

### `coinbase`

Fields:

- `apiKey`: optional
- `apiSecret`: optional
- `passphrase`: optional if needed by the chosen Coinbase API mode
- `useAuthenticatedFeed`: optional boolean

Purpose:

- supports future authenticated feed use
- allows the user to provide credentials now without requiring the app to depend on them for public quote feeds

### `okx`

Fields:

- `apiKey`: optional
- `apiSecret`: optional
- `passphrase`: optional
- `useAuthenticatedFeed`: optional boolean

Purpose:

- same model as Coinbase: public market-data can stay available while authenticated settings remain optional

## Example Config

The project should include a sample local config shape similar to:

```json
{
  "defaults": {
    "exchange": "coinbase",
    "pair": "btc_usd",
    "enabledExchanges": ["coinbase", "okx"]
  },
  "coinbase": {
    "apiKey": "your-coinbase-key",
    "apiSecret": "your-coinbase-secret",
    "passphrase": "your-coinbase-passphrase",
    "useAuthenticatedFeed": false
  },
  "okx": {
    "apiKey": "your-okx-key",
    "apiSecret": "your-okx-secret",
    "passphrase": "your-okx-passphrase",
    "useAuthenticatedFeed": false
  }
}
```

The shipped sample should use placeholders, not real credentials.

## Startup Precedence Rules

The app should resolve exchange/pair startup state with this order:

1. `UserDefaults` last-used selection, if present
2. runtime config `defaults`
3. app fallback: `coinbase` + `btc_usd`

This preserves the current user experience where the app remembers the last viewed selection, while still allowing a config file to define a clean first-run default.

## Bootstrap Behavior

At startup:

1. App bootstrap attempts to load runtime config
2. Loader returns either:
   - loaded config from home path
   - loaded config from project path
   - no config found, use fallback
   - config read/decode error
3. `AppDependencies` resolves startup exchange/pair using the precedence rules above
4. Exchange stream factories receive their optional per-exchange config blocks

If config errors occur, bootstrap should not abort the app. The app should remain usable with fallback behavior.

## Error Handling

The first version should distinguish these cases:

### Missing config file

Behavior:

- not an error
- continue with fallback defaults

### Invalid JSON or schema mismatch

Behavior:

- app still launches
- config loader returns a structured error state
- app can log the failure and optionally expose a lightweight UI error message

### Partial credential block

Behavior:

- treat credentials as incomplete
- do not crash
- only disable authenticated-only behavior if a future path requires those credentials

### Disabled exchange

Behavior:

- exchange picker should only show enabled exchanges
- if the disabled exchange was previously stored in `UserDefaults`, bootstrap should fall back to the next valid resolved exchange

## Integration With Existing State

The app already persists the user's active selection in `UserDefaults`. This feature should not replace that behavior.

Instead:

- runtime config defines startup defaults and optional exchange constraints
- `UserDefaults` remains the source of the last successful in-app selection
- if persisted selection becomes invalid because config disables that exchange or pair, bootstrap should fall back safely

## Exchange Adapter Integration

The first version does not need to fully use authenticated feeds, but it should prepare the path cleanly.

Each exchange adapter should be constructible with an optional config object that may contain:

- credentials
- auth/feed mode preference

If the current market-data path uses only public sockets, the adapter may ignore missing credentials while still accepting the typed config.

This keeps the integration surface stable for future authenticated features.

## Files And Boundaries

Likely additions should include:

- runtime config models
- runtime config loader
- config source/result model
- sample config file under `Config/`

Likely modifications should include:

- app bootstrap / dependency assembly
- selection bootstrap logic
- exchange adapter factory wiring

Views should not parse JSON or know file-system paths.

## Testing Strategy

The first version should cover:

- config file location precedence
- successful decode of valid config JSON
- fallback behavior when no config file exists
- graceful failure behavior for invalid JSON
- startup selection precedence:
  - `UserDefaults`
  - then config defaults
  - then app fallback
- invalid or disabled persisted selection fallback

Manual verification should include:

- run with no config file and confirm fallback startup
- add `Config/local.json` and confirm startup defaults change
- add home config and confirm it overrides project config
- confirm app still remembers last selected exchange/pair after interaction

## V1 Scope

Included in V1:

- typed JSON config model
- home-path and project-path config lookup
- config decode and structured result
- sample config file
- app default selection injection from config
- optional credential/config injection into Coinbase and OKX stream factories

Excluded from V1:

- app settings UI
- credential editing inside the app
- Keychain storage
- cloud sync
- encrypted config files

## Success Criteria

The feature is successful when:

- the app can start with no config file
- the app can load config from `~/.real-time-quote/config.json`
- the app can fall back to `Config/local.json`
- config defaults influence first-run startup behavior
- `UserDefaults` still wins for last-used selection
- optional Coinbase and OKX credentials can be supplied without source-code edits
- invalid config does not prevent the app from launching
