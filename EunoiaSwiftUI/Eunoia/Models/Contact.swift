import Foundation
import SwiftData

enum ContactGroup: String, CaseIterable, Identifiable, Codable, Hashable {
    case friends, important, ungrouped
    var id: String { rawValue }
    var title: String {
        switch self { case .friends: "朋友"; case .important: "重要的人"; case .ungrouped: "未分组" }
    }
}

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var signature: String
    var groupRawValue: String
    var region: String
    var avatarPath: String?
    var profileBackgroundPath: String?
    var chatBackgroundPath: String?
    var isFavorite: Bool
    var createdAt: Date

    init(id: UUID = UUID(), nickname: String, signature: String = "", group: ContactGroup = .ungrouped, region: String = "", avatarPath: String? = nil, profileBackgroundPath: String? = nil, chatBackgroundPath: String? = nil, isFavorite: Bool = false, createdAt: Date = .now) {
        self.id = id; self.nickname = nickname; self.signature = signature; self.groupRawValue = group.rawValue; self.region = region
        self.avatarPath = avatarPath; self.profileBackgroundPath = profileBackgroundPath; self.chatBackgroundPath = chatBackgroundPath
        self.isFavorite = isFavorite; self.createdAt = createdAt
    }

    var group: ContactGroup {
        get { ContactGroup(rawValue: groupRawValue) ?? .ungrouped }
        set { groupRawValue = newValue.rawValue }
    }
}
