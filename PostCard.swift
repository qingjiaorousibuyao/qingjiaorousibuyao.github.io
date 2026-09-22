import SwiftUI

struct PostCard: View {
    @Bindable var post: DiaryPost
    var replyCount: Int = 0
    var onOpen: (() -> Void)?
    var onReply: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(MyLogTheme.palePurple)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").foregroundStyle(MyLogTheme.purple))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Text("我").fontWeight(.semibold)
                    Text("·")
                    Text(post.createdAt, style: .relative)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if onEdit != nil || onDelete != nil {
                        Menu {
                            if let onEdit { Button("编辑", systemImage: "pencil", action: onEdit) }
                            if let onDelete { Button("删除", systemImage: "trash", role: .destructive, action: onDelete) }
                        } label: {
                            Image(systemName: "ellipsis").frame(width: 44, height: 44)
                        }
                    }
                }
                .font(.subheadline)
                if !post.text.isEmpty { Text(post.text).frame(maxWidth: .infinity, alignment: .leading) }
                if !post.photos.isEmpty { PhotoGrid(data: post.photos) }
                HStack(spacing: 26) {
                    if let onReply {
                        Button(action: onReply) { Label("\(replyCount)", systemImage: "bubble.left") }
                    } else {
                        Label("\(replyCount)", systemImage: "bubble.left")
                    }
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
        .onTapGesture { onOpen?() }
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(Array(data.prefix(4).enumerated()), id: \.offset) { _, item in
                if let image = UIImage(data: item) {
                    Image(uiImage: image).resizable().scaledToFill().frame(height: data.count == 1 ? 240 : 140).clipped()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
