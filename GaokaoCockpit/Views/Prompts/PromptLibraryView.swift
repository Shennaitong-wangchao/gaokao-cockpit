import SwiftData
import SwiftUI

struct PromptLibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var templates: [PromptTemplate] = []
    @State private var selectedCategory: PromptCategory = .all
    @State private var searchText = ""
    @State private var totalTemplateCount = 0
    @State private var totalUsageCount = 0
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var activeTemplateDetail: PromptTemplateDetailRoute?
    @State private var recentEntries: [RecentPromptEntry] = []
    @State private var showCreateEditor = false
    @State private var templateFilter: TemplateFilter = .all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PromptLibraryHeaderView()

                PromptSummaryCard(
                    totalTemplateCount: totalTemplateCount,
                    totalUsageCount: totalUsageCount
                )

                HStack(spacing: 12) {
                    Button {
                        showCreateEditor = true
                    } label: {
                        Label("新建模板", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("新建自定义模板")
                }

                PromptCategoryFilterBar(selectedCategory: $selectedCategory)

                PromptTemplateFilterBar(selectedFilter: $templateFilter)

                PromptSearchBar(searchText: $searchText)

                if searchText.isEmpty && selectedCategory == .all {
                    PromptFrequentSection(templates: frequentTemplates) { template in
                        openTemplate(template)
                    }

                    PromptRecentSection(
                        recentEntries: recentEntries,
                        onSelect: { entry in
                            handleRecentEntryTap(entry)
                        }
                    )
                }

                if isLoading {
                    ProgressView("正在加载 Prompt 模板")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if templates.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView {
                            Label("还没有 Prompt 模板", systemImage: "text.bubble")
                        } description: {
                            Text("还没有 Prompt 模板。请检查内置模板 seed 是否成功。")
                        }
                        .padding(.vertical, 12)
                    } else {
                        ContentUnavailableView {
                            Label("没有找到匹配的 Prompt 模板", systemImage: "magnifyingglass")
                        } description: {
                            Text("没有找到匹配的 Prompt 模板。")
                        }
                        .padding(.vertical, 12)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(templates, id: \.id) { template in
                            PromptTemplateRow(template: template) {
                                openTemplate(template)
                            }
                        }
                    }
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Prompt")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadTemplates()
        }
        .onAppear {
            if !isLoading {
                refreshTemplates()
            }
            refreshRecentEntries()
        }
        .onChange(of: selectedCategory) {
            refreshTemplates()
        }
        .onChange(of: templateFilter) {
            refreshTemplates()
        }
        .onChange(of: searchText) {
            refreshTemplates()
        }
        .refreshable {
            refreshTemplates()
        }
        .sheet(item: $activeTemplateDetail) { route in
            PromptTemplateDetailSheet(route: route) { message in
                refreshTemplates()
                refreshRecentEntries()
                statusMessage = message
            }
        }
        .sheet(isPresented: $showCreateEditor) {
            PromptTemplateEditorView(mode: .create) {
                refreshTemplates()
            }
        }
    }

    private var frequentTemplates: [PromptTemplate] {
        let allTemplates = templates
        let used = allTemplates.filter { $0.usageCount > 0 }
        let sorted = used.sorted { $0.usageCount > $1.usageCount }
        return Array(sorted.prefix(5))
    }

    private func refreshRecentEntries() {
        recentEntries = RecentPromptStore.recent(limit: 5)
    }

    private func openTemplate(_ template: PromptTemplate) {
        activeTemplateDetail = PromptTemplateDetailRoute(
            templateID: template.id,
            title: template.title
        )
    }

    private func handleRecentEntryTap(_ entry: RecentPromptEntry) {
        do {
            // 优先通过 templateId 查找
            if let template = try findTemplateById(entry.templateId) {
                openTemplate(template)
                return
            }

            // 如果找不到，再用 title 查找
            if let template = try PromptTemplateStore.fetchTemplate(title: entry.title, in: modelContext) {
                openTemplate(template)
                return
            }

            // 找不到则提示
            statusMessage = "这个模板当前不存在，可能已被移除或重命名。"
        } catch {
            statusMessage = "查找模板失败：\(error.localizedDescription)"
        }
    }

    private func findTemplateById(_ id: UUID) throws -> PromptTemplate? {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func loadTemplates() {
        isLoading = true
        statusMessage = nil

        do {
            try refreshTemplatesThrowing()
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载 Prompt 模板失败：\(error.localizedDescription)"
        }
    }

    private func refreshTemplates() {
        do {
            try refreshTemplatesThrowing()
        } catch {
            statusMessage = "刷新 Prompt 模板失败：\(error.localizedDescription)"
        }
    }

    private func refreshTemplatesThrowing() throws {
        var results = try PromptTemplateStore.fetchTemplates(
            category: selectedCategory == .all ? nil : selectedCategory.storageValue,
            in: modelContext
        )

        // 应用模板类型筛选
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
            // 搜索结果按 usageCount 降序排序
            results.sort { lhs, rhs in
                if lhs.usageCount != rhs.usageCount {
                    return lhs.usageCount > rhs.usageCount
                }
                return lhs.title < rhs.title
            }
        } else {
            // 无搜索时按 category + usageCount desc + title 排序
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

        let allTemplates = try PromptTemplateStore.fetchTemplates(category: nil, in: modelContext)
        totalTemplateCount = allTemplates.count
        totalUsageCount = allTemplates.reduce(0) { $0 + $1.usageCount }
    }
}

