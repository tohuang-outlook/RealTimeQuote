import XCTest
@testable import RealTimeQuote

@MainActor
final class AppDependenciesFactoryTests: XCTestCase {
    func testFactoryCreatesDistinctViewModelsForDifferentWindows() {
        let suiteName = "AppDependenciesFactoryTests.\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = UserDefaultsAppSettingsStore(defaults: defaults)
        let dependencies = AppDependencies(
            settingsStore: settingsStore,
            config: nil
        )

        let first = dependencies.makeQuoteBoardViewModel()
        let second = dependencies.makeQuoteBoardViewModel()

        XCTAssertFalse(first === second)
    }
}
