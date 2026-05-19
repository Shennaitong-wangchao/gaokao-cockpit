import SwiftData
import SwiftUI
import UIKit

struct MistakeSurgeryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var mistakes: [MistakeRecord] = []
    @State private var selectedSubjectFilter: MistakeSubjectFilter = .all
    @State private var selectedReviewFilter: MistakeReviewFilter = .all
    @State private var totalMistakeCount = 0
    @State private var scheduledCount = 0
    @State private var reviewedCount = 0
    @State private var masteredCount = 0
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var activeEditor: MistakeEditorMode?
    @State private var activePromptSheet: MistakePromptSheet?
    @State private var activeImagePreview: MistakeImagePreviewItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                MistakeSurgeryHeaderView()

                MistakeSummaryCard(
                    totalMistakeCount: totalMistakeCount,
                    scheduledCount: scheduledCount,
                    reviewedCount: reviewedCount,
                    masteredCount: masteredCount
                )

                MistakeFilterBar(
                    selectedSubjectFilter: $selectedSubjectFilter,
                    selectedReviewFilter: $selectedReviewFilter
                )

                if isLoading {
                    ProgressView("正在加载错题手术")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if mistakes.isEmpty {
                    ContentUnavailableView {
                        Label("还没有错题", systemImage: "cross.case")
                    } description: {
                        Text("还没有错题。下一次做错题时，别只存答案，把错因拆出来。")
                    } actions: {
                        Button {
                            activeEditor = .add
                        } label: {
                            Label("新增错题手术", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(mistakes, id: \.id) { mistake in
                            MistakeRow(
                                mistake: mistake,
                                onTap: {
                                    activeEditor = .edit(mistake)
                                },
                                onPreviewImage: { path in
                                    activeImagePreview = MistakeImagePreviewItem(path: path)
                                },
                                onGeneratePrompt: {
                                    prepareMistakePrompt(for: mistake)
                                },
                                onChangeStatus: { status in
                                    updateReviewStatus(mistake, to: status)
                                }
                            )
                        }
                    }
                }

                Button {
                    activeEditor = .add
                } label: {
                    Label("新增错题手术", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

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
        .navigationTitle("错题")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadMistakes()
        }
        .onAppear {
            if !isLoading {
                refreshMistakeData()
            }
        }
        .onChange(of: selectedSubjectFilter) {
            refreshMistakeData()
        }
        .onChange(of: selectedReviewFilter) {
            refreshMistakeData()
        }
        .refreshable {
            refreshMistakeData()
        }
        .sheet(item: $activeEditor) { editor in
            MistakeEditorView(mode: editor) { message in
                refreshMistakeData()
                statusMessage = message
            }
        }
        .sheet(item: $activePromptSheet) { promptSheet in
            PromptTemplateDetailView(
                template: promptSheet.template,
                initialValues: promptSheet.values
            ) { message in
                statusMessage = message
            }
        }
        .sheet(item: $activeImagePreview) { item in
            MistakeImagePreviewView(path: item.path)
        }
    }

    private func loadMistakes() {
        isLoading = true
        statusMessage = nil

        do {
            try refreshMistakeDataThrowing()
            isLoading = false
        } catch {
            isLoading = false
            statusMessage = "加载错题失败：\(error.localizedDescription)"
        }
    }

    private func refreshMistakeData() {
        do {
            try refreshMistakeDataThrowing()
        } catch {
            statusMessage = "刷新错题失败：\(error.localizedDescription)"
        }
    }

    private func refreshMistakeDataThrowing() throws {
        mistakes = try MistakeRecordStore.fetchMistakes(
            subject: selectedSubjectFilter.subject,
            reviewStatus: selectedReviewFilter.reviewStatus,
            in: modelContext
        )
        totalMistakeCount = try MistakeRecordStore.countMistakes(in: modelContext)
        scheduledCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ModelDefaults.ReviewStatus.scheduled,
            in: modelContext
        )
        reviewedCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ModelDefaults.ReviewStatus.reviewed,
            in: modelContext
        )
        masteredCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ModelDefaults.ReviewStatus.mastered,
            in: modelContext
        )
    }

    private func updateReviewStatus(_ mistake: MistakeRecord, to status: String) {
        guard mistake.reviewStatus != status else {
            return
        }

        do {
            mistake.reviewStatus = status
            MistakeRecordStore.updateMistakeTimestamp(mistake)
            try modelContext.save()
            try refreshMistakeDataThrowing()
            statusMessage = "已更新复习状态：\(ReviewStatusOption.title(for: status))。"
        } catch {
            statusMessage = "更新复习状态失败：\(error.localizedDescription)"
        }
    }

    private func prepareMistakePrompt(for mistake: MistakeRecord) {
        do {
            guard let template = try PromptTemplateStore.fetchTemplate(title: "错题手术", in: modelContext) else {
                statusMessage = "找不到内置“错题手术”模板。请检查 Prompt seed 是否成功。"
                return
            }

            activePromptSheet = MistakePromptSheet(
                template: template,
                values: mistake.promptValues
            )
        } catch {
            statusMessage = "加载错题 Prompt 失败：\(error.localizedDescription)"
        }
    }
}

