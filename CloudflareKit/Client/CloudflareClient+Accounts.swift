import Foundation

public extension CloudflareClient {
    func verifyToken() async throws -> TokenVerification {
        try await result(path: "user/tokens/verify")
    }

    func accounts() async throws -> [Account] {
        try await allPages(path: "accounts")
    }
}
