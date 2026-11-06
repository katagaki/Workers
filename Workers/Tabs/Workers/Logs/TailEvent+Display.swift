import CloudflareKit
import SwiftUI

extension TailEvent {
    var countryName: String? {
        event?["request"]?["cf"]?["country"]?.stringValue
            .flatMap { Locale.current.localizedString(forRegionCode: $0) }
    }

    var dataCenter: String? {
        event?["request"]?["cf"]?["colo"]?.stringValue
    }

    var message: String {
        if let exception = exceptions?.first {
            return exception.message ?? exception.name ?? ""
        }
        if let text = logs?.first?.text {
            return text
        }
        if let cron {
            return String(localized: .logsEventCronTitle(cron))
        }
        return requestMethod == nil ? scriptName ?? "" : ""
    }
}
