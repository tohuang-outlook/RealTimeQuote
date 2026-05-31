import Foundation

enum ConnectionIssue: String, Equatable, Codable {
    case networkFailure = "network_failure"
    case remoteClosed = "remote_closed"
    case unknown = "unknown"
}

enum ConnectionState: Equatable {
    case connecting
    case live
    case reconnecting
    case disconnected(ConnectionIssue)
}
