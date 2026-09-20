import SwiftUI
import SwiftData

struct ThreadView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DiaryPost.createdAt) private var posts: [DiaryPost]
    let rootID: UUID
    @State private var replying = false
    @State private var editingPost: DiaryPost?

    private var thread: [DiaryPost] {
        guard let root = posts.first(where: { $0.id == rootID }) else { return [] }
        return [root] + posts.filter { $0.parentID == rootID }
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(thread) { post in
                        PostCard(post: post, onReply: { replying = true }, onEdit: { editingPost = post }, onDelete: { delete(post) })
                    }
                }
                .padding(14)
            }
        }
        .navigationTitle("对话")
        .safeAreaInset(edge: .bottom) {
            Button { replying = true } label: {
                Label("回复过去的自己", systemImage: "arrowshape.turn.up.left")
                    .frame(maxWidth: .infinity).padding(12)
            }
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $replying) { ComposeView(parentID: rootID) }
        .sheet(item: $editingPost) { ComposeView(editingPost: $0) }
    }

    private func delete(_ post: DiaryPost) {
        if post.id == rootID {
            posts.filter { $0.parentID == rootID }.forEach(context.delete)
            context.delete(post)
            dismiss()
        } else {
            context.delete(post)
        }
        try? context.save()
    }
}
