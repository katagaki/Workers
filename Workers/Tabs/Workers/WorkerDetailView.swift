import CloudflareKit
import SwiftUI

struct WorkerDetailView: View {
    let client: CloudflareClient
    let accountId: String
    let script: WorkerScript
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var range: AnalyticsRange = .day
    @State private var settings: CachedResource<WorkerSettings>
    @State private var subdomainStatus: CachedResource<WorkerSubdomainStatus>
    @State private var accountSubdomain: CachedResource<WorkersSubdomain>
    @State private var isConfirmingDelete = false
    @State private var deleteError: String?

    init(client: CloudflareClient, accountId: String, script: WorkerScript, onDelete: (() -> Void)? = nil) {
        self.client = client
        self.accountId = accountId
        self.script = script
        self.onDelete = onDelete
        _settings = State(initialValue: CachedResource(key: "worker-settings-\(accountId)-\(script.name)"))
        _subdomainStatus = State(initialValue: CachedResource(key: "worker-subdomain-\(accountId)-\(script.name)"))
        _accountSubdomain = State(initialValue: CachedResource(key: "workers-subdomain-\(accountId)"))
    }

    private var workersDevURL: URL? {
        guard subdomainStatus.value?.enabled == true,
              let subdomain = accountSubdomain.value?.subdomain else { return nil }
        return client.workersDevURL(scriptName: script.name, subdomain: subdomain)
    }

    var body: some View {
        List {
            Section {
                AnalyticsRangePicker(range: $range)
                    .listRowSeparator(.hidden)
                WorkerAnalyticsSummary(client: client, accountId: accountId, scriptName: script.name, range: range)
                    .id(range)
            }

            Section(.sharedOverview) {
                if let workersDevURL {
                    Link(destination: workersDevURL) {
                        LabeledContent(.sharedUrl) {
                            Text(workersDevURL.host() ?? "")
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                if let modifiedOn = script.modifiedOn {
                    LabeledContent(.workersDetailLastUpdated, value: modifiedOn.formatted(date: .abbreviated, time: .shortened))
                }
                if let createdOn = script.createdOn {
                    LabeledContent(.workersDetailCreated, value: createdOn.formatted(date: .abbreviated, time: .omitted))
                }
                if let compatibilityDate = settings.value?.compatibilityDate ?? script.compatibilityDate {
                    LabeledContent(.workersDetailCompatibilityDate, value: compatibilityDate)
                }
                if let usageModel = settings.value?.usageModel ?? script.usageModel {
                    LabeledContent(.workersDetailUsageModel, value: usageModel.capitalizedFirst)
                }
                if let handlers = script.handlers, !handlers.isEmpty {
                    LabeledContent(.workersDetailHandlers, value: handlers.map(\.capitalizedFirst).formatted(.list(type: .and)))
                }
                if let observability = settings.value?.observability {
                    LabeledContent(.workersDetailObservability, value: observability.enabled
                                   ? String(localized: .workersDetailEnabled)
                                   : String(localized: .workersDetailDisabled))
                }
            }

            Section(.workersDetailActivity) {
                NavigationLink(value: WorkersDestination.logs(scriptName: script.name)) {
                    SettingsLabel(title: .logsTitle, systemImage: "text.alignleft", color: .blue)
                }
                NavigationLink(value: WorkersDestination.deployments(scriptName: script.name)) {
                    SettingsLabel(title: .workersDeploymentsTitle, systemImage: "arrow.up", color: .green)
                }
                NavigationLink(value: WorkersDestination.versions(scriptName: script.name)) {
                    SettingsLabel(title: .workersVersionsTitle, systemImage: "clock.arrow.circlepath", color: .indigo)
                }
            }

            Section(.workersDetailConfiguration) {
                NavigationLink(value: WorkersDestination.bindings(scriptName: script.name)) {
                    LabeledContent {
                        if let count = settings.value?.bindings?.count {
                            Text(count, format: .number)
                        }
                    } label: {
                        SettingsLabel(title: .workersBindingsTitle, systemImage: "link", color: .teal)
                    }
                }
                NavigationLink(value: WorkersDestination.triggers(scriptName: script.name)) {
                    SettingsLabel(title: .workersTriggersTitle, systemImage: "bolt.fill", color: .orange)
                }
            }
        }
        .navigationTitle(script.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let workersDevURL {
                        ShareLink(item: workersDevURL)
                    }
                    Link(destination: dashboardURL) {
                        Label(.sharedOpenInDashboard, systemImage: "safari")
                    }
                    Divider()
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label(.workersDeleteTitle, systemImage: "trash")
                    }
                } label: {
                    Label(.sharedMore, systemImage: "ellipsis")
                }
            }
        }
        .alert(
            Text(.workersDeleteConfirm(script.name)),
            isPresented: $isConfirmingDelete
        ) {
            Button(role: .cancel) {}
            Button(.workersDeleteTitle, role: .destructive) {
                Task { await deleteWorker() }
            }
        } message: {
            Text(.workersDeleteMessage)
        }
        .alert(Text(.workersDeleteFailed), isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button(.sharedOk, role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var dashboardURL: URL {
        URL(string: "https://dash.cloudflare.com/\(accountId)/workers/services/view/\(script.name)/production")!
    }

    private func reload() async {
        async let settingsLoad: Void = settings.refresh {
            try await client.workerSettings(accountId: accountId, scriptName: script.name)
        }
        async let statusLoad: Void = subdomainStatus.refresh {
            try await client.workerSubdomainStatus(accountId: accountId, scriptName: script.name)
        }
        async let subdomainLoad: Void = accountSubdomain.refresh {
            try await client.workersSubdomain(accountId: accountId)
        }
        _ = await (settingsLoad, statusLoad, subdomainLoad)
    }

    private func deleteWorker() async {
        do {
            try await client.deleteWorkerScript(accountId: accountId, scriptName: script.name)
            onDelete?()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
