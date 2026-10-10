import SwiftUI

struct LoadMoreButton: View {
    let isLoading: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Text(.storageLoadMore)
                Spacer()
                if isLoading {
                    ProgressView()
                }
            }
        }
        .disabled(isLoading)
    }
}
