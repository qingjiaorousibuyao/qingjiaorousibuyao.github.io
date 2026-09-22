import Foundation

enum ChatAudioStore {
    static func makeRecordingURL() -> URL { MediaStore.audioDirectory.appendingPathComponent(UUID().uuidString.lowercased()).appendingPathExtension("m4a") }
    static func url(for filename: String?) -> URL? { guard let filename else { return nil }; let url = MediaStore.audioDirectory.appendingPathComponent(filename); return FileManager.default.fileExists(atPath: url.path) ? url : nil }
    static func remove(filename: String?) { guard let filename else { return }; try? FileManager.default.removeItem(at: MediaStore.audioDirectory.appendingPathComponent(filename)) }
}
