import Foundation
import SwiftData

enum ChatSender: String { case currentUser, contact }
enum ChatMessageType: String { case text, image, audio }

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var contactID: UUID
    var sender: String
    var type: String
    var text: String?
    var imagePath: String?
    var audioPath: String?
    var audioDuration: Double?
    var createdAt: Date

    init(id: UUID = UUID(), contactID: UUID, sender: ChatSender, type: ChatMessageType, text: String? = nil, imagePath: String? = nil, audioPath: String? = nil, audioDuration: Double? = nil, createdAt: Date = .now) {
        self.id = id; self.contactID = contactID; self.sender = sender.rawValue; self.type = type.rawValue; self.text = text
        self.imagePath = imagePath; self.audioPath = audioPath; self.audioDuration = audioDuration; self.createdAt = createdAt
    }
    var senderValue: ChatSender { ChatSender(rawValue: sender) ?? .currentUser }
    var typeValue: ChatMessageType { ChatMessageType(rawValue: type) ?? .text }
}
