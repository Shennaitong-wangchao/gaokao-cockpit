import SwiftData
import SwiftUI
import UIKit

struct MistakeSurgeryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = MistakeSurgeryModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                MistakeSurgeryHeaderView()

                MistakeSummaryCard(
                    totalMistakeCount: model.totalMistakeCount,
                    scheduledCount: model.scheduledCount,
                    reviewedCount: model.reviewedCount,
                    masteredCount: model.masteredCount
                )

                MistakeFilterBar(
                    selectedSubjectFilter: $model.selectedSubjectFilter,
                    selectedReviewFilter: $model.selectedReviewFilter
                )

                if model.isLoading {
                    ProgressView("正在加载错题手术")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else if model.mistakes.isEmpty {
                    ContentUnavailableView {
                        Label("还没有错题", systemImage: "cross.case")
                    } description: {
                        Text("下一次做错题时，先拍题图，再拆错因。")
                    } actions: {
                        Button {
                            model.activeEditor = .add
                        } label: {
                            Label("新增错题手术", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(model.mistakes, id: \.id) { mistake in
                            MistakeRow(
                                mistake: mistake,
                                onTap: {
                                    model.activeEditor = .edit(mistake)
                                },
                                onPreviewImage: { path in
                                    model.activeImagePreview = MistakeImagePreviewItem(path: path)
                                },
                                onGeneratePrompt: {
                                    model.prepareMistakePrompt(in: modelContext, for: mistake)
                                },
                                onChangeStatus: { status in
                                    model.updateReviewStatus(in: modelContext, mistake: mistake, to: status)
                                }
                            )
                        }
                    }
                }

                Button {
                    model.activeEditor = .add
                } label: {
                    Label("新增错题手术", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let statusMessage = model.statusMessage {
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
            model.loadMistakes(in: modelContext)
        }
        .onAppear {
            if !model.isLoading {
                model.refreshMistakeData(in: modelContext)
            }
        }
        .onChange(of: model.selectedSubjectFilter) {
            model.refreshMistakeData(in: modelContext)
        }
        .onChange(of: model.selectedReviewFilter) {
            model.refreshMistakeData(in: modelContext)
        }
        .refreshable {
            model.refreshMistakeData(in: modelContext)
        }
        .sheet(item: $model.activeEditor) { editor in
            MistakeEditorView(mode: editor) { message in
                model.refreshMistakeData(in: modelContext)
                model.statusMessage = message
            }
        }
        .sheet(item: $model.activePromptSheet) { promptSheet in
            PromptTemplateDetailView(
                template: promptSheet.template,
                initialValues: promptSheet.values
            ) { message in
                model.statusMessage = message
            }
        }
        .sheet(item: $model.activeImagePreview) { item in
            MistakeImagePreviewView(path: item.path)
        }
    }
}

struct MistakePromptSheet: Identifiable {
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
