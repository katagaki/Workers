import CloudflareKit
import SwiftUI

struct VersionRow: View {
    let version: WorkerVersion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Group {
                    if let number = version.number {
                        Text(.workersVersionsVersion(number))
                    } else {
                        Text(version.id.prefix(8))
                    }
                }
                .font(.body.weight(.medium))
                if let tag = version.annotations?.tag, !tag.isEmpty {
                    Text(tag)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if let createdOn = version.metadata?.createdOn {
                    Text(createdOn.relativeFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if let message = version.annotations?.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
            }
            if let author = version.metadata?.authorEmail {
                Label(author, systemImage: "person.fill")
                    .labelStyle(.compact)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                UIPasteboard.general.string = version.id
            } label: {
                Label(.workersVersionsCopyID, systemImage: "doc.on.doc")
            }
        }
    }
}
