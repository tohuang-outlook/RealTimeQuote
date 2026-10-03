import Foundation

struct RealRouteVideoExporter: RouteVideoExporting {
    let configuration: RouteVideoExportConfiguration
    let rendererHostFactory: @MainActor ([ResolvedTripSegment], RouteVideoTimeline, RouteVideoExportConfiguration) -> RouteVideoRendererHosting
    let frameWriterFactory: (RouteVideoTimeline, RouteVideoExportConfiguration, URL) -> RouteVideoFrameWriting

    init(
        configuration: RouteVideoExportConfiguration = .default,
        rendererHostFactory: @escaping @MainActor ([ResolvedTripSegment], RouteVideoTimeline, RouteVideoExportConfiguration) -> RouteVideoRendererHosting,
        frameWriterFactory: @escaping (RouteVideoTimeline, RouteVideoExportConfiguration, URL) -> RouteVideoFrameWriting
    ) {
        self.configuration = configuration
        self.rendererHostFactory = rendererHostFactory
        self.frameWriterFactory = frameWriterFactory
    }

    @MainActor
    func export(segments: [ResolvedTripSegment]) async throws -> URL {
        let timeline = RouteVideoTimeline.make(segments: segments, configuration: configuration)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        let rendererHost = rendererHostFactory(segments, timeline, configuration)
        let frameWriter = frameWriterFactory(timeline, configuration, outputURL)

        do {
            try frameWriter.start()
            try await rendererHost.prepare()

            for time in timeline.frameTimestamps() {
                let image = try await rendererHost.renderFrame(at: time)
                try await frameWriter.append(image: image, at: time)
            }

            let finalURL = try await frameWriter.finish()
            await rendererHost.tearDown()
            return finalURL
        } catch let error as RouteVideoExportError {
            frameWriter.cancel()
            await rendererHost.tearDown()
            throw error
        } catch {
            frameWriter.cancel()
            await rendererHost.tearDown()
            throw RouteVideoExportError.writerFailed(error.localizedDescription)
        }
    }
}
