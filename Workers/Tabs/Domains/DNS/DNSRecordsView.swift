import CloudflareKit
import SwiftUI

struct DNSRecordsView: View {
    let client: CloudflareClient
    let zone: Zone

    @State private var records: CachedResource<[DNSRecord]>
    @State private var searchText = ""
    @State private var typeFilter: String?
    @State private var editorMode: DNSRecordEditorMode?
    @State private var recordPendingDeletion: DNSRecord?
    @State private var deleteError: String?

    init(client: CloudflareClient, zone: Zone) {
        self.client = client
        self.zone = zone
        _records = State(initialValue: CachedResource(key: "dns-\(zone.id)"))
    }

    private var availableTypes: [String] {
        Set((records.value ?? []).map(\.type)).sorted()
    }

    private var filteredRecords: [DNSRecord] {
        (records.value ?? [])
            .filter { typeFilter == nil || $0.type == typeFilter }
            .filter {
                searchText.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.content.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { ($0.type, $0.name.count, $0.name) < ($1.type, $1.name.count, $1.name) }
    }

    var body: some View {
        List {
            RefreshErrorSection(resource: records)
            ForEach(filteredRecords) { record in
                Button {
                    editorMode = .edit(record)
                } label: {
                    DNSRecordRow(record: record, zoneName: zone.name)
                }
                .tint(.primary)
                .swipeActions {
                    Button(role: .destructive) {
                        recordPendingDeletion = record
                    } label: {
                        Label(.sharedDelete, systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = record.content
                    } label: {
                        Label(.dnsCopyContent, systemImage: "doc.on.doc")
                    }
                    Button {
                        UIPasteboard.general.string = record.name
                    } label: {
                        Label(.dnsCopyName, systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        recordPendingDeletion = record
                    } label: {
                        Label(.sharedDelete, systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(.dnsTitle)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.dnsSearch))
        .resourceStatus(
            records,
            emptyTitle: .dnsEmptyTitle,
            emptySystemImage: "list.bullet.rectangle",
            emptyDescription: .dnsEmptyMessage
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(.dnsRecordType, selection: $typeFilter) {
                        Text(.dnsAllTypes).tag(String?.none)
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type).tag(Optional(type))
                        }
                    }
                } label: {
                    Label(.sharedFilter, systemImage: typeFilter == nil
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorMode = .create
                } label: {
                    Label(.dnsEditorAddRecord, systemImage: "plus")
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            DNSRecordEditorView(client: client, zone: zone, mode: mode) { saved in
                records.update { list in
                    if let index = list.firstIndex(where: { $0.id == saved.id }) {
                        list[index] = saved
                    } else {
                        list.append(saved)
                    }
                }
            }
        }
        .alert(
            Text(.dnsDeleteConfirm),
            isPresented: Binding(
                get: { recordPendingDeletion != nil },
                set: { if !$0 { recordPendingDeletion = nil } }
            ),
            presenting: recordPendingDeletion
        ) { record in
            Button(.sharedCancel, role: .cancel) {}
            Button(.dnsDeleteAction(record.type), role: .destructive) {
                Task { await delete(record) }
            }
        } message: { record in
            Text(verbatim: "\(record.name) → \(record.content)")
        }
        .alert(Text(.dnsDeleteFailed), isPresented: Binding(
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

    private func reload() async {
        await records.refresh {
            try await client.dnsRecords(zoneId: zone.id)
        }
    }

    private func delete(_ record: DNSRecord) async {
        do {
            try await client.deleteDNSRecord(zoneId: zone.id, recordId: record.id)
            records.update { $0.removeAll { $0.id == record.id } }
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
