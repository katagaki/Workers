import Foundation

struct CronDescription {
    let text: String?

    init(_ expression: String) {
        let fields = expression.split(separator: " ").map(String.init)
        guard fields.count == 5 else {
            text = nil
            return
        }
        let minute = fields[0]
        let hour = fields[1]
        let rest = fields[2...].allSatisfy { $0 == "*" }
        switch (minute, hour, rest) {
        case ("*", "*", true):
            text = String(localized: .workersTriggersCronEveryMinute)
        case (let minuteField, "*", true) where minuteField.hasPrefix("*/"):
            text = String(localized: .workersTriggersCronEveryMinutes(String(minuteField.dropFirst(2))))
        case (let minuteField, "*", true) where Int(minuteField) != nil:
            text = String(localized: .workersTriggersCronEveryHourAtMinute(minuteField))
        case (let minuteField, let hourField, true) where Int(minuteField) != nil && hourField.hasPrefix("*/"):
            text = String(localized: .workersTriggersCronEveryHours(String(hourField.dropFirst(2))))
        case (let minuteField, let hourField, true):
            if let minuteValue = Int(minuteField), let hourValue = Int(hourField) {
                let time = String(format: "%02d:%02d", hourValue, minuteValue)
                text = String(localized: .workersTriggersCronEveryDayAt(time))
            } else {
                text = nil
            }
        default:
            text = nil
        }
    }
}
