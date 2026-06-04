import Combine
import Foundation

@MainActor
final class QuoteBoardViewModel: ObservableObject {
    @Published private(set) var snapshot: QuoteSnapshot
    @Published private(set) var marketDetails: MarketDetailsSnapshot
    @Published private(set) var referenceStats: ReferenceStatsSnapshot
    @Published private(set) var selectedExchange: ExchangeID
    @Published private(set) var selectedPair: TradingPair
    @Published private(set) var lastSelectionError: String?

    private let quoteEngine: QuoteEngine
    private let marketDetailsLoader: ExchangeMarketDetailsLoading
    private let referenceStatsLoader: ReferenceStatsLoading
    private let settingsStore: AppSettingsStore
    private let startupRetryAttempts: Int
    private let startupRetryDelayNanoseconds: UInt64
    private var cancellables = Set<AnyCancellable>()
    private var selectionAttempt: UInt64 = 0
    private var marketDetailsTask: Task<Void, Never>?
    private var referenceStatsTask: Task<Void, Never>?

    static let preview = QuoteBoardViewModel(
        snapshot: QuoteSnapshot.placeholder(for: .btcUSD, exchange: .coinbase)
    )

    init(
        initialSelection: AppBootstrapSelection,
        settingsStore: AppSettingsStore,
        quoteEngine: QuoteEngine,
        marketDetailsLoader: ExchangeMarketDetailsLoading = NoOpExchangeMarketDetailsLoader(),
        referenceStatsLoader: ReferenceStatsLoading = NoOpReferenceStatsLoader(),
        startupRetryAttempts: Int = 3,
        startupRetryDelayNanoseconds: UInt64 = 1_000_000_000
    ) {
        let selectedExchange = initialSelection.exchange
        let selectedPair = initialSelection.pair

        self.quoteEngine = quoteEngine
        self.marketDetailsLoader = marketDetailsLoader
        self.referenceStatsLoader = referenceStatsLoader
        self.settingsStore = settingsStore
        self.startupRetryAttempts = startupRetryAttempts
        self.startupRetryDelayNanoseconds = startupRetryDelayNanoseconds
        self.selectedExchange = selectedExchange
        self.selectedPair = selectedPair
        self.snapshot = quoteEngine.snapshot
        self.marketDetails = .empty
        self.referenceStats = .empty

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
                self.refreshMarketDetails(exchange: selectedExchange, pair: selectedPair)
                self.refreshReferenceStats(pair: selectedPair)
            } catch {
                guard attempt == self.selectionAttempt else { return }
                guard !(error is CancellationError) else { return }
                self.lastSelectionError = error.localizedDescription
            }
        }
    }

    init(snapshot: QuoteSnapshot) {
        self.quoteEngine = QuoteEngine(initialSnapshot: snapshot, streamFactory: { _, _ in PreviewExchangeQuoteStream() })
        self.marketDetailsLoader = NoOpExchangeMarketDetailsLoader()
        self.referenceStatsLoader = NoOpReferenceStatsLoader()
        self.settingsStore = Self.makePreviewSettingsStore()
        self.startupRetryAttempts = 1
        self.startupRetryDelayNanoseconds = 0
        self.selectedExchange = snapshot.exchange
        self.selectedPair = snapshot.pair
        self.snapshot = snapshot
        self.marketDetails = .empty
        self.referenceStats = .empty

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
        let previousMarketDetails = marketDetails
        let previousReferenceStats = referenceStats
        selectionAttempt &+= 1
        let attempt = selectionAttempt

        selectedExchange = exchange
        marketDetails = .empty
        referenceStats = .empty
        lastSelectionError = nil

        Task {
            do {
                try await quoteEngine.updateSelection(exchange: exchange, pair: previousPair)
                guard attempt == self.selectionAttempt else { return }
                self.settingsStore.setSelection(exchange: exchange, pair: previousPair)
                self.refreshMarketDetails(exchange: exchange, pair: previousPair)
                self.refreshReferenceStats(pair: previousPair)
            } catch {
                guard attempt == self.selectionAttempt else { return }
                self.selectedExchange = previousExchange
                self.selectedPair = previousPair
                self.marketDetails = previousMarketDetails
                self.referenceStats = previousReferenceStats
                self.lastSelectionError = error.localizedDescription
            }
        }
    }

    func selectPair(_ pair: TradingPair) {
        guard pair != selectedPair else { return }

        let previousExchange = selectedExchange
        let previousPair = selectedPair
        let previousMarketDetails = marketDetails
        let previousReferenceStats = referenceStats
        selectionAttempt &+= 1
        let attempt = selectionAttempt

        selectedPair = pair
        marketDetails = .empty
        referenceStats = .empty
        lastSelectionError = nil

        Task {
            do {
                try await quoteEngine.updateSelection(exchange: previousExchange, pair: pair)
                guard attempt == self.selectionAttempt else { return }
                self.settingsStore.setSelection(exchange: previousExchange, pair: pair)
                self.refreshMarketDetails(exchange: previousExchange, pair: pair)
                self.refreshReferenceStats(pair: pair)
            } catch {
                guard attempt == self.selectionAttempt else { return }
                self.selectedExchange = previousExchange
                self.selectedPair = previousPair
                self.marketDetails = previousMarketDetails
                self.referenceStats = previousReferenceStats
                self.lastSelectionError = error.localizedDescription
            }
        }
    }

    private func refreshMarketDetails(exchange: ExchangeID, pair: TradingPair) {
        marketDetailsTask?.cancel()
        marketDetailsTask = Task { [weak self] in
            guard let self else { return }

            do {
                let details = try await self.marketDetailsLoader.loadDetails(for: exchange, pair: pair)
                guard !Task.isCancelled else { return }
                guard self.selectedExchange == exchange, self.selectedPair == pair else { return }
                self.marketDetails = details
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                guard self.selectedExchange == exchange, self.selectedPair == pair else { return }
                self.marketDetails = .empty
            }
        }
    }

    private func refreshReferenceStats(pair: TradingPair) {
        referenceStatsTask?.cancel()
        referenceStatsTask = Task { [weak self] in
            guard let self else { return }

            do {
                let stats = try await self.referenceStatsLoader.loadStats(for: pair)
                guard !Task.isCancelled else { return }
                guard self.selectedPair == pair else { return }
                self.referenceStats = stats
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                guard self.selectedPair == pair else { return }
                self.referenceStats = .empty
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
