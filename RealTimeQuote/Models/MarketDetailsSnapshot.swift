import Foundation

struct MarketDetailsSnapshot: Equatable {
    let open: Decimal?
    let prevClose: Decimal?
    let week52High: Decimal?
    let week52Low: Decimal?
    let marketCap: Decimal?

    static let empty = MarketDetailsSnapshot(
        open: nil,
        prevClose: nil,
        week52High: nil,
        week52Low: nil,
        marketCap: nil
    )
}
