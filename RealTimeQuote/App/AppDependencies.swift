import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let quoteBoardViewModel: QuoteBoardViewModel

    init(quoteBoardViewModel: QuoteBoardViewModel) {
        self.quoteBoardViewModel = quoteBoardViewModel
    }

    static func live() -> AppDependencies {
        let settingsStore = UserDefaultsAppSettingsStore()
        let viewModel = QuoteBoardViewModel(settingsStore: settingsStore)
        return AppDependencies(quoteBoardViewModel: viewModel)
    }
}