private struct PromptLibraryHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt 仓库")
                .font(.largeTitle.bold())

            Text("把 AI 用成教练组，不是答案机")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct PromptSummaryCard: View {
    let totalTemplateCount: Int
    let totalUsageCount: Int

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        PromptLibraryCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Prompt 仓库概览", systemImage: "square.grid.2x2")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 10) {
                    PromptSummaryValue(title: "内置模板", value: totalTemplateCount)
                    PromptSummaryValue(title: "复制使用", value: totalUsageCount, tint: .blue)
                }
            }
        }
    }
}

private struct PromptSummaryValue: View {
    let title: String
    let value: Int
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PromptCategoryFilterBar: View {
    @Binding var selectedCategory: PromptCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分类")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PromptCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.displayName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
                        .background(selectedCategory == category ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.vertical, 1)
            }
            .accessibilityLabel("Prompt 分类筛选")
        }
    }
}

private struct PromptSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索 Prompt 模板", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("搜索 Prompt 模板")
    }
}

private struct PromptTemplateRow: View {
    let template: PromptTemplate
    let onUse: () -> Void

    var body: some View {
        Button {
            onUse()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        if template.isBuiltIn {
                            PromptTag(text: "内置")
                        } else {
                            PromptTag(text: "自定义", tint: .blue)
                        }
                        PromptTag(text: PromptCategory.from(template.category).displayName)
                    }
                }

                Text(template.templateDescription.isEmpty ? "没有模板说明。" : template.templateDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label("使用 \(template.usageCount) 次", systemImage: "doc.on.clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)

                    Label("查看模板", systemImage: "text.bubble")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("打开 Prompt 模板 \(template.title)")
        .accessibilityHint("展示模板内容和变量填写表单")
        .accessibilityAddTraits(.isButton)
    }
}

private struct PromptTag: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text.isEmpty ? "未分类" : text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct PromptLibraryCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PromptFrequentSection: View {
    let templates: [PromptTemplate]
    let onSelect: (PromptTemplate) -> Void

    var body: some View {
        if templates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("常用 Prompt")
                    .font(.headline)

                Text("复制几次模板后，这里会出现常用 Prompt。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("常用 Prompt")
                    .font(.headline)

                ForEach(templates, id: \.id) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(PromptCategory.from(template.category).displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 8)

                            Text("\(template.usageCount) 次")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开常用 Prompt 模板 \(template.title)")
                    .accessibilityHint("展示模板内容和变量填写表单")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

private struct PromptRecentSection: View {
    let recentEntries: [RecentPromptEntry]
    let onSelect: (RecentPromptEntry) -> Void

    var body: some View {
        if !recentEntries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近使用")
                    .font(.headline)

                ForEach(recentEntries) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(PromptCategory.from(entry.category).displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 8)

                            Text(relativeTime(entry.usedAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开最近使用 Prompt 模板 \(entry.title)")
                    .accessibilityHint("展示模板内容和变量填写表单")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 {
            return "刚刚"
        } else if minutes < 60 {
            return "\(minutes) 分钟前"
        } else if hours < 24 {
            return "\(hours) 小时前"
        } else if days < 7 {
            return "\(days) 天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}

private struct PromptTemplateFilterBar: View {
    @Binding var selectedFilter: TemplateFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("模板类型")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(TemplateFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.displayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedFilter == filter ? Color.white : Color.primary)
                    .background(selectedFilter == filter ? Color.accentColor : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityAddTraits(.isButton)
                }
            }
            .accessibilityLabel("模板类型筛选")
        }
    }
}

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

private struct PromptTemplateDetailRoute: Identifiable {
    let templateID: UUID
    let title: String

    var id: UUID { templateID }
}

private struct PromptTemplateDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let route: PromptTemplateDetailRoute
    let onCopied: (String) -> Void

    @State private var template: PromptTemplate?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let template {
                PromptTemplateDetailView(template: template, onCopied: onCopied)
            } else {
                NavigationStack {
                    ContentUnavailableView {
                        Label("没有找到这个 Prompt 模板", systemImage: "text.bubble")
                    } description: {
                        Text(errorMessage ?? "正在打开 \(route.title)。")
                    } actions: {
                        Button("关闭") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .navigationTitle(route.title)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear {
            loadTemplate()
        }
    }

    private func loadTemplate() {
        template = nil
        errorMessage = nil

        do {
            let templateID = route.templateID
            var descriptor = FetchDescriptor<PromptTemplate>(
                predicate: #Predicate<PromptTemplate> { template in
                    template.id == templateID
                }
            )
            descriptor.fetchLimit = 1

            guard let fetchedTemplate = try modelContext.fetch(descriptor).first else {
                errorMessage = "这个模板可能已被删除或重命名。"
                return
            }

            template = fetchedTemplate
        } catch {
            errorMessage = "打开模板失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    try! PromptTemplateSeeder.seedIfNeeded(in: context)

    return NavigationStack {
        PromptLibraryView()
    }
    .modelContainer(container)
}
