import SwiftUI

struct R2BucketConfirmations: ViewModifier {
    @Binding var pendingDeletion: [R2Entry]?
    @Binding var pendingUpload: [URL]?
    let delete: ([R2Entry]) -> Void
    let upload: ([URL]) -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                Text(.storageR2DeleteTitle),
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                presenting: pendingDeletion
            ) { entries in
                Button(role: .cancel) {}
                Button(.sharedDelete, role: .destructive) {
                    delete(entries)
                }
            } message: { entries in
                Text(deletionMessage(for: entries))
            }
            .alert(
                Text(.storageR2ReplaceTitle),
                isPresented: Binding(
                    get: { pendingUpload != nil },
                    set: { if !$0 { pendingUpload = nil } }
                ),
                presenting: pendingUpload
            ) { urls in
                Button(role: .cancel) {}
                Button(.storageR2ReplaceAction, role: .destructive) {
                    upload(urls)
                }
            } message: { _ in
                Text(.storageR2ReplaceMessage)
            }
    }

    private func deletionMessage(for entries: [R2Entry]) -> LocalizedStringResource {
        guard entries.count == 1, let entry = entries.first else {
            return .storageR2DeleteSelectionMessage(entries.count)
        }
        switch entry {
        case .object: return .storageR2DeleteObjectMessage(entry.name)
        case .folder: return .storageR2DeleteFolderMessage(entry.name)
        }
    }
}
