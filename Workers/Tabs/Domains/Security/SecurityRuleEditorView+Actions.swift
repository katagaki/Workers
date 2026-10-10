import CloudflareKit
import SwiftUI

extension SecurityRuleEditorView {
    func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let current = try await client.securityRuleset(zoneId: zone.id)
            var payload = input
            payload.description = input.description.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.expression = input.expression.trimmingCharacters(in: .whitespacesAndNewlines)
            let updated: SecurityRuleset
            switch mode {
            case .create:
                updated = try await client.createSecurityRule(zoneId: zone.id, rulesetId: current.id, input: payload)
            case .edit(let original):
                guard let rulesetId = current.id, let latest = current.rules.first(where: { $0.id == original.id }) else {
                    errorMessage = String(localized: .securityRuleMissing)
                    return
                }
                guard latest.expression == original.expression, latest.action == original.action,
                      latest.description == original.description, latest.enabled == original.enabled,
                      latest.actionParameters == original.actionParameters, latest.logging == original.logging,
                      latest.ratelimit == original.ratelimit, latest.exposedCredentialCheck == original.exposedCredentialCheck,
                      latest.version == original.version else {
                    errorMessage = String(localized: .securityRuleChanged)
                    return
                }
                payload.actionParameters = latest.actionParameters
                payload.logging = latest.logging
                payload.ref = latest.ref
                payload.ratelimit = latest.ratelimit
                payload.exposedCredentialCheck = latest.exposedCredentialCheck
                updated = try await client.updateSecurityRule(zoneId: zone.id, rulesetId: rulesetId, ruleId: original.id, input: payload)
            }
            onSave(updated)
            dismiss()
        } catch {
            show(error)
        }
    }

    func delete() async {
        guard !isSaving, case .edit(let rule) = mode else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let current = try await client.securityRuleset(zoneId: zone.id)
            guard let rulesetId = current.id else {
                errorMessage = String(localized: .securityRuleMissing)
                return
            }
            let updated = try await client.deleteSecurityRule(zoneId: zone.id, rulesetId: rulesetId, ruleId: rule.id)
            onSave(updated)
            dismiss()
        } catch {
            show(error)
        }
    }

    private func show(_ error: Error) {
        if case CloudflareError.http(statusCode: 403) = error {
            errorMessage = String(localized: .securityPermissionMessage)
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
