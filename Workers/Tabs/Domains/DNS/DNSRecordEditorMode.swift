import CloudflareKit
import SwiftUI

enum DNSRecordEditorMode: Identifiable {
    case create
    case edit(DNSRecord)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let record): record.id
        }
    }
}
