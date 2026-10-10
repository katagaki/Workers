import SwiftUI

struct TTLOption {
    let seconds: Int
    let title: String

    init(seconds: Int, title: String? = nil) {
        self.seconds = seconds
        self.title = title ?? Duration.seconds(seconds).formatted(.units(allowed: [.days, .hours, .minutes, .seconds], width: .wide))
    }

    static let all: [TTLOption] = [
        TTLOption(seconds: 1, title: String(localized: .dnsEditorTtlAuto)),
        TTLOption(seconds: 60),
        TTLOption(seconds: 120),
        TTLOption(seconds: 300),
        TTLOption(seconds: 600),
        TTLOption(seconds: 1800),
        TTLOption(seconds: 3600),
        TTLOption(seconds: 7200),
        TTLOption(seconds: 18000),
        TTLOption(seconds: 43200),
        TTLOption(seconds: 86400)
    ]
}
