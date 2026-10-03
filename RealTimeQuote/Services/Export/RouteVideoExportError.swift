import Foundation

enum RouteVideoExportError: LocalizedError, Equatable {
    case rendererLoadFailed
    case rendererTimedOut
    case rendererFrameFailed
    case frameCaptureFailed
    case writerFailed(String)
    case outputFileMissing

    var errorDescription: String? {
        switch self {
        case .rendererLoadFailed:
            return "Preview renderer failed to load during export"
        case .rendererTimedOut:
            return "Preview renderer timed out during export"
        case .rendererFrameFailed:
            return "Preview renderer failed to render a frame"
        case .frameCaptureFailed:
            return "Export frame capture failed"
        case let .writerFailed(message):
            return "Video writer failed during export: \(message)"
        case .outputFileMissing:
            return "Export finished without producing a video file"
        }
    }
}
