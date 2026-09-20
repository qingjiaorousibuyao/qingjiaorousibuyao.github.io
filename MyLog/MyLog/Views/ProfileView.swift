import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProfileView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @AppStorage("requiresFaceID") private var requiresFaceID = false
    @State private var exportURL: URL?

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Circle().fill(MyLogTheme.palePurple).frame(width: 64, height: 64)
                        .overlay(Image(systemName: "person.fill").font(.title).foregroundStyle(MyLogTheme.purple))
                    VStack(alignment: .leading) {
                        Text("我的小世界").font(.title3.bold())
                        Text("\(posts.count) 条记录 · \(posts.filter(\.isFavorite).count) 个收藏").foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
            }
            Section("隐私") { Toggle("Face ID / 密码锁", isOn: $requiresFaceID) }
            Section("数据") {
                Button("导出 JSON 备份") { exportURL = Exporter.makeJSON(posts) }
                if let exportURL { ShareLink(item: exportURL) { Label("分享备份文件", systemImage: "square.and.arrow.up") } }
            }
            Section("收藏") {
                ForEach(posts.filter(\.isFavorite)) { PostCard(post: $0).listRowInsets(.init()) }
            }
        }
        .navigationTitle("我的")
    }
}

private enum Exporter {
    struct Item: Codable { let id: UUID; let text: String; let createdAt: Date; let favorite: Bool; let parentID: UUID? }
    static func makeJSON(_ posts: [DiaryPost]) -> URL? {
        let items = posts.map { Item(id: $0.id, text: $0.text, createdAt: $0.createdAt, favorite: $0.isFavorite, parentID: $0.parentID) }
        guard let data = try? JSONEncoder().encode(items) else { return nil }
        let stamp = Int(Date().timeIntervalSince1970)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyLog-backup-\(stamp).json")
        try? data.write(to: url, options: .atomic)
        return url
    }
}
