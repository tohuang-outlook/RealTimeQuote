import CoreGraphics
import Foundation

protocol RouteVideoFrameWriting {
    var outputURL: URL { get }

    func start() throws
    func append(image: CGImage, at time: TimeInterval) async throws
    func finish() async throws -> URL
    func cancel()
}
