import CloudflareKit
import SwiftUI

extension TailEvent {
    var locationDescription: String? {
        let country = event?["request"]?["cf"]?["country"]?.stringValue
            .flatMap { Locale.current.localizedString(forRegionCode: $0) }
        let colo = event?["request"]?["cf"]?["colo"]?.stringValue
        let parts = [country, colo].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var title: String {
        if let method = requestMethod, let requestURL {
            let path = URL(string: requestURL).map { url in
                url.path().isEmpty ? "/" : url.path()
            } ?? requestURL
            if let responseStatus {
                return "\(method) \(path) · \(responseStatus)"
            }
            return "\(method) \(path)"
        }
        if let cron {
            return String(localized: .logsEventCronTitle(cron))
        }
        return logs?.first?.text ?? scriptName ?? ""
    }
}
