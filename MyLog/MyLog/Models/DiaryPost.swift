import Foundation
import SwiftData

@Model
final class DiaryPost {
    var id: UUID
    var text: String
    var createdAt: Date
    var isFavorite: Bool
    var isLiked: Bool = false
    var likeCount: Int = 0
    var manualCommentCount: Int = 0
    var location: String?
    var visibility: String = "所有人可见"
    var mood: String?
    var parentID: UUID?
    var photos: [Data]

    init(
        text: String,
        photos: [Data] = [],
        mood: String? = nil,
        parentID: UUID? = nil,
        createdAt: Date = .now,
        location: String? = nil,
        visibility: String = "所有人可见"
    ) {
        self.id = UUID()
        self.text = text
        self.createdAt = createdAt
        self.isFavorite = false
        self.mood = mood
        self.parentID = parentID
        self.photos = photos
        self.location = location
        self.visibility = visibility
    }
}