private struct MistakePromptSheet: Identifiable {
    let id = UUID()
    let template: PromptTemplate
    let values: [String: String]
}

private enum MistakeSubjectFilter: String, CaseIterable, Identifiable {
    case all
    case math
    case chinese
    case english
    case physics
    case chemistry
    case biology
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .math:
            return "数学"
        case .chinese:
            return "语文"
        case .english:
            return "英语"
        case .physics:
            return "物理"
        case .chemistry:
            return "化学"
        case .biology:
            return "生物"
        case .other:
            return "其他"
        }
    }

    var subject: String? {
        self == .all ? nil : title
    }
}

private enum MistakeReviewFilter: String, CaseIterable, Identifiable {
    case all
    case new
    case scheduled
    case reviewed
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .new:
            return ReviewStatusOption.title(for: ModelDefaults.ReviewStatus.new)
        case .scheduled:
            return ReviewStatusOption.title(for: ModelDefaults.ReviewStatus.scheduled)
        case .reviewed:
            return ReviewStatusOption.title(for: ModelDefaults.ReviewStatus.reviewed)
        case .mastered:
            return ReviewStatusOption.title(for: ModelDefaults.ReviewStatus.mastered)
        }
    }

    var reviewStatus: String? {
        switch self {
        case .all:
            return nil
        case .new:
            return ModelDefaults.ReviewStatus.new
        case .scheduled:
            return ModelDefaults.ReviewStatus.scheduled
        case .reviewed:
            return ModelDefaults.ReviewStatus.reviewed
        case .mastered:
            return ModelDefaults.ReviewStatus.mastered
        }
    }
}

private struct MistakeSurgeryHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("错题手术")
                .font(.largeTitle.bold())

            Text("不是收藏错题，是拆出下次能赢的机制")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct MistakeSummaryCard: View {
    let totalMistakeCount: Int
    let scheduledCount: Int
    let reviewedCount: Int
    let masteredCount: Int

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        MistakeSurgeryCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("错题手术概览", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 10) {
                    MistakeSummaryValue(title: "总错题", value: totalMistakeCount)
                    MistakeSummaryValue(title: "待复习", value: scheduledCount, tint: .blue)
                    MistakeSummaryValue(title: "已复习", value: reviewedCount, tint: .green)
                    MistakeSummaryValue(title: "已掌握", value: masteredCount, tint: .purple)
                }
            }
        }
    }
}

private struct MistakeSummaryValue: View {
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

private struct MistakeFilterBar: View {
    @Binding var selectedSubjectFilter: MistakeSubjectFilter
    @Binding var selectedReviewFilter: MistakeReviewFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("筛选")
                .font(.headline)

