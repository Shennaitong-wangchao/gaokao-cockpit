import SwiftData
import SwiftUI

struct PromptLibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var templates: [PromptTemplate] = []
    @State private var selectedCategory: PromptCategoryFilter = .all
    @State private var totalTemplateCount = 0
    @State private var totalUsageCount = 0
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var selectedTemplate: PromptTemplate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PromptLibraryHeaderView()

                PromptSummaryCard(
                    totalTemplateCount: totalTemplateCount,
                    totalUsageCount: totalUsageCount
                )

                PromptCategoryFilterBar(selectedCategory: $selectedCategory)

                if isLoading {
                    ProgressView("正在加载 Prompt 模板")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if templates.isEmpty {
                    ContentUnavailableView {
                        Label("还没有 Prompt 模板", systemImage: "text.bubble")
                    } description: {
                        Text("还没有 Prompt 模板。请检查内置模板 seed 是否成功。")
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(templates, id: \.id) { template in
                            PromptTemplateRow(template: template) {
                                selectedTemplate = template
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
        }
        .onChange(of: selectedCategory) {
            refreshTemplates()
        }
        .refreshable {
            refreshTemplates()
        }
        .sheet(item: $selectedTemplate) { template in
            PromptTemplateDetailView(template: template) { message in
                refreshTemplates()
                statusMessage = message
            }
        }
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
        templates = try PromptTemplateStore.fetchTemplates(
            category: selectedCategory.category,
            in: modelContext
        )

        let allTemplates = try PromptTemplateStore.fetchTemplates(category: nil, in: modelContext)
        totalTemplateCount = allTemplates.count
        totalUsageCount = allTemplates.reduce(0) { $0 + $1.usageCount }
    }
}

private enum PromptCategoryFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case mistake = "错题"
    case preview = "预习"
    case organize = "整理"
    case variant = "变式"
    case diagnosis = "诊断"
    case review = "复盘"
    case selfTest = "自测"

    var id: String { rawValue }

    var title: String { rawValue }

    var category: String? {
        self == .all ? nil : rawValue
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
    @Binding var selectedCategory: PromptCategoryFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分类")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PromptCategoryFilter.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
                        .background(selectedCategory == category ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(.vertical, 1)
            }
            .accessibilityLabel("Prompt 分类筛选")
        }
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

                    PromptTag(text: template.category)
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

                    Label("使用", systemImage: "text.bubble")
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
        .accessibilityLabel("使用 Prompt 模板 \(template.title)")
    }
}

private struct PromptTag: View {
    let text: String

    var body: some View {
        Text(text.isEmpty ? "未分类" : text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
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

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    try! PromptTemplateSeeder.seedIfNeeded(in: context)

    return NavigationStack {
        PromptLibraryView()
    }
    .modelContainer(container)
}
