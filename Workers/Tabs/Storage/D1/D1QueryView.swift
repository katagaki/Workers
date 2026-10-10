import CloudflareKit
import SwiftUI

struct D1QueryView: View {
    let client: CloudflareClient
    let accountId: String
    let databaseId: String

    @State private var sql = "SELECT name FROM sqlite_master WHERE type = 'table'"
    @State private var results: [D1QueryResult] = []
    @State private var queryError: String?
    @State private var isRunning = false
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        List {
            Section {
                TextField(String(localized: .storageD1Query), text: $sql, axis: .vertical)
                    .lineLimit(3...10)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isEditorFocused)
            } header: {
                Text(.storageD1Query)
            } footer: {
                Text(.storageD1QueryFooter)
            }

            if let queryError {
                Section {
                    Label {
                        Text(queryError)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                if let meta = result.meta {
                    Section {
                        if let duration = meta.duration {
                            LabeledContent(.storageD1Duration, value: duration.millisecondsFormatted)
                        }
                        if let rowsRead = meta.rowsRead {
                            LabeledContent(.storageD1RowsRead, value: rowsRead.formatted())
                        }
                        if let rowsWritten = meta.rowsWritten {
                            LabeledContent(.storageD1RowsWritten, value: rowsWritten.formatted())
                        }
                    }
                }
                if result.rows.isEmpty {
                    Section {
                        Text(.storageD1NoRows)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    D1ResultSection(result: result)
                }
            }
        }
        .navigationTitle(.storageD1RunQuery)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isRunning {
                    ProgressView()
                } else {
                    Button {
                        Task { await run() }
                    } label: {
                        Label(.storageD1Run, systemImage: "play.fill")
                    }
                    .disabled(sql.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func run() async {
        isEditorFocused = false
        isRunning = true
        defer { isRunning = false }
        do {
            results = try await client.d1Query(accountId: accountId, databaseId: databaseId, sql: sql)
            queryError = nil
        } catch {
            results = []
            queryError = error.localizedDescription
        }
    }
}
