import AppIntents
import CloudflareKit
import WidgetKit

struct SetZoneUnderAttackIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Controls.Attack.Title"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?
    @Parameter(title: "Controls.Enabled") var value: Bool

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let zone else { throw IntentError.zoneNotFound }
        try await requestConfirmation(dialog: IntentDialog(.controlsAttackConfirm(zone.name)))
        let client = try IntentContext.client(zone: zone)
        let current = try await client.zoneSecurityLevel(zoneId: zone.id)
        let key = "SecurityLevel.\(zone.id)"
        if value && !current.isUnderAttack { SharedAccountStore.defaults.set(current.value, forKey: key) }
        let previous = SharedAccountStore.defaults.string(forKey: key) ?? "medium"
        _ = try await client.setZoneUnderAttack(zoneId: zone.id, enabled: value, restoredLevel: previous)
        ControlCenter.shared.reloadAllControls()
        return .result(dialog: IntentDialog(.controlsAttackResult(zone.name)))
    }
}

struct SetZonePausedControlIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Intents.SetPaused.Title"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?
    @Parameter(title: "Intents.SetPaused.Parameter") var value: Bool

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let zone else { throw IntentError.zoneNotFound }
        if value { try await requestConfirmation(dialog: IntentDialog(.domainsPauseConfirm)) }
        _ = try await IntentContext.client(zone: zone).setZonePaused(zoneId: zone.id, paused: value)
        ControlCenter.shared.reloadAllControls()
        return .result(dialog: IntentDialog(value ? .intentsSetPausedPaused(zone.name) : .intentsSetPausedResumed(zone.name)))
    }
}

struct PurgeZoneControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Intents.PurgeCache.Title"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let zone else { throw IntentError.zoneNotFound }
        try await requestConfirmation(dialog: IntentDialog(.domainsPurgeMessage(zone.name)))
        try await IntentContext.client(zone: zone).purgeEverything(zoneId: zone.id)
        return .result(dialog: IntentDialog(.domainsPurgeDoneMessage(zone.name)))
    }
}
