import SwiftUI
import SwiftData

struct ThreadView: View {
    @Query(sort: \DiaryPost.createdAt) private var posts: [DiaryPost]
    let rootID: UUID
    @State private var replying = false

    private var thread: [DiaryPost] {
        guard let root = posts.first(where: { $0.id == rootID }) else { return [] }
        return [root] + posts.filter { $0.parentID == rootID }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(thread) { post in PostCard(post: post); Divider().opacity(0.5) }
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
    }
}

