import CloudflareKit
import SwiftUI

struct SecurityRuleRow: View {
    let rule: SecurityRule
    let number: Int
    let isEditing: Bool
    let onEdit: () -> Void
    let onToggle: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        HStack {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(SecurityRulePresentation.title(for: rule))
                        .font(.headline)
                    Text(.securityRuleOrder(number, SecurityRulePresentation.title(for: rule.action)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if rule.enabled == false {
                        Text(.securityDisabled)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !isEditing {
                Toggle(.securityEnabled, isOn: Binding(
                    get: { rule.enabled ?? true },
                    set: onToggle
                ))
                .labelsHidden()
                .accessibilityLabel(Text(.securityEnableRule(SecurityRulePresentation.title(for: rule))))
            }
        }
    }
}
