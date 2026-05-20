import SwiftUI

struct PromptVariableInput: View {
    let variable: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(variableTitle)
                .font(.subheadline.weight(.semibold))

            if isLongVariable {
                TextEditor(text: $value)
                    .frame(minHeight: 92)
                    .accessibilityLabel(variableTitle)
            } else {
                TextField(variablePlaceholder, text: $value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel(variableTitle)
            }
        }
        .padding(.vertical, 4)
    }

    private var variableTitle: String {
        Self.variableTitles[variable] ?? variable
    }

    private var variablePlaceholder: String {
        Self.variablePlaceholders[variable] ?? "填写 \(variable)"
    }

    private var isLongVariable: Bool {
        Self.longVariables.contains(variable)
    }

    private static let longVariables: Set<String> = [
        "question",
        "mySolution",
        "correctAnswer",
        "currentConfusion",
        "rawNotes",
        "unclearPoints",
        "originalQuestion",
        "mistakeRootCause",
        "correctModel",
        "completedWork",
        "mistakesSummary",
        "completedTasks",
        "unfinishedTasks",
        "focusSummary",
        "mistakeSummary",
        "subjectBreakdown",
        "mistakeTypeBreakdown",
        "keyDailyProblems",
        "imageContent"
    ]

    private static let variableTitles: [String: String] = [
        "subject": "科目",
        "chapter": "章节/专题",
        "question": "题目",
        "mySolution": "我的原解法",
        "correctAnswer": "参考答案/正确解法",
        "currentConfusion": "当前困惑",
        "textbookSection": "教材章节",
        "examGoal": "考试目标",
        "knownBase": "已有基础",
        "lessonTopic": "课程主题",
        "rawNotes": "原始笔记",
        "unclearPoints": "不懂的点",
        "originalQuestion": "原题",
        "mistakeRootCause": "错题根因",
        "correctModel": "正确模型",
        "difficulty": "目标难度",
        "unitName": "单元/专题",
        "completedWork": "已完成内容",
        "mistakesSummary": "错题摘要",
        "selfRating": "我的自评",
        "date": "日期",
        "completedTasks": "完成任务",
        "unfinishedTasks": "未完成任务",
        "focusSummary": "专注摘要",
        "mistakeSummary": "错题摘要",
        "stateScoreEnd": "晚间状态评分",
        "weekRange": "周范围",
        "totalStudyMinutes": "总学习分钟",
        "subjectBreakdown": "科目分布",
        "completedTaskCount": "完成任务数",
        "mistakeTypeBreakdown": "错题类型分布",
        "keyDailyProblems": "每日关键问题摘要",
        "imageContent": "图片内容说明",
        "testGoal": "自测目标",
        "currentLevel": "当前掌握程度"
    ]

    private static let variablePlaceholders: [String: String] = [
        "subject": "例如：数学",
        "chapter": "例如：导数与函数零点",
        "difficulty": "例如：中等偏难",
        "date": "例如：2026-05-19",
        "stateScoreEnd": "例如：6/10",
        "selfRating": "例如：基础会，综合题不稳",
        "testGoal": "例如：检查我是否真的懂题目信号",
        "currentLevel": "例如：刚学完，还不熟"
    ]
}
