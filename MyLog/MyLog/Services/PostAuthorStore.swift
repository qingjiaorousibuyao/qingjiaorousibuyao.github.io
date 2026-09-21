import Foundation

enum PostAuthorSelection: Hashable {
    case me
    case contact(UUID)
}

private struct StoredPostAuthor: Codable {
    let contactID: UUID?
}

enum PostAuthorStore {
    private static let filename = "post-authors.json"
    private static var cachedValues: [String: StoredPostAuthor]?

    static func selection(for postID: UUID) -> PostAuthorSelection {
        guard let author = load()[postID.uuidString.lowercased()],
              let contactID = author.contactID else { return .me }
        return .contact(contactID)
    }

    static func set(_ selection: PostAuthorSelection, for postID: UUID) {
        var values = load()
        switch selection {
        case .me:
            values.removeValue(forKey: postID.uuidString.lowercased())
        case let .contact(contactID):
            values[postID.uuidString.lowercased()] = StoredPostAuthor(contactID: contactID)
        }
        cachedValues = values
        PersistentSettingsStore.save(values, to: filename)
    }

    static func remove(postID: UUID) {
        var values = load()
        values.removeValue(forKey: postID.uuidString.lowercased())
        cachedValues = values
        PersistentSettingsStore.save(values, to: filename)
    }

    private static func load() -> [String: StoredPostAuthor] {
        if let cachedValues { return cachedValues }
        let values = PersistentSettingsStore.load([String: StoredPostAuthor].self, from: filename) ?? [:]
        cachedValues = values
        return values
    }
}
