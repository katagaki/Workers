import Foundation

nonisolated struct SavedToken: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String

    var keychainKey: String { "APIToken.\(id.uuidString)" }
}
