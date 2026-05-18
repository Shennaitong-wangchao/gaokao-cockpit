import SwiftData
import SwiftUI

struct FocusSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: StudyTask
    var onFinished: () -> Void = {}

    @State private var plannedMinutes: Int
    @State private var activeSession: FocusSession?
    @State private var finishSheet: FocusFinishSheetState?
    @State private var elapsedSeconds = 0
    @State private var distractionCount = 0
    @State private var isRunning = false
    @State private var hasStarted = false
    @State private var errorMessage: String?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(task: StudyTask, onFinished: @escaping () -> Void = {}) {
        self.task = task
        self.onFinished = onFinished
        _plannedMinutes = State(initialValue: Self.defaultPlannedMinutes(for: task))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                taskCard

                if hasStarted {
                    runningCard
                    controlCard
                } else {
                    setupCard
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("专注计时")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard isRunning else {
                return
            }

            elapsedSeconds += 1
        }
        .sheet(item: $finishSheet) { state in
            FocusSessionFinishSheet(
                task: task,
                session: state.session,
                elapsedSeconds: elapsedSeconds,
                distractionCount: distractionCount,
                onCancel: resumeAfterFinishCancel,
                onSaved: finishAndReturn
            )
            .interactiveDismissDisabled()
        }
    }

    private var taskCard: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("当前任务", systemImage: "target")
                    .font(.headline)

                Text(task.title.isEmpty ? "未命名任务" : task.title)
                    .font(.title2.weight(.bold))
                    .lineLimit(3)

                HStack(spacing: 8) {
                    FocusTag(text: task.subject.isEmpty ? "未设科目" : task.subject)
                    FocusTag(text: task.category.isEmpty ? "未分类" : task.category)
                    FocusTag(text: task.estimatedMinutes.map { "预计 \($0) 分钟" } ?? "预计未填写")
                }
            }
        }
    }

    private var setupCard: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("计划时长", systemImage: "clock")
                    .font(.headline)

                Picker("计划分钟", selection: $plannedMinutes) {
                    ForEach(plannedMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) 分钟").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("计划分钟")

                Button {
                    startFocus()
                } label: {
                    Label("开始专注", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var runningCard: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: 16) {
                Label(isRunning ? "专注中" : "已暂停", systemImage: isRunning ? "timer" : "pause.circle")
                    .font(.headline)

                Text(formattedElapsedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 10) {
                    FocusMetric(title: "计划", value: "\(plannedMinutes) 分钟")
                    FocusMetric(title: "分心", value: "\(distractionCount) 次", tint: distractionCount > 0 ? .orange : .primary)
                }

                Text(task.title.isEmpty ? "未命名任务" : task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var controlCard: some View {
        FocusCard {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        distractionCount += 1
                    } label: {
                        Label("分心 +1", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        isRunning.toggle()
                    } label: {
                        Label(isRunning ? "暂停" : "继续", systemImage: isRunning ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: .destructive) {
                    prepareFinish()
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var plannedMinuteOptions: [Int] {
        let baseOptions = [15, 25, 45, 60, 90]
        let taskEstimate = task.estimatedMinutes.flatMap { $0 > 0 ? $0 : nil }
        return Array(Set(baseOptions + [taskEstimate].compactMap { $0 })).sorted()
    }

    private var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startFocus() {
        errorMessage = nil

        do {
            let session = try FocusSessionStore.startSession(
                for: task,
                plannedMinutes: plannedMinutes,
                in: modelContext
            )
            activeSession = session
            elapsedSeconds = 0
            distractionCount = 0
            hasStarted = true
            isRunning = true
        } catch {
            errorMessage = "开始专注失败：\(error.localizedDescription)"
        }
    }

    private func prepareFinish() {
        guard let activeSession else {
            errorMessage = "结束失败：没有正在进行的专注记录。"
            return
        }

        isRunning = false
        finishSheet = FocusFinishSheetState(session: activeSession)
    }

    private func resumeAfterFinishCancel() {
        finishSheet = nil
        isRunning = true
    }

    private func finishAndReturn() {
        finishSheet = nil
        onFinished()
        dismiss()
    }

    private static func defaultPlannedMinutes(for task: StudyTask) -> Int {
        guard let estimatedMinutes = task.estimatedMinutes, estimatedMinutes > 0 else {
            return 25
        }

        return estimatedMinutes
    }
}

private struct FocusFinishSheetState: Identifiable {
    let session: FocusSession

    var id: UUID {
        session.id
    }
}

private struct FocusCard<Content: View>: View {
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

private struct FocusTag: View {
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

private struct FocusMetric: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    let task = StudyTask(
        dayKey: DateKey.todayKey(),
        title: "导数压轴题 6 道",
        subject: "数学",
        category: "做题",
        estimatedMinutes: 45
    )

    context.insert(task)

    return NavigationStack {
        FocusSessionView(task: task)
    }
    .modelContainer(container)
}
