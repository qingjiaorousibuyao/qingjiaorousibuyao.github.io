import SwiftUI
import SwiftData

struct PostCard: View {
    @Bindable var post: DiaryPost
    var replyCount: Int = 0
    var replies: [DiaryPost] = []
    var onOpen: (() -> Void)?
    var onReply: (() -> Void)?
    var onEdit: (() -> Void)?
    var onEditData: (() -> Void)?
    var onDelete: (() -> Void)?
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var confirmDelete = false
    @State private var preview: PhotoPreviewSelection?
    @State private var commentText = ""
    @State private var commentAuthor: PostAuthorSelection = .me
    @State private var sharing = false

    private var displayedReplyCount: Int { max(replyCount, replies.count + post.manualCommentCount) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            authorAvatar(size: 44)
                .contentShape(Circle())
                .onTapGesture { onOpen?() }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center, spacing: 6) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(authorName).fontWeight(.semibold)
                        Text(post.createdAt, style: .relative).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onOpen?() }
                    Spacer(minLength: 4)
                    if onEdit != nil || onEditData != nil || onDelete != nil {
                        Menu {
                            if let onEdit { Button("编辑动态", systemImage: "pencil", action: onEdit) }
                            if let onEditData { Button("编辑数据", systemImage: "slider.horizontal.3", action: onEditData) }
                            if onDelete != nil {
                                Button("删除", systemImage: "trash", role: .destructive) { confirmDelete = true }
                            }
                            Button("取消", role: .cancel) { }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)

                HStack {
                    if let location = post.location?.nilIfBlank {
                        Label(location, systemImage: "mappin.and.ellipse")
                    }
                    Spacer()
                    Text(post.createdAt.formatted(date: .numeric, time: .shortened))
                }
                .font(.caption2).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    if !post.text.isEmpty {
                        Text(post.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture { onOpen?() }
                    }
                    if !post.photos.isEmpty {
                        PhotoGrid(data: post.photos) { preview = PhotoPreviewSelection(index: $0) }
                    }
                }

                HStack(spacing: 28) {
                    Button {
                        if let onReply { onReply() } else { onOpen?() }
                    } label: { Label("\(displayedReplyCount)", systemImage: "bubble.left") }
                    Button {
                        post.isLiked.toggle()
                        post.likeCount = max(0, post.likeCount + (post.isLiked ? 1 : -1))
                        try? context.save()
                    } label: {
                        Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLiked ? .pink : .secondary)
                    }
                    Button { sharing = true } label: { Label("分享", systemImage: "square.and.arrow.up") }
                    Button { post.isFavorite.toggle(); try? context.save() } label: {
                        Image(systemName: post.isFavorite ? "bookmark.fill" : "bookmark")
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                if !replies.isEmpty {
                    Divider()
                    ForEach(replies) { PostAuthorSummary(post: $0) }
                }
                if !replies.isEmpty || onReply != nil {
                    HStack(spacing: 9) {
                        Menu {
                            Button(profile.displayName) { commentAuthor = .me }
                            ForEach(contacts) { contact in Button(contact.name) { commentAuthor = .contact(contact.id) } }
                        } label: { commentAvatar }
                        TextField("写下评论…", text: $commentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button("发送") { sendComment() }
                            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .softCard()
        .confirmationDialog("删除这条记录？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) { onDelete?() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复；如果这是主记录，相关回复也会一并删除。")
        }
        .fullScreenCover(item: $preview) { selection in
            FullScreenPhotoViewer(data: post.photos, initialIndex: selection.index)
        }
        .sheet(isPresented: $sharing) { ActivityView(items: shareItems) }
    }

    private var authorSelection: PostAuthorSelection {
        PostAuthorStore.selection(for: post.id)
    }

    private var authorName: String {
        switch authorSelection {
        case .me:
            profile.displayName
        case let .contact(id):
            contacts.first(where: { $0.id == id })?.name ?? profile.displayName
        }
    }

    @ViewBuilder private func authorAvatar(size: CGFloat) -> some View {
        switch authorSelection {
        case .me:
            AvatarView(data: profile.avatarData, size: size)
        case let .contact(id):
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactAvatar(filename: contact.avatarFilename, size: size)
            } else {
                AvatarView(data: profile.avatarData, size: size)
            }
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = [post.text]
        items.append(contentsOf: post.photos.compactMap { UIImage(data: $0) })
        return items
    }

    @ViewBuilder private var commentAvatar: some View {
        switch commentAuthor {
        case .me: AvatarView(data: profile.avatarData, size: 30)
        case let .contact(id):
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactAvatar(filename: contact.avatarFilename, size: 30)
            } else { AvatarView(data: profile.avatarData, size: 30) }
        }
    }

    private func sendComment() {
        let clean = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let reply = DiaryPost(text: clean, parentID: post.id)
        context.insert(reply); PostAuthorStore.set(commentAuthor, for: reply.id)
        try? context.save(); commentText = ""
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct PostDataEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let post: DiaryPost
    @State private var likeCount: Int
    @State private var commentCount: Int

    init(post: DiaryPost) {
        self.post = post
        _likeCount = State(initialValue: post.likeCount)
        _commentCount = State(initialValue: post.manualCommentCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("点赞量：\(likeCount)", value: $likeCount, in: 0...999_999)
                Stepper("手动评论量：\(commentCount)", value: $commentCount, in: 0...999_999)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("编辑数据")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        post.likeCount = likeCount
                        post.manualCommentCount = commentCount
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct AvatarView: View {
    let data: Data?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(MyLogTheme.palePurple)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(MyLogTheme.purple))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
    }
}

private struct PhotoPreviewSelection: Identifiable {
    let index: Int
    var id: Int { index }
}

struct PhotoGrid: View {
    let data: [Data]
    var onTap: ((Int) -> Void)?

    private var visibleData: [Data] { Array(data.prefix(9)) }

    var body: some View {
        Group {
            switch visibleData.count {
            case 0:
                EmptyView()
            case 1:
                tile(visibleData[0], index: 0).frame(height: 260)
            case 2:
                HStack(spacing: 5) {
                    tile(visibleData[0], index: 0)
                    tile(visibleData[1], index: 1)
                }
                .frame(height: 190)
            case 3:
                HStack(spacing: 5) {
                    tile(visibleData[0], index: 0)
                    tile(visibleData[1], index: 1)
                    tile(visibleData[2], index: 2)
                }
                .frame(height: 150)
            case 4:
                grid(columns: 2, tileHeight: 130)
            default:
                grid(columns: 3, tileHeight: 104)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func grid(columns: Int, tileHeight: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: columns), spacing: 5) {
            ForEach(Array(visibleData.enumerated()), id: \.offset) { index, item in
                tile(item, index: index).frame(height: tileHeight)
            }
        }
    }

    @ViewBuilder private func tile(_ item: Data, index: Int) -> some View {
        Button { onTap?(index) } label: {
            if let image = UIImage(data: item) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.secondary.opacity(0.1)
            }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityLabel("查看第\(index + 1)张照片")
    }
}

struct PostAuthorSummary: View {
    let post: DiaryPost
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]

    private var selection: PostAuthorSelection { PostAuthorStore.selection(for: post.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            avatar
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.caption.weight(.semibold))
                if post.text.isEmpty {
                    Label("图片回复", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(post.text)
                        .font(.subheadline)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder private var avatar: some View {
        switch selection {
        case .me:
            AvatarView(data: profile.avatarData, size: 30)
        case let .contact(id):
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactAvatar(filename: contact.avatarFilename, size: 30)
            } else {
                AvatarView(data: profile.avatarData, size: 30)
            }
        }
    }

    private var name: String {
        switch selection {
        case .me:
            profile.displayName
        case let .contact(id):
            contacts.first(where: { $0.id == id })?.name ?? profile.displayName
        }
    }
}

private struct FullScreenPhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let data: [Data]
    @State private var selectedIndex: Int

    init(data: [Data], initialIndex: Int) {
        self.data = Array(data.prefix(9))
        _selectedIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $selectedIndex) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    if let image = UIImage(data: item) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                            .padding(.vertical, 54)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .padding()
            }
            .accessibilityLabel("关闭照片预览")
        }
    }
}
