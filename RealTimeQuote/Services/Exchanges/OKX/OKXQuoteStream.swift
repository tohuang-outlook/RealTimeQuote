import Foundation

final class OKXQuoteStream: ExchangeQuoteStreaming {
    let events: AsyncStream<ExchangeStreamEvent>

    let config: RuntimeConfig.OKX?

    private let session: URLSession
    private let decoder = JSONDecoder()
    private var continuation: AsyncStream<ExchangeStreamEvent>.Continuation?
    private var webSocketTask: URLSessionWebSocketTask?
    private var lifecycleTask: Task<Void, Never>?
    private var activeSubscription: Subscription?
    private var isStopped = false

    init(
        config: RuntimeConfig.OKX? = nil,
        session: URLSession = .shared
    ) {
        self.config = config
        self.session = session
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let milliseconds = Double(value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported OKX timestamp: \(value)"
                )
            }
            return Date(timeIntervalSince1970: milliseconds / 1_000)
        }

        var continuation: AsyncStream<ExchangeStreamEvent>.Continuation?
        self.events = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.continuation = continuation
    }

    func start(exchange: ExchangeID, pair: TradingPair) async throws {
        stop()
        isStopped = false

        let subscription = Subscription(exchange: exchange, pair: pair)
        activeSubscription = subscription

        let task = try await connect(for: subscription)
        guard activeSubscription == subscription, !isStopped else {
            task.cancel(with: .goingAway, reason: nil)
            throw CancellationError()
        }

        webSocketTask = task
        lifecycleTask = Task { [weak self] in
            await self?.runLifecycle(startingWith: task, subscription: subscription)
        }
    }

    func stop() {
        isStopped = true
        activeSubscription = nil
        lifecycleTask?.cancel()
        lifecycleTask = nil
        cancelCurrentSocket()
    }

    private func runLifecycle(
        startingWith task: URLSessionWebSocketTask,
        subscription: Subscription
    ) async {
        var currentTask = task
        var reconnectAttempt = 0

        while !Task.isCancelled, activeSubscription == subscription, !isStopped {
            do {
                let message = try await currentTask.receive()
                guard let snapshot = try decodeSnapshot(
                    from: message,
                    pair: subscription.pair,
                    exchange: subscription.exchange
                ) else {
                    continue
                }
                reconnectAttempt = 0
                continuation?.yield(.didReceiveSnapshot(snapshot))
            } catch is CancellationError {
                return
            } catch {
                guard activeSubscription == subscription, !isStopped else {
                    return
                }

                continuation?.yield(.didDisconnect(Self.connectionIssue(for: error, task: currentTask)))
                currentTask.cancel(with: .goingAway, reason: nil)

                do {
                    currentTask = try await reconnectUntilSuccess(
                        startingAt: reconnectAttempt + 1,
                        for: subscription
                    )
                    guard activeSubscription == subscription, !isStopped else {
                        currentTask.cancel(with: .goingAway, reason: nil)
                        return
                    }
                    webSocketTask = currentTask
                    reconnectAttempt = 0
                } catch is CancellationError {
                    return
                } catch {
                    return
                }
            }
        }
    }

    private func reconnectUntilSuccess(
        startingAt attempt: Int,
        for subscription: Subscription
    ) async throws -> URLSessionWebSocketTask {
        var attempt = attempt

        while !Task.isCancelled, activeSubscription == subscription, !isStopped {
            do {
                return try await reconnect(after: attempt, for: subscription)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if activeSubscription == subscription, !isStopped {
                    continuation?.yield(.didDisconnect(Self.connectionIssue(for: error, task: nil)))
                }
                attempt += 1
            }
        }

        throw CancellationError()
    }

    private func reconnect(after attempt: Int, for subscription: Subscription) async throws -> URLSessionWebSocketTask {
        let cappedAttempt = min(attempt, 3)
        let delaySeconds = UInt64(1 << max(0, cappedAttempt - 1))
        try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
        try Task.checkCancellation()
        return try await connect(for: subscription)
    }

    private func connect(for subscription: Subscription) async throws -> URLSessionWebSocketTask {
        let task = session.webSocketTask(with: URL(string: "wss://ws.okx.com:8443/ws/v5/public")!)
        task.resume()

        do {
            try await task.send(
                .string(
                    """
                    {"op":"subscribe","args":[{"channel":"tickers","instId":"\(subscription.pair.okxInstrumentID)"}]}
                    """
                )
            )
            continuation?.yield(.didConnect)
            return task
        } catch {
            task.cancel(with: .goingAway, reason: nil)
            throw error
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

        let envelope = try decoder.decode(OKXTickerEnvelope.self, from: data)
        return envelope.quoteSnapshot(for: pair, exchange: exchange, connectionState: .live)
    }

    private static func connectionIssue(for error: Error, task: URLSessionWebSocketTask?) -> ConnectionIssue {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkFailure
        }
        if let task, task.closeCode != .invalid {
            return .remoteClosed
        }
        return .unknown
    }

    private func cancelCurrentSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    private struct Subscription: Equatable {
        let exchange: ExchangeID
        let pair: TradingPair
    }
}
