import XCTest
@testable import RealTimeQuote

@MainActor
final class QuoteEngineTests: XCTestCase {
    func testStartRequestsSubscriptionForSelectedPairAndSeedsPlaceholderSnapshot() async throws {
        let stream = MockExchangeQuoteStream()
        let engine = QuoteEngine(streamFactory: { _, _ in stream })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)

        XCTAssertEqual(stream.startCalls, [StartCall(exchange: .coinbase, pair: .btcUSD)])
        XCTAssertEqual(engine.snapshot.exchange, .coinbase)
        XCTAssertEqual(engine.snapshot.pair, .btcUSD)
        XCTAssertEqual(engine.snapshot.connectionState, .connecting)
    }

    func testSwitchSelectionStopsOldStreamBeforeStartingNewOne() async throws {
        let first = MockExchangeQuoteStream()
        let second = MockExchangeQuoteStream()
        let streams = [first, second]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)
        try await engine.updateSelection(exchange: .okx, pair: .ethUSD)

        XCTAssertTrue(first.stopCalled)
        XCTAssertEqual(second.startCalls, [StartCall(exchange: .okx, pair: .ethUSD)])
        XCTAssertEqual(engine.snapshot.exchange, .okx)
        XCTAssertEqual(engine.snapshot.pair, .ethUSD)
        XCTAssertEqual(engine.snapshot.connectionState, .connecting)
    }

    func testLateEventsFromReplacedStreamDoNotOverwriteNewSelection() async throws {
        let first = MockExchangeQuoteStream()
        let second = MockExchangeQuoteStream()
        let streams = [first, second]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)
        first.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 101)))
        await settle()

        try await engine.updateSelection(exchange: .okx, pair: .ethUSD)
        first.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 202)))
        await settle()

        XCTAssertEqual(engine.snapshot.exchange, .okx)
        XCTAssertEqual(engine.snapshot.pair, .ethUSD)
        XCTAssertNil(engine.snapshot.lastPrice)
        XCTAssertEqual(engine.snapshot.connectionState, .connecting)
    }

    func testFailedInitialStartCleansUpFailedStreamAndIgnoresItsLateEvents() async {
        let stream = MockExchangeQuoteStream(startError: MockStreamError.startFailed)
        let engine = QuoteEngine(streamFactory: { _, _ in stream })

        await XCTAssertThrowsErrorAsync(try await engine.start(exchange: .coinbase, pair: .btcUSD))

        stream.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 303)))
        await settle()

        XCTAssertEqual(stream.startCalls, [StartCall(exchange: .coinbase, pair: .btcUSD)])
        XCTAssertTrue(stream.stopCalled)
        XCTAssertEqual(engine.snapshot, .placeholder(for: .btcUSD, exchange: .coinbase))
    }

    func testFailedSelectionStartRestoresPreviousActiveStreamAndSnapshot() async throws {
        let first = MockExchangeQuoteStream()
        let second = MockExchangeQuoteStream(startError: MockStreamError.startFailed)
        let streams = [first, second]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        try await engine.start(exchange: .coinbase, pair: .btcUSD)
        first.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 404)))
        await waitUntil { engine.snapshot.lastPrice == 404 }

        await XCTAssertThrowsErrorAsync(try await engine.updateSelection(exchange: .okx, pair: .ethUSD))

        XCTAssertFalse(first.stopCalled)
        XCTAssertTrue(second.stopCalled)
        XCTAssertEqual(engine.snapshot, Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 404))

        first.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 505)))
        second.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .okx, pair: .ethUSD, price: 606)))
        await waitUntil { engine.snapshot.lastPrice == 505 }

        XCTAssertEqual(engine.snapshot, Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 505))
    }

    func testViewModelRollsBackSelectionAndDoesNotPersistWhenEngineSwitchFails() async throws {
        let settingsStore = InMemoryAppSettingsStore()
        let first = MockExchangeQuoteStream()
        let second = MockExchangeQuoteStream(startError: MockStreamError.startFailed)
        let streams = [first, second]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: engine)
        await waitUntil { first.startCalls.count == 1 }

        viewModel.selectExchange(.okx)
        XCTAssertEqual(viewModel.selectedExchange, .okx)

        await waitUntil { second.startCalls.count == 1 }
        await waitUntil { viewModel.selectedExchange == .coinbase }

        XCTAssertEqual(viewModel.selectedExchange, .coinbase)
        XCTAssertEqual(viewModel.selectedPair, .btcUSD)
        XCTAssertEqual(settingsStore.selectedExchange, .coinbase)
        XCTAssertEqual(settingsStore.selectedPair, .btcUSD)
        XCTAssertEqual(viewModel.lastSelectionError, MockStreamError.startFailed.localizedDescription)
    }

    func testOlderStartCompletionCannotInstallAfterNewerSelectionWins() async throws {
        let first = MockExchangeQuoteStream(startBehavior: .suspended)
        let second = MockExchangeQuoteStream()
        let streams = [first, second]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        let firstTask = Task {
            try await engine.start(exchange: .coinbase, pair: .btcUSD)
        }
        await waitUntil { first.startCalls.count == 1 }

        try await engine.updateSelection(exchange: .okx, pair: .ethUSD)
        first.resumeStart()
        _ = await firstTask.result

        first.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .coinbase, pair: .btcUSD, price: 707)))
        second.emit(.didReceiveSnapshot(Self.makeSnapshot(exchange: .okx, pair: .ethUSD, price: 808)))
        await waitUntil { engine.snapshot.lastPrice == 808 }

        XCTAssertTrue(first.stopCalled)
        XCTAssertEqual(engine.snapshot, Self.makeSnapshot(exchange: .okx, pair: .ethUSD, price: 808))
    }

    func testViewModelPersistsWholeSelectionTupleWhenOverlappingChangesResolve() async throws {
        let settingsStore = InMemoryAppSettingsStore()
        let initial = MockExchangeQuoteStream()
        let exchangeChange = MockExchangeQuoteStream(startBehavior: .suspended)
        let pairChange = MockExchangeQuoteStream()
        let streams = [initial, exchangeChange, pairChange]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: engine)
        await waitUntil { initial.startCalls.count == 1 }

        viewModel.selectExchange(.okx)
        await waitUntil { exchangeChange.startCalls.count == 1 }

        viewModel.selectPair(.ethUSD)
        await waitUntil { pairChange.startCalls.count == 1 }
        await waitUntil {
            settingsStore.selectedExchange == .okx && settingsStore.selectedPair == .ethUSD
        }

        XCTAssertEqual(viewModel.selectedExchange, .okx)
        XCTAssertEqual(viewModel.selectedPair, .ethUSD)
        XCTAssertEqual(settingsStore.selectedExchange, .okx)
        XCTAssertEqual(settingsStore.selectedPair, .ethUSD)
    }

    func testViewModelDoesNotSurfaceStaleInitialStartCancellationAfterNewerSelectionWins() async throws {
        let settingsStore = InMemoryAppSettingsStore()
        let initial = MockExchangeQuoteStream(startBehavior: .suspended)
        let replacement = MockExchangeQuoteStream()
        let streams = [initial, replacement]
        var factoryCalls = 0
        let engine = QuoteEngine(streamFactory: { _, _ in
            defer { factoryCalls += 1 }
            return streams[factoryCalls]
        })

        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore, quoteEngine: engine)
        await waitUntil { initial.startCalls.count == 1 }

        viewModel.selectExchange(.okx)
        await waitUntil { replacement.startCalls.count == 1 }
        initial.resumeStart()
        await waitUntil {
            viewModel.selectedExchange == .okx
                && settingsStore.selectedExchange == .okx
        }

        XCTAssertNil(viewModel.lastSelectionError)
        XCTAssertEqual(viewModel.selectedExchange, .okx)
        XCTAssertEqual(settingsStore.selectedExchange, .okx)
    }

    func testSettingsStorePersistsSelectionTupleWithoutLegacySplitKeys() {
        let suiteName = "RealTimeQuoteTests.QuoteEngineTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let writer = UserDefaultsAppSettingsStore(defaults: defaults)
        writer.setSelection(exchange: .okx, pair: .ethUSD)

        let reader = UserDefaultsAppSettingsStore(defaults: defaults)

        XCTAssertEqual(reader.selectedExchange, .okx)
        XCTAssertEqual(reader.selectedPair, .ethUSD)
        XCTAssertNil(defaults.string(forKey: "selectedExchange"))
        XCTAssertNil(defaults.string(forKey: "selectedPair"))
        XCTAssertNotNil(defaults.data(forKey: "selection"))
    }

    private static func makeSnapshot(
        exchange: ExchangeID,
        pair: TradingPair,
        price: Decimal,
        absoluteChange: Decimal? = nil,
        percentChange: Decimal? = nil,
        updatedAt: Date? = nil
    ) -> QuoteSnapshot {
        QuoteSnapshot(
            exchange: exchange,
            pair: pair,
            lastPrice: price,
            absoluteChange: absoluteChange,
            percentChange: percentChange,
            high24h: nil,
            low24h: nil,
            volume24h: nil,
            updatedAt: updatedAt,
            connectionState: .live
        )
    }

    private func settle() async {
        await Task.yield()
        await Task.yield()
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int(timeoutNanoseconds))
        while ContinuousClock.now < deadline {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Timed out waiting for condition")
    }
}

