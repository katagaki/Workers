import CloudflareKit
import SwiftUI

struct ZoneDetailView: View {
    let client: CloudflareClient
    let accountId: String
    var onUpdate: ((Zone) -> Void)?

    @State private var zone: Zone
    @State private var range: AnalyticsRange = .day
    @State private var isConfirmingPurge = false
    @State private var isConfirmingPause = false
    @State private var isWorking = false
    @State private var actionMessage: ActionMessage?

    init(client: CloudflareClient, accountId: String, zone: Zone, onUpdate: ((Zone) -> Void)? = nil) {
        self.client = client
        self.accountId = accountId
        self.onUpdate = onUpdate
        _zone = State(initialValue: zone)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    ZoneStatusIcon(zone: zone)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.statusTitle)
                            .font(.headline)
                        if let plan = zone.plan?.name {
                            Text(plan)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                AnalyticsRangePicker(range: $range)
                    .listRowSeparator(.hidden)
                ZoneAnalyticsSummary(client: client, zoneId: zone.id, range: range)
                    .id(range)
            } header: {
                Text(.domainsTraffic)
            }

            Section(.domainsManage) {
                NavigationLink(value: DomainsDestination.dnsRecords(zone)) {
                    SettingsLabel(title: .dnsTitle, systemImage: "list.bullet", color: .blue)
                }
                NavigationLink(value: DomainsDestination.workerRoutes(zoneId: zone.id)) {
                    SettingsLabel(title: .domainsRoutesTitle, systemImage: "arrow.triangle.branch", color: .purple)
                }
            }

            Section(.sharedOverview) {
                if let type = zone.type {
                    LabeledContent(.domainsSetup, value: type == "full"
                                   ? String(localized: .domainsSetupFull)
                                   : type.capitalizedFirst)
                }
                if let activatedOn = zone.activatedOn {
                    LabeledContent(.domainsActivated, value: activatedOn.formatted(date: .abbreviated, time: .omitted))
                }
                if let createdOn = zone.createdOn {
                    LabeledContent(.domainsAdded, value: createdOn.formatted(date: .abbreviated, time: .omitted))
                }
                if let registrar = zone.originalRegistrar {
                    LabeledContent(.domainsOriginalRegistrar, value: registrar)
                }
                LabeledContent(.domainsZoneID) {
                    Text(zone.id)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }

            if let nameServers = zone.nameServers, !nameServers.isEmpty {
                Section {
                    ForEach(nameServers, id: \.self) { nameServer in
                        Text(nameServer)
                            .textSelection(.enabled)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = nameServer
                                } label: {
                                    Label(.sharedCopy, systemImage: "doc.on.doc")
                                }
                            }
                    }
                } header: {
                    Text(.domainsNameserversHeader)
                } footer: {
                    if zone.status == "pending" {
                        Text(.domainsNameserversFooter)
                    }
                }
            }

            Section {
                Button {
                    isConfirmingPurge = true
                } label: {
                    SettingsLabel(title: .domainsPurgeTitle, systemImage: "arrow.clockwise", color: .cyan)
                }
                Button {
                    isConfirmingPause = true
                } label: {
                    SettingsLabel(
                        title: zone.paused == true ? .domainsResumeTitle : .domainsPauseTitle,
                        systemImage: zone.paused == true ? "play.fill" : "pause.fill",
                        color: zone.paused == true ? .green : .gray
                    )
                }
            } footer: {
                Text(.domainsPauseFooter)
            }
            .disabled(isWorking)
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let url = URL(string: "https://\(zone.name)") {
                        Link(destination: url) {
                            Label(.domainsOpenWebsite, systemImage: "globe")
                        }
                    }
                    if let url = URL(string: "https://dash.cloudflare.com/\(accountId)/\(zone.name)") {
                        Link(destination: url) {
                            Label(.sharedOpenInDashboard, systemImage: "safari")
                        }
                    }
                } label: {
                    Label(.sharedMore, systemImage: "ellipsis")
                }
            }
        }
        .alert(Text(.domainsPurgeConfirm), isPresented: $isConfirmingPurge) {
            Button(role: .cancel) {}
            Button(.domainsPurgeEverything, role: .destructive) {
                Task { await purgeCache() }
            }
        } message: {
            Text(.domainsPurgeMessage(zone.name))
        }
        .alert(
            Text(zone.paused == true ? .domainsResumeConfirm : .domainsPauseConfirm),
            isPresented: $isConfirmingPause
        ) {
            Button(role: .cancel) {}
            Button(zone.paused == true ? .domainsResumeAction : .domainsPauseAction, role: zone.paused == true ? nil : .destructive) {
                Task { await togglePause() }
            }
        }
        .alert(
            actionMessage?.title ?? "",
            isPresented: Binding(get: { actionMessage != nil }, set: { if !$0 { actionMessage = nil } }),
            presenting: actionMessage
        ) { _ in
            Button(.sharedOk, role: .cancel) {}
        } message: { message in
            Text(message.body)
        }
        .refreshable {
            if let refreshed = try? await client.zone(id: zone.id) {
                zone = refreshed
                onUpdate?(refreshed)
            }
        }
    }

    private func purgeCache() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.purgeEverything(zoneId: zone.id)
            actionMessage = ActionMessage(
                title: String(localized: .domainsPurgeDoneTitle),
                body: String(localized: .domainsPurgeDoneMessage(zone.name))
            )
        } catch {
            actionMessage = ActionMessage(title: String(localized: .domainsPurgeFailed), body: error.localizedDescription)
        }
    }

    private func togglePause() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let updated = try await client.setZonePaused(zoneId: zone.id, paused: !(zone.paused ?? false))
            zone = updated
            onUpdate?(updated)
        } catch {
            actionMessage = ActionMessage(title: String(localized: .domainsUpdateFailed), body: error.localizedDescription)
        }
    }
}
