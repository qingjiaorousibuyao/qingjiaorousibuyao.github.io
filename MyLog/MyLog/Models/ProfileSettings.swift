import Foundation
import SwiftUI

final class ProfileSettings: ObservableObject {
    @Published var nickname: String { didSet { save() } }
    @Published var userID: String { didSet { save() } }
    @Published var bio: String { didSet { save() } }
    @Published var avatarData: Data? { didSet { save() } }
    @Published var coverData: Data? { didSet { save() } }

    private let defaults = UserDefaults.standard

    init() {
        nickname = defaults.string(forKey: "profile.nickname") ?? "我的小世界"
        userID = defaults.string(forKey: "profile.userID") ?? "@mylife"
        bio = defaults.string(forKey: "profile.bio") ?? "写给未来的自己"
        avatarData = defaults.data(forKey: "profile.avatar")
        coverData = defaults.data(forKey: "profile.cover")
    }

    func update(nickname: String, userID: String, bio: String) {
        self.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "我的小世界" : nickname
        let cleanID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userID = cleanID.isEmpty ? "@mylife" : (cleanID.hasPrefix("@") ? cleanID : "@\(cleanID)")
        self.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "写给未来的自己" : bio
    }

    private func save() {
        defaults.set(nickname, forKey: "profile.nickname")
        defaults.set(userID, forKey: "profile.userID")
        defaults.set(bio, forKey: "profile.bio")
        defaults.set(avatarData, forKey: "profile.avatar")
        defaults.set(coverData, forKey: "profile.cover")
    }
}
