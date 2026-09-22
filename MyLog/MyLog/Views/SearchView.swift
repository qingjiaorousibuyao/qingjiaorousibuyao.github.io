import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \DiaryPost.createdAt, order: .reverse) private var posts: [DiaryPost]
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var query = ""
    @State private var selectedPostID: UUID?
    private var results: [DiaryPost] {
        guard !query.isEmpty else { return posts.filter { $0.parentID == nil } }
        return posts.filter { post in
            guard post.parentID == nil else { return false }
            let authorMatches: Bool = {
                guard case let .contact(id) = PostAuthorStore.selection(for: post.id) else { return false }
                return contacts.first(where: { $0.id == id })?.name.localizedCaseInsensitiveContains(query) == true
            }()
            return post.text.localizedCaseInsensitiveContains(query)
                || (post.location?.localizedCaseInsensitiveContains(query) == true)
                || authorMatches
        }
    }

    var body: some View {
        List(results) { post in
            PostCard(post: post, onOpen: { selectedPostID = post.id })
                .listRowInsets(.init()).listRowBackground(Color.clear)
        }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("搜索")
            .searchable(text: $query, prompt: "搜索正文、联系人或地点")
            .navigationDestination(item: $selectedPostID) { ThreadView(rootID: $0) }
    }
}
