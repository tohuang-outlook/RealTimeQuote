import Foundation

enum RuntimeConfigSource: Equatable {
    case homeDirectory(URL)
    case projectLocal(URL)
    case fallback
}
