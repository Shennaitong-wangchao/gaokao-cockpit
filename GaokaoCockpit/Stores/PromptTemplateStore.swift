import Foundation
import SwiftData

enum PromptTemplateStore {
    static func fetchBuiltInTemplates(in context: ModelContext) throws -> [PromptTemplate] {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.isBuiltIn
            },
            sortBy: templateSortDescriptors
        )

        return try context.fetch(descriptor)
    }

    static func fetchTemplates(category: String?, in context: ModelContext) throws -> [PromptTemplate] {
        if let category = normalizedCategory(category) {
            let descriptor = FetchDescriptor<PromptTemplate>(
                predicate: #Predicate<PromptTemplate> { template in
                    template.category == category
                },
                sortBy: templateSortDescriptors
            )

            return try context.fetch(descriptor)
        }

        let descriptor = FetchDescriptor<PromptTemplate>(
            sortBy: templateSortDescriptors
        )

        return try context.fetch(descriptor)
    }

    static func fetchTemplate(title: String, in context: ModelContext) throws -> PromptTemplate? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.title == cleanTitle
            },
            sortBy: templateSortDescriptors
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    static func countBuiltInTemplates(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.isBuiltIn
            }
        )

        return try context.fetchCount(descriptor)
    }

    static func incrementUsageCount(_ template: PromptTemplate, in context: ModelContext) throws {
        template.usageCount += 1
        template.updatedAt = Date()

        try context.save()
    }

    private static func normalizedCategory(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "全部" ? nil : trimmed
    }

    private static var templateSortDescriptors: [SortDescriptor<PromptTemplate>] {
        [
            SortDescriptor(\.category, order: .forward),
            SortDescriptor(\.title, order: .forward)
        ]
    }
}
