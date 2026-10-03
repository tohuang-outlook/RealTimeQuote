import CoreGraphics
import Foundation

@MainActor
protocol RouteVideoRendererHosting {
    func prepare() async throws
    func renderFrame(at time: TimeInterval) async throws -> CGImage
    func tearDown() async
}
