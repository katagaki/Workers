import Foundation

public extension CloudflareClient {
    func verifyToken() async throws -> TokenVerification {
        try await result(path: "user/tokens/verify")
    }

    func userProfile() async throws -> UserProfile {
        try await result(path: "user")
    }

    func accountsForSignIn() async throws -> [Account] {
        let accessibleAccounts: [Account]
        do {
            accessibleAccounts = try await accounts()
        } catch CloudflareError.http(statusCode: 403) {
            throw CloudflareError.accountAccessDenied
        }
        guard !accessibleAccounts.isEmpty else {
            throw CloudflareError.noAccessibleAccounts
        }
        return accessibleAccounts
    }

    func accounts() async throws -> [Account] {
        try await allPages(path: "accounts")
    }
}
