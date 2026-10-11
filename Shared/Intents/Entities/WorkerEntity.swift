import AppIntents
import CloudflareKit
import CoreSpotlight
import UniformTypeIdentifiers

nonisolated struct WorkerEntity: IndexedEntity, Codable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Intents.Worker.Type")
    static let defaultQuery = WorkerEntityQuery()

    let accountId: String
    let name: String

    var id: String { "\(accountId)/\(name)" }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = name
        attributes.contentDescription = String(localized: .intentsWorkerType)
        return attributes
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "hammer"))
    }

    init(accountId: String, name: String) {
        self.accountId = accountId
        self.name = name
    }

    init?(id: String) {
        let components = id.split(separator: "/", maxSplits: 1).map(String.init)
        guard components.count == 2 else { return nil }
        self.init(accountId: components[0], name: components[1])
    }
}
