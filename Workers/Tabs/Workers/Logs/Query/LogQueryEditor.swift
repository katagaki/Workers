import SwiftUI

struct LogQueryEditor: View {
    @Binding var queryText: String
    @Binding var selection: TextSelection?
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(String(localized: .logsQueryPlaceholder), text: $queryText, selection: $selection, axis: .vertical)
                .lineLimit(1...6)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .focused(isFocused)
                .accessibilityIdentifier("LogQueryEditor")
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.background.secondary, in: .rect(cornerRadius: 10))
            Text(.logsQueryFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }
}
