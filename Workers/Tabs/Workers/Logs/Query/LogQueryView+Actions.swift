import CloudflareKit
import SwiftUI

extension LogQueryView {
    var cursorOffset: Int {
        guard case .selection(let range) = selection?.indices else { return queryText.count }
        let index = min(range.upperBound, queryText.endIndex)
        return queryText.distance(from: queryText.startIndex, to: index)
    }

    var completionContext: LogQueryCompletionContext {
        LogQueryAutocomplete.context(in: queryText, cursor: cursorOffset, keys: catalog.keys)
    }

    func suggestions(for context: LogQueryCompletionContext) -> [LogQuerySuggestion] {
        var values: [LogQueryValue] = []
        if let key = valueLookupKey(for: context) {
            values = catalog.values(for: key)
        }
        return LogQueryAutocomplete.suggestions(for: context, keys: catalog.keys, values: values)
    }

    func valueLookupKey(for context: LogQueryCompletionContext) -> String? {
        guard isEditorFocused, case .value(let key, _) = context.position else { return nil }
        return key
    }

    func apply(_ suggestion: LogQuerySuggestion) {
        let completed = LogQueryAutocomplete.applying(suggestion, to: queryText)
        queryText = completed.text
        let index = completed.text.index(completed.text.startIndex, offsetBy: completed.cursor)
        selection = TextSelection(insertionPoint: index)
    }

    /// A vertical TextField inserts a newline on Return instead of calling onSubmit.
    func submitIfReturnWasPressed() {
        guard queryText.contains(where: \.isNewline) else { return }
        queryText = queryText.filter { !$0.isNewline }
        selection = nil
        Task { await run() }
    }

    func run() async {
        isEditorFocused = false
        isRunning = true
        defer { isRunning = false }
        do {
            let query = try LogQuery(parsing: queryText, keys: catalog.keys)
            events = try await client.workerEvents(
                accountId: accountId,
                scriptName: scriptName,
                matching: query,
                from: .now.addingTimeInterval(-window.duration),
                to: .now,
                limit: resultLimit
            )
            queryError = nil
        } catch let parseError as LogQueryParseError {
            events = nil
            queryError = String(localized: parseError.message)
        } catch {
            events = nil
            queryError = error.localizedDescription
        }
    }
}
