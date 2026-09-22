import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var date = Date()
    private var selected: [DiaryPost] { posts.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) } }

    var body: some View {
        List {
            DatePicker("日期", selection: $date, displayedComponents: .date).datePickerStyle(.graphical)
            Section(date.formatted(date: .long, time: .omitted)) {
                if selected.isEmpty { Text("这一天还没有记录").foregroundStyle(.secondary) }
                ForEach(selected) { PostCard(post: $0).listRowInsets(.init()).listRowBackground(Color.clear) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("日历")
    }
}
