import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var composing = false

    private var roots: [DiaryPost] { posts.filter { $0.parentID == nil } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if roots.isEmpty { EmptyTimelineView().padding(.top, 100) }
                ForEach(roots) { post in
                    NavigationLink(value: post.id) {
                        FirstEditionPostCard(
                            post: post,
                            replyCount: posts.filter { $0.parentID == post.id }.count
                        )
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.5)
                }
            }
        }
        .navigationTitle("MyLog")
        .navigationDestination(for: UUID.self) { id in
            ThreadView(rootID: id)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { composing = true } label: { Image(systemName: "square.and.pencil") }
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button { composing = true } label: {
                Image(systemName: "plus").font(.title2.bold()).frame(width: 54, height: 54)
            }
            .foregroundStyle(.white)
            .background(MyLogTheme.purple, in: Circle())
            .shadow(color: MyLogTheme.purple.opacity(0.3), radius: 10, y: 5)
            .padding()
        }
        .sheet(isPresented: $composing) { ComposeView() }
    }
}

private struct FirstEditionPostCard: View {
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
                if !post.text.isEmpty {
                    Text(post.text).frame(maxWidth: .infinity, alignment: .leading)
                }
                if !post.photos.isEmpty {
                    FirstEditionPhotoGrid(data: post.photos)
                }
                HStack(spacing: 26) {
                    Label("\(replyCount)", systemImage: "bubble.left")
                    Button { post.isFavorite.toggle() } label: {
                        Label(
                            post.isFavorite ? "已收藏" : "收藏",
                            systemImage: post.isFavorite ? "heart.fill" : "heart"
                        )
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

private struct FirstEditionPhotoGrid: View {
    let data: [Data]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(Array(data.prefix(4).enumerated()), id: \.offset) { _, item in
                if let image = UIImage(data: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: data.count == 1 ? 240 : 140)
                        .clipped()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        ContentUnavailableView(
            "写下第一条",
            systemImage: "quote.bubble",
            description: Text("这里不会有人打扰，想到什么就发什么。")
        )
    }
}
