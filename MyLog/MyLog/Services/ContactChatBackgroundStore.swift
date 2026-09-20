import Foundation

enum ContactChatBackgroundStore {
    private static let registryFilename = "contact-chat-backgrounds.json"

    static func data(for contactID: UUID) -> Data? {
        PersistentSettingsStore.loadImage(filename: registry()[contactID.uuidString])
    }

    static func set(_ data: Data?, for contactID: UUID) {
        var values = registry()
        let key = contactID.uuidString
        let oldFilename = values[key]

        if let data {
            let filename = "contact-\(contactID.uuidString.lowercased())-chat-background.jpg"
            guard let saved = PersistentSettingsStore.saveImage(data, filename: filename, maxDimension: 2600) else { return }
            values[key] = saved
            if oldFilename != saved { PersistentSettingsStore.removeImage(filename: oldFilename) }
        } else {
            PersistentSettingsStore.removeImage(filename: oldFilename)
            values.removeValue(forKey: key)
        }

        PersistentSettingsStore.save(values, to: registryFilename)
    }

    private static func registry() -> [String: String] {
        PersistentSettingsStore.load([String: String].self, from: registryFilename) ?? [:]
    }
}
