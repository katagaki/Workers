import SwiftUI

struct AIPlaygroundOptionsSection: View {
    @Bindable var model: AIPlaygroundModel

    var body: some View {
        Section {
            if model.isLoadingSchema { ProgressView() }
            if model.schema?.supports("temperature") == true {
                LabeledContent(.workersAIPlaygroundTemperature, value: model.temperature.formatted(.number.precision(.fractionLength(1))))
                Slider(value: $model.temperature, in: 0...1, step: 0.1) {
                    Text(.workersAIPlaygroundTemperature)
                }
            }
            if model.schema?.supports("max_tokens") == true {
                Stepper(value: $model.maximumTokens, in: 128...2048, step: 128) {
                    LabeledContent(.workersAIPlaygroundMaxTokens, value: model.maximumTokens.formatted())
                }
            }
            if model.schema?.supports("stream") == true {
                Toggle(.workersAIPlaygroundStreaming, isOn: $model.streamsResponse)
            }
        } header: {
            Text(.workersAIPlaygroundOptions)
        }
        .disabled(model.isRunning)
    }
}
