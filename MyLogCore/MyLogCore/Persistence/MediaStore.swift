import Foundation
import UIKit

enum MediaStore {
    private static let fileManager = FileManager.default

    private static var root: URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyLogCore", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func directory(_ name: String) -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    static func saveImage(_ data: Data, category: String, maxDimension: CGFloat = 2200) -> String? {
        guard let source = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(source.size.width, source.size.height))
        let size = CGSize(width: max(1, source.size.width * scale), height: max(1, source.size.height * scale))
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in source.draw(in: CGRect(origin: .zero, size: size)) }
        guard let compressed = rendered.jpegData(compressionQuality: 0.84) else { return nil }
        let relativePath = "Images/\(category)-\(UUID().uuidString.lowercased()).jpg"
        let url = root.appendingPathComponent(relativePath)
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        do {
            try compressed.write(to: url, options: .atomic)
            return relativePath
        } catch { return nil }
    }

    static func image(path: String?) -> UIImage? {
        guard let path, let data = try? Data(contentsOf: root.appendingPathComponent(path)) else { return nil }
        return UIImage(data: data)
    }

    static func makeAudioURL() -> URL {
        directory("Audio").appendingPathComponent("\(UUID().uuidString.lowercased()).m4a")
    }

    static func audioURL(path: String?) -> URL? {
        guard let path else { return nil }
        let url = root.appendingPathComponent(path)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func relativeAudioPath(for url: URL) -> String { "Audio/\(url.lastPathComponent)" }

    static func remove(path: String?) {
        guard let path else { return }
        try? fileManager.removeItem(at: root.appendingPathComponent(path))
    }
}
