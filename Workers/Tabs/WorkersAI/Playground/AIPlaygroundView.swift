import CloudflareKit
import SwiftUI

struct AIPlaygroundView: View {
    @State private var model: AIPlaygroundModel

    init(client: CloudflareClient, accountId: String) {
        _model = State(initialValue: AIPlaygroundModel(client: client, accountId: accountId))
    }

    var body: some View {
        @Bindable var model = model
        List {
            Section {
                if let models = model.models.value, !models.isEmpty {
                    Picker(.workersAIPlaygroundModel, selection: $model.modelName) {
                        ForEach(models) { available in
                            Text(available.name).tag(available.name)
                        }
                    }
                    .disabled(model.isRunning)
                } else {
                    AnalyticsSectionStatus(resource: model.models)
                    if model.models.value?.isEmpty == true {
                        Text(.workersAIPlaygroundNoModels).foregroundStyle(.secondary)
                    }
                }
                if let error = model.models.error { Text(error.localizedDescription).foregroundStyle(.secondary) }
            } header: {
                Text(.workersAIPlaygroundModel)
            } footer: {
                Text(.workersAIPlaygroundPermission)
            }
            Section {
                TextField(.workersAIPlaygroundPromptPlaceholder, text: $model.prompt, axis: .vertical)
                    .lineLimit(4...12)
                    .disabled(model.isRunning)
                    .accessibilityIdentifier("PlaygroundPrompt")
            } header: {
                Text(.workersAIPlaygroundPrompt)
            }
            AIPlaygroundOptionsSection(model: model)
            Section {
                if model.isRunning {
                    HStack {
                        ProgressView()
                        Button(.workersAIPlaygroundStop, role: .cancel) { model.cancel() }
                    }
                } else {
                    Button(.workersAIPlaygroundRun, systemImage: "play.fill") { model.run() }
                        .disabled(!model.canRun)
                        .accessibilityIdentifier("PlaygroundRun")
                }
                if let error = model.error {
                    Text(error).foregroundStyle(.red)
                }
                if let schema = model.schema, !schema.supports("prompt"), !schema.supports("messages") {
                    Text(.workersAIPlaygroundUnsupported).foregroundStyle(.secondary)
                }
            } footer: {
                Text(model.client.isDemo ? .workersAIPlaygroundDemo : .workersAIPlaygroundUsage)
            }
            if !model.response.isEmpty {
                Section {
                    Text(model.response).textSelection(.enabled)
                        .accessibilityIdentifier("PlaygroundResponse")
                    ShareLink(item: model.response)
                } header: {
                    Text(.workersAIPlaygroundResponse)
                }
            }
        }
        .navigationTitle(.workersAIPlaygroundTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadModels() }
        .task(id: model.modelName) { await model.loadSchema() }
        .refreshable { await model.loadModels(); await model.loadSchema() }
        .onDisappear { model.cancel() }
    }
}
