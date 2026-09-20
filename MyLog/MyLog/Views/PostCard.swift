import SwiftUI

struct PostCard: View {
    @Bindable var post: DiaryPost
    var replyCount: Int = 0

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

