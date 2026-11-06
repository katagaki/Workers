import CloudflareKit
import SwiftUI

struct LogQuerySuggestionRow: View {
    let suggestion: LogQuerySuggestion

    var body: some View {
        if let detail {
            LabeledContent {
                Text(detail)
            } label: {
                suggestionText
            }
        } else {
            suggestionText
        }
    }

    private var suggestionText: some View {
        Text(verbatim: suggestion.text)
            .lineLimit(2)
    }

    private var detail: LocalizedStringResource? {
        switch suggestion.kind {
        case .key(let type): type.title
        case .operation(let operation): operation.title
        case .value: nil
        }
    }
}
