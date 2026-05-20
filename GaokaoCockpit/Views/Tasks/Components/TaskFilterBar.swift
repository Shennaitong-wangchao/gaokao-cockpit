import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case unfinished
    case done
    case skipped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .unfinished:
            return "未完成"
        case .done:
            return "已完成"
        case .skipped:
            return "跳过"
        }
    }

    var status: StudyTaskStatus? {
        switch self {
        case .all, .unfinished:
            return nil
        case .done:
            return .done
        case .skipped:
            return .skipped
        }
    }

    var emptyTitle: String {
        switch self {
        case .all:
            return "今天还没有任务"
        case .unfinished:
            return "没有未完成任务"
        case .done:
            return "还没有完成任务"
        case .skipped:
            return "没有跳过任务"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all:
            return "还没有任务。可以从 Today 生成，或在这里手动添加。"
        case .unfinished:
            return "当前筛选下没有未开始或进行中任务。"
        case .done:
            return "完成任务后会出现在这里。"
        case .skipped:
            return "手动标记跳过的任务会出现在这里。"
        }
    }

    var emptySystemImage: String {
        switch self {
        case .all:
            return "checklist"
        case .unfinished:
            return "circle"
        case .done:
            return "checkmark.circle"
        case .skipped:
            return "minus.circle"
        }
    }
}



struct TaskFilterBar: View {
    @Binding var selectedFilter: TaskFilter

    var body: some View {
        Picker("任务筛选", selection: $selectedFilter) {
            ForEach(TaskFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("任务筛选")
    }
}
