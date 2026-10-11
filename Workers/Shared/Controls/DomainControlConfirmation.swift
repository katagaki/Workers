import CloudflareKit
import SwiftUI
import WidgetKit

struct DomainControlConfirmation: View {
    let request: ControlActionNavigator.Request
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    @State private var error: String?

    private var title: LocalizedStringResource {
        switch request.action {
        case .pause: request.enabled ? .domainsPauseAction : .domainsResumeAction
        case .underAttack: .controlsAttack
        case .purge: .domainsPurgeEverything
        }
    }

    private var message: LocalizedStringResource {
        switch request.action {
        case .pause: .controlsPauseConfirm(request.zone.name)
        case .underAttack: .controlsAttackConfirm(request.zone.name)
        case .purge: .domainsPurgeMessage(request.zone.name)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(verbatim: request.zone.name).font(.headline)
                    Text(message)
                    if request.action != .purge {
                        LabeledContent(.controlsEnabled, value: String(localized: request.enabled ? .controlsOn : .controlsOff))
                    }
                }
                Section {
                    Button(title, role: .destructive) { Task { await apply() } }
                        .disabled(isRunning)
                    if isRunning { ProgressView() }
                    if let error { Text(verbatim: error).foregroundStyle(.red) }
                } footer: {
                    Text(.controlsPermissions)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.sharedCancel) { dismiss() }.disabled(isRunning)
                }
            }
            .interactiveDismissDisabled(isRunning)
        }
    }

    private func apply() async {
        isRunning = true
        error = nil
        defer { isRunning = false }
        do {
            let client = try IntentContext.client(zone: request.zone)
            switch request.action {
            case .pause:
                _ = try await client.setZonePaused(zoneId: request.zone.id, paused: request.enabled)
                if let accountID = request.zone.accountId { DiskCache.shared.remove(for: "zones-\(accountID)") }
            case .underAttack:
                let current = try await client.zoneSecurityLevel(zoneId: request.zone.id)
                if current.isUnderAttack != request.enabled {
                    let key = "SecurityLevel.\(request.zone.id)"
                    if request.enabled { SharedAccountStore.defaults.set(current.value, forKey: key) }
                    let previous = SharedAccountStore.defaults.string(forKey: key) ?? "medium"
                    _ = try await client.setZoneUnderAttack(zoneId: request.zone.id, enabled: request.enabled, restoredLevel: previous)
                }
            case .purge:
                try await client.purgeEverything(zoneId: request.zone.id)
            }
            ControlCenter.shared.reloadAllControls()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
