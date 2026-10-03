import Foundation

struct TripSegmentInput: Equatable, Identifiable {
    let id: UUID
    var order: Int
    var fromCityName: String
    var toCityName: String
    var transportType: TripTransportType
    var date: Date

    var isComplete: Bool {
        !fromCityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !toCityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func empty(order: Int) -> TripSegmentInput {
        TripSegmentInput(
            id: UUID(),
            order: order,
            fromCityName: "",
            toCityName: "",
            transportType: .plane,
            date: .now
        )
    }
}
