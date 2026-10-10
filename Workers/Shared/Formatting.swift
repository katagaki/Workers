import Foundation

extension Int {
    var compactFormatted: String {
        formatted(.number.notation(.compactName))
    }

    var byteFormatted: String {
        guard self > 0 else { return "0" }
        return Int64(self).formatted(.byteCount(style: .file))
    }
}

extension Double {
    var percentFormatted: String {
        formatted(.percent.precision(.fractionLength(0...1)))
    }

    var millisecondsFromMicroseconds: String {
        let milliseconds = self / 1000
        return String(localized: .sharedMilliseconds(milliseconds.formatted(.number.precision(.fractionLength(0...1)))))
    }
}

extension Double {
    var millisecondsFormatted: String {
        String(localized: .sharedMilliseconds(formatted(.number.precision(.fractionLength(0...2)))))
    }
}

extension Date {
    var relativeFormatted: String {
        formatted(.relative(presentation: .named))
    }
}

extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
