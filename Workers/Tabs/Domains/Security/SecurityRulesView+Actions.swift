import CloudflareKit
import SwiftUI

extension SecurityRulesView {
    func reload() async {
        guard !isWorking, editorMode == nil else { return }
        await ruleset.refresh { try await client.securityRuleset(zoneId: zone.id) }
        if ruleset.error == nil { mutationNeedsPermission = false }
    }

    func setEnabled(_ rule: SecurityRule, enabled: Bool) async {
        guard canModify, let rulesetId = ruleset.value?.id else { return }
        await performMutation {
            try await client.setSecurityRuleEnabled(zoneId: zone.id, rulesetId: rulesetId, ruleId: rule.id, enabled: enabled)
        }
    }

    func delete(_ rule: SecurityRule) async {
        guard canModify, let rulesetId = ruleset.value?.id else { return }
        await performMutation {
            try await client.deleteSecurityRule(zoneId: zone.id, rulesetId: rulesetId, ruleId: rule.id)
        }
    }

    func move(from source: IndexSet, to destination: Int) async {
        guard canModify, let current = ruleset.value, let rulesetId = current.id else { return }
        var desired = current.rules
        desired.move(fromOffsets: source, toOffset: destination)
        await performMutation {
            var updated = current
            for (index, rule) in desired.enumerated() where updated.rules[index].id != rule.id {
                updated = try await client.moveSecurityRule(
                    zoneId: zone.id, rulesetId: rulesetId, ruleId: rule.id,
                    beforeRuleId: updated.rules[index].id
                )
            }
            return updated
        }
    }

    private func performMutation(_ operation: () async throws -> SecurityRuleset) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let updated = try await operation()
            ruleset.update { $0 = updated }
        } catch {
            mutationError = error.localizedDescription
            if case CloudflareError.http(statusCode: 403) = error { mutationNeedsPermission = true }
            await ruleset.refresh { try await client.securityRuleset(zoneId: zone.id) }
        }
    }
}
