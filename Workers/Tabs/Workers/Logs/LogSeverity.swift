import SwiftUI

enum LogSeverity {
    case informational
    case success
    case redirect
    case warning
    case error

    var symbol: String {
        switch self {
        case .informational: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .redirect: "arrow.right.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .informational: .gray
        case .success: .blue
        case .redirect: .purple
        case .warning: .yellow
        case .error: .red
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .informational: .logsSeverityInformational
        case .success: .logsSeveritySuccess
        case .redirect: .logsSeverityRedirect
        case .warning: .logsSeverityWarning
        case .error: .logsSeverityError
        }
    }

    init(isError: Bool, statusCode: Int?) {
        if isError {
            self = .error
            return
        }
        switch statusCode ?? 200 {
        case 100..<200: self = .informational
        case 300..<400: self = .redirect
        case 400..<500: self = .warning
        case 500...: self = .error
        default: self = .success
        }
    }
}
