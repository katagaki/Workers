import Foundation

public extension CloudflareClient {
    static let demoToken = "demo"

    static func demo() -> CloudflareClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DemoURLProtocol.self]
        return CloudflareClient(token: demoToken, session: URLSession(configuration: configuration))
    }

    var isDemo: Bool {
        token == Self.demoToken
    }
}
