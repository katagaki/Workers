import Foundation

public struct UserProfile: Codable, Hashable, Sendable {
    public let id: String
    public let email: String?
    public let firstName: String?
    public let lastName: String?

    public var displayName: String? {
        let fullName = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !fullName.isEmpty { return fullName }
        guard let email, !email.isEmpty else { return nil }
        return email
    }
}
