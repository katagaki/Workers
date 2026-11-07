import Foundation

struct R2Upload: Codable, Identifiable, Hashable {
    let id: UUID
    let accountId: String
    let bucketName: String
    let key: String
    let contentType: String?
    let totalBytes: Int64
    var isDemo = false
    var sentBytes: Int64 = 0
    var failureMessage: String?

    var fractionCompleted: Double {
        totalBytes > 0 ? min(1, Double(sentBytes) / Double(totalBytes)) : 0
    }
}
