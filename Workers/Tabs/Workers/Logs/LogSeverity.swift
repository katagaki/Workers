import SwiftUI

enum LogSeverity {
    case success
    case warning
    case error

    var symbol: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .success: .logsSeveritySuccess
        case .warning: .logsSeverityWarning
        case .error: .logsSeverityError
        }
    }

    init(isError: Bool, statusCode: Int?) {
        if isError || (statusCode ?? 0) >= 500 {
            self = .error
        } else if (statusCode ?? 0) >= 400 {
            self = .warning
        } else {
            self = .success
        }
    }
}
