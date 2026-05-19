import SwiftData
import SwiftUI
import UIKit

struct PromptTemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let template: PromptTemplate
    let onCopied: (String) -> Void

    @State private var values: [String: String]
    @State private var generatedPrompt: String
    @State private var statusMessage: String?

    init(
        template: PromptTemplate,
        initialValues: [String: String] = [:],
        onCopied: @escaping (String) -> Void = { _ in }
    ) {
        self.template = template
        self.onCopied = onCopied

        let cleanValues = Self.normalizedValues(initialValues)
        _values = State(initialValue: cleanValues)
        _generatedPrompt = State(initialValue: PromptRenderer.render(templateText: template.templateText, values: cleanValues))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(template.title)
                                .font(.title3.bold())
                                .lineLimit(2)

                            Spacer(minLength: 8)

                            Text(template.category.isEmpty ? "未分类" : template.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(template.templateDescription.isEmpty ? "没有模板说明。" : template.templateDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                if variables.isEmpty {
                    Section("变量") {
                        ContentUnavailableView {
                            Label("这个模板没有变量", systemImage: "text.cursor")
                        } description: {
                            Text("可以直接生成并复制。")
                        }
                    }
                } else {
                    Section("变量") {
                        ForEach(variables, id: \.self) { variable in
                            PromptVariableInput(
                                variable: variable,
                                value: binding(for: variable)
                            )
                        }
                    }
                }

                Section {
                    Button {
                        generatePrompt()
                    } label: {
                        Label("生成 Prompt", systemImage: "wand.and.stars")
                    }

                    Button {
                        copyPrompt()
                    } label: {
                        Label("复制到剪贴板", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        clearValues()
                    } label: {
                        Label("清空变量", systemImage: "xmark.circle")
                    }
                    .disabled(values.values.allSatisfy { clean($0).isEmpty })
                }

                Section("Prompt 预览") {
                    Text(generatedPrompt)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(statusMessage.hasPrefix("已复制") ? Color.secondary : Color.red)
                    }
                }
            }
            .navigationTitle(template.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var variables: [String] {
        Self.parseVariables(template.variablesText)
    }

    private func binding(for variable: String) -> Binding<String> {
        Binding(
            get: { values[variable, default: ""] },
            set: { values[variable] = $0 }
        )
    }

    private func generatePrompt() {
        generatedPrompt = PromptRenderer.render(templateText: template.templateText, values: values)
        statusMessage = nil
    }

    private func copyPrompt() {
        let prompt = PromptRenderer.render(templateText: template.templateText, values: values)
        generatedPrompt = prompt
        UIPasteboard.general.string = prompt

        do {
            try PromptTemplateStore.incrementUsageCount(template, in: modelContext)
            let message = "已复制，可以粘贴到 AI 工具了。"
            statusMessage = message
            onCopied(message)
        } catch {
            statusMessage = "已复制，但更新使用次数失败：\(error.localizedDescription)"
        }
    }

    private func clearValues() {
        values = variables.reduce(into: [String: String]()) { result, variable in
            result[variable] = ""
        }
        generatedPrompt = PromptRenderer.render(templateText: template.templateText, values: values)
        statusMessage = nil
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseVariables(_ variablesText: String) -> [String] {
        var seenVariables = Set<String>()
        var parsedVariables: [String] = []

        for rawValue in variablesText.split(whereSeparator: { $0 == "," || $0.isNewline }) {
            let variable = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !variable.isEmpty, !seenVariables.contains(variable) else {
                continue
            }

            seenVariables.insert(variable)
            parsedVariables.append(variable)
        }

        return parsedVariables
    }

    private static func normalizedValues(_ values: [String: String]) -> [String: String] {
        values.reduce(into: [String: String]()) { result, pair in
            let key = pair.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                return
            }

            result[key] = pair.value
        }
    }
}

private struct PromptVariableInput: View {
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

#Preview {
    let container = try! AppModelContainerFactory.make(inMemory: true)
    let context = container.mainContext
    try! PromptTemplateSeeder.seedIfNeeded(in: context)
    let template = try! PromptTemplateStore.fetchTemplate(title: "错题手术", in: context)!

    return PromptTemplateDetailView(template: template)
        .modelContainer(container)
}
