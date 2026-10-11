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
        guard current.isUnderAttack != value else {
            return .result(dialog: IntentDialog(.controlsAttackResult(zone.name)))
        }
        let key = "SecurityLevel.\(zone.id)"
        if value && !current.isUnderAttack { SharedAccountStore.defaults.set(current.value, forKey: key) }
        let previous = SharedAccountStore.defaults.string(forKey: key) ?? "medium"
        _ = try await client.setZoneUnderAttack(zoneId: zone.id, enabled: value, restoredLevel: previous)
        ControlCenter.shared.reloadAllControls()
        return .result(dialog: IntentDialog(.controlsAttackResult(zone.name)))
    }
}

struct SetZoneUnderAttackControlIntent: SetValueIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Controls.Attack.Title"
    static let supportedModes: IntentModes = .foreground
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?
    @Parameter(title: "Controls.Enabled") var value: Bool

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    @MainActor func perform() async throws -> some IntentResult {
        guard let zone else { throw IntentError.zoneNotFound }
        ControlActionNavigator.shared.pendingRequest = .init(zone: zone, action: .underAttack, enabled: value)
        return .result()
    }
}

struct SetZonePausedControlIntent: SetValueIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Intents.SetPaused.Title"
    static let supportedModes: IntentModes = .foreground
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?
    @Parameter(title: "Intents.SetPaused.Parameter") var value: Bool

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    @MainActor func perform() async throws -> some IntentResult {
        guard let zone else { throw IntentError.zoneNotFound }
        ControlActionNavigator.shared.pendingRequest = .init(zone: zone, action: .pause, enabled: value)
        return .result()
    }
}

struct PurgeZoneControlIntent: AppIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Intents.PurgeCache.Title"
    static let supportedModes: IntentModes = .foreground
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?

    init() {}
    init(zone: ZoneEntity?) { self.zone = zone }

    @MainActor func perform() async throws -> some IntentResult {
        guard let zone else { throw IntentError.zoneNotFound }
        ControlActionNavigator.shared.pendingRequest = .init(zone: zone, action: .purge)
        return .result()
    }
}
