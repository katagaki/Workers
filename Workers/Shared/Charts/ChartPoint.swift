import SwiftUI

struct ChartPoint: Identifiable {
    let date: Date
    let series: String
    let value: Double

    var id: String { "\(series)-\(date.timeIntervalSince1970)" }
}
