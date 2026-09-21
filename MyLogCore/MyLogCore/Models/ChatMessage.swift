import Foundation
import SwiftData

enum MessageSender: String, CaseIterable { case me, contact }
enum MessageKind: String { case text, image, audio }

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var contactID: UUID
    var sender: String
    var kind: String
    var text: String?
    var imagePath: String?
    var audioPath: String?
    var audioDuration: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        contactID: UUID,
        sender: MessageSender,
        kind: MessageKind,
        text: String? = nil,
        imagePath: String? = nil,
        audioPath: String? = nil,
        audioDuration: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contactID = contactID
        self.sender = sender.rawValue
        self.kind = kind.rawValue
        self.text = text
        self.imagePath = imagePath
        self.audioPath = audioPath
        self.audioDuration = audioDuration
        self.createdAt = createdAt
    }

    var senderValue: MessageSender { MessageSender(rawValue: sender) ?? .me }
    var kindValue: MessageKind { MessageKind(rawValue: kind) ?? .text }
}
