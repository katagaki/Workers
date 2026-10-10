import CloudflareKit
import SwiftUI

struct ManageAccountsView: View {
    @Environment(CloudflareSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingAccount = false
    @State private var tokenToRename: SavedToken?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(session.savedTokens) { savedToken in
                        Button {
                            session.select(tokenId: savedToken.id, accountId: nil)
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
                                renameText = savedToken.name
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
            .alert(Text(.accountsRename), isPresented: Binding(
                get: { tokenToRename != nil },
                set: { if !$0 { tokenToRename = nil } }
            )) {
                TextField(String(localized: .accountsName), text: $renameText)
                Button(role: .cancel) {
                    tokenToRename = nil
                }
                Button(.sharedSave) {
                    if let tokenToRename {
                        session.rename(tokenId: tokenToRename.id, to: renameText)
                    }
                    tokenToRename = nil
                }
            }
            .onChange(of: session.savedTokens.isEmpty) { _, isEmpty in
                if isEmpty {
                    dismiss()
                }
            }
        }
    }
}
