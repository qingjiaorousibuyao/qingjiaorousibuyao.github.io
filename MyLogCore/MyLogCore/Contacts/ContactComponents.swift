import SwiftUI

struct ContactAvatar: View {
    let path: String?
    let size: CGFloat
    var body: some View {
        Group {
            if let image = MediaStore.image(path: path) { Image(uiImage: image).resizable().scaledToFill() }
            else { Circle().fill(AppPalette.palePurple).overlay(Image(systemName: "person.fill").foregroundStyle(AppPalette.accent)) }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
    }
}

extension String {
    var nonBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
