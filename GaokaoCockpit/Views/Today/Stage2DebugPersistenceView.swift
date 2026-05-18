import SwiftData
import SwiftUI

struct Stage2DebugPersistenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dayPlans: [DayPlan]
    @Query private var studyTasks: [StudyTask]

    @State private var todayKey = DateKey.todayKey()
    @State private var todayDayPlanStatus = "未查询"
    @State private var todayTaskCount = 0
    @State private var todayCompletedTaskCount = 0
    @State private var builtInPromptTemplateCount = 0
    @State private var helperResultMessage = "尚未执行 helper 操作"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Stage 2 Debug / 本地持久化验证", systemImage: "wrench.and.screwdriver")
                .font(.headline)

            Label("Stage 2 Debug only - will be replaced by real Today Cockpit.", systemImage: "exclamationmark.triangle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 8) {
                Label("SwiftData 已接入本地 ModelContainer", systemImage: "externaldrive.connected.to.line.below")
                Label("todayKey：\(todayKey)", systemImage: "calendar.day.timeline.left")
                Label("今日 DayPlan：\(todayDayPlanStatus)", systemImage: "calendar")
                Label("今日任务数：\(todayTaskCount) / 已完成：\(todayCompletedTaskCount)", systemImage: "checklist")
                Label("内置 Prompt 模板数量（helper）：\(builtInPromptTemplateCount)", systemImage: "text.bubble")
                Label("总 DayPlan 数量：\(dayPlans.count)", systemImage: "tray.full")
                Label("总 StudyTask 数量：\(studyTasks.count)", systemImage: "list.bullet.rectangle")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    fetchOrCreateTodayDayPlan()
                } label: {
                    Label("Helper：获取或创建今日 DayPlan", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    createTestStudyTaskWithHelper()
                } label: {
                    Label("Helper：创建今日测试 StudyTask", systemImage: "plus.square.on.square")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)

                Button {
                    loadHelperSnapshot(markAsAction: true)
                } label: {
                    Label("刷新 helper 查询结果", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            .labelStyle(.titleAndIcon)

            Text("最近一次 helper 操作：\(helperResultMessage)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
        .onAppear {
            loadHelperSnapshot()
        }
    }

    private func fetchOrCreateTodayDayPlan() {
        do {
            let dayPlan = try DayPlanStore.fetchOrCreateToday(in: modelContext)
            DayPlanStore.updateDayPlanTimestamp(dayPlan)
            try modelContext.save()
            loadHelperSnapshot()
            helperResultMessage = "已获取或创建今日 DayPlan：\(dayPlan.dayKey)"
        } catch {
            helperResultMessage = "DayPlan helper 失败：\(error.localizedDescription)"
        }
    }

    private func createTestStudyTaskWithHelper() {
        do {
            let task = try StudyTaskStore.createTask(
                dayKey: DateKey.todayKey(),
                title: "Stage 2B Helper 测试任务",
                subject: "数学",
                category: "验证",
                estimatedMinutes: 25,
                in: modelContext
            )
            task.outputNote = "用于确认 StudyTask helper 可写入、读取、按 dayKey 统计。"
            try modelContext.save()
            loadHelperSnapshot()
            helperResultMessage = "已通过 helper 创建 StudyTask：\(task.title)"
        } catch {
            helperResultMessage = "StudyTask helper 失败：\(error.localizedDescription)"
        }
    }

    private func loadHelperSnapshot(markAsAction: Bool = false) {
        let key = DateKey.todayKey()
        todayKey = key

        do {
            todayTaskCount = try StudyTaskStore.countTasks(for: key, in: modelContext)
            todayCompletedTaskCount = try StudyTaskStore.countCompletedTasks(for: key, in: modelContext)
            builtInPromptTemplateCount = try PromptTemplateStore.countBuiltInTemplates(in: modelContext)

            if let dayPlan = try DayPlanStore.fetchDayPlan(for: key, in: modelContext) {
                todayDayPlanStatus = "已存在（updatedAt \(dayPlan.updatedAt.formatted(date: .omitted, time: .shortened))）"
            } else {
                todayDayPlanStatus = "尚未创建"
            }

            if markAsAction {
                helperResultMessage = "已刷新 helper 查询结果：\(key)"
            }
        } catch {
            helperResultMessage = "Helper 查询失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        Stage2DebugPersistenceView()
            .padding()
    }
    .modelContainer(try! AppModelContainerFactory.make(inMemory: true))
}
