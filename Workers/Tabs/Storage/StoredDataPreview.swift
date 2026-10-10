import QuickLook
import SwiftUI
import UIKit

struct StoredDataPreview: View {
    private enum Content {
        case image(UIImage)
        case text(String, isTruncated: Bool)
        case binary
    }

    let data: Data
    let fileName: String

    @State private var content: Content?
    @State private var fileURL: URL?
    @State private var previewURL: URL?

    private static let textLimit = 20_000

    var body: some View {
        Section {
            switch content {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            case .text(let text, _):
                Text(text)
                    .font(.callout)
                    .textSelection(.enabled)
            case .binary:
                Text(.storagePreviewBinary)
                    .foregroundStyle(.secondary)
            case nil:
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            if let fileURL {
                Button {
                    previewURL = fileURL
                } label: {
                    Label(.storagePreviewQuickLook, systemImage: "eye")
                }
                ShareLink(item: fileURL)
            }
        } header: {
            Text(.storageValue)
        } footer: {
            if case .text(_, true) = content {
                Text(.storagePreviewTruncated(Self.textLimit.formatted()))
            }
        }
        .quickLookPreview($previewURL)
        .task(id: data) {
            content = Self.makeContent(from: data)
            fileURL = Self.writeTemporaryFile(data: data, fileName: fileName)
        }
    }

    private static func makeContent(from data: Data) -> Content {
        if let image = UIImage(data: data) {
            return .image(image)
        }
        guard var text = String(data: data, encoding: .utf8) else { return .binary }
        if let object = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
           let prettyText = String(data: pretty, encoding: .utf8) {
            text = prettyText
        }
        return .text(String(text.prefix(textLimit)), isTruncated: text.count > textLimit)
    }

    private static func writeTemporaryFile(data: Data, fileName: String) -> URL? {
        let lastComponent = fileName.split(separator: "/").last.map(String.init) ?? ""
        let safeName = lastComponent.replacingOccurrences(of: ":", with: "_")
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoredData", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent(safeName.isEmpty ? "value" : safeName)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
