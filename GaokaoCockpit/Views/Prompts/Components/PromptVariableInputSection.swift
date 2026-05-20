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
        Self.longVariableKeywords.contains(where: { variable.lowercased().contains($0) })
    }

    private static let longVariableKeywords: Set<String> = [
        "question", "solution", "notes", "summary", "text", "content",
        "answer", "confusion", "raw", "thinking", "analysis", "design",
        "writing", "translation", "calculation", "list", "progress",
        "breakdown", "problems", "items", "comparison", "description",
        "forces", "understanding", "guess", "materials", "idea"
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
        "currentLevel": "当前掌握程度",
        "mistakeList": "错题列表摘要",
        "timeRange": "时间范围",
        "lastMistakeReason": "上次错因",
        "commonRootCause": "共同错因",
        "myThinking": "我目前的思路",
        "stuckPoint": "卡住的地方",
        "myAnalysis": "我的分析",
        "questionSummary": "题目摘要",
        "myProgress": "我目前能做到的部分",
        "calculationErrors": "计算失误列表",
        "questionTypes": "失误题型",
        "timePressure": "时间压力",
        "imageDescription": "图像描述",
        "myUnderstanding": "我的理解",
        "myGuess": "我认为的模型",
        "myForces": "我画的受力",
        "confusion": "疑问",
        "experimentName": "实验名称",
        "myAnswer": "我的回答",
        "concepts": "概念组",
        "reactionDescription": "反应描述",
        "myEquation": "我写的方程式",
        "requirement": "题目要求",
        "confusingSteps": "不理解的步骤",
        "myCalculation": "我的计算过程",
        "concept": "概念",
        "boundaryQuestion": "边界问题",
        "chartDescription": "图表描述",
        "myDesign": "我的设计方案",
        "uncertainty": "不确定的地方",
        "completedContent": "已学完的内容",
        "unstablePoints": "不稳的知识点",
        "options": "选项",
        "correctAnswer": "正确答案",
        "articleTopic": "文章主题",
        "articleContent": "文章内容",
        "wrongQuestions": "做错的题",
        "sentence": "句子",
        "myTranslation": "我的翻译",
        "confusingPart": "看不懂的部分",
        "questionType": "题型",
        "passage": "原文段落",
        "wrongItems": "选错的题",
        "answerComparison": "答案对比",
        "essayTopic": "作文题目",
        "myWriting": "我的原文",
        "improvementGoal": "提升方向",
        "originalSummary": "原文摘要",
        "paragraphStarters": "续写段落开头句",
        "myIdea": "我的续写思路",
        "originalText": "原文",
        "uncertainWords": "不确定的字词",
        "poem": "诗歌",
        "articleType": "文章类型",
        "prompt": "作文题目/材料",
        "myThesis": "我的立意",
        "myMaterials": "我想到的素材",
        "examType": "考试类型",
        "score": "总分/得分",
        "scoreBreakdown": "各题得分情况",
        "stateScore": "当前状态评分",
        "pendingTasks": "当前待办任务",
        "availableTime": "剩余可用时间",
        "mainWorry": "最担心的事",
        "todaySummary": "今天完成情况",
        "biggestProblem": "今天最大问题",
        "tomorrowTime": "明天可用时间",
        "tomorrowExam": "明天的考试/测验"
    ]

    private static let variablePlaceholders: [String: String] = [
        "subject": "例如：数学",
        "chapter": "例如：导数与函数零点",
        "difficulty": "例如：中等偏难",
        "date": "例如：2026-05-19",
        "stateScoreEnd": "例如：6/10",
        "selfRating": "例如：基础会，综合题不稳",
        "testGoal": "例如：检查我是否真的懂题目信号",
        "currentLevel": "例如：刚学完，还不熟",
        "timeRange": "例如：最近一周",
        "experimentName": "例如：验证牛顿第二定律",
        "examType": "例如：月考/模考/周练",
        "score": "例如：120/150",
        "stateScore": "例如：4/10",
        "availableTime": "例如：3 小时",
        "questionType": "例如：完形填空",
        "articleType": "例如：散文/小说/论述类"
    ]
}
