import Foundation

enum ExchangeStreamEvent: Equatable {
    case didConnect
    case didReceiveSnapshot(QuoteSnapshot)
    case didDisconnect(ConnectionIssue?)
}
