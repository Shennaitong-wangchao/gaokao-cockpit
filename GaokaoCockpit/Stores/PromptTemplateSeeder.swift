import Foundation
import SwiftData

enum PromptTemplateSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        var descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { template in
                template.isBuiltIn
            }
        )
        descriptor.fetchLimit = 1

        guard try context.fetch(descriptor).isEmpty else {
            return
        }

        for seed in builtInTemplates {
            context.insert(
                PromptTemplate(
                    title: seed.title,
                    category: seed.category,
                    templateDescription: seed.templateDescription,
                    templateText: seed.templateText,
                    variablesText: seed.variablesText,
                    isBuiltIn: true
                )
            )
        }

        try context.save()
    }
}

private struct PromptTemplateSeed {
    let title: String
    let category: String
    let templateDescription: String
    let templateText: String
    let variablesText: String
}

private let builtInTemplates: [PromptTemplateSeed] = [
    PromptTemplateSeed(
        title: "错题手术",
        category: "错题",
        templateDescription: "把一道错题拆成错因、根因、信号、模型和变式任务。",
        templateText: """
        你是我的高考错题外科医生，不要只给答案。请帮我对下面这道题做“错题手术”。

        科目：{{subject}}
        章节/专题：{{chapter}}
        题目：{{question}}
        我的原解法：{{mySolution}}
        参考答案/正确解法：{{correctAnswer}}
        我现在的困惑：{{currentConfusion}}

        请按以下步骤分析：
        1. 先判断我错在哪里，不要泛泛说“粗心”。
        2. 找出真正根因：概念、模型、审题、计算、表达、时间分配，或其他。
        3. 指出题目中本应触发正确思路的关键信号。
        4. 给出正确模型或解题框架。
        5. 用高考学生能理解的方式解释关键步骤。
        6. 设计 1 个同型变式任务，不要直接给完整答案。
        7. 给我一句下次遇到同类题时要提醒自己的话。

        输出格式：
        【错误位置】
        【真正根因】
        【题目信号】
        【正确模型】
        【关键步骤解释】
        【同型变式任务】
        【下次提醒】
        【建议回填到错题记录的字段】
        """,
        variablesText: "subject\nchapter\nquestion\nmySolution\ncorrectAnswer\ncurrentConfusion"
    ),
    PromptTemplateSeed(
        title: "教材预习",
        category: "预习",
        templateDescription: "学习新章节前建立预习框架和问题清单。",
        templateText: """
        你是我的高考教材预习教练。请帮我预习下面这个章节，但不要把它讲成百科全书。

        科目：{{subject}}
        教材章节：{{textbookSection}}
        我的目标：{{examGoal}}
        我已有的基础：{{knownBase}}

        请完成：
        1. 这个章节在高考中的位置和价值。
        2. 我预习时必须抓住的 3 到 5 个核心问题。
        3. 容易混淆或误解的概念。
        4. 推荐的预习顺序。
        5. 读教材时要主动标记的题目信号。
        6. 预习后我应该能完成的最小输出。

        输出格式：
        【章节价值】
        【核心问题】
        【易混点】
        【预习顺序】
        【题目信号】
        【最小输出】
        【预习后自测问题】
        """,
        variablesText: "subject\ntextbookSection\nexamGoal\nknownBase"
    ),
    PromptTemplateSeed(
        title: "课后整理",
        category: "整理",
        templateDescription: "把课后内容整理成可复习、可做题、可追问的结构。",
        templateText: """
        你是我的高考课后整理教练。请帮我把下面的课后内容整理成可复习、可做题、可追问的结构。

        科目：{{subject}}
        主题：{{lessonTopic}}
        原始笔记：{{rawNotes}}
        不懂的点：{{unclearPoints}}

        请完成：
        1. 把内容整理成清晰层级。
        2. 标出本节最重要的概念、公式、模型或方法。
        3. 标出做题时会出现的题目信号。
        4. 标出我目前可能没有真正掌握的地方。
        5. 给出 3 个课后自测问题。
        6. 给出一个 20 分钟复习任务。

        输出格式：
        【整理后的笔记】
        【核心概念/模型】
        【题目信号】
        【掌握风险】
        【自测问题】
        【20 分钟复习任务】
        """,
        variablesText: "subject\nlessonTopic\nrawNotes\nunclearPoints"
    ),
    PromptTemplateSeed(
        title: "同型变式",
        category: "变式",
        templateDescription: "围绕同一解题模型设计变式训练。",
        templateText: """
        你是我的高考同型变式训练教练。请基于下面这道错题，为我设计同型变式训练。

        科目：{{subject}}
        原题：{{originalQuestion}}
        我的错因：{{mistakeRootCause}}
        正确模型：{{correctModel}}
        目标难度：{{difficulty}}

        请生成 3 道同型变式题：
        1. 第 1 道保持核心模型不变，只换表述。
        2. 第 2 道改变条件呈现方式，训练识别题目信号。
        3. 第 3 道提高一点综合度，接近高考压轴或综合题思维。

        每道题请先只给题目和提示，不要直接给完整答案。

        输出格式：
        【变式 1：模型不变】
        【变式 2：信号变化】
        【变式 3：综合提升】
        【每题提示】
        【完成后检查标准】
        【我做完后应该回传给你的内容】
        """,
        variablesText: "subject\noriginalQuestion\nmistakeRootCause\ncorrectModel\ndifficulty"
    ),
    PromptTemplateSeed(
        title: "单元诊断",
        category: "诊断",
        templateDescription: "完成章节或专题后诊断薄弱点和训练方向。",
        templateText: """
        你是我的高考单元诊断教练。请根据我的学习记录，诊断这个单元目前的问题。

        科目：{{subject}}
        单元/专题：{{unitName}}
        已完成内容：{{completedWork}}
        错题摘要：{{mistakesSummary}}
        我的自评：{{selfRating}}

        请分析：
        1. 我已经掌握的部分。
        2. 我看似会了但可能不稳的部分。
        3. 错题暴露出的知识漏洞和模型漏洞。
        4. 最需要优先补的 1 到 3 个点。
        5. 接下来 3 天的训练建议。
        6. 每天的最小保底任务。

        输出格式：
        【已掌握】
        【不稳定】
        【知识漏洞】
        【模型漏洞】
        【优先补强点】
        【3 天训练建议】
        【每日保底任务】
        """,
        variablesText: "subject\nunitName\ncompletedWork\nmistakesSummary\nselfRating"
    ),
    PromptTemplateSeed(
        title: "每日复盘",
        category: "复盘",
        templateDescription: "把今天的学习记录整理成明天可以继续执行的复盘。",
        templateText: """
        你是我的高考每日复盘教练。请帮我把今天的学习记录整理成明天可以继续执行的复盘。

        日期：{{date}}
        完成任务：{{completedTasks}}
        未完成任务：{{unfinishedTasks}}
        专注摘要：{{focusSummary}}
        错题摘要：{{mistakeSummary}}
        晚间状态评分：{{stateScoreEnd}}

        请完成：
        1. 总结今天真正完成的有效学习。
        2. 判断未完成任务的主要原因。
        3. 找出今天最大的一个问题。
        4. 选出最值得复盘的一条错题或一个卡点。
        5. 给出明天第一步，必须具体到能立刻开始。
        6. 如果我明天状态差，给出一个保底版本。

        输出格式：
        【今日有效学习】
        【未完成原因】
        【最大问题】
        【最佳复盘点】
        【明天第一步】
        【状态差保底版】
        """,
        variablesText: "date\ncompletedTasks\nunfinishedTasks\nfocusSummary\nmistakeSummary\nstateScoreEnd"
    ),
    PromptTemplateSeed(
        title: "周复盘",
        category: "复盘",
        templateDescription: "从一周数据中找到结构性问题和下周重点。",
        templateText: """
        你是我的高考周复盘教练。请根据本周记录，帮我找出结构性问题，并制定下周重点。

        周范围：{{weekRange}}
        总学习分钟：{{totalStudyMinutes}}
        科目分布：{{subjectBreakdown}}
        完成任务数：{{completedTaskCount}}
        错题类型分布：{{mistakeTypeBreakdown}}
        每日关键问题摘要：{{keyDailyProblems}}

        请分析：
        1. 本周投入是否匹配我的提分目标。
        2. 哪个科目或专题投入不足。
        3. 错题类型暴露了什么底层问题。
        4. 下周最多只能抓 3 个重点，应该是什么。
        5. 每个重点对应的可执行动作。
        6. 下周状态差时的保底策略。

        输出格式：
        【本周判断】
        【投入问题】
        【错题结构】
        【下周 3 个重点】
        【对应动作】
        【保底策略】
        【需要砍掉或推迟的事情】
        """,
        variablesText: "weekRange\ntotalStudyMinutes\nsubjectBreakdown\ncompletedTaskCount\nmistakeTypeBreakdown\nkeyDailyProblems"
    ),
    PromptTemplateSeed(
        title: "拍图自测",
        category: "自测",
        templateDescription: "基于图片内容描述进行追问式自测。",
        templateText: """
        你是我的高考拍图自测教练。请根据我上传或描述的图片内容，对我进行追问式自测。

        科目：{{subject}}
        图片内容说明：{{imageContent}}
        自测目标：{{testGoal}}
        当前掌握程度：{{currentLevel}}

        请按以下方式进行：
        1. 先概括图片中最重要的知识点或题目结构。
        2. 不要直接讲完整答案，先问我 3 个递进问题。
        3. 每个问题都要能暴露一个关键理解点。
        4. 如果我回答错，请指出错因并给一个更小的提示。
        5. 最后给我一个 10 分钟巩固任务。

        输出格式：
        【图片核心内容】
        【追问 1】
        【追问 2】
        【追问 3】
        【回答后的反馈规则】
        【10 分钟巩固任务】
        """,
        variablesText: "subject\nimageContent\ntestGoal\ncurrentLevel"
    )
]
