import SwiftUI
import SwiftData

struct PostCard: View {
    @Bindable var post: DiaryPost
    var replyCount: Int = 0
    var onOpen: (() -> Void)?
    var onReply: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var confirmDelete = false
    @State private var preview: PhotoPreviewSelection?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            authorAvatar(size: 44)
                .contentShape(Circle())
                .onTapGesture { onOpen?() }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center, spacing: 6) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(authorName).fontWeight(.semibold)
                        Text(ChineseTimeFormatter.string(from: post.createdAt)).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onOpen?() }
                    Spacer(minLength: 4)
                    if onEdit != nil || onDelete != nil {
                        Menu {
                            if let onEdit { Button("编辑", systemImage: "pencil", action: onEdit) }
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
                    } label: { Label("\(replyCount)", systemImage: "bubble.left") }
                    Button {
                        post.isFavorite.toggle()
                        try? context.save()
                    } label: {
                        Label(post.isFavorite ? "已收藏" : "收藏", systemImage: post.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(post.isFavorite ? .pink : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background {
            Button { onOpen?() } label: {
                Color.clear
                    .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
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
                    VStack(spacing: 5) {
                        tile(visibleData[1], index: 1)
                        tile(visibleData[2], index: 2)
                    }
                }
                .frame(height: 220)
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
