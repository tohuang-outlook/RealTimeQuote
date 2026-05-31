import SwiftUI

@main
struct RealTimeQuoteApp: App {
    @StateObject private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup("Real Time Quote") {
            WindowStyler.makeRootView {
                QuoteBoardView(viewModel: dependencies.quoteBoardViewModel)
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: WindowStyler.defaultSize.width, height: WindowStyler.defaultSize.height)
    }
}
