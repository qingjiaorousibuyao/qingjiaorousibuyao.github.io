import Foundation

enum ChatMessageTimeFormatter {
    static let groupInterval: TimeInterval = 10 * 60

    static func groupTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func separatorText(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.calendar = calendar
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: date)
        }

        let sameYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "Mdjmm" : "yMdjmm")
        return formatter.string(from: date)
    }
}
