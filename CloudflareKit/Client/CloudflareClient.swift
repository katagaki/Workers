import Foundation

public final class CloudflareClient: Sendable {
    public static let apiBaseURL = URL(string: "https://api.cloudflare.com/client/v4")!

    let token: String
    let session: URLSession

    public init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    func makeRequest(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil
    ) throws -> URLRequest {
        guard !token.isEmpty else { throw CloudflareError.missingToken }
        var components = URLComponents(
            url: Self.apiBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else { throw CloudflareError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    func send<Result: Decodable>(
        _ method: HTTPMethod = .get,
        path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        as resultType: Result.Type = Result.self
    ) async throws -> APIEnvelope<Result> {
        let request = try makeRequest(method, path: path, query: query, body: body)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareError.invalidResponse
        }
        if [401, 403].contains(httpResponse.statusCode) {
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        let envelope = try? CloudflareJSON.makeDecoder().decode(APIEnvelope<Result>.self, from: data)
        if let envelope, let errors = envelope.errors, !errors.isEmpty, envelope.success != true {
            throw CloudflareError.api(messages: errors.map(\.message))
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        if let envelope {
            return envelope
        }
        _ = try CloudflareJSON.makeDecoder().decode(APIEnvelope<Result>.self, from: data)
        throw CloudflareError.invalidResponse
    }

    func result<Result: Decodable>(
        _ method: HTTPMethod = .get,
        path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> Result {
        let envelope: APIEnvelope<Result> = try await send(method, path: path, query: query, body: body)
        guard let result = envelope.result else { throw CloudflareError.invalidResponse }
        return result
    }

    func allPages<Item: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        perPage: Int = 50
    ) async throws -> [Item] {
        var items: [Item] = []
        var page = 1
        while true {
            let pageQuery = query + [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
            let envelope: APIEnvelope<[Item]> = try await send(path: path, query: pageQuery)
            let pageItems = envelope.result ?? []
            items.append(contentsOf: pageItems)
            let totalPages = envelope.resultInfo?.totalPages ?? 1
            if pageItems.isEmpty || page >= totalPages {
                break
            }
            page += 1
        }
        return items
    }

    func rawData(path: String, pathComponent: String) async throws -> Data {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#%")
        let encodedComponent = pathComponent.addingPercentEncoding(withAllowedCharacters: allowed) ?? pathComponent
        guard let url = URL(string: Self.apiBaseURL.absoluteString + "/" + path + "/" + encodedComponent) else {
            throw CloudflareError.invalidResponse
        }
        var request = try makeRequest(.get, path: path)
        request.url = url
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareError.invalidResponse
        }
        if [401, 403].contains(httpResponse.statusCode) {
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let envelope = try? CloudflareJSON.makeDecoder().decode(APIEnvelope<JSONValue>.self, from: data),
               let errors = envelope.errors, !errors.isEmpty {
                throw CloudflareError.api(messages: errors.map(\.message))
            }
            throw CloudflareError.http(statusCode: httpResponse.statusCode)
        }
        return data
    }

    func encode(_ value: some Encodable) throws -> Data {
        try CloudflareJSON.makeEncoder().encode(value)
    }
}
