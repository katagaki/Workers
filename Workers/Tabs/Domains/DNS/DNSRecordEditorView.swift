import CloudflareKit
import SwiftUI

struct DNSRecordEditorView: View {
    let client: CloudflareClient
    let zone: Zone
    let mode: DNSRecordEditorMode
    let onSave: (DNSRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: DNSRecordInput
    @State private var priorityText: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(client: CloudflareClient, zone: Zone, mode: DNSRecordEditorMode, onSave: @escaping (DNSRecord) -> Void) {
        self.client = client
        self.zone = zone
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _input = State(initialValue: DNSRecordInput(type: "A", name: "", content: "", proxied: true))
            _priorityText = State(initialValue: "10")
        case .edit(let record):
            _input = State(initialValue: DNSRecordInput(record: record))
            _priorityText = State(initialValue: record.priority.map(String.init) ?? "")
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var usesPriority: Bool {
        input.type == "MX" || input.type == "SRV"
    }

    private var isProxiable: Bool {
        DNSRecordInput.proxiableTypes.contains(input.type)
    }

    private var canSave: Bool {
        !input.name.trimmingCharacters(in: .whitespaces).isEmpty
            && !input.content.trimmingCharacters(in: .whitespaces).isEmpty
            && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(.dnsEditorType, selection: $input.type) {
                        ForEach(typeOptions, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .disabled(isEditing)
                    TextField(.dnsEditorName, text: $input.name, prompt: Text(.dnsEditorNamePrompt))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField(contentLabel, text: $input.content, axis: .vertical)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(input.type == "A" || input.type == "AAAA" ? .numbersAndPunctuation : .default)
                    if usesPriority {
                        TextField(.dnsEditorPriority, text: $priorityText)
                            .keyboardType(.numberPad)
                    }
                } footer: {
                    Text(.dnsEditorNameFooter(zone.name))
                }

                Section {
                    if isProxiable {
                        Toggle(isOn: Binding(
                            get: { input.proxied ?? false },
                            set: { input.proxied = $0 }
                        )) {
                            Label {
                                Text(.dnsEditorProxy)
                            } icon: {
                                Image(systemName: input.proxied == true ? "cloud.fill" : "cloud")
                                    .foregroundStyle(input.proxied == true ? .orange : .secondary)
                            }
                        }
                    }
                    Picker(.dnsEditorTtl, selection: $input.ttl) {
                        ForEach(ttlOptions, id: \.seconds) { option in
                            Text(option.title).tag(option.seconds)
                        }
                    }
                    .disabled(isProxiable && input.proxied == true)
                } footer: {
                    if isProxiable && input.proxied == true {
                        Text(.dnsEditorProxiedTTLFooter)
                    }
                }

                Section(.dnsEditorComment) {
                    TextField(.dnsEditorOptional, text: Binding(
                        get: { input.comment ?? "" },
                        set: { input.comment = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? .dnsEditorEditRecord : .dnsEditorAddRecord)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.sharedCancel, role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(.sharedSave, role: .confirm) {
                            Task { await save() }
                        }
                        .disabled(!canSave)
                    }
                }
            }
        }
    }

    private var typeOptions: [String] {
        DNSRecordInput.supportedTypes.contains(input.type)
            ? DNSRecordInput.supportedTypes
            : DNSRecordInput.supportedTypes + [input.type]
    }

    private var ttlOptions: [TTLOption] {
        guard !TTLOption.all.contains(where: { $0.seconds == input.ttl }) else { return TTLOption.all }
        return (TTLOption.all + [TTLOption(seconds: input.ttl)]).sorted { $0.seconds < $1.seconds }
    }

    private var contentLabel: LocalizedStringResource {
        switch input.type {
        case "A": .dnsEditorContentIpv4Address
        case "AAAA": .dnsEditorContentIpv6Address
        case "CNAME": .dnsEditorContentTarget
        case "MX": .dnsEditorContentMailServer
        case "NS": .dnsEditorContentNameserver
        default: .dnsEditorContentContent
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        var payload = input
        payload.name = payload.name.trimmingCharacters(in: .whitespaces)
        payload.content = payload.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isProxiable {
            payload.proxied = nil
        }
        if isProxiable && payload.proxied == true {
            payload.ttl = 1
        }
        payload.priority = usesPriority ? Int(priorityText) : nil
        do {
            let saved: DNSRecord
            switch mode {
            case .create:
                saved = try await client.createDNSRecord(zoneId: zone.id, record: payload)
            case .edit(let record):
                saved = try await client.updateDNSRecord(zoneId: zone.id, recordId: record.id, record: payload)
            }
            onSave(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
