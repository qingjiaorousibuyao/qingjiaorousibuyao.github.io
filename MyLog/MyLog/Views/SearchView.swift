import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @State private var query = ""
    private var results: [DiaryPost] { query.isEmpty ? posts : posts.filter { $0.text.localizedCaseInsensitiveContains(query) } }

    var body: some View {
        List(results) { post in PostCard(post: post).listRowInsets(.init()) }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .searchable(text: $query, prompt: "搜索以前的碎碎念")
    }
}

