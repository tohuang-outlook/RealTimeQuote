import Foundation

@MainActor
final class QuoteEngine: ObservableObject {
    typealias StreamFactory = (ExchangeID, TradingPair) -> ExchangeQuoteStreaming

    @Published private(set) var snapshot: QuoteSnapshot

    private let streamFactory: StreamFactory
    private var currentStream: ExchangeQuoteStreaming?
    private var eventTask: Task<Void, Never>?
    private var streamGeneration: UInt64 = 0

    init(
        initialSnapshot: QuoteSnapshot = .placeholder(for: .btcUSD, exchange: .coinbase),
        streamFactory: @escaping StreamFactory
    ) {
        self.snapshot = initialSnapshot
        self.streamFactory = streamFactory
    }

    deinit {
        eventTask?.cancel()
        currentStream?.stop()
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        try await replaceStream(exchange: exchange, pair: pair)
    }

    func updateSelection(exchange: ExchangeID, pair: TradingPair) async throws {
        try await replaceStream(exchange: exchange, pair: pair)
    }

    private func replaceStream(exchange: ExchangeID, pair: TradingPair) async throws {
        let previousStream = currentStream
        let previousTask = eventTask
        let previousSnapshot = snapshot
        let previousGeneration = streamGeneration

        let nextGeneration = previousGeneration &+ 1
        streamGeneration = nextGeneration
        snapshot = .placeholder(for: pair, exchange: exchange)

        let stream = streamFactory(exchange, pair)
        let task = Task { [weak self] in
            for await event in stream.events {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.consume(event, generation: nextGeneration)
                }
            }
        }

        do {
            try await stream.start(exchange: exchange, pair: pair)
        } catch {
            task.cancel()
            stream.stop()
            guard streamGeneration == nextGeneration else {
                throw CancellationError()
            }
            streamGeneration = previousGeneration
            currentStream = previousStream
            eventTask = previousTask
            snapshot = previousSnapshot
            throw error
        }

        guard streamGeneration == nextGeneration else {
            task.cancel()
            stream.stop()
            throw CancellationError()
        }

        previousTask?.cancel()
        previousStream?.stop()
        currentStream = stream
        eventTask = task
    }

    private func consume(_ event: ExchangeStreamEvent, generation: UInt64) {
        guard generation == streamGeneration else { return }

        switch event {
        case .didConnect:
            snapshot = QuoteSnapshot(
                exchange: snapshot.exchange,
                pair: snapshot.pair,
                lastPrice: snapshot.lastPrice,
                absoluteChange: snapshot.absoluteChange,
                percentChange: snapshot.percentChange,
                high24h: snapshot.high24h,
                low24h: snapshot.low24h,
                volume24h: snapshot.volume24h,
                updatedAt: snapshot.updatedAt,
                connectionState: .live
            )

        case .didReceiveSnapshot(let snapshot):
            self.snapshot = snapshot

        case .didDisconnect(let issue):
            snapshot = QuoteSnapshot(
                exchange: snapshot.exchange,
                pair: snapshot.pair,
                lastPrice: snapshot.lastPrice,
                absoluteChange: snapshot.absoluteChange,
                percentChange: snapshot.percentChange,
                high24h: snapshot.high24h,
                low24h: snapshot.low24h,
                volume24h: snapshot.volume24h,
                updatedAt: snapshot.updatedAt,
                connectionState: .disconnected(issue ?? .unknown)
            )
        }
    }
}
