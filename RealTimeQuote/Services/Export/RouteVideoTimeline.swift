import Foundation

struct RouteVideoTimeline: Equatable {
    struct SegmentTiming: Equatable {
        let segmentID: UUID
        let startTime: TimeInterval
        let endTime: TimeInterval
    }

    let segmentTimings: [SegmentTiming]
    let totalDuration: TimeInterval
    let frameDuration: TimeInterval

    func frameTimestamps() -> [TimeInterval] {
        guard totalDuration > 0, frameDuration > 0 else { return [] }
        let frameCount = Int((totalDuration / frameDuration).rounded(.down))
        return (0..<frameCount).map { TimeInterval($0) * frameDuration }
    }

    static func make(
        segments: [ResolvedTripSegment],
        configuration: RouteVideoExportConfiguration
    ) -> RouteVideoTimeline {
        let frameDuration = 1.0 / TimeInterval(configuration.framesPerSecond)
        // Four readable beats per stop: establish the city, reveal the route,
        // arrive at the destination, then leave a short handoff to the next leg.
        let secondsPerSegment: TimeInterval = 6.0
        var cursor: TimeInterval = 0

        let timings = segments.map { segment in
            let timing = SegmentTiming(
                segmentID: segment.id,
                startTime: cursor,
                endTime: cursor + secondsPerSegment
            )
            cursor += secondsPerSegment
            return timing
        }

        return RouteVideoTimeline(
            segmentTimings: timings,
            totalDuration: cursor,
            frameDuration: frameDuration
        )
    }
}
