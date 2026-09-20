import Foundation
import UIKit

enum PersistentSettingsStore {
    private static let fileManager = FileManager.default

    static var rootDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("MyLog", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static var mediaDirectory: URL {
        let directory = rootDirectory.appendingPathComponent("Media", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = rootDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to filename: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: rootDirectory.appendingPathComponent(filename), options: .atomic)
    }

    @discardableResult
    static func saveImage(_ data: Data, filename: String, maxDimension: CGFloat) -> String? {
        guard let image = UIImage(data: data), let compressed = image.persistedJPEG(maxDimension: maxDimension) else { return nil }
        let url = mediaDirectory.appendingPathComponent(filename)
        do {
            try compressed.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func loadImage(filename: String?) -> Data? {
        guard let filename else { return nil }
        return try? Data(contentsOf: mediaDirectory.appendingPathComponent(filename))
    }

    static func removeImage(filename: String?) {
        guard let filename else { return }
        try? fileManager.removeItem(at: mediaDirectory.appendingPathComponent(filename))
    }
}

private extension UIImage {
    func persistedJPEG(maxDimension: CGFloat) -> Data? {
        let largest = max(size.width, size.height)
        let scale = largest > maxDimension ? maxDimension / largest : 1
        let targetSize = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in draw(in: CGRect(origin: .zero, size: targetSize)) }
        return rendered.jpegData(compressionQuality: 0.84)
    }
}
