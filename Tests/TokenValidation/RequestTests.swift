import Foundation

final class RequestFixtures: @unchecked Sendable {
    static let shared = RequestFixtures()
    private let lock = NSLock()
    private var responses: [(Int, Data)] = []
    private var requests: [URLRequest] = []

    func enqueue(status: Int = 200, json: String) {
        lock.withLock { responses.append((status, Data(json.utf8))) }
    }

    func receive(_ request: URLRequest) -> (Int, Data) {
        lock.withLock {
            requests.append(request)
            precondition(!responses.isEmpty, "Unexpected request")
            return responses.removeFirst()
        }
    }

    var lastRequest: URLRequest { lock.withLock { requests.last! } }
}

final class FixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        let (status, data) = RequestFixtures.shared.receive(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@main
struct TokenValidationTests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let client = CloudflareClient(token: "fixture-only", session: URLSession(configuration: configuration))
        let fixtures = RequestFixtures.shared

        for statusCode in [401, 403] {
            for response in [#"{"success":false,"errors":[{"code":10000,"message":"Authentication error"}]}"#, "<html>Access denied</html>"] {
                fixtures.enqueue(status: statusCode, json: response)
                do {
                    _ = try await client.accounts()
                    preconditionFailure("Authentication failure must be surfaced")
                } catch CloudflareError.http(let actualStatus) {
                    precondition(actualStatus == statusCode, "Status must survive API error decoding")
                }
            }
        }

        fixtures.enqueue(status: 403, json: #"{"success":false,"errors":[{"message":"Forbidden"}]}"#)
        do {
            _ = try await client.accountsForSignIn()
            preconditionFailure("Missing account access must prevent sign-in")
        } catch CloudflareError.accountAccessDenied {}

        fixtures.enqueue(json: #"{"success":true,"result":[]}"#)
        do {
            _ = try await client.accountsForSignIn()
            preconditionFailure("An empty account list must prevent sign-in")
        } catch CloudflareError.noAccessibleAccounts {}

        fixtures.enqueue(json: #"{"success":true,"result":[{"id":"account","name":"Fixture Account"}]}"#)
        let accounts = try await client.accountsForSignIn()
        precondition(accounts.first?.id == "account", "An accessible account must allow sign-in")

        fixtures.enqueue(status: 400, json: #"{"success":false,"errors":[{"code":6003,"message":"Invalid request headers"}]}"#)
        do {
            _ = try await client.accountsForSignIn()
            preconditionFailure("Malformed authentication must prevent sign-in")
        } catch let error as CloudflareError {
            precondition(error.errorDescription == String(localized: .errorsInvalidToken), "Malformed authentication needs token guidance")
        }

        fixtures.enqueue(status: 401, json: #"{"success":false,"errors":[{"message":"Authentication error"}]}"#)
        do {
            _ = try await client.rawData(path: "storage", pathComponent: "key")
            preconditionFailure("Raw requests must surface authentication failures")
        } catch CloudflareError.http(statusCode: 401) {}

        let emptyClient = CloudflareClient(token: "", session: URLSession(configuration: configuration))
        do {
            _ = try await emptyClient.accountsForSignIn()
            preconditionFailure("An empty token must not send a request")
        } catch CloudflareError.missingToken {}

        precondition(CloudflareError.http(statusCode: 401).errorDescription == String(localized: .errorsInvalidToken))
        precondition(CloudflareError.http(statusCode: 403).errorDescription == String(localized: .errorsPermissionDenied))
        let permissionError = CloudflareError.graphQL(messages: ["Missing Account Analytics permission"])
        precondition(permissionError.errorDescription?.contains("Missing Account Analytics permission") == true, "Keep specific permission details")
        let unrelatedError = CloudflareError.api(messages: ["Invalid DNS record"])
        precondition(unrelatedError.errorDescription == "Invalid DNS record", "Unrelated API failures must remain intact")
        print("Token validation request tests passed")
    }
}
