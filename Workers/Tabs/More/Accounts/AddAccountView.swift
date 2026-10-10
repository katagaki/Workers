import SwiftUI

struct AddAccountView: View {
    @Environment(CloudflareSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var token = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var isShowingError = false

    private var canAdd: Bool {
        !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: .accountsName), text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text(.accountsName)
                } footer: {
                    Text(.accountsNameFooter)
                }

                Section {
                    Link(destination: TokenTemplate.url) {
                        HStack {
                            Spacer()
                            Text(.signInGettingTokenCreateToken)
                            Spacer()
                        }
                    }
                }

                Section {
                    SecureField(.signInTokenPlaceholder, text: $token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.signInTokenHeader)
                } footer: {
                    Text(.signInTokenFooter)
                }

                if let validationError {
                    Section {
                        Label(validationError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert(.signInErrorTitle, isPresented: $isShowingError) {
                Button(role: .confirm) {}
            } message: {
                Text(validationError ?? "")
            }
            .navigationTitle(.accountsAdd)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isValidating {
                        ProgressView()
                    } else {
                        Button(role: .confirm) {
                            Task { await add() }
                        }
                        .disabled(!canAdd)
                    }
                }
            }
        }
    }

    private func add() async {
        isValidating = true
        validationError = nil
        defer { isValidating = false }
        do {
            try await session.addToken(name: name, token: token)
            dismiss()
        } catch {
            validationError = error.localizedDescription
            isShowingError = true
        }
    }
}
