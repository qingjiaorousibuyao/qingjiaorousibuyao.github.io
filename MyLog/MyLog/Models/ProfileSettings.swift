import Foundation
import SwiftUI

private struct ProfileConfiguration: Codable {
    var nickname: String
    var userID: String
    var bio: String
    var avatarFilename: String?
    var coverFilename: String?
}

final class ProfileSettings: ObservableObject {
    @Published var nickname: String { didSet { persistIfReady() } }
    @Published var userID: String { didSet { persistIfReady() } }
    @Published var bio: String { didSet { persistIfReady() } }
    @Published private(set) var avatarData: Data?
    @Published private(set) var coverData: Data?

    private var avatarFilename: String?
    private var coverFilename: String?
    private var isRestoring = true
    private static let configurationFilename = "profile-settings.json"

    var displayName: String {
        let value = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "我" : value
    }

    init() {
        if let saved = PersistentSettingsStore.load(ProfileConfiguration.self, from: Self.configurationFilename) {
            nickname = saved.nickname
            userID = saved.userID
            bio = saved.bio
            avatarFilename = saved.avatarFilename
            coverFilename = saved.coverFilename
        } else {
            let defaults = UserDefaults.standard
            nickname = defaults.string(forKey: "profile.nickname") ?? ""
            userID = defaults.string(forKey: "profile.userID") ?? "@mylife"
            bio = defaults.string(forKey: "profile.bio") ?? "写给未来的自己"
            avatarFilename = nil
            coverFilename = nil

            if let legacyAvatar = defaults.data(forKey: "profile.avatar") {
                avatarFilename = PersistentSettingsStore.saveImage(legacyAvatar, filename: "profile-avatar.jpg", maxDimension: 640)
            }
            if let legacyCover = defaults.data(forKey: "profile.cover") {
                coverFilename = PersistentSettingsStore.saveImage(legacyCover, filename: "profile-cover.jpg", maxDimension: 2200)
            }
        }

        avatarData = PersistentSettingsStore.loadImage(filename: avatarFilename)
        coverData = PersistentSettingsStore.loadImage(filename: coverFilename)
        isRestoring = false
        persist()
    }

    func update(nickname: String, userID: String, bio: String) {
        self.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userID = cleanID.isEmpty ? "@mylife" : (cleanID.hasPrefix("@") ? cleanID : "@\(cleanID)")
        self.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "写给未来的自己" : bio
        persist()
    }

    func setAvatar(_ data: Data?) {
        if let data {
            guard let filename = PersistentSettingsStore.saveImage(data, filename: "profile-avatar.jpg", maxDimension: 640) else { return }
            avatarFilename = filename
            avatarData = PersistentSettingsStore.loadImage(filename: filename)
        } else {
            PersistentSettingsStore.removeImage(filename: avatarFilename)
            avatarFilename = nil
            avatarData = nil
        }
        persist()
    }

    func setCover(_ data: Data?) {
        if let data {
            guard let filename = PersistentSettingsStore.saveImage(data, filename: "profile-cover.jpg", maxDimension: 2200) else { return }
            coverFilename = filename
            coverData = PersistentSettingsStore.loadImage(filename: filename)
        } else {
            PersistentSettingsStore.removeImage(filename: coverFilename)
            coverFilename = nil
            coverData = nil
        }
        persist()
    }

    private func persistIfReady() {
        guard !isRestoring else { return }
        persist()
    }

    private func persist() {
        let configuration = ProfileConfiguration(
            nickname: nickname,
            userID: userID,
            bio: bio,
            avatarFilename: avatarFilename,
            coverFilename: coverFilename
        )
        PersistentSettingsStore.save(configuration, to: Self.configurationFilename)
    }
}
