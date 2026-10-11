import Foundation

public extension CloudflareClient {
    func aiTextModels(accountId: String) async throws -> [AIModel] {
        try await allPages(path: "accounts/\(accountId)/ai/models/search", query: [
            URLQueryItem(name: "task", value: "Text Generation"),
            URLQueryItem(name: "hide_experimental", value: "true")
        ], perPage: 100)
    }

    func aiModelSchema(accountId: String, modelName: String) async throws -> AIModelSchema {
        try await result(path: "accounts/\(accountId)/ai/models/schema", query: [URLQueryItem(name: "model", value: modelName)])
    }

    func runAIText(accountId: String, modelName: String, input: [String: JSONValue]) async throws -> String {
        let response: JSONValue = try await result(.post, path: "accounts/\(accountId)/ai/run/\(modelName)", body: try encode(input))
        guard let text = response["response"]?.stringValue else { throw CloudflareError.invalidResponse }
        return text
    }

    func streamAIText(accountId: String, modelName: String, input: [String: JSONValue]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    if isDemo {
                        let text = try await runAIText(accountId: accountId, modelName: modelName, input: input)
                        for word in text.split(separator: " ") {
                            try await Task.sleep(for: .milliseconds(35))
                            continuation.yield(String(word) + " ")
                        }
                    } else {
                        var streamedInput = input
                        streamedInput["stream"] = .bool(true)
                        var request = try makeRequest(.post, path: "accounts/\(accountId)/ai/run/\(modelName)", body: try encode(streamedInput))
                        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                        let (bytes, response) = try await session.bytes(for: request)
                        guard let response = response as? HTTPURLResponse else { throw CloudflareError.invalidResponse }
                        guard (200..<300).contains(response.statusCode) else {
                            throw CloudflareError.http(statusCode: response.statusCode)
                        }
                        var receivedText = false
                        for try await line in bytes.lines {
                            try Task.checkCancellation()
                            guard line.hasPrefix("data:") else { continue }
                            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            if payload == "[DONE]" { break }
                            let value = try JSONDecoder().decode(JSONValue.self, from: Data(payload.utf8))
                            if let error = value["error"] {
                                throw CloudflareError.api(messages: [error["message"]?.stringValue ?? error.displayText])
                            }
                            if let text = value["response"]?.stringValue {
                                receivedText = true
                                continuation.yield(text)
                            }
                        }
                        guard receivedText else { throw CloudflareError.invalidResponse }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
