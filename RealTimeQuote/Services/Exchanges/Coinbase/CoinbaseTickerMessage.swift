import Foundation

struct CoinbaseTickerMessage: Decodable {
    let channel: String?
    let timestamp: Date?
    let events: [Event]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decodeIfPresent(String.self, forKey: .channel)
        timestamp = try container.decodeDateIfPresent(forKey: .timestamp)
        events = try container.decodeIfPresent([Event].self, forKey: .events) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case channel
        case timestamp
        case events
    }

    struct Event: Decodable {
        let type: String?
        let tickers: [Ticker]

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            tickers = try container.decodeIfPresent([Ticker].self, forKey: .tickers) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case tickers
        }
    }

    struct Ticker: Decodable {
        let type: String?
        let productID: String
        let price: Decimal?
        let volume24h: Decimal?
        let low24h: Decimal?
        let high24h: Decimal?
        let pricePercentChange24h: Decimal?

        enum CodingKeys: String, CodingKey {
            case type
            case productID = "product_id"
            case price
            case volume24h = "volume_24_h"
            case low24h = "low_24_h"
            case high24h = "high_24_h"
            case pricePercentChange24h = "price_percent_chg_24_h"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            productID = try container.decode(String.self, forKey: .productID)
            price = try container.decodeDecimalIfPresent(forKey: .price)
            volume24h = try container.decodeDecimalIfPresent(forKey: .volume24h)
            low24h = try container.decodeDecimalIfPresent(forKey: .low24h)
            high24h = try container.decodeDecimalIfPresent(forKey: .high24h)
            pricePercentChange24h = try container.decodeDecimalIfPresent(forKey: .pricePercentChange24h)
        }
    }

    func quoteSnapshot(
        for pair: TradingPair,
        exchange: ExchangeID,
        connectionState: ConnectionState
    ) -> QuoteSnapshot? {
        guard
            let ticker = events.lazy
                .flatMap(\.tickers)
                .first(where: { $0.productID == pair.coinbaseProductID })
        else {
            return nil
        }

        return QuoteSnapshot(
            exchange: exchange,
            pair: pair,
            lastPrice: ticker.price,
            absoluteChange: ticker.absoluteChange24h,
            percentChange: ticker.pricePercentChange24h,
            high24h: ticker.high24h,
            low24h: ticker.low24h,
            volume24h: ticker.volume24h,
            updatedAt: timestamp,
            connectionState: connectionState
        )
    }
}

private extension KeyedDecodingContainer {
    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        guard let stringValue = try decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: stringValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid date value: \(stringValue)"
            )
        }
        return date
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

private extension CoinbaseTickerMessage.Ticker {
    var absoluteChange24h: Decimal? {
        guard
            let price,
            let percent = pricePercentChange24h,
            percent != -100
        else {
            return nil
        }

        let denominator = Decimal(1) + (percent / 100)
        guard denominator != 0 else { return nil }
        let openPrice = price / denominator
        return price - openPrice
    }
}
