import SwiftUI

enum LogTableColumn: Hashable, Identifiable {
    case time
    case status
    case message
    case method
    case url
    case trigger
    case outcome
    case cpuTime
    case wallTime
    case country
    case dataCenter

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .time: .sharedTime
        case .status: .sharedStatus
        case .message: .logsEventMessage
        case .method: .logsEventMethod
        case .url: .sharedUrl
        case .trigger: .logsEventTrigger
        case .outcome: .sharedOutcome
        case .cpuTime: .logsEventCpuTime
        case .wallTime: .logsEventWallTime
        case .country: .logsEventCountry
        case .dataCenter: .logsEventDataCenter
        }
    }

    var width: CGFloat {
        switch self {
        case .time: 76
        case .status: 72
        case .message: 420
        case .method: 64
        case .url: 240
        case .trigger: 88
        case .outcome: 88
        case .cpuTime: 80
        case .wallTime: 80
        case .country: 120
        case .dataCenter: 88
        }
    }
}
