import AppIntents
import CloudflareKit
import SwiftUI
import WidgetKit

struct ZoneControlValue: Sendable {
    let zone: ZoneEntity?
    let enabled: Bool
}

struct ZonePauseProvider: AppIntentControlValueProvider {
    func previewValue(configuration: ZoneControlConfiguration) -> ZoneControlValue {
        ZoneControlValue(zone: configuration.zone, enabled: false)
    }
    func currentValue(configuration: ZoneControlConfiguration) async throws -> ZoneControlValue {
        guard let zone = configuration.zone else { return previewValue(configuration: configuration) }
        let current = try await IntentContext.client(zone: zone).zone(id: zone.id)
        return ZoneControlValue(zone: zone, enabled: current.paused == true)
    }
}

struct ZoneAttackProvider: AppIntentControlValueProvider {
    func previewValue(configuration: ZoneControlConfiguration) -> ZoneControlValue {
        ZoneControlValue(zone: configuration.zone, enabled: false)
    }
    func currentValue(configuration: ZoneControlConfiguration) async throws -> ZoneControlValue {
        guard let zone = configuration.zone else { return previewValue(configuration: configuration) }
        let current = try await IntentContext.client(zone: zone).zoneSecurityLevel(zoneId: zone.id)
        return ZoneControlValue(zone: zone, enabled: current.isUnderAttack)
    }
}

struct ZonePauseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "ZonePause", provider: ZonePauseProvider()) { value in
            ControlWidgetToggle(isOn: value.enabled, action: SetZonePausedControlIntent(zone: value.zone)) {
                Label(.controlsPause, systemImage: "pause.circle")
            }
        }.displayName(.controlsPause)
    }
}

struct ZoneAttackControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "ZoneAttack", provider: ZoneAttackProvider()) { value in
            ControlWidgetToggle(isOn: value.enabled, action: SetZoneUnderAttackIntent(zone: value.zone)) {
                Label(.controlsAttack, systemImage: "shield.lefthalf.filled")
            }
        }.displayName(.controlsAttack)
    }
}

struct ZonePurgeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "ZonePurge", intent: ZoneControlConfiguration.self) { configuration in
            ControlWidgetButton(action: PurgeZoneControlIntent(zone: configuration.zone)) {
                Label(.controlsPurge, systemImage: "arrow.clockwise")
            }
        }.displayName(.controlsPurge)
    }
}
