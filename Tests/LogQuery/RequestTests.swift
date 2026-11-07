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
            var captured = request
            if captured.httpBody == nil, let stream = captured.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var data = Data()
                var buffer = [UInt8](repeating: 0, count: 4096)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    data.append(buffer, count: count)
                }
                captured.httpBody = data
            }
            requests.append(captured)
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

private let keys = LogQueryKey.merged(with: [
    LogQueryKey(key: "customerId", type: .string),
    LogQueryKey(key: "retries", type: .number),
    LogQueryKey(key: "cached", type: .boolean)
])

private func context(_ text: String, cursor: Int? = nil) -> LogQueryCompletionContext {
    LogQueryAutocomplete.context(in: text, cursor: cursor ?? text.count, keys: keys)
}

private func suggestions(_ text: String, cursor: Int? = nil, values: [LogQueryValue] = []) -> [LogQuerySuggestion] {
    LogQueryAutocomplete.suggestions(for: context(text, cursor: cursor), keys: keys, values: values)
}

private func filters(_ query: LogQuery) -> [LogQuery.Filter] {
    switch query.expression {
    case .filter(let filter): [filter]
    case .all(let parts): parts.map { part in
        guard case .filter(let filter) = part else { preconditionFailure("Expected a plain AND of filters") }
        return filter
    }
    default: preconditionFailure("Expected a plain AND of filters")
    }
}

private func filter(_ key: String, _ operation: LogQueryOperator, _ value: JSONValue?, _ type: LogQueryValueType = .string) -> LogQueryExpression {
    .filter(LogQuery.Filter(key: key, operation: operation, type: type, value: value))
}

private func parseError(_ text: String) -> LogQueryParseError? {
    do {
        _ = try LogQuery(parsing: text, keys: keys)
        return nil
    } catch {
        return error as? LogQueryParseError
    }
}

@main
struct LogQueryTests {
    static func main() async throws {
        testParsing()
        testConnectors()
        testParentheses()
        testCompletionContexts()
        testSuggestions()
        testApplying()
        try await testRequests()
        print("Log query tests passed")
    }

