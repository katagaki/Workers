import CloudflareKit
import SwiftUI

struct SecurityRulesView: View {
    let client: CloudflareClient
    let zone: Zone

    @State var ruleset: CachedResource<SecurityRuleset>
    @State var editorMode: SecurityRuleEditorMode?
    @State var rulePendingDeletion: SecurityRule?
    @State var mutationError: String?
    @State var isWorking = false
    @State var mutationNeedsPermission = false
    @State private var editMode: EditMode = .inactive

    init(client: CloudflareClient, zone: Zone) {
        self.client = client
        self.zone = zone
        _ruleset = State(initialValue: CachedResource(key: "security-rules-\(zone.id)"))
    }

    var needsPermission: Bool {
        if let error = ruleset.error, case CloudflareError.http(statusCode: 403) = error { return true }
        return mutationNeedsPermission
    }

    var canModify: Bool {
        ruleset.value != nil && !ruleset.isLoading && !isWorking && !needsPermission
    }

    var body: some View {
        List {
            if needsPermission {
                Section {
                    Label(.securityPermissionTitle, systemImage: "lock.shield")
                    Text(.securityPermissionMessage)
                        .foregroundStyle(.secondary)
                    Link(.securityManageToken, destination: URL(string: "https://dash.cloudflare.com/profile/api-tokens")!)
                    Button(.securityRetry) { Task { await reload() } }
                        .disabled(isWorking || ruleset.isLoading)
                }
            } else {
                RefreshErrorSection(resource: ruleset)
            }

            if let current = ruleset.value, !current.rules.isEmpty {
                Section {
                    ForEach(Array(current.rules.enumerated()), id: \.element.id) { index, rule in
                        SecurityRuleRow(rule: rule, number: index + 1, isEditing: editMode.isEditing) {
                            editorMode = .edit(rule)
                        } onToggle: { enabled in
                            Task { await setEnabled(rule, enabled: enabled) }
                        }
                        .disabled(!canModify)
                        .swipeActions {
                            Button(role: .destructive) { rulePendingDeletion = rule } label: {
                                Label(.sharedDelete, systemImage: "trash")
                            }
                            .disabled(!canModify)
                        }
                    }
                    .onMove { source, destination in
                        Task { await move(from: source, to: destination) }
                    }
                    .moveDisabled(!canModify)
                } header: {
                    Text(.securityCustomRules)
                } footer: {
                    Text(.securityOrderFooter)
                }
            } else if ruleset.value != nil, !needsPermission, ruleset.error == nil {
                Section {
                    ContentUnavailableView {
                        Label(.securityEmptyTitle, systemImage: "checkmark.shield")
                    } description: {
                        Text(.securityEmptyMessage)
                    } actions: {
                        Button(.securityAddRule) { editorMode = .create }
                            .disabled(!canModify)
                    }
                }
            } else if ruleset.value == nil, !needsPermission {
                if ruleset.isLoading {
                    ProgressView()
                } else if let error = ruleset.error {
                    Section {
                        Text(error.localizedDescription)
                        Button(.securityRetry) { Task { await reload() } }
                    }
                }
            }

        }
        .navigationTitle(.securityTitle)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isWorking || ruleset.isLoading { ProgressView() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .environment(\.editMode, $editMode)
                    .disabled(!canModify || (ruleset.value?.rules.isEmpty ?? true))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { editorMode = .create } label: {
                    Label(.securityAddRule, systemImage: "plus")
                }
                .disabled(!canModify)
            }
        }
        .sheet(item: $editorMode) { mode in
            SecurityRuleEditorView(client: client, zone: zone, mode: mode) { updated in
                ruleset.update { $0 = updated }
            }
        }
        .alert(Text(.securityDeleteTitle), isPresented: Binding(
            get: { rulePendingDeletion != nil },
            set: { if !$0 { rulePendingDeletion = nil } }
        ), presenting: rulePendingDeletion) { rule in
            Button(role: .cancel) {}
            Button(.sharedDelete, role: .destructive) { Task { await delete(rule) } }
        } message: { rule in
            Text(.securityDeleteMessage(SecurityRulePresentation.title(for: rule)))
        }
        .alert(Text(.securityUpdateFailed), isPresented: Binding(
            get: { mutationError != nil },
            set: { if !$0 { mutationError = nil } }
        )) {
            Button(.sharedOk, role: .cancel) {}
        } message: {
            Text(mutationError ?? "")
        }
        .task { await reload() }
        .refreshable { await reload() }
    }
}
