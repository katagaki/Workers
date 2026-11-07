import Foundation

@main
struct BackgroundUploadHarness {
    static func main() async {
        let mode = CommandLine.arguments[1]
        let port = CommandLine.arguments[2]
        let fileURL = URL(fileURLWithPath: CommandLine.arguments[3])
        let uploader = R2BackgroundUploader(identifier: "com.tsubuzaki.Workers.tests.\(port)")

        func request(_ path: String) -> URLRequest {
            var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/\(path)")!)
            request.httpMethod = "PUT"
            return request
        }

        var pending: [UUID: String] = [:]
        switch mode {
        case "errors":
            for path in ["accepted", "denied", "rejected"] {
                let id = UUID()
                pending[id] = path
                uploader.start(id: id, request: request(path), fileURL: fileURL)
            }
        case "start":
            uploader.start(id: UUID(), request: request("slow"), fileURL: fileURL)
            for await event in uploader.events {
                if case .progress(_, let sentBytes) = event, sentBytes > 0 { exit(0) }
            }
        default:
            let activeUploads = await uploader.activeUploads()
            precondition(activeUploads.count == 1, "The upload must survive its process exiting")
            pending[activeUploads[0].id] = "slow"
        }

        var progressCount = 0
        for await event in uploader.events {
            switch event {
            case .progress:
                progressCount += 1
            case .finished(let id, let failureMessage):
                switch pending.removeValue(forKey: id) {
                case "denied": precondition(failureMessage != nil, "403 must fail the upload")
                case "rejected": precondition(failureMessage == "Bucket quota exceeded", "API errors must be surfaced")
                default: precondition(failureMessage == nil, "A 200 response must succeed")
                }
            case .backgroundEventsDelivered:
                break
            }
            if pending.isEmpty { break }
        }
        if mode == "resume" {
            precondition(progressCount > 1, "A reattached upload must keep reporting progress")
        }
    }
}
