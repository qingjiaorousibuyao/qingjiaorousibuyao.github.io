import Foundation

enum ChatTimeFormatter {
    static let separatorInterval: TimeInterval = 10 * 60

    static func message(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func separator(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = .autoupdatingCurrent; formatter.dateStyle = .medium; formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}
