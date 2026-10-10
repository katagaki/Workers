import Foundation

struct ZonesViewer<ZoneData: Decodable>: Decodable {
    let zones: [ZoneData]
}
