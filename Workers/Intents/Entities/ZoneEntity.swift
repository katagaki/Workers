import AppIntents
import CloudflareKit

struct ZoneEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Intents.Zone.Type")
    static let defaultQuery = ZoneEntityQuery()

    let id: String
    let name: String
    let accountId: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "globe"))
    }

    init(zone: Zone) {
        id = zone.id
        name = zone.name
        accountId = zone.account?.id
    }
}
