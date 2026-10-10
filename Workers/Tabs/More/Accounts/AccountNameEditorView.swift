import SwiftUI

struct AccountNameEditorView: View {
    @Environment(CloudflareSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    let savedToken: SavedToken

    @State private var name: String
    @State private var isSaving = false

    init(savedToken: SavedToken) {
        self.savedToken = savedToken
        _name = State(initialValue: savedToken.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: .accountsName), text: $name)
                        .autocorrectionDisabled()
                        .disabled(isSaving)
                } header: {
                    Text(.accountsName)
                } footer: {
                    Text(.accountsNameFooter)
                }
            }
            .navigationTitle(.accountsRename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(.sharedSave) {
                            isSaving = true
                            Task {
                                await session.rename(tokenId: savedToken.id, to: name)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
