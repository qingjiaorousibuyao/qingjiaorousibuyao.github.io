import SwiftUI

struct PostCard: View {
    @Bindable var post: DiaryPost
    var replyCount: Int = 0
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    @EnvironmentObject private var profile: ProfileSettings
    @State private var confirmDelete = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(data: profile.avatarData, size: 44)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("我").fontWeight(.semibold)
                    Text(ChineseTimeFormatter.string(from: post.createdAt)).foregroundStyle(.secondary)
                    Spacer()
                    if onEdit != nil || onDelete != nil {
                        Menu {
                            if let onEdit { Button("编辑", systemImage: "pencil", action: onEdit) }
                            if onDelete != nil {
                                Button("删除", systemImage: "trash", role: .destructive) { confirmDelete = true }
                            }
                        } label: { Image(systemName: "ellipsis").foregroundStyle(.secondary).padding(6) }
                    }
                }
                .font(.subheadline)
                if !post.text.isEmpty { Text(post.text).frame(maxWidth: .infinity, alignment: .leading) }
                if !post.photos.isEmpty { PhotoGrid(data: post.photos) }
                HStack(spacing: 26) {
                    Label("\(replyCount)", systemImage: "bubble.left")
                    Button { post.isFavorite.toggle() } label: {
                        Label(post.isFavorite ? "已收藏" : "收藏", systemImage: post.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(post.isFavorite ? .pink : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .softCard()
        .confirmationDialog("删除这条记录？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) { onDelete?() }
            Button("取消", role: .cancel) { }
        } message: { Text("删除后无法恢复，相关回复也会一并删除。") }
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

struct PhotoGrid: View {
    let data: [Data]
    var body: some View {
        Group {
            if data.count == 1 {
                photo(data[0]).frame(height: 260)
            } else if data.count == 2 {
                HStack(spacing: 4) {
                    photo(data[0]); photo(data[1])
                }.frame(height: 190)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(Array(data.prefix(4).enumerated()), id: \.offset) { _, item in
                        photo(item).frame(height: 130)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private func photo(_ item: Data) -> some View {
        if let image = UIImage(data: item) {
            Image(uiImage: image).resizable().scaledToFill().clipped()
        } else { Color.secondary.opacity(0.1) }
    }
}
