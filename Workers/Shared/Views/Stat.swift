import SwiftUI

struct Stat: Identifiable {
    let title: LocalizedStringResource
    let value: String
    var tint: Color = .primary

    var id: String { value + title.key }
}
