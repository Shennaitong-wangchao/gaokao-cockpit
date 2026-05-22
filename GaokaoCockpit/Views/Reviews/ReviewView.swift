import SwiftData
import SwiftUI

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = ReviewModel()

    var body: some View {
        Group {
            switch model.loadState {
            case .loading:
                ProgressView("正在加载复盘")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                ContentUnavailableView {
                    Label("复盘加载失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重新加载") {
                        model.loadReviews(in: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ReviewHeaderView()

                        Picker("复盘类型", selection: $model.selectedMode) {
                            ForEach(ReviewMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("复盘类型")

                        switch model.selectedMode {
                        case .daily:
                            DailyReviewSection(
                                date: model.todayDate,
                                summary: model.dailySummary,
                                todayMistakes: model.todayMistakes,
                                completedSummary: $model.completedSummary,
                                unfinishedSummary: $model.unfinishedSummary,
                                biggestProblem: $model.biggestProblem,
                                bestMistakeId: $model.bestMistakeId,
                                stateScoreEnd: $model.stateScoreEnd,
                                tomorrowFirstAction: $model.tomorrowFirstAction,
                                onApplyQuickTemplate: {
                                    model.applyDailyQuickTemplate()
                                },
                                onSave: {
                                    model.saveDailyReview(in: modelContext)
                                },
                                onGeneratePrompt: {
                                    model.generateDailyPrompt(in: modelContext)
                                }
                            )

                        case .weekly:
                            WeeklyReviewSection(
                                weekStart: model.currentWeekStart,
                                weekEnd: model.currentWeekEnd,
                                summary: model.weeklySummary,
                                keyProblemsText: $model.keyProblemsText,
                                nextWeekFocusText: $model.nextWeekFocusText,
                                onSave: {
                                    model.saveWeeklyReview(in: modelContext)
                                },
                                onGeneratePrompt: {
                                    model.generateWeeklyPrompt(in: modelContext)
                                }
                            )
                        }

                        if let statusMessage = model.statusMessage {
                            Text(statusMessage)
                                .font(.footnote)
                                .foregroundStyle(statusMessage.contains("失败") ? Color.red : Color.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ReviewBackupEntryCard {
                            model.activeBackupSheet = ReviewBackupSheet()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    model.loadReviews(in: modelContext)
                }
            }
        }
        .navigationTitle("复盘")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.loadReviews(in: modelContext)
        }
        .sheet(item: $model.activePromptSheet) { sheet in
            PromptTemplateDetailView(
                template: sheet.template,
                initialValues: sheet.values
            ) { message in
                model.statusMessage = message
            }
        }
        .sheet(item: $model.activeBackupSheet) { _ in
            BackupExportView()
        }
    }
}

enum ReviewLoadState: Equatable {
    case loading
    case loaded
    case failed(String)
}

enum ReviewMode: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "每日复盘"
        case .weekly:
            return "周复盘"
        }
    }
}

struct ReviewPromptSheet: Identifiable {
    let id = UUID()
    let template: PromptTemplate
    let values: [String: String]
}

struct ReviewBackupSheet: Identifiable {
    let id = UUID()
}

#Preview {
    NavigationStack {
        ReviewView()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