            HStack(spacing: 10) {
                Menu {
                    ForEach(MistakeSubjectFilter.allCases) { filter in
                        Button {
                            selectedSubjectFilter = filter
                        } label: {
                            Label(filter.title, systemImage: selectedSubjectFilter == filter ? "checkmark" : "book.closed")
                        }
                    }
                } label: {
                    Label("科目：\(selectedSubjectFilter.title)", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach(MistakeReviewFilter.allCases) { filter in
                        Button {
                            selectedReviewFilter = filter
                        } label: {
                            Label(filter.title, systemImage: selectedReviewFilter == filter ? "checkmark" : "arrow.triangle.2.circlepath")
                        }
                    }
                } label: {
                    Label("状态：\(selectedReviewFilter.title)", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct MistakeRow: View {
    let mistake: MistakeRecord
    let onTap: () -> Void
    let onPreviewImage: (String) -> Void
    let onGeneratePrompt: () -> Void
    let onChangeStatus: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MistakeQuestionThumbnail(
                    path: mistake.questionImagePath,
                    onTap: onPreviewImage
                )

                Button {
                    onTap()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            MistakeTag(text: mistake.subject.isEmpty ? "未设科目" : mistake.subject)
                            MistakeTag(text: mistake.chapter.isEmpty ? "未设章节" : mistake.chapter)
                            Spacer(minLength: 8)
                            MistakeStatusBadge(status: mistake.reviewStatus)
                        }

                        Text(mistake.questionPreviewText)
                            .font(.headline)
                            .foregroundStyle(mistake.questionText.isEmpty ? .secondary : .primary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Label(MistakeTypeOption.title(for: mistake.mistakeType), systemImage: MistakeTypeOption.systemImage(for: mistake.mistakeType))
                            Text(mistake.source.isEmpty ? "来源未填写" : mistake.source)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                        Label("根因：\(mistake.rootCausePreviewText)", systemImage: "stethoscope")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Label("信号：\(mistake.questionSignalPreviewText)", systemImage: "scope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(mistake.shortUpdatedDateText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑错题手术")
            }

            HStack(spacing: 10) {
                Button {
                    onTap()
                } label: {
                    Label("继续手术", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach(ReviewStatusOption.all) { option in
                        Button {
                            onChangeStatus(option.status)
                        } label: {
                            Label(option.title, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    Label(ReviewStatusOption.title(for: mistake.reviewStatus), systemImage: "chevron.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("切换复习状态")
            }

            Button {
                onGeneratePrompt()
            } label: {
                Label("生成错题 Prompt", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MistakeQuestionThumbnail: View {
    let path: String
    let onTap: (String) -> Void

    var body: some View {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if let image = MistakeImageStore.loadImage(path: cleanPath) {
            Button {
                onTap(cleanPath)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                        }

                    Image(systemName: "magnifyingglass")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开题图预览")
        } else if !cleanPath.isEmpty {
            Button {
                onTap(cleanPath)
            } label: {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 58, height: 58)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("题图读取失败，打开说明")
        }
    }
}

private struct MistakeTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct MistakeStatusBadge: View {
    let status: String

    var body: some View {
        Label(ReviewStatusOption.title(for: status), systemImage: ReviewStatusOption.systemImage(for: status))
            .font(.caption.weight(.semibold))
            .foregroundStyle(ReviewStatusOption.tint(for: status))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

private struct MistakeSurgeryCard<Content: View>: View {
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

private extension MistakeRecord {
    var questionPreviewText: String {
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            return text
        }

        return questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未填写题面，先记录错因也可以。"
            : "已上传题图，题面文字未填写。"
    }

    var rootCausePreviewText: String {
        let text = rootCause.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "根因未填写" : text
    }

    var questionSignalPreviewText: String {
        let text = questionSignal.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "题目信号未填写" : text
    }

    var shortUpdatedDateText: String {
        "更新 \(Self.shortDateFormatter.string(from: updatedAt))"
    }

    var promptValues: [String: String] {
        [
            "subject": subject,
            "chapter": chapter,
            "question": questionPromptText,
            "mySolution": mySolution,
            "correctAnswer": correctSolution,
            "currentConfusion": currentConfusionText
        ]
    }

    private var questionPromptText: String {
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty else {
            return text
        }

        return questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "题目文字和题图都未提供，请先补充题面。"
            : "题目文字未填写。本错题有本地题图，请我在 AI 对话中同时上传图片，或先补充题面文字。"
    }

    private var currentConfusionText: String {
        let parts = [
            labeledPromptPart(title: "根因", value: rootCause),
            labeledPromptPart(title: "题目信号", value: questionSignal),
            labeledPromptPart(title: "正确模型", value: correctModel)
        ].compactMap { $0 }

        return parts.joined(separator: "\n")
    }

    private func labeledPromptPart(title: String, value: String) -> String? {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : "\(title)：\(text)"
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext

    context.insert(
        MistakeRecord(
            subject: "数学",
            chapter: "导数与函数零点",
            source: "周练第 17 题",
            questionText: "已知函数 f(x)=... 求参数 a 的取值范围。",
            mistakeType: ModelDefaults.MistakeType.model,
            rootCause: "看到参数范围题没有先判断是否适合分离参数，直接进入机械求导。",
            questionSignal: "参数取值范围 + 恒成立结构。",
            correctModel: "先判断分离参数、端点、极值、边界。",
            variantTask: "明天完成 3 道同型题。",
            reviewStatus: ModelDefaults.ReviewStatus.scheduled
        )
    )
    context.insert(
        MistakeRecord(
            subject: "英语",
            chapter: "阅读理解",
            source: "模考 C 篇",
            questionText: "",
            mistakeType: ModelDefaults.MistakeType.reading,
            rootCause: "定位句和选项之间发生偷换概念时没有回看原文。",
            questionSignal: "选项里出现绝对化表达。",
            reviewStatus: ModelDefaults.ReviewStatus.new
        )
    )

    return NavigationStack {
        MistakeSurgeryView()
    }
    .modelContainer(container)
}
