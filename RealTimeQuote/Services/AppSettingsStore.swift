import Foundation

protocol AppSettingsStore: AnyObject {
    var selectedExchange: ExchangeID { get set }
    var selectedPair: TradingPair { get set }
}

final class UserDefaultsAppSettingsStore: AppSettingsStore {
    private enum Keys {
        static let selectedExchange = "selectedExchange"
        static let selectedPair = "selectedPair"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedExchange: ExchangeID {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedExchange) else {
                return .coinbase
            }
            return ExchangeID(rawValue: rawValue) ?? .coinbase
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedExchange)
        }
    }

    var selectedPair: TradingPair {
        get {
            guard let persistenceKey = defaults.string(forKey: Keys.selectedPair) else {
                return .btcUSD
            }
            return TradingPair(persistenceKey: persistenceKey) ?? .btcUSD
        }
        set {
            defaults.set(newValue.persistenceKey, forKey: Keys.selectedPair)
        }
    }
}
