import CloudflareKit
import SwiftUI

enum DomainsDestination: Hashable {
    case dnsRecords(Zone)
    case workerRoutes(zoneId: String)

    @ViewBuilder
    func view(client: CloudflareClient) -> some View {
        switch self {
        case .dnsRecords(let zone):
            DNSRecordsView(client: client, zone: zone)
        case .workerRoutes(let zoneId):
            ZoneWorkerRoutesView(client: client, zoneId: zoneId)
        }
    }
}
