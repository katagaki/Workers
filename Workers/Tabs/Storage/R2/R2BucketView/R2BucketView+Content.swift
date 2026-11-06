import CloudflareKit
import SwiftUI

extension R2BucketView {
    var foldersSection: some View {
        Section(.storageR2Folders) {
            ForEach(folders, id: \.self) { folder in
                NavigationLink(value: StorageDestination.r2Bucket(bucketName: bucketName, prefix: folder)) {
                    Label {
                        Text(folder.dropFirst(prefix.count).dropLast())
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .swipeActions { swipeButtons(for: .folder(folder)) }
                .contextMenu { menuButtons(for: .folder(folder)) }
            }
        }
    }

    var objectsSection: some View {
        Section {
            ForEach(objects) { object in
                NavigationLink(value: StorageDestination.r2Object(bucketName: bucketName, object: object)) {
                    R2ObjectRow(object: object, prefix: prefix)
                }
                .swipeActions { swipeButtons(for: .object(object)) }
                .contextMenu { menuButtons(for: .object(object)) }
            }
            if nextCursor != nil {
                LoadMoreButton(isLoading: isLoadingMore) { await loadMore() }
            }
        } header: {
            Text(.storageR2Objects)
        } footer: {
            if let loadMoreError {
                Text(loadMoreError)
            }
        }
    }

    // Bottom bar items render behind the tab bar and the demo mode accessory.
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if editMode.isEditing {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await save(selectedObjects) }
                } label: {
                    Label(.storageR2SaveToFiles, systemImage: "square.and.arrow.down")
                }
                .disabled(selectedObjects.isEmpty || selectedObjects.count != selection.count)
                Button(role: .destructive) {
                    pendingDeletion = selectedEntries
                } label: {
                    Label(.sharedDelete, systemImage: "trash")
                }
                .disabled(selection.isEmpty)
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isImportingFiles = true
                    } label: {
                        Label(.storageR2Upload, systemImage: "square.and.arrow.up")
                    }
                    Button {
                        promptForNewFolder()
                    } label: {
                        Label(.storageR2NewFolder, systemImage: "folder.badge.plus")
                    }
                } label: {
                    Label(.storageR2Add, systemImage: "plus")
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
    }

    @ViewBuilder
    private func swipeButtons(for entry: R2Entry) -> some View {
        Button(role: .destructive) {
            pendingDeletion = [entry]
        } label: {
            Label(.sharedDelete, systemImage: "trash")
        }
        Button {
            promptForRename(entry)
        } label: {
            Label(.storageR2Rename, systemImage: "pencil")
        }
    }

    @ViewBuilder
    private func menuButtons(for entry: R2Entry) -> some View {
        if case .object(let object) = entry {
            Button {
                Task { await save([object]) }
            } label: {
                Label(.storageR2SaveToFiles, systemImage: "square.and.arrow.down")
            }
        }
        Button {
            promptForRename(entry)
        } label: {
            Label(.storageR2Rename, systemImage: "pencil")
        }
        Button(role: .destructive) {
            pendingDeletion = [entry]
        } label: {
            Label(.sharedDelete, systemImage: "trash")
        }
    }
}
