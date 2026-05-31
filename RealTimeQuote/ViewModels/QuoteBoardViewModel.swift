import Foundation

@MainActor
final class QuoteBoardViewModel: ObservableObject {
    @Published private(set) var snapshot: QuoteSnapshot
    @Published private(set) var selectedExchange: ExchangeID
    @Published private(set) var selectedPair: TradingPair

    private let settingsStore: AppSettingsStore

    static let preview = QuoteBoardViewModel(settingsStore: makePreviewSettingsStore())

    init(settingsStore: AppSettingsStore) {
        let selectedExchange = settingsStore.selectedExchange
        let selectedPair = settingsStore.selectedPair

        self.settingsStore = settingsStore
        self.selectedExchange = selectedExchange
        self.selectedPair = selectedPair
        self.snapshot = QuoteSnapshot.placeholder(for: selectedPair, exchange: selectedExchange)
    }

    func selectExchange(_ exchange: ExchangeID) {
        guard exchange != selectedExchange else { return }

        selectedExchange = exchange
        settingsStore.selectedExchange = exchange
        snapshot = QuoteSnapshot.placeholder(for: selectedPair, exchange: exchange)
    }

    func selectPair(_ pair: TradingPair) {
        guard pair != selectedPair else { return }

        selectedPair = pair
        settingsStore.selectedPair = pair
        snapshot = QuoteSnapshot.placeholder(for: pair, exchange: selectedExchange)
    }

    private static func makePreviewSettingsStore() -> AppSettingsStore {
        let defaults = UserDefaults(suiteName: "RealTimeQuote.QuoteBoardViewModel.preview") ?? .standard
        defaults.removePersistentDomain(forName: "RealTimeQuote.QuoteBoardViewModel.preview")
        return UserDefaultsAppSettingsStore(defaults: defaults)
    }
}
