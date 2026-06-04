import Foundation

final class CoinGeckoReferenceStatsLoader: ReferenceStatsLoading {
    private let session: URLSession
    private let config: RuntimeConfig.CoinGecko?

    init(
        config: RuntimeConfig.CoinGecko?,
        session: URLSession = .shared
    ) {
        self.config = config
        self.session = session
    }

    func loadStats(for pair: TradingPair) async throws -> ReferenceStatsSnapshot {
        guard let config, let apiKey = config.apiKey, !apiKey.isEmpty else {
            return .empty
        }

        async let marketData = loadMarketData(for: pair, config: config, apiKey: apiKey)
        async let chartData = loadChartData(for: pair, config: config, apiKey: apiKey)

        let (marketCap, prices) = try await (marketData, chartData)

        let week52High = prices.max()
        let week52Low = prices.min()

        return ReferenceStatsSnapshot(
            week52High: week52High,
            week52Low: week52Low,
            marketCap: marketCap
        )
    }

    private func loadMarketData(
        for pair: TradingPair,
        config: RuntimeConfig.CoinGecko,
        apiKey: String
    ) async throws -> Decimal? {
        var components = URLComponents(url: config.baseURL.appendingPathComponent("/coins/markets"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "ids", value: pair.coinGeckoID),
            URLQueryItem(name: "precision", value: "full")
        ]

        guard let url = components?.url else {
            throw ReferenceStatsLoaderError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: config.headerName)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let payload = try JSONDecoder().decode([CoinGeckoMarketsResponse].self, from: data)
        return payload.first?.marketCap
    }

    private func loadChartData(
        for pair: TradingPair,
        config: RuntimeConfig.CoinGecko,
        apiKey: String
    ) async throws -> [Decimal] {
        var components = URLComponents(url: config.baseURL.appendingPathComponent("/coins/\(pair.coinGeckoID)/market_chart"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "days", value: "365"),
            URLQueryItem(name: "interval", value: "daily"),
            URLQueryItem(name: "precision", value: "full")
        ]

        guard let url = components?.url else {
            throw ReferenceStatsLoaderError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: config.headerName)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let payload = try JSONDecoder().decode(CoinGeckoMarketChartResponse.self, from: data)
        return payload.prices.compactMap { $0.value }
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReferenceStatsLoaderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ReferenceStatsLoaderError.invalidResponse
        }
    }
}

private struct CoinGeckoMarketsResponse: Decodable {
    let marketCap: Decimal?

    enum CodingKeys: String, CodingKey {
        case marketCap = "market_cap"
    }
}

private struct CoinGeckoMarketChartResponse: Decodable {
    struct PricePoint: Decodable {
        let timestamp: Double
        let value: Decimal?

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            timestamp = try container.decode(Double.self)

            if let decimal = try? container.decode(Decimal.self) {
                value = decimal
            } else if let doubleValue = try? container.decode(Double.self) {
                value = Decimal(doubleValue)
            } else {
                value = nil
            }
        }
    }

    let prices: [PricePoint]
}

enum ReferenceStatsLoaderError: Error {
    case invalidRequest
    case invalidResponse
}
