import Foundation

public enum R2UploadEvent: Sendable {
    case progress(id: UUID, sentBytes: Int64)
    case finished(id: UUID, failureMessage: String?)
    case backgroundEventsDelivered
}

public struct R2ActiveUpload: Sendable {
    public let id: UUID
    public let sentBytes: Int64
}

public final class R2BackgroundUploader: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    public static let sessionIdentifier = "com.tsubuzaki.Workers.r2-uploads"
    public static let shared = R2BackgroundUploader(identifier: sessionIdentifier)

    public let events: AsyncStream<R2UploadEvent>

    private let continuation: AsyncStream<R2UploadEvent>.Continuation
    private let lock = NSLock()
    private var responseBodies: [Int: Data] = [:]
    private var session: URLSession!

    private static let responseBodyLimit = 65_536

    public init(identifier: String) {
        (events, continuation) = AsyncStream.makeStream()
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    public func start(id: UUID, request: URLRequest, fileURL: URL) {
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.taskDescription = id.uuidString
        task.resume()
    }

    public func cancel(id: UUID) async {
        for task in await session.allTasks where task.taskDescription == id.uuidString {
            task.cancel()
        }
    }

    public func cancelAll() async {
        for task in await session.allTasks {
            task.cancel()
        }
    }

    public func activeUploads() async -> [R2ActiveUpload] {
        await session.allTasks.compactMap { task in
            guard let id = task.taskDescription.flatMap(UUID.init(uuidString:)) else { return nil }
            return R2ActiveUpload(id: id, sentBytes: task.countOfBytesSent)
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard let id = task.taskDescription.flatMap(UUID.init(uuidString:)) else { return }
        continuation.yield(.progress(id: id, sentBytes: totalBytesSent))
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock {
            let existing = responseBodies[dataTask.taskIdentifier] ?? Data()
            guard existing.count < Self.responseBodyLimit else { return }
            responseBodies[dataTask.taskIdentifier] = existing + data
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let body = lock.withLock { responseBodies.removeValue(forKey: task.taskIdentifier) } ?? Data()
        guard let id = task.taskDescription.flatMap(UUID.init(uuidString:)) else { return }
        continuation.yield(.finished(id: id, failureMessage: Self.failureMessage(for: task, error: error, body: body)))
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        continuation.yield(.backgroundEventsDelivered)
    }

    private static func failureMessage(for task: URLSessionTask, error: Error?, body: Data) -> String? {
        if let error {
            return error.localizedDescription
        }
        guard let response = task.response else {
            return CloudflareError.invalidResponse.localizedDescription
        }
        do {
            try CloudflareClient.validateRawResponse(response, data: body)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
