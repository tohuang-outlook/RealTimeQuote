import Foundation

protocol ReferenceStatsLoading {
    func loadStats(for pair: TradingPair) async throws -> ReferenceStatsSnapshot
}

struct NoOpReferenceStatsLoader: ReferenceStatsLoading {
    func loadStats(for pair: TradingPair) async throws -> ReferenceStatsSnapshot {
        .empty
    }
}
