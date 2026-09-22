import Foundation
import UIKit

enum MediaStore {
    private static let manager = FileManager.default
    private static var root: URL {
        let url = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Eunoia", isDirectory: true)
        try? manager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private static var media: URL {
        let url = root.appendingPathComponent("Media", isDirectory: true)
        try? manager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    static var audioDirectory: URL {
        let url = root.appendingPathComponent("ChatAudio", isDirectory: true)
        try? manager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    @discardableResult static func saveImage(_ data: Data, prefix: String, maxDimension: CGFloat) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let largest = max(image.size.width, image.size.height)
        let scale = largest > maxDimension ? maxDimension / largest : 1
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let compressed = rendered.jpegData(compressionQuality: 0.84) else { return nil }
        let filename = "\(prefix)-\(UUID().uuidString.lowercased()).jpg"
        do { try compressed.write(to: media.appendingPathComponent(filename), options: .atomic); return filename } catch { return nil }
    }
    static func imageData(path: String?) -> Data? { guard let path else { return nil }; return try? Data(contentsOf: media.appendingPathComponent(path)) }
    static func remove(path: String?) { guard let path else { return }; try? manager.removeItem(at: media.appendingPathComponent(path)) }
}
