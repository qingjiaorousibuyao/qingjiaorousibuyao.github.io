import Foundation
import SwiftData

enum ChatSender: String {
    case me
    case contact
}

enum ChatMessageType: String {
    case text
    case image
    case audio
}

@Model
final class ChatMessage {
    var id: UUID
    var contactID: UUID
    var sender: String
    var type: String
    var text: String?
    var imagePath: String?
    var audioPath: String? = nil
    var audioDuration: Double? = nil
    var createdAt: Date

    init(
        id: UUID = UUID(),
        contactID: UUID,
        sender: ChatSender,
        type: ChatMessageType,
        text: String? = nil,
        imagePath: String? = nil,
        audioPath: String? = nil,
        audioDuration: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contactID = contactID
        self.sender = sender.rawValue
        self.type = type.rawValue
        self.text = text
        self.imagePath = imagePath
        self.audioPath = audioPath
        self.audioDuration = audioDuration
        self.createdAt = createdAt
    }

    var senderValue: ChatSender { ChatSender(rawValue: sender) ?? .me }
    var typeValue: ChatMessageType { ChatMessageType(rawValue: type) ?? .text }
}
