import CloudflareKit
import SwiftUI

struct KVKeyRow: View {
    let key: KVKey

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key.name)
                .lineLimit(2)
                .truncationMode(.middle)
            if let expiration = key.expiration {
                Text(.storageKvExpires(expiration.relativeFormatted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = key.name
            } label: {
                Label(.sharedCopy, systemImage: "doc.on.doc")
            }
        }
    }
}
