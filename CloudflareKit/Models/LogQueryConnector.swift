import Foundation

public enum LogQueryConnector: String, CaseIterable, Hashable, Sendable {
    case or = "OR"
    case and = "AND"
}
