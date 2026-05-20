import SwiftData
import SwiftUI
import UIKit

struct MistakeSurgeryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var mistakes: [MistakeRecord] = []
    @State private var selectedSubjectFilter: LearningSubject?
    @State private var selectedReviewFilter: ReviewStatus?
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
                        Text("下一次做错题时，先拍题图，再拆错因。")
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
            subject: selectedSubjectFilter?.storageValue,
            reviewStatus: selectedReviewFilter?.storageValue,
            in: modelContext
        )
        totalMistakeCount = try MistakeRecordStore.countMistakes(in: modelContext)
        scheduledCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.scheduled.storageValue,
            in: modelContext
        )
        reviewedCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.reviewed.storageValue,
            in: modelContext
        )
        masteredCount = try MistakeRecordStore.countMistakes(
            reviewStatus: ReviewStatus.mastered.storageValue,
            in: modelContext
        )
    }

    private func updateReviewStatus(_ mistake: MistakeRecord, to status: ReviewStatus) {
        guard ReviewStatus.from(mistake.reviewStatus) != status else {
            return
        }

        do {
            mistake.reviewStatus = status.storageValue
            MistakeRecordStore.updateMistakeTimestamp(mistake)
            try modelContext.save()
            try refreshMistakeDataThrowing()
            statusMessage = "已更新复习状态：\(status.displayName)。"
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

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext

    context.insert(
        MistakeRecord(
            subject: LearningSubject.math.storageValue,
            chapter: "导数与函数零点",
            source: "周练第 17 题",
            questionText: "已知函数 f(x)=... 求参数 a 的取值范围。",
            mistakeType: MistakeType.model.storageValue,
            rootCause: "看到参数范围题没有先判断是否适合分离参数，直接进入机械求导。",
            questionSignal: "参数取值范围 + 恒成立结构。",
            correctModel: "先判断分离参数、端点、极值、边界。",
            variantTask: "明天完成 3 道同型题。",
            reviewStatus: ReviewStatus.scheduled.storageValue
        )
    )
    context.insert(
        MistakeRecord(
            subject: LearningSubject.english.storageValue,
            chapter: "阅读理解",
            source: "模考 C 篇",
            questionText: "",
            mistakeType: MistakeType.reading.storageValue,
            rootCause: "定位句和选项之间发生偷换概念时没有回看原文。",
            questionSignal: "选项里出现绝对化表达。",
            reviewStatus: ReviewStatus.new.storageValue
        )
    )

    return NavigationStack {
        MistakeSurgeryView()
    }
    .modelContainer(container)
}
