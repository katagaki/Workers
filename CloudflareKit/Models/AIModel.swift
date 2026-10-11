import Foundation

public struct AIModel: Codable, Hashable, Identifiable, Sendable {
    public struct TaskType: Codable, Hashable, Sendable {
        public let name: String
    }

    public let id: String
    public let name: String
    public let description: String?
    public let task: TaskType?
}
