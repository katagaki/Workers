import AppIntents
import CloudflareKit

struct OpenZoneIntent: OpenIntent {
    static let title: LocalizedStringResource = "Intents.OpenZone.Title"
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Intents.Zone.Type")
    var target: ZoneEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let client = try IntentContext.client(zone: target)
        let zone = try await client.zone(id: target.id)
        guard let accountId = zone.account?.id ?? target.accountId else { throw IntentError.zoneNotFound }
        AppNavigator.shared.open(.zone(zone), accountId: accountId)
        return .result()
    }
}
