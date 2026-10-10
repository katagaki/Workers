enum AppTab: Hashable {
    case workers
    case storage
    case workersAI
    case domains
    case analytics
    case worker(name: String)
    case storageCategory(StorageCategory)
    case zone(id: String)

    /// The tab bar tab a sidebar item belongs to, for when the sidebar is not available.
    var tabBarTab: AppTab {
        switch self {
        case .worker: .workers
        case .storageCategory: .storage
        case .zone: .domains
        default: self
        }
    }
}

extension AppTab: RawRepresentable {
    init?(rawValue: String) {
        let parts = rawValue.split(separator: ":", maxSplits: 1).map(String.init)
        switch (parts.first, parts.count == 2 ? parts[1] : nil) {
        case ("workers", nil): self = .workers
        case ("storage", nil): self = .storage
        case ("workersAI", nil): self = .workersAI
        case ("domains", nil): self = .domains
        case ("analytics", nil): self = .analytics
        case ("more", nil): self = .workers
        case ("worker", let name?): self = .worker(name: name)
        case ("storage", let category?):
            guard let category = StorageCategory(rawValue: category) else { return nil }
            self = .storageCategory(category)
        case ("zone", let id?): self = .zone(id: id)
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .workers: "workers"
        case .storage: "storage"
        case .workersAI: "workersAI"
        case .domains: "domains"
        case .analytics: "analytics"
        case .worker(let name): "worker:\(name)"
        case .storageCategory(let category): "storage:\(category.rawValue)"
        case .zone(let id): "zone:\(id)"
        }
    }
}
