import Foundation

enum StudyTaskStatus: String, CaseIterable, Identifiable {
    case pending
    case inProgress
    case done
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending:
            return "未开始"
        case .inProgress:
            return "进行中"
        case .done:
            return "已完成"
        case .skipped:
            return "已跳过"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> StudyTaskStatus {
        switch normalizedModelValue(raw) {
        case "pending", "未开始", "待做":
            return .pending
        case "inprogress", "进行中":
            return .inProgress
        case "done", "已完成", "完成":
            return .done
        case "skipped", "已跳过", "跳过":
            return .skipped
        default:
            return .pending
        }
    }
}

enum StudyTaskCategory: String, CaseIterable, Identifiable {
    case exercise
    case preview
    case review
    case recite
    case organize
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .exercise:
            return "做题"
        case .preview:
            return "预习"
        case .review:
            return "复盘"
        case .recite:
            return "背诵"
        case .organize:
            return "整理"
        case .other:
            return "其他"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> StudyTaskCategory {
        switch normalizedModelValue(raw) {
        case "exercise", "做题":
            return .exercise
        case "preview", "预习":
            return .preview
        case "review", "复盘":
            return .review
        case "recite", "背诵":
            return .recite
        case "organize", "整理":
            return .organize
        case "other", "其他":
            return .other
        default:
            return .other
        }
    }
}

enum MistakeType: String, CaseIterable, Identifiable {
    case concept
    case method
    case calculation
    case reading
    case model
    case expression
    case time
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concept:
            return "概念"
        case .method:
            return "方法"
        case .calculation:
            return "计算"
        case .reading:
            return "审题"
        case .model:
            return "模型"
        case .expression:
            return "表达"
        case .time:
            return "时间"
        case .other:
            return "其他"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> MistakeType {
        switch normalizedModelValue(raw) {
        case "concept", "概念":
            return .concept
        case "method", "方法":
            return .method
        case "calculation", "计算":
            return .calculation
        case "reading", "审题":
            return .reading
        case "model", "模型":
            return .model
        case "expression", "表达":
            return .expression
        case "time", "时间":
            return .time
        case "other", "其他":
            return .other
        default:
            return .other
        }
    }
}

enum ReviewStatus: String, CaseIterable, Identifiable {
    case new
    case scheduled
    case reviewed
    case mastered

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new:
            return "新错题"
        case .scheduled:
            return "待复习"
        case .reviewed:
            return "已复习"
        case .mastered:
            return "已掌握"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> ReviewStatus {
        switch normalizedModelValue(raw) {
        case "new", "新错题":
            return .new
        case "scheduled", "待复习":
            return .scheduled
        case "reviewed", "已复习":
            return .reviewed
        case "mastered", "已掌握":
            return .mastered
        default:
            return .new
        }
    }
}

enum PromptCategory: String, CaseIterable, Identifiable {
    case all
    case mistake
    case preview
    case organize
    case variant
    case diagnosis
    case review
    case selfTest
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "全部"
        case .mistake:
            return "错题"
        case .preview:
            return "预习"
        case .organize:
            return "整理"
        case .variant:
            return "变式"
        case .diagnosis:
            return "诊断"
        case .review:
            return "复盘"
        case .selfTest:
            return "自测"
        case .other:
            return "其他"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> PromptCategory {
        switch normalizedModelValue(raw) {
        case "all", "全部":
            return .all
        case "mistake", "错题":
            return .mistake
        case "preview", "预习":
            return .preview
        case "organize", "整理":
            return .organize
        case "variant", "变式":
            return .variant
        case "diagnosis", "诊断":
            return .diagnosis
        case "review", "复盘":
            return .review
        case "selftest", "self_test", "自测":
            return .selfTest
        case "other", "其他":
            return .other
        default:
            return .other
        }
    }
}

enum LearningSubject: String, CaseIterable, Identifiable {
    case math
    case chinese
    case english
    case physics
    case chemistry
    case biology
    case politics
    case history
    case geography
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
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
        case .politics:
            return "政治"
        case .history:
            return "历史"
        case .geography:
            return "地理"
        case .other:
            return "其他"
        }
    }

    // Subjects keep the Chinese display string in storage to match current user-facing habits.
    var storageValue: String {
        displayName
    }

    static func from(_ raw: String) -> LearningSubject {
        switch normalizedModelValue(raw) {
        case "math", "数学":
            return .math
        case "chinese", "语文":
            return .chinese
        case "english", "英语":
            return .english
        case "physics", "物理":
            return .physics
        case "chemistry", "化学":
            return .chemistry
        case "biology", "生物":
            return .biology
        case "politics", "政治":
            return .politics
        case "history", "历史":
            return .history
        case "geography", "地理":
            return .geography
        case "other", "其他":
            return .other
        default:
            return .other
        }
    }
}

enum ResourceStatus: String, CaseIterable, Identifiable {
    case unread
    case inProgress
    case done
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unread:
            return "未读"
        case .inProgress:
            return "进行中"
        case .done:
            return "已完成"
        case .archived:
            return "已归档"
        }
    }

    var storageValue: String {
        rawValue
    }

    static func from(_ raw: String) -> ResourceStatus {
        switch normalizedModelValue(raw) {
        case "unread", "未读":
            return .unread
        case "inprogress", "进行中":
            return .inProgress
        case "done", "已完成":
            return .done
        case "archived", "已归档":
            return .archived
        default:
            return .unread
        }
    }
}

private func normalizedModelValue(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}
