import CloudflareKit
import SwiftUI

struct LiveTailView: View {
    let client: CloudflareClient
    let accountId: String
    let scriptName: String

    @State private var events: [TailEvent] = []
    @State private var tailTask: Task<Void, Never>?
    @State private var tailSessionId: UUID?
    @State private var tailError: String?

    private static let maximumEvents = 500

    private var isTailing: Bool {
        tailTask != nil
    }

    var body: some View {
        List {
            if let tailError {
                Section {
                    Label(tailError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(events) { event in
                NavigationLink {
                    TailEventDetailView(event: event)
                } label: {
                    LogRow(
                        severity: LogSeverity(isError: event.isError, statusCode: event.responseStatus),
                        title: event.title,
                        subtitle: event.locationDescription,
                        date: event.date
                    )
                }
            }
        }
        .overlay {
            if events.isEmpty && tailError == nil {
                ContentUnavailableView {
                    Label(isTailing ? .logsLiveWaitingTitle : .logsLivePausedTitle,
                          systemImage: isTailing ? "antenna.radiowaves.left.and.right" : "pause.circle")
                } description: {
                    Text(isTailing
                         ? .logsLiveWaitingMessage
                         : .logsLivePausedMessage)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !events.isEmpty {
                    Button {
                        events.removeAll()
                    } label: {
                        Label(.sharedClear, systemImage: "trash")
                    }
                }
                Button {
                    isTailing ? stopTail() : startTail()
                } label: {
                    Label(isTailing ? .logsLivePause : .logsLiveStart, systemImage: isTailing ? "pause.fill" : "play.fill")
                }
            }
        }
        .onAppear(perform: startTail)
        .onDisappear(perform: stopTail)
    }

    private func startTail() {
        guard tailTask == nil else { return }
        tailError = nil
        let session = WorkerTailSession(client: client, accountId: accountId, scriptName: scriptName)
        let sessionId = UUID()
        tailSessionId = sessionId
        tailTask = Task {
            do {
                for try await event in session.events() {
                    events.insert(event, at: 0)
                    if events.count > Self.maximumEvents {
                        events.removeLast(events.count - Self.maximumEvents)
                    }
                }
            } catch is CancellationError {
            } catch {
                tailError = error.localizedDescription
            }
            await session.stop()
            if tailSessionId == sessionId {
                tailTask = nil
                tailSessionId = nil
            }
        }
    }

    private func stopTail() {
        tailTask?.cancel()
        tailTask = nil
        tailSessionId = nil
    }
}
