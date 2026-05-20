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
            let selectedStorageValue = category.storageValue
            let selectedDisplayName = category.displayName
            let descriptor = FetchDescriptor<PromptTemplate>(
                predicate: #Predicate<PromptTemplate> { template in
                    template.category == selectedStorageValue || template.category == selectedDisplayName
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

    private static func normalizedCategory(_ value: String?) -> PromptCategory? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let category = PromptCategory.from(trimmed)
        return category == .all ? nil : category
    }

    // MARK: - Custom Template Helpers

    static func createCustomTemplate(
        title: String,
        category: String,
        templateDescription: String,
        templateText: String,
        variablesText: String,
        in context: ModelContext
    ) throws -> PromptTemplate {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = templateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            throw CustomTemplateError.emptyTitle
        }
        guard !cleanText.isEmpty else {
            throw CustomTemplateError.emptyTemplateText
        }

        let template = PromptTemplate(
            title: cleanTitle,
            category: category,
            templateDescription: templateDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            templateText: cleanText,
            variablesText: variablesText.trimmingCharacters(in: .whitespacesAndNewlines),
            usageCount: 0,
            isBuiltIn: false,
            createdAt: .now,
            updatedAt: .now
        )
        context.insert(template)
        try context.save()
        return template
    }

    static func updateCustomTemplate(
        _ template: PromptTemplate,
        title: String,
        category: String,
        templateDescription: String,
        templateText: String,
        variablesText: String,
        in context: ModelContext
    ) throws {
        guard !template.isBuiltIn else {
            throw CustomTemplateError.cannotEditBuiltIn
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = templateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            throw CustomTemplateError.emptyTitle
        }
        guard !cleanText.isEmpty else {
            throw CustomTemplateError.emptyTemplateText
        }

        template.title = cleanTitle
        template.category = category
        template.templateDescription = templateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        template.templateText = cleanText
        template.variablesText = variablesText.trimmingCharacters(in: .whitespacesAndNewlines)
        template.updatedAt = .now

        try context.save()
    }

    static func deleteCustomTemplate(_ template: PromptTemplate, in context: ModelContext) throws {
        guard !template.isBuiltIn else {
            throw CustomTemplateError.cannotDeleteBuiltIn
        }

        context.delete(template)
        try context.save()
    }

    static func duplicateBuiltInTemplate(_ template: PromptTemplate, in context: ModelContext) throws -> PromptTemplate {
        let newTemplate = PromptTemplate(
            title: "\(template.title) 副本",
            category: template.category,
            templateDescription: template.templateDescription,
            templateText: template.templateText,
            variablesText: template.variablesText,
            usageCount: 0,
            isBuiltIn: false,
            createdAt: .now,
            updatedAt: .now
        )
        context.insert(newTemplate)
        try context.save()
        return newTemplate
    }

    static func fetchCustomTemplates(in context: ModelContext) throws -> [PromptTemplate] {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                !template.isBuiltIn
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    static func extractVariablesFromTemplate(_ templateText: String) -> [String] {
        let pattern = #"\{\{\s*([^}]+?)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let fullRange = NSRange(templateText.startIndex..<templateText.endIndex, in: templateText)
        let matches = regex.matches(in: templateText, range: fullRange)

        var variables: [String] = []
        var seen = Set<String>()

        for match in matches {
            guard match.numberOfRanges > 1,
                  let variableRange = Range(match.range(at: 1), in: templateText) else {
                continue
            }

            let variable = templateText[variableRange]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !variable.isEmpty && !seen.contains(variable) {
                seen.insert(variable)
                variables.append(variable)
            }
        }

        return variables
    }

    // MARK: - Private

    private static var templateSortDescriptors: [SortDescriptor<PromptTemplate>] {
        [
            SortDescriptor(\.category, order: .forward),
            SortDescriptor(\.title, order: .forward)
        ]
    }
}

enum CustomTemplateError: LocalizedError {
    case emptyTitle
    case emptyTemplateText
    case cannotEditBuiltIn
    case cannotDeleteBuiltIn

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "标题不能为空"
        case .emptyTemplateText:
            return "模板正文不能为空"
        case .cannotEditBuiltIn:
            return "内置模板不能直接编辑"
        case .cannotDeleteBuiltIn:
            return "内置模板不能删除"
        }
    }
}
