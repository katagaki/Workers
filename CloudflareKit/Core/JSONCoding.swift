import Foundation

public enum CloudflareJSON {
    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let milliseconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: milliseconds / 1000)
            }
            let string = try container.decode(String.self)
            guard let date = parseDate(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognized date: \(string)"
                )
            }
            return date
        }
        return decoder
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true)))
        }
        return encoder
    }

    static func parseDate(_ string: String) -> Date? {
        let normalized = normalizeFractionalSeconds(string)
        if let date = try? Date(normalized, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true)) {
            return date
        }
        if let date = try? Date(normalized, strategy: .iso8601) {
            return date
        }
        if let date = try? Date(normalized, strategy: .iso8601.year().month().day()) {
            return date
        }
        return nil
    }

    private static func normalizeFractionalSeconds(_ string: String) -> String {
        guard let dotIndex = string.firstIndex(of: ".") else { return string }
        let fractionStart = string.index(after: dotIndex)
        let fractionEnd = string[fractionStart...].firstIndex { !$0.isNumber } ?? string.endIndex
        let fraction = string[fractionStart..<fractionEnd]
        let milliseconds = String(fraction.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
        return String(string[..<fractionStart]) + milliseconds + String(string[fractionEnd...])
    }
}
