import CloudflareKit
import SwiftUI

struct ManageAccountsView: View {
    @Environment(CloudflareSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingAccount = false
    @State private var tokenToRename: SavedToken?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(session.savedTokens) { savedToken in
                        Button {
                            tokenToRename = savedToken
                        } label: {
                            SavedTokenRow(
                                savedToken: savedToken,
                                accounts: session.accountLists[savedToken.id]?.value ?? [],
                                isSelected: savedToken.id == session.selectedTokenId
                            )
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                session.delete(tokenId: savedToken.id)
                            } label: {
                                Label(.sharedDelete, systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                tokenToRename = savedToken
                            } label: {
                                Label(.accountsRename, systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                session.delete(tokenId: savedToken.id)
                            } label: {
                                Label(.sharedDelete, systemImage: "trash")
                            }
                        }
                    }
                } footer: {
                    Text(.accountsFooter)
                }

                Section {
                    Button {
                        isAddingAccount = true
                    } label: {
                        Label(.accountsAdd, systemImage: "plus")
                    }
                }
            }
            .navigationTitle(.accountsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
            .sheet(item: $tokenToRename) { savedToken in
                AccountNameEditorView(savedToken: savedToken)
            }
            .onChange(of: session.savedTokens.isEmpty) { _, isEmpty in
                if isEmpty {
                    dismiss()
                }
            }
        }
    }
}
