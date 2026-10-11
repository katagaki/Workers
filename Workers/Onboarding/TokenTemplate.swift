import Foundation

enum TokenTemplate {
    // Unknown keys are silently dropped by the dashboard instead of failing.
    private static let permissions: [(key: String, type: String)] = [
        ("account_settings", "read"),
        ("user_details", "read"),
        ("workers_scripts", "edit"),
        ("workers_tail", "read"),
        ("workers_observability", "read"),
        ("ai", "read"),
        ("ai", "edit"),
        ("account_analytics", "read"),
        ("workers_kv_storage", "read"),
        ("workers_r2", "read"),
        ("d1", "read"),
        ("zone", "edit"),
        ("zone_settings", "edit"),
        ("zone_waf", "edit"),
        ("dns", "edit"),
        ("analytics", "read"),
        ("cache", "purge"),
        ("workers_routes", "read")
    ]

    static var url: URL {
        let permissionObjects = permissions.map { ["key": $0.key, "type": $0.type] }
        let permissionData = (try? JSONSerialization.data(withJSONObject: permissionObjects)) ?? Data()
        var components = URLComponents(string: "https://dash.cloudflare.com/profile/api-tokens")!
        components.queryItems = [
            URLQueryItem(name: "permissionGroupKeys", value: String(decoding: permissionData, as: UTF8.self)),
            URLQueryItem(name: "accountId", value: "*"),
            URLQueryItem(name: "zoneId", value: "all"),
            URLQueryItem(name: "name", value: "Workers for iOS")
        ]
        return components.url!
    }
}
