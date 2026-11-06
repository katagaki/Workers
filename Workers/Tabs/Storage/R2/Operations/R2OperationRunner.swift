import Foundation
import Observation

@Observable
final class R2OperationRunner {
    private(set) var title: LocalizedStringResource?
    private(set) var completedCount = 0
    private(set) var totalCount = 0
    var failureMessage: String?

    private var task: Task<Void, Error>?

    var isRunning: Bool { title != nil }

    @discardableResult
    func run(_ title: LocalizedStringResource, work: @escaping @MainActor () async throws -> Void) async -> Bool {
        guard !isRunning else { return false }
        self.title = title
        report(completed: 0, total: 0)
        let task = Task { try await work() }
        self.task = task
        defer {
            self.title = nil
            self.task = nil
        }
        do {
            try await task.value
            return true
        } catch is CancellationError {
            return false
        } catch let urlError as URLError where urlError.code == .cancelled {
            return false
        } catch {
            failureMessage = error.localizedDescription
            return false
        }
    }

    func report(completed: Int, total: Int) {
        completedCount = completed
        totalCount = total
    }

    func cancel() {
        task?.cancel()
    }
}