private final class MockExchangeQuoteStream: ExchangeQuoteStreaming {
    let events: AsyncStream<ExchangeStreamEvent>
    private let continuation: AsyncStream<ExchangeStreamEvent>.Continuation
    private(set) var startCalls: [StartCall] = []
    private(set) var stopCalled = false
    private let startBehavior: StartBehavior
    private var startContinuation: CheckedContinuation<Void, Never>?

    init(startError: Error? = nil, startBehavior: StartBehavior = .immediate) {
        if let startError {
            self.startBehavior = .failing(startError)
        } else {
            self.startBehavior = startBehavior
        }
        var continuation: AsyncStream<ExchangeStreamEvent>.Continuation!
        self.events = AsyncStream<ExchangeStreamEvent> {
            continuation = $0
        }
        self.continuation = continuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        startCalls.append(StartCall(exchange: exchange, pair: pair))
        switch startBehavior {
        case .immediate:
            return
        case .failing(let error):
            throw error
        case .suspended:
            await withCheckedContinuation { continuation in
                startContinuation = continuation
            }
        }
    }

    func stop() {
        stopCalled = true
    }

    func emit(_ event: ExchangeStreamEvent) {
        continuation.yield(event)
    }

    func resumeStart() {
        startContinuation?.resume()
        startContinuation = nil
    }
}

private struct StartCall: Equatable {
    let exchange: ExchangeID
    let pair: TradingPair
}

private final class InMemoryAppSettingsStore: AppSettingsStore {
    var selectedExchange: ExchangeID = .coinbase
    var selectedPair: TradingPair = .btcUSD

    func setSelection(exchange: ExchangeID, pair: TradingPair) {
        selectedExchange = exchange
        selectedPair = pair
    }
}

private enum MockStreamError: LocalizedError {
    case startFailed

    var errorDescription: String? {
        switch self {
        case .startFailed:
            return "Mock stream failed to start"
        }
    }
}

private enum StartBehavior {
    case immediate
    case suspended
    case failing(Error)
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {}
}