    static func testParsing() {
        let query = try! LogQuery(parsing: #"$metadata.level = error $metadata.statusCode>=500 customerId contains "acme corp" timeout reached"#, keys: keys)
        precondition(filters(query).count == 3)
        precondition(filters(query)[0].operation == .equals && filters(query)[0].value == .string("error"))
        precondition(filters(query)[1].type == .number && filters(query)[1].value == .number(500))
        precondition(filters(query)[2].operation == .contains && filters(query)[2].value == .string("acme corp"))
        precondition(query.searchText == "timeout reached")

        let plainText = try! LogQuery(parsing: "errors in production", keys: keys)
        precondition(plainText.expression == nil && plainText.searchText == "errors in production")

        let existence = try! LogQuery(parsing: "$metadata.error exists retries missing", keys: keys)
        precondition(filters(existence).map(\.operation) == [.exists, .missing])
        precondition(filters(existence).allSatisfy { $0.value == nil })
        precondition(filters(existence)[1].type == .number)

        let typed = try! LogQuery(parsing: #"$metadata.level = 200 cached = true $metadata.statusCode in 200,404 unseen.field = 7"#, keys: keys)
        precondition(filters(typed)[0].type == .string && filters(typed)[0].value == .string("200"))
        precondition(filters(typed)[1].type == .boolean && filters(typed)[1].value == .bool(true))
        precondition(filters(typed)[2].type == .number && filters(typed)[2].value == .string("200,404"))
        precondition(filters(typed)[3].type == .number && filters(typed)[3].value == .number(7))

        let url = try! LogQuery(parsing: "$metadata.url = https://example.com/?a=1", keys: keys)
        precondition(filters(url)[0].value == .string("https://example.com/?a=1"))

        let regex = try! LogQuery(parsing: #"$metadata.message matches "\d+ \"ok\"""#, keys: keys)
        precondition(filters(regex)[0].value == .string(#"\d+ "ok""#))

        let curly = try! LogQuery(parsing: "\u{201C}hello there\u{201D}", keys: keys)
        precondition(curly.searchText == "hello there")

        precondition(try! LogQuery(parsing: "   ", keys: keys).expression == nil)
        precondition(parseError("$metadata.level =") == .missingValue)
        precondition(parseError("$metadata.level = \"") == .unterminatedQuote)
        precondition(parseError("\"open") == .unterminatedQuote)
        precondition(parseError("$metadata.statusCode > abc") == .invalidValue)
        precondition(parseError("cached = maybe") == .invalidValue)
    }

    static func testConnectors() {
        let level = filter("$metadata.level", .equals, .string("error"))
        let retries = filter("retries", .greater, .number(2), .number)
        let cached = filter("cached", .equals, .bool(true), .boolean)
        let either = try! LogQuery(parsing: "$metadata.level = error OR retries > 2 cached = true", keys: keys)
        precondition(either.expression == .any([level, .all([retries, cached])]) && either.searchText == nil)

        let explicit = try! LogQuery(parsing: "$metadata.level = error AND retries > 2", keys: keys)
        precondition(filters(explicit).count == 2)

        let plainWords = try! LogQuery(parsing: "this or that and more", keys: keys)
        precondition(plainWords.expression == nil && plainWords.searchText == "this or that and more")
        let quoted = try! LogQuery(parsing: #""OR" $metadata.level = OR"#, keys: keys)
        precondition(quoted.searchText == "OR" && filters(quoted)[0].value == .string("OR"))

        let text = try! LogQuery(parsing: "timeout reached OR a.b(c)", keys: keys)
        precondition(text.expression == nil && text.isSearchRegex)
        precondition(text.searchText == #"timeout reached|a\.b\(c\)"#)

        let shared = try! LogQuery(parsing: "timeout retries > 1 OR timeout cached = true", keys: keys)
        precondition(shared.searchText == "timeout" && !shared.isSearchRegex)
        guard case .any(let sharedBranches) = shared.expression else { preconditionFailure() }
        precondition(sharedBranches.count == 2)

        precondition(parseError("OR retries > 1") == .missingCondition)
        precondition(parseError("retries > 1 OR") == .missingCondition)
        precondition(parseError("retries > 1 AND") == .missingCondition)
        precondition(parseError("retries > 1 OR OR cached = true") == .missingCondition)
        precondition(parseError("retries > 1 OR timeout") == .mixedSearch)
        precondition(parseError("one retries > 1 OR two cached = true") == .mixedSearch)
    }

    static func testParentheses() {
        let level = filter("$metadata.level", .equals, .string("error"))
        let warn = filter("$metadata.level", .equals, .string("warn"))
        let retries = filter("retries", .greater, .number(2), .number)
        let cached = filter("cached", .equals, .bool(true), .boolean)

        let grouped = try! LogQuery(parsing: "($metadata.level = error OR $metadata.level = warn) retries > 2", keys: keys)
        precondition(grouped.expression == .all([.any([level, warn]), retries]))
        let glued = try! LogQuery(parsing: "retries>2 ($metadata.level=error OR $metadata.level=warn)", keys: keys)
        precondition(glued.expression == .all([retries, .any([level, warn])]))
        let nested = try! LogQuery(parsing: "((retries > 2))", keys: keys)
        precondition(nested.expression == retries)
        let deep = try! LogQuery(parsing: "(retries > 2 OR (cached = true $metadata.level = error)) OR $metadata.level = warn", keys: keys)
        precondition(deep.expression == .any([retries, .all([cached, level]), warn]))
        let existence = try! LogQuery(parsing: "(retries exists OR cached missing)", keys: keys)
        precondition(existence.expression.map { if case .any(let branches) = $0 { branches.count == 2 } else { false } } == true)

        let balanced = try! LogQuery(parsing: "($metadata.message = f(x) OR $metadata.message matches (a|b))", keys: keys)
        guard case .any(let branches) = balanced.expression,
              case .filter(let first) = branches[0], case .filter(let second) = branches[1] else { preconditionFailure() }
        precondition(first.value == .string("f(x)") && second.value == .string("(a|b)"))
        let url = try! LogQuery(parsing: "$metadata.url = https://example.com/(path)", keys: keys)
        precondition(filters(url)[0].value == .string("https://example.com/(path)"))
        let closing = try! LogQuery(parsing: "(retries = 1 OR $metadata.message = f(x))", keys: keys)
        guard case .any(let closingBranches) = closing.expression, case .filter(let closingLast) = closingBranches[1] else { preconditionFailure() }
        precondition(closingLast.value == .string("f(x)"))
        let smile = try! LogQuery(parsing: "smile :)", keys: keys)
        precondition(smile.expression == nil && smile.searchText == "smile :)")

        let sharedText = try! LogQuery(parsing: "timeout ($metadata.level = error OR $metadata.level = warn)", keys: keys)
        precondition(sharedText.searchText == "timeout" && !sharedText.isSearchRegex)
        precondition(sharedText.expression == .any([level, warn]))
        let textGroup = try! LogQuery(parsing: "retries > 2 (timeout OR failed)", keys: keys)
        precondition(textGroup.expression == retries && textGroup.searchText == "timeout|failed" && textGroup.isSearchRegex)
        let textOnly = try! LogQuery(parsing: "(timeout reached OR a.b) final", keys: keys)
        precondition(textOnly.expression == nil && textOnly.searchText == #"(?:timeout reached|a\.b) final"#)
        let groupedPhrase = try! LogQuery(parsing: "(timeout reached)", keys: keys)
        precondition(groupedPhrase.searchText == "timeout reached" && !groupedPhrase.isSearchRegex)

        precondition(parseError("(retries > 2") == .unbalancedParentheses)
        precondition(parseError("((retries > 2)") == .unbalancedParentheses)
        precondition(parseError("()") == .missingCondition)
        precondition(parseError("(retries > 2 OR)") == .missingCondition)
        precondition(parseError("(OR retries > 2)") == .missingCondition)
        precondition(parseError("retries > 2 AND (cached = true") == .unbalancedParentheses)
        precondition(parseError("(retries = )") == .missingValue)
        precondition(parseError("($metadata.level = error OR timeout)") == .mixedSearch)
        _ = cached
    }

    static func testCompletionContexts() {
        precondition(context("").position == .key)
        precondition(context("lev").position == .key && context("lev").partial == "lev")
        precondition(context("$metadata.level ").position == .operation(key: "$metadata.level"))
        precondition(context("$metadata.level co").position == .operation(key: "$metadata.level"))
        precondition(context("$metadata.level contains").position == .operation(key: "$metadata.level"))
        precondition(context("$metadata.level =").position == .value(key: "$metadata.level", operation: .equals))
        precondition(context("$metadata.level = er").partial == "er")
        precondition(context("$metadata.level contains ").position == .value(key: "$metadata.level", operation: .contains))
        precondition(context(#"$metadata.level = "out of"#).position == .value(key: "$metadata.level", operation: .equals))
        precondition(context(#"$metadata.level = "out of"#).partial == "out of")
        precondition(context("$metadata.level = error ").position == .key)
        precondition(context("$metadata.error exists ").position == .key)
        precondition(context(#""free text"#).position == .none)
        precondition(context(#""free text" "#).position == .key)
        precondition(context("timeout ").position == .key)
        precondition(context("hello wor").position == .key && context("hello wor").partial == "wor")

        let middle = "$metadata.level = error retries > 2"
        precondition(context(middle, cursor: 5).position == .key && context(middle, cursor: 5).partial == "$meta")
        precondition(context(middle, cursor: 20).position == .value(key: "$metadata.level", operation: .equals))
    }

    static func testSuggestions() {
        precondition(suggestions("").first?.text == "$metadata.message")
        precondition(suggestions("").count == 12)
        precondition(suggestions("level").first?.text == "$metadata.level")
        precondition(suggestions("$met").allSatisfy { $0.text.hasPrefix("$metadata") })
        precondition(suggestions("CUST").first?.text == "customerId")
        precondition(suggestions("zzzzz").isEmpty)
        precondition(suggestions("retries ").map(\.text).contains(">="))
        precondition(!suggestions("retries ").map(\.text).contains("contains"))
        precondition(suggestions("cached ").map(\.text) == ["=", "!=", "exists", "missing"])
        precondition(suggestions("$metadata.level sta").map(\.text) == ["starts"])
        precondition(suggestions("retries > 2 ").prefix(2).map(\.text) == ["OR", "AND"])
        precondition(suggestions("timeout ").first?.text == "OR")
        precondition(suggestions("retries > 2 o").first?.text == "OR")
        precondition(suggestions("retries > 2 OR ").first?.text == "$metadata.message")
        precondition(suggestions("retries > 2 OR sta").first?.text == "$metadata.statusCode")
        precondition(suggestions("$metadata.error exists ").first?.text == "OR")
        precondition(suggestions(#""free text" "#).first?.text == "OR")
        precondition(suggestions("(").first?.text == "$metadata.message")
        precondition(suggestions("retries > 2 (").first?.text == "$metadata.message")
        precondition(suggestions("(lev").first?.text == "$metadata.level")
        precondition(suggestions("(retries > 2) ").first?.text == "OR")
        precondition(suggestions("(retries > 2 ").first?.text == "OR")
        precondition(suggestions("(retries > 2)").isEmpty)
        precondition(suggestions("(cached ").map(\.text) == ["=", "!=", "exists", "missing"])
        let values = ["error", "warn", "log"].map {
            LogQueryValue(key: "$metadata.level", type: .string, value: .string($0))
        }
        precondition(suggestions("$metadata.level = ", values: values).count == 3)
        precondition(suggestions("$metadata.level = er", values: values).map(\.text) == ["error"])
        precondition(suggestions("$metadata.level = error", values: values).isEmpty)
    }

    static func testApplying() {
        func apply(_ text: String, cursor: Int? = nil, values: [LogQueryValue] = []) -> (text: String, cursor: Int) {
            LogQueryAutocomplete.applying(suggestions(text, cursor: cursor, values: values)[0], to: text)
        }
        let key = apply("lev")
        precondition(key.text == "$metadata.level " && key.cursor == key.text.count)

        let operation = apply("$metadata.level sta")
        precondition(operation.text == "$metadata.level starts " && operation.cursor == operation.text.count)

        let insideGroup = apply("(lev)", cursor: 4)
        precondition(insideGroup.text == "($metadata.level)" && insideGroup.cursor == "($metadata.level".count)
        let groupValues = ["error"].map { LogQueryValue(key: "$metadata.level", type: .string, value: .string($0)) }
        let valueInGroup = apply("($metadata.level = er)", cursor: 20, values: groupValues)
        precondition(valueInGroup.text == "($metadata.level = error)")

        let connector = apply("retries > 2 o")
        precondition(connector.text == "retries > 2 OR " && connector.cursor == connector.text.count)

        let spaced = [LogQueryValue(key: "$metadata.message", type: .string, value: .string(#"said "hi" now"#))]
        let value = apply("$metadata.message = sa", values: spaced)
        precondition(value.text == #"$metadata.message = "said \"hi\" now" "#)
        let reparsed = try! LogQuery(parsing: value.text, keys: keys)
        precondition(filters(reparsed)[0].value == .string(#"said "hi" now"#))

        let quoted = apply(#"$metadata.message = "sa"#, values: spaced)
        precondition(quoted.text == #"$metadata.message = "said \"hi\" now" "#)

        let middle = apply("$me retries > 2", cursor: 3)
        precondition(middle.text == "$metadata.url retries > 2")
        precondition(middle.cursor == "$metadata.url ".count)

        let insideWord = apply("$metadata.lev > 1", cursor: 11)
        precondition(insideWord.text == "$metadata.level > 1")

        let emoji = apply("\u{1F600} lev")
        precondition(emoji.text == "\u{1F600} $metadata.level ")
        precondition(emoji.cursor == emoji.text.count)
    }

    static func testRequests() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let client = CloudflareClient(token: "fixture-only", session: URLSession(configuration: configuration))
        let fixtures = RequestFixtures.shared
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)

        fixtures.enqueue(json: #"{"success":true,"result":{"events":{"events":[]}}}"#)
        let query = try LogQuery(parsing: "$metadata.statusCode >= 500 $metadata.error exists timeout", keys: keys)
        _ = try await client.workerEvents(accountId: "account", scriptName: "script", matching: query, from: start, to: end)
        precondition(fixtures.lastRequest.url?.path == "/client/v4/accounts/account/workers/observability/telemetry/query")
        let queryBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        let parameters = queryBody["parameters"] as! [String: Any]
        let filters = parameters["filters"] as! [[String: Any]]
        precondition(filters.count == 3)
        precondition(filters[0]["key"] as? String == "$metadata.service" && filters[0]["value"] as? String == "script")
        precondition(filters[1]["operation"] as? String == "gte" && filters[1]["type"] as? String == "number")
        precondition(filters[1]["value"] as? Double == 500)
        precondition(filters[2]["operation"] as? String == "exists" && filters[2]["value"] == nil)
        let needle = parameters["needle"] as? [String: Any]
        precondition(needle?["value"] as? String == "timeout" && needle?["isRegex"] == nil)

        fixtures.enqueue(json: #"{"success":true,"result":{"events":{"events":[]}}}"#)
        _ = try await client.workerEvents(accountId: "account", scriptName: "script", from: start, to: end)
        let plainBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition((plainBody["parameters"] as! [String: Any])["needle"] == nil)

        fixtures.enqueue(json: #"{"success":true,"result":{"events":{"events":[]}}}"#)
        let either = try LogQuery(parsing: "$metadata.level = error OR retries > 2 cached = true", keys: keys)
        _ = try await client.workerEvents(accountId: "account", scriptName: "script", matching: either, from: start, to: end)
        let eitherBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        let eitherParameters = eitherBody["parameters"] as! [String: Any]
        let eitherFilters = eitherParameters["filters"] as! [[String: Any]]
        precondition(eitherParameters["filterCombination"] == nil && eitherFilters.count == 2)
        precondition(eitherFilters[0]["key"] as? String == "$metadata.service" && eitherFilters[0]["kind"] == nil)
        precondition(eitherFilters[1]["kind"] as? String == "group" && eitherFilters[1]["filterCombination"] as? String == "or")
        let branches = eitherFilters[1]["filters"] as! [[String: Any]]
        precondition(branches[0]["key"] as? String == "$metadata.level")
        precondition(branches[1]["kind"] as? String == "group" && branches[1]["filterCombination"] as? String == "and")
        precondition((branches[1]["filters"] as! [[String: Any]]).count == 2)

        fixtures.enqueue(json: #"{"success":true,"result":{"events":{"events":[]}}}"#)
        let grouped = try LogQuery(parsing: "($metadata.level = error OR retries > 2) cached = true", keys: keys)
        _ = try await client.workerEvents(accountId: "account", scriptName: "script", matching: grouped, from: start, to: end)
        let groupedBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        let groupedFilters = (groupedBody["parameters"] as! [String: Any])["filters"] as! [[String: Any]]
        precondition(groupedFilters.count == 3)
        precondition(groupedFilters[1]["kind"] as? String == "group" && groupedFilters[1]["filterCombination"] as? String == "or")
        precondition((groupedFilters[1]["filters"] as! [[String: Any]]).count == 2)
        precondition(groupedFilters[2]["key"] as? String == "cached" && groupedFilters[2]["kind"] == nil)

        fixtures.enqueue(json: #"{"success":true,"result":{"events":{"events":[]}}}"#)
        let textOnly = try LogQuery(parsing: "timeout OR failed", keys: keys)
        _ = try await client.workerEvents(accountId: "account", scriptName: "script", matching: textOnly, from: start, to: end)
        let textBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        let textParameters = textBody["parameters"] as! [String: Any]
        precondition((textParameters["filters"] as! [[String: Any]]).count == 1)
        let textNeedle = textParameters["needle"] as! [String: Any]
        precondition(textNeedle["value"] as? String == "timeout|failed" && textNeedle["isRegex"] as? Bool == true)

        fixtures.enqueue(json: #"{"success":true,"errors":[],"messages":[],"result":[{"key":"$metadata.level","lastSeenAt":0,"type":"string"},{"key":"retries","lastSeenAt":0,"type":"number"}]}"#)
        let discovered = try await client.workerLogKeys(accountId: "account", scriptName: "script", from: start, to: end)
        precondition(discovered.map(\.key) == ["$metadata.level", "retries"] && discovered[1].type == .number)
        precondition(fixtures.lastRequest.url?.path == "/client/v4/accounts/account/workers/observability/telemetry/keys")
        let keysBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(keysBody["from"] as? Int == 1_000_000 && keysBody["to"] as? Int == 2_000_000)
        precondition((keysBody["filters"] as! [[String: Any]])[0]["value"] as? String == "script")

        fixtures.enqueue(json: #"{"success":true,"errors":[],"messages":[],"result":[{"dataset":"cloudflare-workers","key":"retries","type":"number","value":3}]}"#)
        let key = LogQueryKey(key: "retries", type: .number)
        let values = try await client.workerLogValues(accountId: "account", scriptName: "script", key: key, from: start, to: end)
        precondition(values.first?.value == .number(3))
        precondition(fixtures.lastRequest.url?.path == "/client/v4/accounts/account/workers/observability/telemetry/values")
        let valuesBody = try JSONSerialization.jsonObject(with: fixtures.lastRequest.httpBody!) as! [String: Any]
        precondition(valuesBody["key"] as? String == "retries" && valuesBody["type"] as? String == "number")
        precondition((valuesBody["datasets"] as? [String])?.isEmpty == true)
        precondition((valuesBody["timeframe"] as? [String: Any])?["from"] as? Int == 1_000_000)
    }
}
