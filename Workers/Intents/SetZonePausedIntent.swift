import AppIntents
import CloudflareKit
import WidgetKit

struct SetZonePausedIntent: AppIntent {
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let title: LocalizedStringResource = "Intents.SetPaused.Title"
    static let description = IntentDescription("Intents.SetPaused.Description")

    @Parameter(title: "Intents.Zone.Type")
    var zone: ZoneEntity

    @Parameter(title: "Intents.SetPaused.Parameter", default: true)
    var paused: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        if paused {
            try await requestConfirmation(
                actionName: .custom(acceptLabel: .domainsPauseAction, acceptAlternatives: [], denyLabel: .sharedCancel, denyAlternatives: [], destructive: true),
                dialog: IntentDialog(.domainsPauseConfirm)
            )
        }
        let updated = try await IntentContext.client(zone: zone).setZonePaused(zoneId: zone.id, paused: paused)
        let dialog: LocalizedStringResource = updated.paused == true
            ? .intentsSetPausedPaused(zone.name)
            : .intentsSetPausedResumed(zone.name)
        ControlCenter.shared.reloadAllControls()
        return .result(dialog: IntentDialog(dialog))
    }
}
