import Foundation

protocol AppSettingsStore: AnyObject {
    var selectedExchange: ExchangeID { get set }
    var selectedPair: TradingPair { get set }

    func setSelection(exchange: ExchangeID, pair: TradingPair)
}

final class UserDefaultsAppSettingsStore: AppSettingsStore {
    private enum Keys {
        static let selection = "selection"
        static let legacySelectedExchange = "selectedExchange"
        static let legacySelectedPair = "selectedPair"
    }

    private struct StoredSelection: Codable, Equatable {
        let exchange: ExchangeID
        let pair: TradingPair
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedExchange: ExchangeID {
        get {
            storedSelection().exchange
        }
        set {
            setSelection(exchange: newValue, pair: selectedPair)
        }
    }

    var selectedPair: TradingPair {
        get {
            storedSelection().pair
        }
        set {
            setSelection(exchange: selectedExchange, pair: newValue)
        }
    }

    func setSelection(exchange: ExchangeID, pair: TradingPair) {
        let storedSelection = StoredSelection(exchange: exchange, pair: pair)
        if let data = try? encoder.encode(storedSelection) {
            defaults.set(data, forKey: Keys.selection)
            defaults.removeObject(forKey: Keys.legacySelectedExchange)
            defaults.removeObject(forKey: Keys.legacySelectedPair)
        }
    }

    private func storedSelection() -> StoredSelection {
        if
            let data = defaults.data(forKey: Keys.selection),
            let storedSelection = try? decoder.decode(StoredSelection.self, from: data)
        {
            return storedSelection
        }

        let exchange = defaults.string(forKey: Keys.legacySelectedExchange).flatMap(ExchangeID.init(rawValue:)) ?? .coinbase
        let pair = defaults.string(forKey: Keys.legacySelectedPair).flatMap(TradingPair.init(persistenceKey:)) ?? .btcUSD
        return StoredSelection(exchange: exchange, pair: pair)
    }
}
