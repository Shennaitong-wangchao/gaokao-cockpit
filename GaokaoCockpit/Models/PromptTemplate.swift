import Foundation
import SwiftData

@Model
final class PromptTemplate {
    var id: UUID
    var title: String
    var category: String
    var templateDescription: String
    var templateText: String
    var variablesText: String
    var usageCount: Int
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        category: String = "",
        templateDescription: String = "",
        templateText: String = "",
        variablesText: String = "",
        usageCount: Int = 0,
        isBuiltIn: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.templateDescription = templateDescription
        self.templateText = templateText
        self.variablesText = variablesText
        self.usageCount = usageCount
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension PromptTemplate: Identifiable {}
