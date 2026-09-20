import Foundation

enum ChineseTimeFormatter {
    static func string(from date: Date, relativeTo now: Date = .now) -> String {
        let interval = max(0, now.timeIntervalSince(date))
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 21600 { return "\(Int(interval / 3600))小时前" }

        let calendar = Calendar.current
        let time = date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN")))
        if calendar.isDateInYesterday(date) { return "昨天 \(time)" }
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN")))
        }
        return date.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN")))
    }
}
