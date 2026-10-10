import Foundation

public final class WorkerTailSession: Sendable {
    private let client: CloudflareClient
    private let accountId: String
    private let scriptName: String
    private let state = TailState()

    public init(client: CloudflareClient, accountId: String, scriptName: String) {
        self.client = client
        self.accountId = accountId
        self.scriptName = scriptName
    }

    public func events() -> AsyncThrowingStream<TailEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.run(continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await self.stop() }
            }
        }
    }

    public func stop() async {
        guard let tail = await state.takeTail() else { return }
        await state.socket?.cancel(with: .goingAway, reason: nil)
        try? await client.deleteTail(accountId: accountId, scriptName: scriptName, tailId: tail.id)
    }

    private func run(continuation: AsyncThrowingStream<TailEvent, Error>.Continuation) async throws {
        if client.isDemo {
            try await DemoTail.run(scriptName: scriptName, continuation: continuation)
            return
        }
        let tail = try await client.startTail(accountId: accountId, scriptName: scriptName)
        guard let url = URL(string: tail.url) else { throw CloudflareError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue("trace-v1", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        let socket = client.session.webSocketTask(with: request)
        await state.start(tail: tail, socket: socket)
        socket.resume()
        try await socket.send(.string(#"{"debug":false}"#))
        let decoder = CloudflareJSON.makeDecoder()
        while !Task.isCancelled {
            let message = try await socket.receive()
            let data: Data
            switch message {
            case .data(let payload):
                data = payload
            case .string(let text):
                data = Data(text.utf8)
            @unknown default:
                continue
            }
            if let event = try? decoder.decode(TailEvent.self, from: data) {
                continuation.yield(event)
            }
        }
    }
}
