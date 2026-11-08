import CloudflareKit
import Foundation

struct R2OversizedUpload {
    let fileNames: [String]
    let remainingURLs: [URL]

    var message: LocalizedStringResource {
        let limit = CloudflareClient.r2UploadLimit.formatted(.byteCount(style: .file))
        if fileNames.count == 1, let fileName = fileNames.first {
            return .storageR2TooLargeSingle(fileName, limit)
        }
        return .storageR2TooLargeMultiple(limit, fileNames.formatted(.list(type: .and)))
    }
}
