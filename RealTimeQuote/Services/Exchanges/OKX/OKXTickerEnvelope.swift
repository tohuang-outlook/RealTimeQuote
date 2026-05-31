import Foundation

struct OKXTickerEnvelope: Decodable {
    let arg: Channel?
    let data: [Ticker]?
    let event: String?

    struct Channel: Decodable {
        let channel: String
        let instID: String?

        enum CodingKeys: String, CodingKey {
            case channel
            case instID = "instId"
        }
    }

    struct Ticker: Decodable {
        let instID: String
        let last: Decimal?
        let open24h: Decimal?
        let high24h: Decimal?
        let low24h: Decimal?
        let vol24h: Decimal?
        let timestamp: Date?

        enum CodingKeys: String, CodingKey {
            case instID = "instId"
            case last
            case open24h
            case high24h
            case low24h
            case vol24h
            case timestamp = "ts"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            instID = try container.decode(String.self, forKey: .instID)
            last = try container.decodeDecimalIfPresent(forKey: .last)
            open24h = try container.decodeDecimalIfPresent(forKey: .open24h)
            high24h = try container.decodeDecimalIfPresent(forKey: .high24h)
            low24h = try container.decodeDecimalIfPresent(forKey: .low24h)
            vol24h = try container.decodeDecimalIfPresent(forKey: .vol24h)
            timestamp = try container.decodeUnixMillisecondsDateIfPresent(forKey: .timestamp)
        }
    }

    func quoteSnapshot(
        for pair: TradingPair,
        exchange: ExchangeID,
        connectionState: ConnectionState
    ) -> QuoteSnapshot? {
        guard let ticker = data?.first(where: { $0.instID == pair.okxInstrumentID }) else {
            return nil
        }

        return QuoteSnapshot(
            exchange: exchange,
            pair: pair,
            lastPrice: ticker.last,
            absoluteChange: ticker.absoluteChange24h,
            percentChange: ticker.percentChange24h,
            high24h: ticker.high24h,
            low24h: ticker.low24h,
            volume24h: ticker.vol24h,
            updatedAt: ticker.timestamp,
            connectionState: connectionState
        )
    }
}

private extension KeyedDecodingContainer {
    func decodeUnixMillisecondsDateIfPresent(forKey key: Key) throws -> Date? {
        guard let stringValue = try decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        guard let milliseconds = Double(stringValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid Unix milliseconds value: \(stringValue)"
            )
        }
        return Date(timeIntervalSince1970: milliseconds / 1_000)
    }

    func decodeDecimalIfPresent(forKey key: Key) throws -> Decimal? {
        guard let stringValue = try decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        guard let decimalValue = Decimal(string: stringValue, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid decimal value: \(stringValue)"
            )
        }
        return decimalValue
    }
}

private extension OKXTickerEnvelope.Ticker {
    var absoluteChange24h: Decimal? {
        guard let last, let open24h else { return nil }
        return last - open24h
    }

    var percentChange24h: Decimal? {
        guard let absoluteChange24h, let open24h, open24h != 0 else { return nil }
        return (absoluteChange24h / open24h) * 100
    }
}
