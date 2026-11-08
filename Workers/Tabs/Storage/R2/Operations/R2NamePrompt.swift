import SwiftUI

struct R2NamePrompt: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    let message: LocalizedStringResource?
    let actionTitle: LocalizedStringResource
    let initialName: String
    let submit: (String) -> Void
}

struct R2NamePromptModifier: ViewModifier {
    @Binding var prompt: R2NamePrompt?

    @State private var name = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameValid: Bool {
        !trimmedName.isEmpty
            && !trimmedName.contains("/")
            && ![".", "..", prompt?.initialName].contains(trimmedName)
    }

    func body(content: Content) -> some View {
        content
            .alert(
                prompt.map { Text($0.title) } ?? Text(verbatim: ""),
                isPresented: Binding(
                    get: { prompt != nil },
                    set: { if !$0 { prompt = nil } }
                ),
                presenting: prompt
            ) { prompt in
                TextField(String(localized: .storageR2NamePlaceholder), text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(role: .cancel) {}
                Button(prompt.actionTitle) {
                    prompt.submit(trimmedName)
                }
                .disabled(!isNameValid)
            } message: { prompt in
                if let message = prompt.message {
                    Text(message)
                }
            }
            .onChange(of: prompt?.id) {
                name = prompt?.initialName ?? ""
            }
    }
}

extension View {
    func r2NamePrompt(_ prompt: Binding<R2NamePrompt?>) -> some View {
        modifier(R2NamePromptModifier(prompt: prompt))
    }
}
