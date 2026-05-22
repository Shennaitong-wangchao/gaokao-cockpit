import SwiftData
import SwiftUI

enum TemplateFilter: String, CaseIterable, Identifiable {
    case all
    case builtIn
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "全部"
        case .builtIn:
            return "内置"
        case .custom:
            return "自定义"
        }
    }
}

struct PromptTemplateDetailRoute: Identifiable {
    let templateID: UUID
    let title: String

    var id: UUID { templateID }
}

@Observable
final class PromptLibraryModel {
    var templates: [PromptTemplate] = []
    var selectedCategory: PromptCategory = .all
    var searchText = ""
    var totalTemplateCount = 0
    var totalUsageCount = 0
    var isLoading = true
    var statusMessage: String?
    var activeTemplateDetail: PromptTemplateDetailRoute?
    var recentEntries: [RecentPromptEntry] = []
    var showCreateEditor = false
    var templateFilter: TemplateFilter = .all

    var frequentTemplates: [PromptTemplate] {
        let allTemplates = templates
        let used = allTemplates.filter { $0.usageCount > 0 }
        let sorted = used.sorted { $0.usageCount > $1.usageCount }
        return Array(sorted.prefix(5))
    }

    func loadTemplates(in context: ModelContext) {
        isLoading = true
        statusMessage = nil

        do {
            try refreshTemplatesThrowing(in: context)
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载 Prompt 模板失败：\(error.localizedDescription)"
            HapticFeedback.error()
            ToastManager.shared.show(message: "加载模板失败", style: .error)
        }
    }

    func refreshTemplates(in context: ModelContext) {
        do {
            try refreshTemplatesThrowing(in: context)
        } catch {
            statusMessage = "刷新 Prompt 模板失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func refreshRecentEntries() {
        recentEntries = RecentPromptStore.recent(limit: 5)
    }

    func openTemplate(_ template: PromptTemplate) {
        activeTemplateDetail = PromptTemplateDetailRoute(
            templateID: template.id,
            title: template.title
        )
    }

    func handleRecentEntryTap(in context: ModelContext, entry: RecentPromptEntry) {
        do {
            if let template = try findTemplateById(entry.templateId, in: context) {
                openTemplate(template)
                return
            }

            if let template = try PromptTemplateStore.fetchTemplate(title: entry.title, in: context) {
                openTemplate(template)
                return
            }

            statusMessage = "这个模板当前不存在，可能已被移除或重命名。"
            HapticFeedback.warning()
        } catch {
            statusMessage = "查找模板失败：\(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    private func findTemplateById(_ id: UUID, in context: ModelContext) throws -> PromptTemplate? {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    private func refreshTemplatesThrowing(in context: ModelContext) throws {
        var results = try PromptTemplateStore.fetchTemplates(
            category: selectedCategory == .all ? nil : selectedCategory.storageValue,
            in: context
        )

        switch templateFilter {
        case .all:
            break
        case .builtIn:
            results = results.filter { $0.isBuiltIn }
        case .custom:
            results = results.filter { !$0.isBuiltIn }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            results = results.filter { template in
                template.title.lowercased().contains(query)
                    || template.templateDescription.lowercased().contains(query)
                    || template.category.lowercased().contains(query)
            }
            results.sort { lhs, rhs in
                if lhs.usageCount != rhs.usageCount {
                    return lhs.usageCount > rhs.usageCount
                }
                return lhs.title < rhs.title
            }
        } else {
            results.sort { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category < rhs.category
                }
                if lhs.usageCount != rhs.usageCount {
                    return lhs.usageCount > rhs.usageCount
                }
                return lhs.title < rhs.title
            }
        }

        templates = results

        let allTemplates = try PromptTemplateStore.fetchTemplates(category: nil, in: context)
        totalTemplateCount = allTemplates.count
        totalUsageCount = allTemplates.reduce(0) { $0 + $1.usageCount }
    }
}
