import Foundation
import SwiftData

@Model
final class ResourceItem {
    var id: UUID
    var title: String
    var subject: String
    var chapter: String
    var type: String
    var uri: String
    var status: String
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        subject: String = "",
        chapter: String = "",
        type: String = "",
        uri: String = "",
        status: String = ModelDefaults.ResourceStatus.unread,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.subject = subject
        self.chapter = chapter
        self.type = type
        self.uri = uri
        self.status = status
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
