import CloudflareKit
import SwiftUI

extension WorkerBinding {
    var typeTitle: String {
        switch type {
        case "durable_object_namespace": String(localized: .workersBindingsTypesDurableObjects)
        case "kv_namespace": String(localized: .workersBindingsTypesKvNamespaces)
        case "r2_bucket": String(localized: .workersBindingsTypesR2Buckets)
        case "d1": String(localized: .workersBindingsTypesD1Databases)
        case "queue": String(localized: .workersBindingsTypesQueues)
        case "service": String(localized: .workersBindingsTypesServices)
        case "plain_text": String(localized: .workersBindingsTypesVariables)
        case "secret_text": String(localized: .workersBindingsTypesSecrets)
        case "analytics_engine": String(localized: .workersBindingsTypesAnalyticsEngine)
        case "ai": String(localized: .workersBindingsTypesWorkersAI)
        case "vectorize": String(localized: .workersBindingsTypesVectorize)
        case "hyperdrive": String(localized: .workersBindingsTypesHyperdrive)
        case "assets": String(localized: .workersBindingsTypesStaticAssets)
        case "browser": String(localized: .workersBindingsTypesBrowserRendering)
        case "workflow": String(localized: .workersBindingsTypesWorkflows)
        default: type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var detail: String? {
        switch type {
        case "durable_object_namespace":
            if let className, let scriptName { return "\(className) · \(scriptName)" }
            return className ?? namespaceId
        case "kv_namespace": return namespaceId
        case "r2_bucket": return bucketName
        case "d1": return databaseId ?? id
        case "queue": return queueName
        case "service":
            if let service, let environment { return "\(service) · \(environment)" }
            return service
        case "plain_text": return text
        case "secret_text": return String(localized: .workersBindingsValueHidden)
        case "analytics_engine": return dataset
        default: return nil
        }
    }
}
