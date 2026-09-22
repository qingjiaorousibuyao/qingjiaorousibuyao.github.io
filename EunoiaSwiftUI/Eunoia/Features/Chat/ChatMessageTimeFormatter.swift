import Foundation

enum ChatMessageTimeFormatter {
    static let groupInterval: TimeInterval = 10 * 60
    static func messageTime(from date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
    static func separatorText(from date: Date) -> String { date.formatted(.dateTime.year().month().day().hour().minute()) }
}
