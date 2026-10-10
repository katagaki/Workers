import CloudflareKit
import SwiftUI

struct R2ObjectRow: View {
    let object: R2Object
    let prefix: String

    private var subtitle: String {
        var parts: [String] = []
        if let size = object.size {
            parts.append(size.byteFormatted)
        }
        if let lastModified = object.lastModified {
            parts.append(lastModified.relativeFormatted)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(object.key.dropFirst(prefix.count))
                    .lineLimit(2)
                    .truncationMode(.middle)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: object.systemImage)
                .foregroundStyle(.secondary)
        }
    }
}

extension R2Object {
    var systemImage: String {
        let contentType = httpMetadata?.contentType ?? ""
        if contentType.hasPrefix("image/") { return "photo" }
        if contentType.hasPrefix("video/") { return "film" }
        if contentType.hasPrefix("audio/") { return "waveform" }
        if contentType.hasPrefix("text/") || contentType.contains("json") { return "doc.text" }
        if contentType.contains("zip") || contentType.contains("gzip") { return "doc.zipper" }
        return "doc"
    }
}
