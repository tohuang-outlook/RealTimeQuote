# Real Time Quote Multi-Window Independent Quotes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let multiple `Real Time Quote` windows show different crypto pairs independently while new windows start from the app's latest successful selection.

**Architecture:** Replace the single shared quote board view model with an app-level bootstrap factory that creates a fresh `QuoteBoardViewModel` and `QuoteEngine` for each `WindowGroup` instance. Keep `UserDefaults` as one app-level "last selection" store so new windows and relaunches still start from the latest successful choice without coupling already-open windows together.

**Tech Stack:** SwiftUI macOS app, Combine, async/await, XCTest, Xcode

---

## File Structure

- Modify: `RealTimeQuote/RealTimeQuoteApp.swift`
  - Stop sharing one view model across all windows and request a fresh one per scene instance.
- Modify: `RealTimeQuote/App/AppDependencies.swift`
  - Convert the shared app object into a view model factory with bootstrap selection helpers.
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
  - Accept an explicit window-local initial selection while preserving selection persistence on successful updates.
- Modify: `RealTimeQuote/Services/AppSettingsStore.swift`
  - Keep schema stable, but expose any minimal helper needed for cleaner bootstrap reads if required.
- Create or Modify: `RealTimeQuoteTests/AppDependenciesFactoryTests.swift`
  - Verify the factory creates independent window-local view models from shared app-level dependencies.
- Modify: `RealTimeQuoteTests/QuoteEngineTests.swift`
  - Add focused regression coverage for independent multi-window selection behavior if existing doubles are already the best fit there.
- Modify: `RealTimeQuoteTests/AppDependenciesConfigTests.swift`
  - Preserve fallback/bootstrap assertions if refactoring touches selection resolution.

### Task 1: Refactor app bootstrap to create a fresh view model per window

**Files:**
- Modify: `RealTimeQuote/RealTimeQuoteApp.swift`
- Modify: `RealTimeQuote/App/AppDependencies.swift`
- Test: `RealTimeQuoteTests/AppDependenciesFactoryTests.swift`

- [ ] **Step 1: Write the failing factory test**

Create or update `RealTimeQuoteTests/AppDependenciesFactoryTests.swift` with:

```swift
import XCTest
@testable import RealTimeQuote

@MainActor
final class AppDependenciesFactoryTests: XCTestCase {
    func testFactoryCreatesDistinctViewModelsForDifferentWindows() {
        let settingsStore = UserDefaultsAppSettingsStore(
            defaults: UserDefaults(suiteName: #filePath)!
        )
        let dependencies = AppDependencies(
            settingsStore: settingsStore,
            config: nil
        )

        let first = dependencies.makeQuoteBoardViewModel()
        let second = dependencies.makeQuoteBoardViewModel()

        XCTAssertFalse(first === second)
    }
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests/testFactoryCreatesDistinctViewModelsForDifferentWindows
```

Expected: FAIL because `AppDependencies` does not yet expose an initializer and factory API that creates independent view models.

- [ ] **Step 3: Implement the app-level factory**

Update `RealTimeQuote/RealTimeQuoteApp.swift` to request a fresh view model inside the window closure:

```swift
@main
struct RealTimeQuoteApp: App {
    @StateObject private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup("Real Time Quote") {
            WindowStyler.makeRootView {
                QuoteBoardView(viewModel: dependencies.makeQuoteBoardViewModel())
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: WindowStyler.defaultSize.width, height: WindowStyler.defaultSize.height)
    }
}
```

Update `RealTimeQuote/App/AppDependencies.swift` so it becomes a factory:

```swift
@MainActor
final class AppDependencies: ObservableObject {
    private let settingsStore: AppSettingsStore
    private let config: RuntimeConfig?

    init(settingsStore: AppSettingsStore, config: RuntimeConfig?) {
        self.settingsStore = settingsStore
        self.config = config
    }

    func makeQuoteBoardViewModel() -> QuoteBoardViewModel {
        let selection = AppBootstrapSelectionResolver.resolve(
            settingsStore: settingsStore,
            config: config
        )

        let quoteEngine = QuoteEngine(
            initialSnapshot: .placeholder(for: selection.pair, exchange: selection.exchange),
            streamFactory: { [config] exchange, _ in
                switch exchange {
                case .coinbase:
                    return CoinbaseQuoteStream(config: config?.coinbase)
                case .okx:
                    return OKXQuoteStream(config: config?.okx)
                }
            }
        )

        return QuoteBoardViewModel(
            initialSelection: selection,
            settingsStore: settingsStore,
            quoteEngine: quoteEngine
        )
    }

    static func live() -> AppDependencies {
        let settingsStore = UserDefaultsAppSettingsStore()
        let config = try? RuntimeConfigLoader().load().config
        return AppDependencies(settingsStore: settingsStore, config: config)
    }
}
```

