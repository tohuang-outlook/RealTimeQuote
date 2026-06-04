import Foundation

struct ReferenceStatsSnapshot: Equatable {
    let week52High: Decimal?
    let week52Low: Decimal?
    let marketCap: Decimal?

    static let empty = ReferenceStatsSnapshot(
        week52High: nil,
        week52Low: nil,
        marketCap: nil
    )
}
