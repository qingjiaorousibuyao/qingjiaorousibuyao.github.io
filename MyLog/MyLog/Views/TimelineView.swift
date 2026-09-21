import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var composing = false
    @State private var editingPost: DiaryPost?
    @State private var selectedThreadID: UUID?
    @EnvironmentObject private var theme: ThemeSettings

    private var roots: [DiaryPost] { posts.filter { $0.parentID == nil } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if roots.isEmpty { EmptyTimelineView().padding(.top, 100) }
                ForEach(roots) { post in
                    let replies = replies(for: post)
                    VStack(spacing: 8) {
                        NavigationLink(value: post.id) {
                            PostCard(
                                post: post,
                                replyCount: replies.count,
                                onReply: { selectedThreadID = post.id },
                                onEdit: { editingPost = post },
                                onDelete: { delete(post) }
                            )
                        }
                        .buttonStyle(.plain)
                        if !replies.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(Array(replies.enumerated()), id: \.element.id) { index, reply in
                                    if index > 0 { Divider().opacity(0.45) }
                                    PostAuthorSummary(post: reply)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .softCard()
                            .onTapGesture { selectedThreadID = post.id }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 90)
        }
        .background(PaperBackground())
        .navigationTitle("MyLog")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedThreadID) { id in
            ThreadView(rootID: id)
        }
        .navigationDestination(for: UUID.self) { id in
            ThreadView(rootID: id)
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
        posts.filter { $0.parentID == post.id }.forEach {
            PostAuthorStore.remove(postID: $0.id)
            context.delete($0)
        }
        PostAuthorStore.remove(postID: post.id)
        context.delete(post)
        try? context.save()
    }

    private func replies(for post: DiaryPost) -> [DiaryPost] {
        posts.filter { $0.parentID == post.id }.sorted { $0.createdAt < $1.createdAt }
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        ContentUnavailableView("写下第一条", systemImage: "quote.bubble", description: Text("这里不会有人打扰，想到什么就发什么。"))
    }
}
