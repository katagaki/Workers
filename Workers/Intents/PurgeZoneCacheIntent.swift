import AppIntents
import CloudflareKit
import WidgetKit

struct PurgeZoneCacheIntent: AppIntent {
    // App Intents metadata extraction rejects generated string symbols, so these use literal catalog keys.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let title: LocalizedStringResource = "Intents.PurgeCache.Title"
    static let description = IntentDescription("Intents.PurgeCache.Description")

    @Parameter(title: "Intents.Zone.Type")
    var zone: ZoneEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestConfirmation(
            actionName: .custom(acceptLabel: .domainsPurgeEverything, acceptAlternatives: [], denyLabel: .sharedCancel, denyAlternatives: [], destructive: true),
            dialog: IntentDialog(.domainsPurgeMessage(zone.name))
        )
        try await IntentContext.client(zone: zone).purgeEverything(zoneId: zone.id)
        ControlCenter.shared.reloadAllControls()
        return .result(dialog: IntentDialog(.domainsPurgeDoneMessage(zone.name)))
    }
}
