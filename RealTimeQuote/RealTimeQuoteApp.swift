import SwiftUI

@main
struct TravelMapApp: App {
    var body: some Scene {
        WindowGroup("Y Companion") {
            TripPlannerRootView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1320, height: 860)
    }
}

private struct TripPlannerRootView: View {
    var body: some View {
        WindowStyler.makePlannerRootView {
            TripPlannerView()
        }
    }
}
