import XCTest
@testable import RealTimeQuote

final class CoinbaseTickerMessageTests: XCTestCase {
    func testTickerMessageDecodesSnapshotPayloadAndBuildsQuoteSnapshot() throws {
        let payload = Data(
            #"""
            {
              "channel": "ticker",
              "client_id": "",
              "timestamp": "2023-02-09T20:30:37.167359596Z",
              "sequence_num": 0,
              "events": [
                {
                  "type": "snapshot",
                  "tickers": [
                    {
                      "type": "ticker",
                      "product_id": "BTC-USD",
                      "price": "21932.98",
                      "volume_24_h": "16038.28770938",
                      "low_24_h": "21835.29",
                      "high_24_h": "23011.18",
                      "low_52_w": "15460",
                      "high_52_w": "48240",
                      "price_percent_chg_24_h": "-4.15775596190603",
                      "best_bid": "21931.98",
                      "best_bid_quantity": "8000.21",
                      "best_ask": "21933.98",
                      "best_ask_quantity": "8038.07770938"
                    }
                  ]
                }
              ]
            }
            """#.utf8
        )

        let message = try JSONDecoder().decode(CoinbaseTickerMessage.self, from: payload)
        let snapshot = try XCTUnwrap(
            message.quoteSnapshot(for: .btcUSD, exchange: .coinbase, connectionState: .live)
        )

        XCTAssertEqual(message.channel, "ticker")
        XCTAssertEqual(snapshot.exchange, .coinbase)
        XCTAssertEqual(snapshot.pair, .btcUSD)
        XCTAssertEqual(snapshot.lastPrice, Decimal(string: "21932.98"))
        XCTAssertEqual(snapshot.percentChange, Decimal(string: "-4.15775596190603"))
        XCTAssertEqual(snapshot.absoluteChange, Decimal(string: "-951.480000000000702130888893"))
        XCTAssertEqual(snapshot.high24h, Decimal(string: "23011.18"))
        XCTAssertEqual(snapshot.low24h, Decimal(string: "21835.29"))
        XCTAssertEqual(snapshot.volume24h, Decimal(string: "16038.28770938"))
        XCTAssertEqual(snapshot.connectionState, .live)
        let expectedTimestampFormatter = ISO8601DateFormatter()
        expectedTimestampFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertEqual(
            snapshot.updatedAt,
            expectedTimestampFormatter.date(from: "2023-02-09T20:30:37.167359596Z")
        )
    }

    func testTickerMessageIgnoresMismatchedProduct() throws {
        let payload = Data(
            #"""
            {
              "channel": "ticker",
              "timestamp": "2023-02-09T20:30:37.167359596Z",
              "events": [
                {
                  "type": "snapshot",
                  "tickers": [
                    {
                      "type": "ticker",
                      "product_id": "ETH-USD",
                      "price": "1677.01",
                      "volume_24_h": "9812.4",
                      "low_24_h": "1601.22",
                      "high_24_h": "1699.90",
                      "price_percent_chg_24_h": "1.25"
                    }
                  ]
                }
              ]
            }
            """#.utf8
        )

        let message = try JSONDecoder().decode(CoinbaseTickerMessage.self, from: payload)

        XCTAssertNil(message.quoteSnapshot(for: .btcUSD, exchange: .coinbase, connectionState: .live))
    }

    func testTickerMessageDecodesControlFrameWithoutTickerPayload() throws {
        let payload = Data(
            #"""
            {
              "type": "subscriptions",
              "channels": [
                {
                  "name": "ticker",
                  "product_ids": ["BTC-USD"]
                }
              ]
            }
            """#.utf8
        )

        let message = try JSONDecoder().decode(CoinbaseTickerMessage.self, from: payload)

        XCTAssertNil(message.channel)
        XCTAssertTrue(message.events.isEmpty)
        XCTAssertNil(message.quoteSnapshot(for: .btcUSD, exchange: .coinbase, connectionState: .live))
    }
}
