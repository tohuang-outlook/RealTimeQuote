import Foundation

struct AppSelection: Codable, Equatable {
    let exchange: ExchangeID
    let pair: TradingPair
}

protocol AppSettingsStore: AnyObject {
    var selectedExchange: ExchangeID { get set }
    var selectedPair: TradingPair { get set }
    var storedSelection: AppSelection? { get }

    func setSelection(exchange: ExchangeID, pair: TradingPair)
}

final class UserDefaultsAppSettingsStore: AppSettingsStore {
    private enum Keys {
        static let selection = "selection"
        static let legacySelectedExchange = "selectedExchange"
        static let legacySelectedPair = "selectedPair"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedExchange: ExchangeID {
        get {
            storedSelection?.exchange ?? .coinbase
        }
        set {
            setSelection(exchange: newValue, pair: selectedPair)
        }
    }

    var selectedPair: TradingPair {
        get {
            storedSelection?.pair ?? .btcUSD
        }
        set {
            setSelection(exchange: selectedExchange, pair: newValue)
        }
    }

    var storedSelection: AppSelection? {
        if
            let data = defaults.data(forKey: Keys.selection),
            let storedSelection = try? decoder.decode(AppSelection.self, from: data)
        {
            return storedSelection
        }

        let exchange = defaults.string(forKey: Keys.legacySelectedExchange).flatMap(ExchangeID.init(rawValue:))
        let pair = defaults.string(forKey: Keys.legacySelectedPair).flatMap(TradingPair.init(persistenceKey:))

        if let exchange, let pair {
            return AppSelection(exchange: exchange, pair: pair)
        }

        if let pair {
            return AppSelection(exchange: .coinbase, pair: pair)
        }

        return nil
    }

    func setSelection(exchange: ExchangeID, pair: TradingPair) {
        let storedSelection = AppSelection(exchange: exchange, pair: pair)
        if let data = try? encoder.encode(storedSelection) {
            defaults.set(data, forKey: Keys.selection)
            defaults.removeObject(forKey: Keys.legacySelectedExchange)
            defaults.removeObject(forKey: Keys.legacySelectedPair)
        }
    }
}
