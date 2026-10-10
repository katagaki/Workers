import Foundation
import Observation

@Observable
final class CachedResource<Value: Codable> {
    private(set) var value: Value?
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdated: Date?

    let key: String

    init(key: String) {
        self.key = key
        if let entry = DiskCache.shared.value(for: key, as: Value.self) {
            value = entry.value
            lastUpdated = entry.savedAt
        }
    }

    var hasLoadedOnce: Bool {
        value != nil
    }

    func refresh(_ fetch: () async throws -> Value) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await fetch()
            value = fetched
            lastUpdated = .now
            error = nil
            DiskCache.shared.store(fetched, for: key)
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            self.error = error
        }
    }

    func update(_ transform: (inout Value) -> Void) {
        guard var current = value else { return }
        transform(&current)
        value = current
        DiskCache.shared.store(current, for: key)
    }
}
