import Foundation

extension DemoAnalytics {
    static func aiResponse(query: String, buckets: [Date], hourly: Bool) -> [String: Any] {
        let modelIds = ["@cf/meta/llama-3.3-70b-instruct-fp8-fast", "@cf/baai/bge-base-en-v1.5", "@cf/black-forest-labs/flux-1-schnell"]
        let filterModel = value(after: "modelId: ", in: query)
        let groups = modelIds.filter { filterModel == nil || $0 == filterModel }.flatMap { modelId in
            buckets.enumerated().map { index, date -> [String: Any] in
                let seed = DemoData.stableHash(modelId) &+ index
                let requests = Int((hourly ? 18.0 : 432.0) * (0.7 + DemoData.noise(seed)))
                let neurons = Double(requests) * 2.3
                return [
                    "count": requests,
                    "sum": ["totalNeurons": neurons, "totalInputTokens": Double(requests * 180),
                            "totalOutputTokens": Double(requests * 75), "totalInferenceTimeMs": Double(requests * 230)],
                    "dimensions": [hourly ? "datetimeHour" : "date": hourly ? DemoData.iso(date) : date.formatted(.iso8601.year().month().day()),
                                   "modelId": modelId, "errorCode": index % 19 == 8 ? 3036 : 0]
                ]
            }
        }
        return ["viewer": ["accounts": [["aiInferenceAdaptiveGroups": groups]]]]
    }
}
