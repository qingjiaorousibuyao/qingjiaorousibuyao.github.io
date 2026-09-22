import SwiftUI
import UIKit

struct ContactAvatar: View {
    let path: String?
    var size: CGFloat
    var body: some View {
        Group {
            if let data = MediaStore.imageData(path: path), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
            else { Circle().fill(EunoiaTheme.muted).overlay(Image(systemName: "person.fill").foregroundStyle(EunoiaTheme.accent)) }
        }
        .frame(width: size, height: size).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
    }
}