- [ ] **Step 4: Re-run the focused test**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests/testFactoryCreatesDistinctViewModelsForDifferentWindows
```

Expected: PASS

- [ ] **Step 5: Commit the bootstrap factory refactor**

```bash
git add RealTimeQuote/RealTimeQuoteApp.swift RealTimeQuote/App/AppDependencies.swift RealTimeQuoteTests/AppDependenciesFactoryTests.swift
git commit -m "refactor: create quote view models per window"
```

### Task 2: Make the view model honor window-local initial selection

**Files:**
- Modify: `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`
- Test: `RealTimeQuoteTests/AppDependenciesFactoryTests.swift`

- [ ] **Step 1: Add a failing startup-selection test**

Extend `RealTimeQuoteTests/AppDependenciesFactoryTests.swift` with:

```swift
func testViewModelUsesExplicitInitialSelectionInsteadOfReadingSharedStoreState() async throws {
    let settingsStore = InMemoryAppSettingsStore(
        selection: AppSelection(exchange: .coinbase, pair: .btcUSD)
    )
    let quoteEngine = QuoteEngine(
        initialSnapshot: .placeholder(for: .ethUSD, exchange: .coinbase),
        streamFactory: { _, _ in PreviewExchangeQuoteStream() }
    )
    let viewModel = QuoteBoardViewModel(
        initialSelection: AppBootstrapSelection(exchange: .coinbase, pair: .ethUSD),
        settingsStore: settingsStore,
        quoteEngine: quoteEngine,
        startupRetryAttempts: 1,
        startupRetryDelayNanoseconds: 0
    )

    XCTAssertEqual(viewModel.selectedPair, .ethUSD)
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests/testViewModelUsesExplicitInitialSelectionInsteadOfReadingSharedStoreState
```

Expected: FAIL because the view model currently derives its startup state directly from `settingsStore`.

- [ ] **Step 3: Implement explicit initial selection**

Update the designated initializer in `RealTimeQuote/ViewModels/QuoteBoardViewModel.swift`:

```swift
init(
    initialSelection: AppBootstrapSelection,
    settingsStore: AppSettingsStore,
    quoteEngine: QuoteEngine,
    startupRetryAttempts: Int = 3,
    startupRetryDelayNanoseconds: UInt64 = 1_000_000_000
) {
    let selectedExchange = initialSelection.exchange
    let selectedPair = initialSelection.pair

    self.quoteEngine = quoteEngine
    self.settingsStore = settingsStore
    self.startupRetryAttempts = startupRetryAttempts
    self.startupRetryDelayNanoseconds = startupRetryDelayNanoseconds
    self.selectedExchange = selectedExchange
    self.selectedPair = selectedPair
    self.snapshot = quoteEngine.snapshot

    quoteEngine.$snapshot
        .receive(on: RunLoop.main)
        .sink { [weak self] snapshot in
            self?.snapshot = snapshot
        }
        .store(in: &cancellables)

    let attempt = selectionAttempt
    Task {
        do {
            try await self.startupConnect(exchange: selectedExchange, pair: selectedPair)
        } catch {
            guard attempt == self.selectionAttempt else { return }
            guard !(error is CancellationError) else { return }
            self.lastSelectionError = error.localizedDescription
        }
    }
}
```

Keep `setSelection(exchange:pair:)` persistence behavior unchanged so successful updates still refresh app-level last selection for future windows.

- [ ] **Step 4: Re-run the focused test**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests/testViewModelUsesExplicitInitialSelectionInsteadOfReadingSharedStoreState
```

Expected: PASS

- [ ] **Step 5: Commit the window-local startup selection change**

```bash
git add RealTimeQuote/ViewModels/QuoteBoardViewModel.swift RealTimeQuoteTests/AppDependenciesFactoryTests.swift
git commit -m "refactor: bootstrap each quote window with explicit selection"
```

### Task 3: Add regression coverage for independent multi-window behavior

**Files:**
- Modify: `RealTimeQuoteTests/AppDependenciesFactoryTests.swift`
- Modify: `RealTimeQuoteTests/AppDependenciesConfigTests.swift`

- [ ] **Step 1: Add a failing independence test**

Add this test to `RealTimeQuoteTests/AppDependenciesFactoryTests.swift`:

```swift
func testNewWindowCopiesLatestPersistedSelectionWhileExistingWindowKeepsItsOwnState() async throws {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let settingsStore = UserDefaultsAppSettingsStore(defaults: defaults)
    let dependencies = AppDependencies(settingsStore: settingsStore, config: nil)

    let first = dependencies.makeQuoteBoardViewModel()
    first.selectPair(.ethUSD)

    try? await Task.sleep(nanoseconds: 50_000_000)

    let second = dependencies.makeQuoteBoardViewModel()

    XCTAssertEqual(first.selectedPair, .ethUSD)
    XCTAssertEqual(second.selectedPair, .ethUSD)

    second.selectPair(.btcUSD)

    try? await Task.sleep(nanoseconds: 50_000_000)

    XCTAssertEqual(first.selectedPair, .ethUSD)
    XCTAssertEqual(second.selectedPair, .btcUSD)
}
```

- [ ] **Step 2: Add or adjust config bootstrap coverage if needed**

If the resolver or `AppDependencies` refactor affects fallback behavior, add a focused assertion in `RealTimeQuoteTests/AppDependenciesConfigTests.swift` like:

```swift
func testFactoryUsesResolvedBootstrapSelectionForNewWindow() {
    let settingsStore = InMemoryAppSettingsStore(selection: nil)
    let config = RuntimeConfig(
        defaults: .init(exchange: .okx, pair: .ethUSD, enabledExchanges: [.coinbase, .okx]),
        coinbase: nil,
        okx: nil
    )
    let dependencies = AppDependencies(settingsStore: settingsStore, config: config)

    let viewModel = dependencies.makeQuoteBoardViewModel()

    XCTAssertEqual(viewModel.selectedExchange, .okx)
    XCTAssertEqual(viewModel.selectedPair, .ethUSD)
}
```

- [ ] **Step 3: Run the focused regression tests**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests -only-testing:RealTimeQuoteTests/AppDependenciesConfigTests
```

Expected: PASS

- [ ] **Step 4: Commit the multi-window regression coverage**

```bash
git add RealTimeQuoteTests/AppDependenciesFactoryTests.swift RealTimeQuoteTests/AppDependenciesConfigTests.swift
git commit -m "test: cover independent multi-window quote state"
```

### Task 4: Run end-to-end verification and manual multi-window check

**Files:**
- Test: `RealTimeQuote/RealTimeQuoteApp.swift`
- Test: `Build/Debug/RealTimeQuote.app`

- [ ] **Step 1: Run the relevant automated test suite**

Run:

```bash
xcodebuild test -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -destination 'platform=macOS' -only-testing:RealTimeQuoteTests/AppDependenciesFactoryTests -only-testing:RealTimeQuoteTests/AppDependenciesConfigTests -only-testing:RealTimeQuoteTests/QuoteEngineTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: Build the app**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath Build/DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Refresh the double-clickable app bundle**

Run:

```bash
mkdir -p Build/Debug
rm -rf Build/Debug/RealTimeQuote.app
cp -R Build/DerivedData/Build/Products/Debug/RealTimeQuote.app Build/Debug/RealTimeQuote.app
```

Expected: `Build/Debug/RealTimeQuote.app` contains the latest multi-window behavior.

- [ ] **Step 4: Perform a manual multi-window verification**

Run:

```bash
open Build/Debug/RealTimeQuote.app
```

Manual check:

- open a second window from the app menu
- confirm the second window starts from the latest successful selection
- switch Window A to one pair and Window B to another
- confirm each window keeps its own quote instead of synchronizing

Expected: two windows can stay on different crypto pairs at the same time.

- [ ] **Step 5: Commit any final source adjustments from verification**

```bash
git status --short
```

Expected: only intentional source changes are present. Commit only if a verification-driven source fix was needed.
