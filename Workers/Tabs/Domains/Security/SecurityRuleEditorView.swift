import CloudflareKit
import SwiftUI

struct SecurityRuleEditorView: View {
    let client: CloudflareClient
    let zone: Zone
    let mode: SecurityRuleEditorMode
    let onSave: (SecurityRuleset) -> Void

    @Environment(\.dismiss) var dismiss
    @State var input: SecurityRuleInput
    @State var isSaving = false
    @State var errorMessage: String?
    @State private var isConfirmingDelete = false
    @State private var template = ""

    init(client: CloudflareClient, zone: Zone, mode: SecurityRuleEditorMode, onSave: @escaping (SecurityRuleset) -> Void) {
        self.client = client
        self.zone = zone
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create: _input = State(initialValue: SecurityRuleInput())
        case .edit(let rule): _input = State(initialValue: SecurityRuleInput(rule: rule))
        }
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var hasAdvancedSettings: Bool {
        input.actionParameters != nil || input.logging != nil || input.ratelimit != nil
            || input.exposedCredentialCheck != nil || !SecurityRulePresentation.editableActions.contains(input.action)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(.securityRuleHeader) {
                    TextField(.securityDescription, text: $input.description)
                    Toggle(.securityEnabled, isOn: $input.enabled)
                    Picker(.securityActionTitle, selection: $input.action) {
                        ForEach(Array(Set(SecurityRulePresentation.editableActions + [input.action])).sorted(), id: \.self) { action in
                            Text(SecurityRulePresentation.title(for: action)).tag(action)
                        }
                    }
                    .disabled(hasAdvancedSettings)
                }

                Section {
                    TextField(.securityExpression, text: $input.expression, axis: .vertical)
                        .lineLimit(4...12)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("security-expression")
                } header: {
                    Text(.securityMatchHeader)
                } footer: {
                    Text(.securityExpressionFooter)
                }

                if !isEditing {
                    Section {
                        Picker(.securityTemplateTitle, selection: $template) {
                            Text(.securityTemplateChoose).tag("")
                            Text(.securityTemplateCountry).tag("country")
                            Text(.securityTemplatePath).tag("path")
                        }
                        .onChange(of: template) { _, selection in
                            applyTemplate(selection)
                        }
                    } footer: {
                        Text(.securityTemplateFooter)
                    }
                }

                if hasAdvancedSettings {
                    Section {
                        Text(.securityAdvancedMessage)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                        Link(.securityManageToken, destination: URL(string: "https://dash.cloudflare.com/profile/api-tokens")!)
                    }
                }

                if isEditing {
                    Section {
                        Button(.securityDeleteTitle, role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .disabled(isSaving)
            .navigationTitle(isEditing ? .securityEditRule : .securityAddRule)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(role: .confirm) { Task { await save() } }
                            .disabled(input.expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert(Text(.securityDeleteTitle), isPresented: $isConfirmingDelete) {
                Button(role: .cancel) {}
                Button(.sharedDelete, role: .destructive) { Task { await delete() } }
            } message: {
                Text(.securityDeleteMessage(input.description.isEmpty ? String(localized: .securityUntitled) : input.description))
            }
        }
    }

    private func applyTemplate(_ selection: String) {
        switch selection {
        case "country":
            input.expression = "ip.src.country eq \"CN\""
            input.action = "block"
            if input.description.isEmpty { input.description = String(localized: .securityTemplateCountry) }
        case "path":
            input.expression = "starts_with(http.request.uri.path, \"/admin\")"
            input.action = "managed_challenge"
            if input.description.isEmpty { input.description = String(localized: .securityTemplatePath) }
        default: break
        }
    }
}
