import Foundation

struct TelemetryQueryResponse: Decodable {
    struct Events: Decodable {
        let events: [ObservabilityEvent]?
    }

    let events: Events?
}
