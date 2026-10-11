import CloudflareKit
import Foundation
import Observation

@Observable
final class AIPlaygroundModel {
    let client: CloudflareClient
    let accountId: String
    let models: CachedResource<[AIModel]>
    var modelName = ""
    var schema: AIModelSchema?
    var prompt = ""
    var temperature = 0.7
    var maximumTokens = 512
    var streamsResponse = false
    var response = ""
    var error: String?
    var isLoadingSchema = false
    var isRunning = false
    private var generation: Task<Void, Never>?

    init(client: CloudflareClient, accountId: String) {
        self.client = client
        self.accountId = accountId
        models = CachedResource(key: "ai-playground-models-\(accountId)")
        modelName = models.value?.first?.name ?? ""
    }

    var canRun: Bool {
        !modelName.isEmpty && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && schema != nil && !isLoadingSchema && !isRunning
            && (schema?.supports("prompt") == true || schema?.supports("messages") == true)
    }

    func loadModels() async {
        await models.refresh { try await client.aiTextModels(accountId: accountId) }
        if let available = models.value, !available.contains(where: { $0.name == modelName }) {
            modelName = available.first?.name ?? ""
        }
    }

    func loadSchema() async {
        schema = nil
        error = nil
        guard !modelName.isEmpty else { return }
        let requestedModel = modelName
        isLoadingSchema = true
        defer { if modelName == requestedModel { isLoadingSchema = false } }
        do {
            let fetched = try await client.aiModelSchema(accountId: accountId, modelName: requestedModel)
            try Task.checkCancellation()
            guard modelName == requestedModel else { return }
            schema = fetched
            streamsResponse = false
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            if modelName == requestedModel { self.error = error.localizedDescription }
        }
    }

    func run() {
        guard canRun, let schema else { return }
        var input: [String: JSONValue] = schema.supports("prompt")
            ? ["prompt": .string(prompt)]
            : ["messages": .array([.object(["role": .string("user"), "content": .string(prompt)])])]
        if schema.supports("temperature") { input["temperature"] = .number(temperature) }
        if schema.supports("max_tokens") { input["max_tokens"] = .number(Double(maximumTokens)) }
        let selectedModel = modelName
        let usesStream = streamsResponse && schema.supports("stream")
        response = ""
        error = nil
        isRunning = true
        generation = Task {
            defer { isRunning = false; generation = nil }
            do {
                if usesStream {
                    for try await text in client.streamAIText(accountId: accountId, modelName: selectedModel, input: input) {
                        try Task.checkCancellation()
                        response += text
                    }
                } else {
                    let text = try await client.runAIText(accountId: accountId, modelName: selectedModel, input: input)
                    try Task.checkCancellation()
                    response = text
                }
            } catch is CancellationError {
            } catch let urlError as URLError where urlError.code == .cancelled {
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func cancel() {
        generation?.cancel()
    }
}
