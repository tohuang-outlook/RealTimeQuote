import CoreGraphics
import Foundation

struct RouteVideoExportConfiguration: Equatable {
    let renderSize: CGSize
    let framesPerSecond: Int32

    static let `default` = RouteVideoExportConfiguration(
        renderSize: CGSize(width: 1280, height: 720),
        framesPerSecond: 30
    )
}
