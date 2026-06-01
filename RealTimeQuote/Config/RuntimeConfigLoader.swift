import Foundation

struct RuntimeConfigLoadResult {
    let source: RuntimeConfigSource
    let config: RuntimeConfig?
    let error: Error?
}

struct RuntimeConfigLoader {
    private let fileManager: FileManager
    private let homeDirectoryURL: URL
    private let projectDirectoryURL: URL
    private let decoder = JSONDecoder()

    init(
        fileManager: FileManager = .default,
        homeDirectoryURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        projectDirectoryURL: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) {
        self.fileManager = fileManager
        self.homeDirectoryURL = homeDirectoryURL
        self.projectDirectoryURL = projectDirectoryURL
    }

    func load() throws -> RuntimeConfigLoadResult {
        let homeURL = homeDirectoryURL.appendingPathComponent(".real-time-quote/config.json")
        if fileManager.fileExists(atPath: homeURL.path) {
            return decodeConfig(at: homeURL, source: .homeDirectory(homeURL))
        }

        let projectURL = projectDirectoryURL.appendingPathComponent("Config/local.json")
        if fileManager.fileExists(atPath: projectURL.path) {
            return decodeConfig(at: projectURL, source: .projectLocal(projectURL))
        }

        return RuntimeConfigLoadResult(source: .fallback, config: nil, error: nil)
    }

    private func decodeConfig(at url: URL, source: RuntimeConfigSource) -> RuntimeConfigLoadResult {
        do {
            let data = try Data(contentsOf: url)
            let config = try decoder.decode(RuntimeConfig.self, from: data)
            return RuntimeConfigLoadResult(source: source, config: config, error: nil)
        } catch {
            return RuntimeConfigLoadResult(source: source, config: nil, error: error)
        }
    }
}
