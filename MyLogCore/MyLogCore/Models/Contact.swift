import Foundation
import SwiftData

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var name: String
    var bio: String?
    var avatarPath: String?
    var coverPath: String?
    var chatBackgroundPath: String?
    var gender: String?
    var birthday: Date?
    var hometown: String?
    var persona: String?
    var taboos: String?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
