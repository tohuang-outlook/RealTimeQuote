import Combine
import Foundation

@MainActor
final class QuoteBoardViewModel: ObservableObject {
    @Published private(set) var snapshot: QuoteSnapshot
    @Published private(set) var selectedExchange: ExchangeID
    @Published private(set) var selectedPair: TradingPair
    @Published private(set) var lastSelectionError: String?

    private let quoteEngine: QuoteEngine
    private let settingsStore: AppSettingsStore
    private let startupRetryAttempts: Int
    private let startupRetryDelayNanoseconds: UInt64
    private var cancellables = Set<AnyCancellable>()
    private var selectionAttempt: UInt64 = 0

    static let preview = QuoteBoardViewModel(
        snapshot: QuoteSnapshot.placeholder(for: .btcUSD, exchange: .coinbase)
    )

    init(
        settingsStore: AppSettingsStore,
        quoteEngine: QuoteEngine,
        startupRetryAttempts: Int = 3,
        startupRetryDelayNanoseconds: UInt64 = 1_000_000_000
    ) {
        let selectedExchange = settingsStore.selectedExchange
        let selectedPair = settingsStore.selectedPair

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

    init(snapshot: QuoteSnapshot) {
        self.quoteEngine = QuoteEngine(initialSnapshot: snapshot, streamFactory: { _, _ in PreviewExchangeQuoteStream() })
        self.settingsStore = Self.makePreviewSettingsStore()
        self.startupRetryAttempts = 1
        self.startupRetryDelayNanoseconds = 0
        self.selectedExchange = snapshot.exchange
        self.selectedPair = snapshot.pair
        self.snapshot = snapshot

        quoteEngine.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
            .store(in: &cancellables)
    }

    func selectExchange(_ exchange: ExchangeID) {
        guard exchange != selectedExchange else { return }

        let previousExchange = selectedExchange
        let previousPair = selectedPair
        selectionAttempt &+= 1
        let attempt = selectionAttempt

        selectedExchange = exchange
        lastSelectionError = nil

        Task {
            do {
                try await quoteEngine.updateSelection(exchange: exchange, pair: previousPair)
                guard attempt == self.selectionAttempt else { return }
                self.settingsStore.setSelection(exchange: exchange, pair: previousPair)
            } catch {
                guard attempt == self.selectionAttempt else { return }
                self.selectedExchange = previousExchange
                self.selectedPair = previousPair
                self.lastSelectionError = error.localizedDescription
            }
        }
    }

    func selectPair(_ pair: TradingPair) {
        guard pair != selectedPair else { return }

        let previousExchange = selectedExchange
        let previousPair = selectedPair
        selectionAttempt &+= 1
        let attempt = selectionAttempt

        selectedPair = pair
        lastSelectionError = nil

        Task {
            do {
                try await quoteEngine.updateSelection(exchange: previousExchange, pair: pair)
                guard attempt == self.selectionAttempt else { return }
                self.settingsStore.setSelection(exchange: previousExchange, pair: pair)
            } catch {
                guard attempt == self.selectionAttempt else { return }
                self.selectedExchange = previousExchange
                self.selectedPair = previousPair
                self.lastSelectionError = error.localizedDescription
            }
        }
    }

    private static func makePreviewSettingsStore() -> AppSettingsStore {
        let defaults = UserDefaults(suiteName: "RealTimeQuote.QuoteBoardViewModel.preview") ?? .standard
        defaults.removePersistentDomain(forName: "RealTimeQuote.QuoteBoardViewModel.preview")
        return UserDefaultsAppSettingsStore(defaults: defaults)
    }

    private func startupConnect(exchange: ExchangeID, pair: TradingPair) async throws {
        let attempts = max(1, startupRetryAttempts)
        var lastError: Error?

        for attempt in 1...attempts {
            do {
                try await quoteEngine.start(exchange: exchange, pair: pair)
                return
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                guard attempt < attempts else { break }
                if startupRetryDelayNanoseconds > 0 {
                    try await Task.sleep(nanoseconds: startupRetryDelayNanoseconds)
                } else {
                    await Task.yield()
                }
            }
        }

        throw lastError ?? StartupConnectError.unknown
    }
}

private enum StartupConnectError: LocalizedError {
    case unknown
}

private final class PreviewExchangeQuoteStream: ExchangeQuoteStreaming {
    let events = AsyncStream<ExchangeStreamEvent> { _ in }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {}

    func stop() {}
}
