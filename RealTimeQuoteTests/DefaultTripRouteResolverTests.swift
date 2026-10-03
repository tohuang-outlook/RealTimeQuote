import XCTest
@testable import RealTimeQuote

final class DefaultTripRouteResolverTests: XCTestCase {
    func testResolverBuildsOrderedSegmentsForKnownCities() async throws {
        let resolver = DefaultTripRouteResolver(cityResolver: StaticCityResolver())
        let input = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                order: 1,
                fromCityName: "Istanbul",
                toCityName: "Moscow",
                transportType: .train,
                date: Date(timeIntervalSince1970: 1_783_209_600)
            ),
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                order: 0,
                fromCityName: "Bologna",
                toCityName: "Istanbul",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_123_200)
            )
        ]

        let result = try await resolver.resolve(segments: input)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        XCTAssertEqual(result[0].fromCityName, "Bologna")
        XCTAssertEqual(result[0].transportType, .plane)
        XCTAssertEqual(result[0].dateLabel, "2026-07-04")
        XCTAssertEqual(result[1].id, UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        XCTAssertEqual(result[1].fromCityName, "Istanbul")
        XCTAssertEqual(result[1].transportType, .train)
        XCTAssertEqual(result[1].dateLabel, "2026-07-05")
    }

    func testResolverSupportsSanFranciscoToTaipeiRoute() async throws {
        let resolver = DefaultTripRouteResolver(cityResolver: StaticCityResolver())
        let input = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                order: 0,
                fromCityName: "San Francisco",
                toCityName: "Taipei",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_296_000)
            )
        ]

        let result = try await resolver.resolve(segments: input)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].fromCityName, "San Francisco")
        XCTAssertEqual(result[0].toCityName, "Taipei")
        XCTAssertEqual(result[0].fromCoordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(result[0].fromCoordinate.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(result[0].toCoordinate.latitude, 25.0330, accuracy: 0.0001)
        XCTAssertEqual(result[0].toCoordinate.longitude, 121.5654, accuracy: 0.0001)
        XCTAssertEqual(result[0].dateLabel, "2026-07-06")
    }

    func testResolverSupportsAirportCodeAliasesForCities() async throws {
        let resolver = DefaultTripRouteResolver(cityResolver: StaticCityResolver())
        let firstInput = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                order: 0,
                fromCityName: "SFO",
                toCityName: "TPE",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_382_400)
            )
        ]

        let firstResult = try await resolver.resolve(segments: firstInput)

        XCTAssertEqual(firstResult.count, 1)
        XCTAssertEqual(firstResult[0].fromCityName, "SFO")
        XCTAssertEqual(firstResult[0].toCityName, "TPE")
        XCTAssertEqual(firstResult[0].fromCoordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(firstResult[0].fromCoordinate.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(firstResult[0].toCoordinate.latitude, 25.0330, accuracy: 0.0001)
        XCTAssertEqual(firstResult[0].toCoordinate.longitude, 121.5654, accuracy: 0.0001)
        XCTAssertEqual(firstResult[0].dateLabel, "2026-07-07")

        let secondInput = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                order: 0,
                fromCityName: "JFK",
                toCityName: "HND",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_468_800)
            )
        ]

        let secondResult = try await resolver.resolve(segments: secondInput)

        XCTAssertEqual(secondResult.count, 1)
        XCTAssertEqual(secondResult[0].fromCityName, "JFK")
        XCTAssertEqual(secondResult[0].toCityName, "HND")
        XCTAssertEqual(secondResult[0].fromCoordinate.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(secondResult[0].fromCoordinate.longitude, -74.0060, accuracy: 0.0001)
        XCTAssertEqual(secondResult[0].toCoordinate.latitude, 35.6762, accuracy: 0.0001)
        XCTAssertEqual(secondResult[0].toCoordinate.longitude, 139.6503, accuracy: 0.0001)
        XCTAssertEqual(secondResult[0].dateLabel, "2026-07-08")

        let thirdInput = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                order: 0,
                fromCityName: "LHR",
                toCityName: "CDG",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_555_200)
            )
        ]

        let thirdResult = try await resolver.resolve(segments: thirdInput)

        XCTAssertEqual(thirdResult.count, 1)
        XCTAssertEqual(thirdResult[0].fromCityName, "LHR")
        XCTAssertEqual(thirdResult[0].toCityName, "CDG")
        XCTAssertEqual(thirdResult[0].fromCoordinate.latitude, 51.5072, accuracy: 0.0001)
        XCTAssertEqual(thirdResult[0].fromCoordinate.longitude, -0.1276, accuracy: 0.0001)
        XCTAssertEqual(thirdResult[0].toCoordinate.latitude, 48.8566, accuracy: 0.0001)
        XCTAssertEqual(thirdResult[0].toCoordinate.longitude, 2.3522, accuracy: 0.0001)
        XCTAssertEqual(thirdResult[0].dateLabel, "2026-07-09")

        let fourthInput = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                order: 0,
                fromCityName: "LAX",
                toCityName: "NRT",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_641_600)
            )
        ]

        let fourthResult = try await resolver.resolve(segments: fourthInput)

        XCTAssertEqual(fourthResult.count, 1)
        XCTAssertEqual(fourthResult[0].fromCityName, "LAX")
        XCTAssertEqual(fourthResult[0].toCityName, "NRT")
        XCTAssertEqual(fourthResult[0].fromCoordinate.latitude, 34.0522, accuracy: 0.0001)
        XCTAssertEqual(fourthResult[0].fromCoordinate.longitude, -118.2437, accuracy: 0.0001)
        XCTAssertEqual(fourthResult[0].toCoordinate.latitude, 35.6762, accuracy: 0.0001)
        XCTAssertEqual(fourthResult[0].toCoordinate.longitude, 139.6503, accuracy: 0.0001)
        XCTAssertEqual(fourthResult[0].dateLabel, "2026-07-10")

        let fifthInput = [
            TripSegmentInput(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
                order: 0,
                fromCityName: "DXB",
                toCityName: "SYD",
                transportType: .plane,
                date: Date(timeIntervalSince1970: 1_783_728_000)
            )
        ]

        let fifthResult = try await resolver.resolve(segments: fifthInput)

        XCTAssertEqual(fifthResult.count, 1)
        XCTAssertEqual(fifthResult[0].fromCityName, "DXB")
        XCTAssertEqual(fifthResult[0].toCityName, "SYD")
        XCTAssertEqual(fifthResult[0].fromCoordinate.latitude, 25.2048, accuracy: 0.0001)
        XCTAssertEqual(fifthResult[0].fromCoordinate.longitude, 55.2708, accuracy: 0.0001)
        XCTAssertEqual(fifthResult[0].toCoordinate.latitude, -33.8688, accuracy: 0.0001)
        XCTAssertEqual(fifthResult[0].toCoordinate.longitude, 151.2093, accuracy: 0.0001)
        XCTAssertEqual(fifthResult[0].dateLabel, "2026-07-11")
    }

    func testResolverThrowsIncompleteSegmentErrorForBlankCityInput() async {
        let resolver = DefaultTripRouteResolver(cityResolver: StaticCityResolver())
        let input = [
            TripSegmentInput(
                id: UUID(),
                order: 0,
                fromCityName: "   ",
                toCityName: "Moscow",
                transportType: .plane,
                date: .now
            )
        ]

        do {
            _ = try await resolver.resolve(segments: input)
            XCTFail("Expected incomplete segment error")
        } catch let error as TripRouteResolutionError {
            XCTAssertEqual(error, .incompleteSegment(segmentIndex: 0))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testResolverThrowsUnresolvedCityErrorForUnknownCity() async {
        let resolver = DefaultTripRouteResolver(cityResolver: StaticCityResolver())
        let input = [
            TripSegmentInput(
                id: UUID(),
                order: 0,
                fromCityName: "Atlantis",
                toCityName: "Moscow",
                transportType: .plane,
                date: .now
            )
        ]

        do {
            _ = try await resolver.resolve(segments: input)
            XCTFail("Expected unresolved city error")
        } catch let error as TripRouteResolutionError {
            XCTAssertEqual(error, .unresolvedCity(segmentIndex: 0, cityName: "Atlantis"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
