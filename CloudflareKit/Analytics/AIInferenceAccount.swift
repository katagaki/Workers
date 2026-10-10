import Foundation

struct AIInferenceAccount: Decodable {
    struct Group: Decodable {
        struct Sum: Decodable {
            let totalNeurons: Double
            let totalInputTokens: Double
            let totalOutputTokens: Double
            let totalInferenceTimeMs: Double
        }

        struct Dimensions: Decodable {
            let datetimeHour: Date?
            let date: Date?
            let modelId: String
            let errorCode: Int
        }

        let count: Int
        let sum: Sum
        let dimensions: Dimensions
    }

    let aiInferenceAdaptiveGroups: [Group]
}
