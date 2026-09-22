import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var name: String
    var avatarFilename: String?
    var coverImageFilename: String?
    var bio: String?
    var gender: String?
    var birthday: Date?
    var hometown: String?
    var persona: String?
    var taboos: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        avatarFilename: String? = nil,
        coverImageFilename: String? = nil,
        bio: String? = nil,
        gender: String? = nil,
        birthday: Date? = nil,
        hometown: String? = nil,
        persona: String? = nil,
        taboos: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.avatarFilename = avatarFilename
        self.coverImageFilename = coverImageFilename
        self.bio = bio
        self.gender = gender
        self.birthday = birthday
        self.hometown = hometown
        self.persona = persona
        self.taboos = taboos
        self.createdAt = createdAt
    }
}
