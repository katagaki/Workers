import AppIntents
import CloudflareKit
import CoreSpotlight
import UniformTypeIdentifiers

nonisolated struct ZoneEntity: IndexedEntity, Codable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Intents.Zone.Type")
    static let defaultQuery = ZoneEntityQuery()

    let id: String
    let name: String
    let accountId: String?

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = name
        attributes.contentDescription = String(localized: .intentsZoneType)
        return attributes
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "globe"))
    }

    init(zone: Zone) {
        id = zone.id
        name = zone.name
        accountId = zone.account?.id
    }
}
