import CloudflareKit
import SwiftUI

struct R2UploadRow: View {
    let upload: R2Upload
    let client: CloudflareClient
    let showsLocation: Bool

    @Environment(R2UploadCenter.self) private var uploads

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(upload.key.r2Name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if showsLocation {
                    Text(verbatim: "\(upload.bucketName)/\(upload.key.r2ParentPrefix)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if let failureMessage = upload.failureMessage {
                    Text(failureMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                } else {
                    ProgressView(value: upload.fractionCompleted)
                    Text(.storageR2UploadsProgress(
                        upload.sentBytes.formatted(.byteCount(style: .file)),
                        upload.totalBytes.formatted(.byteCount(style: .file))
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if upload.failureMessage != nil {
                Button {
                    uploads.retry(upload, client: client)
                } label: {
                    Label(.storageR2UploadsRetry, systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
            Button {
                uploads.remove(upload)
            } label: {
                if upload.failureMessage != nil {
                    Label(.storageR2UploadsRemove, systemImage: "xmark")
                        .labelStyle(.iconOnly)
                } else {
                    Label(.sharedCancel, systemImage: "xmark")
                        .labelStyle(.iconOnly)
                }
            }
            .buttonStyle(.borderless)
            .tint(.secondary)
        }
    }
}
