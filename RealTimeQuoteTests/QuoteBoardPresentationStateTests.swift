import XCTest
@testable import RealTimeQuote

final class QuoteBoardPresentationStateTests: XCTestCase {
    func testPresentationStateUsesSingleSnapshotIdentityAndFormatsValues() {
        let snapshot = QuoteSnapshot(
            exchange: .coinbase,
            pair: .btcUSD,
            lastPrice: Decimal(string: "73707.82"),
            absoluteChange: Decimal(string: "273.09"),
            percentChange: Decimal(string: "0.37"),
            high24h: Decimal(string: "74172.05"),
            low24h: Decimal(string: "73127.08"),
            volume24h: Decimal(string: "4040.12"),
            updatedAt: Date(timeIntervalSince1970: 1_780_181_040),
            connectionState: .live
        )

        let presentation = QuoteBoardPresentationState(
            snapshot: snapshot,
            lastSelectionError: "ignored"
        )

        XCTAssertEqual(presentation.header.symbol, "BTC-USD")
        XCTAssertEqual(presentation.header.exchangeName, "Coinbase")
        XCTAssertEqual(presentation.header.priceText, "$73,707.82")
        XCTAssertEqual(presentation.header.changeAmountText, "+273.09")
        XCTAssertEqual(presentation.header.changePercentText, "+0.37%")
        XCTAssertEqual(presentation.header.changeTone, .positive)
        XCTAssertEqual(
            presentation.stats,
            [
                StatsGridView.Item(label: "Open", value: "--", valueColor: .white),
                StatsGridView.Item(label: "High", value: "$74,172.05", valueColor: QuoteBoardTheme.positive),
                StatsGridView.Item(label: "Low", value: "$73,127.08", valueColor: QuoteBoardTheme.negative),
                StatsGridView.Item(label: "Prev Close", value: "--", valueColor: .white),
                StatsGridView.Item(label: "52 Wk High", value: "--", valueColor: .white),
                StatsGridView.Item(label: "52 Wk Low", value: "--", valueColor: .white),
                StatsGridView.Item(label: "24H Volume", value: "4,040.12", valueColor: .white),
                StatsGridView.Item(label: "Market Cap", value: "--", valueColor: .white)
            ]
        )
        XCTAssertEqual(presentation.connectionState, .live)
        XCTAssertEqual(presentation.lastSelectionError, "ignored")
    }
}
