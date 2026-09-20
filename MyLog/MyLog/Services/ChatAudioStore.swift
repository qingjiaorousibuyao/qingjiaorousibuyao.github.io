import Foundation

enum ChatAudioStore {
    private static let fileManager = FileManager.default

    private static var directory: URL {
        let directory = PersistentSettingsStore.rootDirectory
            .appendingPathComponent("ChatAudio", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func makeRecordingURL() -> URL {
        directory.appendingPathComponent(UUID().uuidString.lowercased())
            .appendingPathExtension("m4a")
    }

    static func url(for filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = directory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func remove(filename: String?) {
        guard let filename else { return }
        try? fileManager.removeItem(at: directory.appendingPathComponent(filename))
    }
}
