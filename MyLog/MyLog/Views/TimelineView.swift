import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var composing = false
    @State private var editingPost: DiaryPost?
    @EnvironmentObject private var theme: ThemeManager

    private var roots: [DiaryPost] { posts.filter { $0.parentID == nil } }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                LazyVStack(spacing: 14) {
                    if roots.isEmpty { EmptyTimelineView().padding(.top, 100) }
                    ForEach(roots) { post in
                        NavigationLink(value: post.id) {
                            PostCard(
                                post: post,
                                replyCount: posts.filter { $0.parentID == post.id }.count,
                                onEdit: { editingPost = post },
                                onDelete: { delete(post) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 90)
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
            .background(theme.accent, in: Circle())
            .shadow(color: theme.accent.opacity(0.3), radius: 10, y: 5)
            .padding()
        }
        .sheet(isPresented: $composing) { ComposeView() }
        .sheet(item: $editingPost) { ComposeView(editingPost: $0) }
    }

    private func delete(_ post: DiaryPost) {
        posts.filter { $0.parentID == post.id }.forEach(context.delete)
        context.delete(post)
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        ContentUnavailableView("写下第一条", systemImage: "quote.bubble", description: Text("这里不会有人打扰，想到什么就发什么。"))
    }
}
