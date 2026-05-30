import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let quoteBoardTitle = "Real Time Quote"

    static func live() -> AppDependencies {
        AppDependencies()
    }
}
