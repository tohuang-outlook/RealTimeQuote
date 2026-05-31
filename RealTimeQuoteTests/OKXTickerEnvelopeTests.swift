import XCTest
@testable import RealTimeQuote

final class OKXTickerEnvelopeTests: XCTestCase {
    func testTickerEnvelopeDecodesPayloadAndBuildsQuoteSnapshot() throws {
        let payload = Data(
            #"""
            {
              "arg": {
                "channel": "tickers",
                "instId": "BTC-USD"
              },
              "data": [
                {
                  "instType": "SPOT",
                  "instId": "BTC-USD",
                  "last": "64215.7",
                  "lastSz": "0.01807331",
                  "askPx": "64215.8",
                  "askSz": "1.123",
                  "bidPx": "64215.7",
                  "bidSz": "0.8442",
                  "open24h": "63000",
                  "high24h": "64888.8",
                  "low24h": "62123.4",
                  "vol24h": "1284.5567",
                  "volCcy24h": "81234567.987",
                  "ts": "1717436715123"
                }
              ]
            }
            """#.utf8
        )

        let envelope = try JSONDecoder().decode(OKXTickerEnvelope.self, from: payload)
        let snapshot = try XCTUnwrap(
            envelope.quoteSnapshot(for: .btcUSD, exchange: .okx, connectionState: .live)
        )
        let channel = try XCTUnwrap(envelope.arg)

        XCTAssertEqual(channel.channel, "tickers")
        XCTAssertEqual(snapshot.exchange, .okx)
        XCTAssertEqual(snapshot.pair, .btcUSD)
        XCTAssertEqual(snapshot.lastPrice, Decimal(string: "64215.7"))
        XCTAssertEqual(snapshot.absoluteChange, Decimal(string: "1215.7"))
        XCTAssertEqual(snapshot.percentChange, Decimal(string: "1.92968253968253968253968253968253968253"))
        XCTAssertEqual(snapshot.high24h, Decimal(string: "64888.8"))
        XCTAssertEqual(snapshot.low24h, Decimal(string: "62123.4"))
        XCTAssertEqual(snapshot.volume24h, Decimal(string: "1284.5567"))
        XCTAssertEqual(snapshot.connectionState, .live)
        let updatedAt = try XCTUnwrap(snapshot.updatedAt)
        XCTAssertEqual(updatedAt.timeIntervalSince1970, 1_717_436_715.123, accuracy: 0.0001)
    }

    func testTickerEnvelopeIgnoresControlMessageWithoutTickerData() throws {
        let payload = Data(
            #"""
            {
              "event": "subscribe",
              "arg": {
                "channel": "tickers",
                "instId": "BTC-USD"
              },
              "connId": "a4d3ae55"
            }
            """#.utf8
        )

        let envelope = try JSONDecoder().decode(OKXTickerEnvelope.self, from: payload)

        XCTAssertNil(envelope.quoteSnapshot(for: .btcUSD, exchange: .okx, connectionState: .live))
    }
}
