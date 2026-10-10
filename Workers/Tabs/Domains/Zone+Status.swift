import CloudflareKit
import SwiftUI

extension Zone {
    var statusTitle: String {
        if paused == true { return String(localized: .domainsStatusPaused) }
        switch status {
        case "active": return String(localized: .domainsStatusActive)
        case "pending": return String(localized: .domainsStatusPending)
        case "initializing": return String(localized: .domainsStatusInitializing)
        case "moved": return String(localized: .domainsStatusMoved)
        case "deleted": return String(localized: .domainsStatusDeleted)
        case "deactivated": return String(localized: .domainsStatusDeactivated)
        default: return status.capitalizedFirst
        }
    }

    var statusSymbol: String {
        if paused == true { return "pause.circle.fill" }
        switch status {
        case "active": return "checkmark.seal.fill"
        case "pending", "initializing": return "clock.fill"
        default: return "exclamationmark.circle.fill"
        }
    }

    var statusColor: Color {
        if paused == true { return .secondary }
        switch status {
        case "active": return .orange
        case "pending", "initializing": return .yellow
        default: return .red
        }
    }

    var subtitle: String {
        [statusTitle, plan?.name].compactMap { $0 }.joined(separator: " · ")
    }
}
