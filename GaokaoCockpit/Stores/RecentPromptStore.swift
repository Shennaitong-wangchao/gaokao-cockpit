import Foundation

struct RecentPromptEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let templateId: UUID
    let title: String
    let category: String
    let usedAt: Date

    init(
        id: UUID = UUID(),
        templateId: UUID,
        title: String,
        category: String,
        usedAt: Date = .now
    ) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.category = category
        self.usedAt = usedAt
    }
}

enum RecentPromptStore {
    private static let userDefaultsKey = "gaokaoCockpit.recentPrompts.v1"
    private static let maxRecentCount = 20

    static func load() -> [RecentPromptEntry] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            let entries = try JSONDecoder().decode([RecentPromptEntry].self, from: data)
            return entries
        } catch {
            return []
        }
    }

    static func recordUse(template: PromptTemplate) {
        var entries = load()

        // 移除同一个 templateId 的旧记录
        entries.removeAll { $0.templateId == template.id }

        // 插入新记录到最前
        let newEntry = RecentPromptEntry(
            templateId: template.id,
            title: template.title,
            category: template.category,
            usedAt: .now
        )
        entries.insert(newEntry, at: 0)

        // 保留最多 maxRecentCount 条
        if entries.count > maxRecentCount {
            entries = Array(entries.prefix(maxRecentCount))
        }

        save(entries)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    static func recent(limit: Int) -> [RecentPromptEntry] {
        let entries = load()
        return Array(entries.prefix(limit))
    }

    private static func save(_ entries: [RecentPromptEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // 静默失败，不影响主流程
        }
    }
}
