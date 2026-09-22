import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @EnvironmentObject private var theme: ThemeSettings
    @EnvironmentObject private var profile: ProfileSettings
    @AppStorage("requiresFaceID") private var requiresFaceID = false
    @State private var backgroundItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var splashItem: PhotosPickerItem?
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section("主题") {
                ForEach(AppThemePreset.allCases) { preset in
                    Button { theme.apply(preset) } label: {
                        HStack { Text(preset.title); Spacer(); if theme.preset == preset { Image(systemName: "checkmark") } }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section("个性化") {
                PhotosPicker(selection: $backgroundItem, matching: .images) { Label("选择主页背景", systemImage: "photo.on.rectangle") }
                PhotosPicker(selection: $coverItem, matching: .images) { Label("选择个人页封面", systemImage: "rectangle.on.rectangle") }
                if theme.homeBackgroundData != nil {
                    Button("移除主页背景", role: .destructive) { theme.setHomeBackground(nil) }
                }
                VStack(alignment: .leading) {
                    Text("强调色").font(.subheadline)
                    HStack(spacing: 18) {
                        ForEach(0..<4) { index in
                            let colors: [Color] = [MyLogTheme.purple, MyLogTheme.pink, .indigo, .mint]
                            Circle().fill(colors[index]).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(.primary, lineWidth: theme.accentIndex == index ? 2 : 0))
                                .onTapGesture { theme.accentIndex = index }
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Text("卡片透明度 \(Int(theme.cardOpacity * 100))%")
                    Slider(value: $theme.cardOpacity, in: 0...1)
                }
            }

            Section("开屏图片") {
                Toggle("显示自定义开屏", isOn: $theme.showsCustomSplash)
                    .disabled(theme.splashData == nil)
                if let data = theme.splashData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    DefaultSplashArtwork().frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                PhotosPicker(selection: $splashItem, matching: .images) {
                    Label(theme.splashData == nil ? "选择开屏图片" : "更换开屏图片", systemImage: "photo.badge.plus")
                }
                if theme.splashData != nil {
                    Button("删除并恢复默认开屏", role: .destructive) { theme.setSplashImage(nil) }
                }
            }

            Section("隐私") { Toggle("Face ID / 密码锁", isOn: $requiresFaceID) }

            Section("数据") {
                Button("导出 JSON 备份") { exportURL = Exporter.makeJSON(posts) }
                if let exportURL { ShareLink(item: exportURL) { Label("分享备份文件", systemImage: "square.and.arrow.up") } }
            }

            Section { Text("MyLog 0.2 · 数据只保存在你的设备上").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("主题与设置")
        .tint(theme.accent)
        .onChange(of: backgroundItem) { _, item in
            Task { if let data = try? await item?.loadTransferable(type: Data.self) { theme.setHomeBackground(data) } }
        }
        .onChange(of: coverItem) { _, item in
            Task { if let data = try? await item?.loadTransferable(type: Data.self) { profile.setCover(data) } }
        }
        .onChange(of: splashItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    theme.setSplashImage(data)
                    theme.showsCustomSplash = true
                }
            }
        }
    }
}

private enum Exporter {
    struct Item: Codable {
        let id: UUID
        let text: String
        let createdAt: Date
        let favorite: Bool
        let parentID: UUID?
    }

    static func makeJSON(_ posts: [DiaryPost]) -> URL? {
        let items = posts.map { Item(id: $0.id, text: $0.text, createdAt: $0.createdAt, favorite: $0.isFavorite, parentID: $0.parentID) }
        guard let data = try? JSONEncoder().encode(items) else { return nil }
        let stamp = Int(Date().timeIntervalSince1970)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyLog-backup-\(stamp).json")
        try? data.write(to: url, options: .atomic)
        return url
    }
}
