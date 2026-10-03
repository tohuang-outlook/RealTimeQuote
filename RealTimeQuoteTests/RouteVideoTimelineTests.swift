import XCTest
@testable import RealTimeQuote

final class RouteVideoTimelineTests: XCTestCase {
    func testTimelineComputesSegmentSpansAndTotalDuration() {
        let segments = [
            makeSegment(from: "Bologna", to: "Istanbul", transport: .plane),
            makeSegment(from: "Istanbul", to: "Moscow", transport: .train)
        ]

        let timeline = RouteVideoTimeline.make(
            segments: segments,
            configuration: .default
        )

        XCTAssertEqual(timeline.segmentTimings.count, 2)
        XCTAssertEqual(timeline.segmentTimings[0].startTime, 0, accuracy: 0.0001)
        XCTAssertEqual(timeline.segmentTimings[0].endTime, 6, accuracy: 0.0001)
        XCTAssertEqual(timeline.segmentTimings[0].endTime, timeline.segmentTimings[1].startTime, accuracy: 0.0001)
        XCTAssertEqual(timeline.totalDuration, timeline.segmentTimings[1].endTime, accuracy: 0.0001)
    }

    func testTimelineProducesExpectedFrameTimestampsAtThirtyFPS() {
        let timeline = RouteVideoTimeline(
            segmentTimings: [
                .init(segmentID: UUID(), startTime: 0, endTime: 2)
            ],
            totalDuration: 2,
            frameDuration: 1.0 / 30.0
        )

        let frameTimes = timeline.frameTimestamps()

        XCTAssertEqual(frameTimes.first ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(frameTimes.count, 60)
        XCTAssertEqual(frameTimes.last ?? -1, 59.0 / 30.0, accuracy: 0.0001)
    }

    private func makeSegment(from: String, to: String, transport: TripTransportType) -> ResolvedTripSegment {
        ResolvedTripSegment(
            id: UUID(),
            fromCityName: from,
            toCityName: to,
            fromCoordinate: .init(latitude: 44.4949, longitude: 11.3426),
            toCoordinate: .init(latitude: 41.0082, longitude: 28.9784),
            transportType: transport,
            dateLabel: "2026-07-01"
        )
    }
}
