import SwiftUI

@main
struct RealTimeQuoteApp: App {
    @StateObject private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup("Real Time Quote") {
            QuoteBoardWindowRootView(makeViewModel: dependencies.makeQuoteBoardViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: WindowStyler.defaultSize.width, height: WindowStyler.defaultSize.height)
    }
}

private struct QuoteBoardWindowRootView: View {
    @StateObject private var viewModel: QuoteBoardViewModel

    init(makeViewModel: @escaping @MainActor () -> QuoteBoardViewModel) {
        _viewModel = StateObject(wrappedValue: makeViewModel())
    }

    var body: some View {
        WindowStyler.makeRootView {
            QuoteBoardView(viewModel: viewModel)
        }
    }
}
