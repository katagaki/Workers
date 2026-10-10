import Foundation

actor TailState {
    private(set) var tail: WorkerTail?
    private(set) var socket: URLSessionWebSocketTask?

    func start(tail: WorkerTail, socket: URLSessionWebSocketTask) {
        self.tail = tail
        self.socket = socket
    }

    func takeTail() -> WorkerTail? {
        defer { tail = nil }
        return tail
    }
}
