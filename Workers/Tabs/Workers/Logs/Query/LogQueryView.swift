import CloudflareKit
import SwiftUI

struct LogQueryView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String
    @Binding var queryText: String

    @AppStorage("RecentLogsWindow") var window: LogWindow = .hour
    @State var selection: TextSelection?
    @State var catalog: LogQueryCatalog
    @State var events: [ObservabilityEvent]?
    @State var queryError: String?
    @State var isRunning = false
    @FocusState var isEditorFocused: Bool

    let resultLimit = 100

    init(client: CloudflareClient, accountId: String, scriptName: String, queryText: Binding<String>) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
        _queryText = queryText
        _catalog = State(initialValue: LogQueryCatalog(client: client, accountId: accountId, scriptName: scriptName))
    }

    var body: some View {
        let context = completionContext
        let suggestions = isEditorFocused ? suggestions(for: context) : []
        Group {
            if suggestions.isEmpty, let events, !events.isEmpty {
                LogTableView(columns: ObservabilityEvent.logTableColumns, rows: events.map(\.logTableRow))
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if events.count >= resultLimit {
                            Text(.logsQueryLimitFooter)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.bar)
                        }
                    }
            } else {
                List {
                    if suggestions.isEmpty {
                        LogQueryResultsSections(events: events, queryError: queryError)
                    } else {
                        Section(.logsQuerySuggestions) {
                            ForEach(suggestions) { suggestion in
                                Button {
                                    apply(suggestion)
                                } label: {
                                    LogQuerySuggestionRow(suggestion: suggestion)
                                }
                                .tint(.primary)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            LogQueryEditor(queryText: $queryText, selection: $selection, isFocused: $isEditorFocused)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LogWindowMenu(window: $window)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isRunning {
                    ProgressView()
                } else {
                    Button {
                        Task { await run() }
                    } label: {
                        Label(.logsQueryRun, systemImage: "play.fill")
                    }
                }
            }
        }
        .task {
            await catalog.loadKeys()
        }
        .task {
            if !queryText.isEmpty, events == nil { await run() }
        }
        .task(id: valueLookupKey(for: context)) {
            guard let key = valueLookupKey(for: context) else { return }
            await catalog.loadValues(for: key)
        }
        .onChange(of: queryText) {
            submitIfReturnWasPressed()
        }
        .onChange(of: window) {
            guard events != nil else { return }
            Task { await run() }
        }
    }
}
