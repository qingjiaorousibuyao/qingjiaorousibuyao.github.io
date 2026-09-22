import Foundation
import SwiftData

@Model
final class DiaryPost {
    var id: UUID
    var text: String
    var createdAt: Date
    var isFavorite: Bool
    var mood: String?
    var parentID: UUID?
    var photos: [Data]

    init(text: String, photos: [Data] = [], mood: String? = nil, parentID: UUID? = nil) {
        self.id = UUID()
        self.text = text
        self.createdAt = .now
        self.isFavorite = false
        self.mood = mood
        self.parentID = parentID
        self.photos = photos
    }
}
