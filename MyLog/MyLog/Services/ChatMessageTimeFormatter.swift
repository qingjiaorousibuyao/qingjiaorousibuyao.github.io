import Foundation

enum ChatMessageTimeFormatter {
    static let groupInterval: TimeInterval = 10 * 60

    static func messageTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
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
