import CloudflareKit
import SwiftUI

extension DurableObjectNamespace {
    var storageBackendTitle: String {
        useSqlite == true
            ? String(localized: .durableObjectsStorageSqlite)
            : String(localized: .durableObjectsStorageKeyValue)
    }
}
