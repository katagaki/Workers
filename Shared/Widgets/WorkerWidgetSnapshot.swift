import CloudflareKit
import Foundation

nonisolated struct WorkerWidgetSnapshot: Codable, Sendable {
    struct Point: Codable, Identifiable, Sendable {
        let date: Date
        let requests: Int
        let errors: Int
        var id: Date { date }
    }
    let worker: WorkerEntity
    let date: Date
    let points: [Point]
    var requests: Int { points.reduce(0) { $0 + $1.requests } }
    var errors: Int { points.reduce(0) { $0 + $1.errors } }
    var successRate: Double { requests > 0 ? Double(max(0, requests - errors)) / Double(requests) : 0 }

    init(worker: WorkerEntity, date: Date = .now, analytics: [WorkerAnalyticsPoint]) {
        self.worker = worker
        self.date = date
        self.points = analytics.sorted { $0.date < $1.date }.map { Point(date: $0.date, requests: $0.requests, errors: $0.errors) }
    }

    init(worker: WorkerEntity, date: Date, points: [Point]) {
        self.worker = worker
        self.date = date
        self.points = points
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "workers"
        components.host = "worker"
        components.queryItems = [URLQueryItem(name: "account", value: worker.accountId), URLQueryItem(name: "name", value: worker.name)]
        return components.url
    }
    var cacheKey: String { "Widget.\(worker.id)" }
    static let sample = Self(worker: WorkerEntity(accountId: "preview", name: "schale-gateway"), date: .now, points: (0..<24).map { hour in
        Point(date: .now.addingTimeInterval(Double(hour - 24) * 3600), requests: 1800 + (hour * 673 % 2400), errors: hour * 11 % 29)
    })
}
