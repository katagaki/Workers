import AppIntents
import CloudflareKit
import Foundation

struct PurgeZoneURLsIntent: AppIntent {
    static let title: LocalizedStringResource = "Intents.PurgeURLs.Title"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity
    @Parameter(title: "Intents.PurgeURLs.Parameter") var urls: [URL]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestConfirmation(dialog: IntentDialog(.intentsPurgeURLsConfirm(urls.count, zone.name)))
        try await IntentContext.client(zone: zone).purgeURLs(zoneId: zone.id, urls: urls)
        return .result(dialog: IntentDialog(.intentsPurgeURLsResult(urls.count, zone.name)))
    }
}
