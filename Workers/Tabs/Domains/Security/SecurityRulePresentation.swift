import CloudflareKit
import SwiftUI

enum SecurityRuleEditorMode: Identifiable {
    case create
    case edit(SecurityRule)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let rule): rule.id
        }
    }
}

enum SecurityRulePresentation {
    static let editableActions = ["managed_challenge", "block", "js_challenge"]

    static func title(for action: String) -> String {
        switch action {
        case "managed_challenge": String(localized: .securityActionManagedChallenge)
        case "block": String(localized: .securityActionBlock)
        case "js_challenge": String(localized: .securityActionJavaScriptChallenge)
        case "challenge": String(localized: .securityActionChallenge)
        case "skip": String(localized: .securityActionSkip)
        case "log": String(localized: .securityActionLog)
        default: action
        }
    }

    static func title(for rule: SecurityRule) -> String {
        let description = rule.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return description.isEmpty ? String(localized: .securityUntitled) : description
    }
}
