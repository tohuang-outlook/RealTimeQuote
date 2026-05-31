import Foundation

final class CoinbaseQuoteStream: ExchangeQuoteStreaming {
    let events: AsyncStream<ExchangeStreamEvent>

    private let session: URLSession
    private let decoder: JSONDecoder
    private var continuation: AsyncStream<ExchangeStreamEvent>.Continuation?
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var activePair: TradingPair?

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported Coinbase timestamp: \(value)"
            )
        }
        self.decoder = decoder

        var continuation: AsyncStream<ExchangeStreamEvent>.Continuation?
        self.events = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.continuation = continuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        stop()
        activePair = pair

        let task = session.webSocketTask(with: URL(string: "wss://advanced-trade-ws.coinbase.com")!)
        webSocketTask = task
        task.resume()

        do {
            try await task.send(
                .string(
                    """
                    {"type":"subscribe","channel":"ticker","product_ids":["\(pair.coinbaseProductID)"]}
                    """
                )
            )

            receiveTask = Task { [weak self] in
                await self?.receiveLoop(exchange: exchange, pair: pair, task: task)
            }
        } catch {
            cleanupAfterStartFailure(task: task)
            throw error
        }
    }

    func stop() {
        receiveTask?.cancel()
        receiveTask = nil
        activePair = nil

        if let webSocketTask {
            webSocketTask.cancel(with: .goingAway, reason: nil)
            self.webSocketTask = nil
        }
    }

    private func receiveLoop(exchange: ExchangeID, pair: TradingPair, task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                guard let snapshot = try decodeSnapshot(from: message, pair: pair, exchange: exchange) else {
                    continue
                }
                continuation?.yield(.didReceiveSnapshot(snapshot))
            } catch is CancellationError {
                return
            } catch {
                continuation?.yield(.didDisconnect(Self.connectionIssue(for: error)))
                return
            }
        }
    }

    private func decodeSnapshot(
        from message: URLSessionWebSocketTask.Message,
        pair: TradingPair,
        exchange: ExchangeID
    ) throws -> QuoteSnapshot? {
        let data: Data
        switch message {
        case .data(let messageData):
            data = messageData
        case .string(let messageString):
            data = Data(messageString.utf8)
        @unknown default:
            return nil
        }

        let tickerMessage = try decoder.decode(CoinbaseTickerMessage.self, from: data)
        return tickerMessage.quoteSnapshot(for: pair, exchange: exchange, connectionState: .live)
    }

    private static func connectionIssue(for error: Error) -> ConnectionIssue {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkFailure
        }
        return .unknown
    }

    private func cleanupAfterStartFailure(task: URLSessionWebSocketTask) {
        if webSocketTask === task {
            webSocketTask = nil
        }
        receiveTask?.cancel()
        receiveTask = nil
        activePair = nil
        task.cancel(with: .goingAway, reason: nil)
    }
}
