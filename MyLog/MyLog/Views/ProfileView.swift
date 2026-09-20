import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    enum Tab: String, CaseIterable { case posts = "记录", media = "媒体", favorites = "收藏" }

    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @EnvironmentObject private var profile: ProfileSettings
    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedTab: Tab = .posts
    @State private var avatarItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var editingProfile = false
    @State private var editingPost: DiaryPost?

    private var roots: [DiaryPost] { posts.filter { $0.parentID == nil } }
    private var media: [Data] { posts.flatMap(\.photos) }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                LazyVStack(spacing: 16) {
                    header
                    stats
                    Picker("内容", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(6)
                    .softCard()

                    tabContent
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("我的")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
            }
        }
        .sheet(isPresented: $editingProfile) { ProfileEditorView() }
        .sheet(item: $editingPost) { ComposeView(editingPost: $0) }
        .onChange(of: avatarItem) { _, item in Task { profile.avatarData = try? await item?.loadTransferable(type: Data.self) } }
        .onChange(of: coverItem) { _, item in Task { profile.coverData = try? await item?.loadTransferable(type: Data.self) } }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let data = profile.coverData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        LinearGradient(colors: [MyLogTheme.palePurple, MyLogTheme.pink.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 180).clipped()

                PhotosPicker(selection: $coverItem, matching: .images) {
                    Label("更换封面", systemImage: "photo").font(.caption.bold()).padding(9)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(12)
            }

            VStack(spacing: 7) {
                PhotosPicker(selection: $avatarItem, matching: .images) {
                    AvatarView(data: profile.avatarData, size: 84)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill").font(.caption).padding(7)
                                .foregroundStyle(.white).background(theme.accent, in: Circle())
                        }
                }
                .offset(y: -42).padding(.bottom, -42)

                Text(profile.nickname).font(.title2.bold())
                Text(profile.userID).foregroundStyle(.secondary)
                Text(profile.bio).font(.subheadline)
                Button("编辑资料") { editingProfile = true }.buttonStyle(.bordered)
            }
            .padding(.bottom, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .softCard()
    }

    private var stats: some View {
        HStack {
            stat("记录", posts.count)
            Divider().frame(height: 30)
            stat("收藏", posts.filter(\.isFavorite).count)
            Divider().frame(height: 30)
            stat("含照片", posts.filter { !$0.photos.isEmpty }.count)
        }
        .padding(.vertical, 14)
        .softCard()
    }

    private func stat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 3) { Text("\(value)").font(.headline); Text(title).font(.caption).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .posts:
            ForEach(roots) { card($0) }
        case .favorites:
            if posts.filter(\.isFavorite).isEmpty { empty("还没有收藏", "heart") }
            ForEach(posts.filter(\.isFavorite)) { card($0) }
        case .media:
            if media.isEmpty { empty("还没有照片", "photo") }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(Array(media.enumerated()), id: \.offset) { _, data in
                    if let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill().frame(height: 118).clipped()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func card(_ post: DiaryPost) -> some View {
        PostCard(post: post, replyCount: posts.filter { $0.parentID == post.id }.count,
                 onEdit: { editingPost = post }, onDelete: { delete(post) })
    }

    private func delete(_ post: DiaryPost) {
        posts.filter { $0.parentID == post.id }.forEach(context.delete)
        context.delete(post)
    }

    private func empty(_ title: String, _ icon: String) -> some View {
        ContentUnavailableView(title, systemImage: icon).padding(.vertical, 36).frame(maxWidth: .infinity).softCard()
    }
}

private struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profile: ProfileSettings
    @State private var nickname = ""
    @State private var userID = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("昵称", text: $nickname)
                TextField("ID", text: $userID).textInputAutocapitalization(.never)
                TextField("签名", text: $bio, axis: .vertical)
            }
            .navigationTitle("编辑资料")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { profile.update(nickname: nickname, userID: userID, bio: bio); dismiss() }
                }
            }
            .onAppear { nickname = profile.nickname; userID = profile.userID; bio = profile.bio }
        }
    }
}
