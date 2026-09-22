import SwiftUI
import SwiftData

struct TimelineView: View {
    private enum FeedTab: String, CaseIterable { case posts = "投稿", liked = "点赞", photos = "照片" }
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var selectedTab: FeedTab = .posts
    @State private var selectedPostID: UUID?
    @State private var editingPost: DiaryPost?
    @State private var dataEditingPost: DiaryPost?
    @State private var photoPreview: TimelinePhotoSelection?
    @State private var searching = false
    @State private var showingProfile = false

    private var roots: [DiaryPost] { posts.filter { $0.parentID == nil } }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                LazyVStack(spacing: 16) {
                    profileHeader
                    LocalHTMLTopCardView(resourceName: "GreyMoodPreview")
                    Picker("动态分类", selection: $selectedTab) {
                        ForEach(FeedTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).padding(5).softCard()
                    tabContent
                }
                .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedPostID) { ThreadView(rootID: $0) }
        .navigationDestination(isPresented: $searching) { SearchView() }
        .navigationDestination(isPresented: $showingProfile) { ProfileView() }
        .sheet(item: $editingPost) { ComposeView(editingPost: $0) }
        .sheet(item: $dataEditingPost) { PostDataEditor(post: $0) }
        .fullScreenCover(item: $photoPreview) { selection in
            TimelinePhotoViewer(post: selection.post, initialIndex: selection.index) {
                photoPreview = nil
                selectedPostID = selection.post.id
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 12) {
            Button { showingProfile = true } label: { AvatarView(data: profile.avatarData, size: 54) }
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName).font(.headline)
                Text(profile.bio.nilIfBlank ?? "个性签名未设置")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            .contentShape(Rectangle()).onTapGesture { showingProfile = true }
            Spacer()
            Button { searching = true } label: {
                Image(systemName: "magnifyingglass").font(.title3.weight(.semibold))
                    .frame(width: 42, height: 42).background(.thinMaterial, in: Circle())
            }.accessibilityLabel("搜索动态")
        }
        .padding(14).softCard()
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .posts:
            postList(roots, emptyTitle: "还没有投稿", icon: "square.and.pencil")
        case .liked:
            postList(roots.filter(\.isLiked), emptyTitle: "还没有点赞内容", icon: "heart")
        case .photos:
            let items = roots.flatMap { post in post.photos.indices.map { (post, $0) } }
            if items.isEmpty {
                emptyState("还没有照片", icon: "photo.on.rectangle")
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        Button { photoPreview = .init(post: item.0, index: item.1) } label: {
                            if let image = UIImage(data: item.0.photos[item.1]) {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(maxWidth: .infinity).frame(height: 118).clipped()
                            }
                        }.buttonStyle(.plain)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder private func postList(_ values: [DiaryPost], emptyTitle: String, icon: String) -> some View {
        if values.isEmpty { emptyState(emptyTitle, icon: icon) }
        ForEach(values) { post in
            PostCard(post: post, replies: posts.filter { $0.parentID == post.id },
                     onOpen: { selectedPostID = post.id }, onReply: { selectedPostID = post.id },
                     onEdit: { editingPost = post }, onEditData: { dataEditingPost = post },
                     onDelete: { delete(post) })
        }
    }

    private func emptyState(_ title: String, icon: String) -> some View {
        ContentUnavailableView(title, systemImage: icon).padding(.vertical, 32).frame(maxWidth: .infinity).softCard()
    }

    private func delete(_ post: DiaryPost) {
        posts.filter { $0.parentID == post.id }.forEach { reply in
            PostAuthorStore.remove(postID: reply.id); context.delete(reply)
        }
        PostAuthorStore.remove(postID: post.id); context.delete(post); try? context.save()
    }
}

private struct FeaturedPostCard: View {
    @Environment(\.modelContext) private var context
    let post: DiaryPost?
    let onOpen: (UUID) -> Void

    var body: some View {
        Group {
            if let post, let data = post.photos.first, let image = UIImage(data: data) {
                ZStack(alignment: .bottom) {
                    Image(uiImage: image).resizable().scaledToFill().frame(height: 250).clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.text.nilIfBlank?.components(separatedBy: .newlines).first ?? "图片动态")
                            .font(.title3.bold()).foregroundStyle(.white).lineLimit(1)
                        HStack {
                            FeaturedAuthor(post: post)
                            Spacer()
                            Text(post.createdAt, style: .relative).font(.caption).foregroundStyle(.white.opacity(0.8))
                            Button { toggleLike(post) } label: { Image(systemName: post.isLiked ? "heart.fill" : "heart") }
                            Button { post.isFavorite.toggle(); try? context.save() } label: {
                                Image(systemName: post.isFavorite ? "bookmark.fill" : "bookmark")
                            }
                        }.foregroundStyle(.white)
                    }.padding(16)
                }
                .contentShape(Rectangle()).onTapGesture { onOpen(post.id) }
            } else {
                ContentUnavailableView("还没有图片动态", systemImage: "photo", description: Text("发布带有图片的动态后会显示在这里。"))
                    .frame(maxWidth: .infinity).frame(height: 180)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).softCard()
    }

    private func toggleLike(_ post: DiaryPost) {
        post.isLiked.toggle(); post.likeCount = max(0, post.likeCount + (post.isLiked ? 1 : -1)); try? context.save()
    }
}

private struct FeaturedAuthor: View {
    let post: DiaryPost
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]

    private var selection: PostAuthorSelection { PostAuthorStore.selection(for: post.id) }

    var body: some View {
        HStack(spacing: 7) {
            avatar
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(.white)
        }
    }

    @ViewBuilder private var avatar: some View {
        switch selection {
        case .me: AvatarView(data: profile.avatarData, size: 28)
        case let .contact(id):
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactAvatar(filename: contact.avatarFilename, size: 28)
            } else { AvatarView(data: profile.avatarData, size: 28) }
        }
    }

    private var name: String {
        switch selection {
        case .me: profile.displayName
        case let .contact(id): contacts.first(where: { $0.id == id })?.name ?? profile.displayName
        }
    }
}

private struct TimelinePhotoSelection: Identifiable {
    let post: DiaryPost
    let index: Int
    var id: String { "\(post.id)-\(index)" }
}

private struct TimelinePhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let post: DiaryPost
    @State private var index: Int
    let openPost: () -> Void

    init(post: DiaryPost, initialIndex: Int, openPost: @escaping () -> Void) {
        self.post = post; _index = State(initialValue: initialIndex); self.openPost = openPost
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $index) {
                ForEach(Array(post.photos.enumerated()), id: \.offset) { index, data in
                    if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().tag(index) }
                }
            }.tabViewStyle(.page)
            VStack { HStack {
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.white) }
                Spacer(); Button("查看动态") { openPost() }.buttonStyle(.borderedProminent)
            }.padding(); Spacer() }
        }
    }
}
