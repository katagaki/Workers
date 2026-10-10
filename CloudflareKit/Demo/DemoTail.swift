import Foundation

enum DemoTail {
    static func run(scriptName: String, continuation: AsyncThrowingStream<TailEvent, Error>.Continuation) async throws {
        let decoder = CloudflareJSON.makeDecoder()
        let countries = ["JP", "US", "DE", "SG", "GB", "AU", "CA"]
        let colos = ["NRT", "SJC", "FRA", "SIN", "LHR", "SYD", "YYZ"]
        var index = 0
        while !Task.isCancelled {
            let event = DemoTraffic.event(scriptName: scriptName, index: index)
            let timestamp = Date.now.timeIntervalSince1970 * 1000
            let trigger: [String: Any]
            switch event.eventType {
            case "scheduled":
                trigger = ["cron": event.trigger, "scheduledTime": timestamp]
            case "queue":
                trigger = ["queue": event.trigger, "batchSize": 10]
            default:
                var request: [String: Any] = [
                    "method": event.method ?? "GET",
                    "cf": ["country": countries[index % countries.count], "colo": colos[index % colos.count]]
                ]
                if let url = event.url { request["url"] = url }
                trigger = ["request": request, "response": ["status": event.status ?? 200]]
            }
            let payload: [String: Any] = [
                "outcome": event.exception == nil ? "ok" : "exception",
                "scriptName": scriptName,
                "eventTimestamp": timestamp,
                "logs": event.logs.map { ["message": [$0.message], "level": $0.level, "timestamp": timestamp] },
                "exceptions": event.exception.map { [["name": $0.name, "message": $0.message, "timestamp": timestamp]] } ?? [],
                "event": trigger
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let tailEvent = try? decoder.decode(TailEvent.self, from: data) {
                continuation.yield(tailEvent)
            }
            index += 1
            try await Task.sleep(for: .milliseconds(700 + Int(DemoData.noise(index) * 1600)))
        }
    }
}
