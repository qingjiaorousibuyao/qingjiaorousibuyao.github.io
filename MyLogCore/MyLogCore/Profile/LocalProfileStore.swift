import Foundation
import SwiftUI

@MainActor
final class LocalProfileStore: ObservableObject {
    @Published var name: String { didSet { UserDefaults.standard.set(name, forKey: "profile.name") } }
    @Published private(set) var avatar: UIImage? = nil
    private var avatarPath: String

    init() {
        name = UserDefaults.standard.string(forKey: "profile.name") ?? "我"
        avatarPath = UserDefaults.standard.string(forKey: "profile.avatarPath") ?? ""
        avatar = MediaStore.image(path: avatarPath.isEmpty ? nil : avatarPath)
    }

    func setAvatar(_ data: Data) {
        MediaStore.remove(path: avatarPath.isEmpty ? nil : avatarPath)
        guard let path = MediaStore.saveImage(data, category: "my-avatar", maxDimension: 800) else { return }
        avatarPath = path
        UserDefaults.standard.set(path, forKey: "profile.avatarPath")
        avatar = MediaStore.image(path: path)
    }
}

struct AvatarView: View {
    let image: UIImage?
    let size: CGFloat
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Circle().fill(AppPalette.palePurple).overlay(Image(systemName: "person.fill").foregroundStyle(AppPalette.accent)) }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
    }
}
