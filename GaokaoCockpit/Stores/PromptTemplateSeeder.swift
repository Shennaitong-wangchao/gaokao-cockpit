import Foundation
import SwiftData

// Built-in templates are upserted by title while preserving usageCount.
// User templates (isBuiltIn == false) are never overwritten.
enum PromptTemplateSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        try seedOrUpdateBuiltIns(in: context)
    }

    private static func seedOrUpdateBuiltIns(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<PromptTemplate>(
            predicate: #Predicate<PromptTemplate> { $0.isBuiltIn }
        )
        let existing = try context.fetch(descriptor)
        let existingByTitle = Dictionary(
            existing.map { ($0.title, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for seed in builtInTemplates {
            if let match = existingByTitle[seed.title] {
                match.category = seed.category
                match.templateDescription = seed.templateDescription
                match.templateText = seed.templateText
                match.variablesText = seed.variablesText
                match.updatedAt = .now
            } else {
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
        }

        try context.save()
    }
}

struct PromptTemplateSeed {
    let title: String
    let category: String
    let templateDescription: String
    let templateText: String
    let variablesText: String
}

// MARK: - Built-in Templates (48)

let builtInTemplates: [PromptTemplateSeed] = [

    // MARK: 错题类 (7)

    PromptTemplateSeed(
        title: "错题手术",
        category: "错题",
        templateDescription: "把一道错题拆成错因、根因、信号、模型和变式任务。",
        templateText: """
        你是我的高考错题外科医生，不要只给答案。请帮我对下面这道题做"错题手术"。

        科目：{{subject}}
        章节/专题：{{chapter}}
        题目：{{question}}
        我的原解法：{{mySolution}}
        参考答案/正确解法：{{correctAnswer}}
        我现在的困惑：{{currentConfusion}}

        请按以下步骤分析：
        1. 先判断我错在哪里，不要泛泛说"粗心"。
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
        【建议回填到 Gaokao Cockpit 的字段】
        """,
        variablesText: "subject\nchapter\nquestion\nmySolution\ncorrectAnswer\ncurrentConfusion"
    ),

    PromptTemplateSeed(
        title: "错因归类",
        category: "错题",
        templateDescription: "对多道错题进行错因分类，找出高频根因。",
        templateText: """
        你是我的高考错因分析教练。请帮我对下面这批错题做错因归类。

        科目：{{subject}}
        错题列表摘要：{{mistakeList}}
        时间范围：{{timeRange}}

        请按以下步骤分析：
        1. 把每道错题归入一个错因类型：概念、模型、审题、计算、表达、时间分配。
        2. 统计各类型出现频次。
        3. 找出出现最多的 1-2 个高频根因。
        4. 分析高频根因背后的底层问题。
        5. 给出针对高频根因的 3 天训练计划。
        6. 给出每天的最小保底任务。

        输出格式：
        【错因分类表】
        【频次统计】
        【高频根因】
        【底层问题】
        【3 天训练计划】
        【每日保底任务】
        【建议回填到 Gaokao Cockpit 的字段】
        """,
        variablesText: "subject\nmistakeList\ntimeRange"
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
        title: "二刷检测",
        category: "错题",
        templateDescription: "对已复习错题进行二刷检测，验证是否真正掌握。",
        templateText: """
        你是我的高考二刷检测教练。请帮我验证这道错题是否真正掌握。

        科目：{{subject}}
        原题：{{question}}
        上次错因：{{lastMistakeReason}}
        上次正确模型：{{correctModel}}
        这次我的解法：{{mySolution}}

        请按以下步骤检测：
        1. 判断我这次的解法是否正确。
        2. 判断我是否真正用了正确模型，还是碰巧做对。
        3. 如果做对了，追问一个变化条件，看我能否灵活应对。
        4. 如果做错了，指出这次错因和上次是否相同。
        5. 给出掌握程度判断：已掌握 / 不稳定 / 未掌握。
        6. 给出下一步建议。

        输出格式：
        【解法判断】
        【模型使用判断】
        【追问或错因分析】
        【掌握程度】
        【下一步建议】
        【建议回填到 Gaokao Cockpit 的字段】
        """,
        variablesText: "subject\nquestion\nlastMistakeReason\ncorrectModel\nmySolution"
    ),

    PromptTemplateSeed(
        title: "错题压缩成模型",
        category: "错题",
        templateDescription: "把多道同类错题压缩成一个可复用的解题模型。",
        templateText: """
        你是我的高考模型提炼教练。请帮我把下面这几道同类错题压缩成一个可复用的解题模型。

        科目：{{subject}}
        章节/专题：{{chapter}}
        错题列表：{{mistakeList}}
        共同错因：{{commonRootCause}}

        请按以下步骤分析：
        1. 找出这几道题的共同结构。
        2. 提炼出一个通用解题模型，用 3-5 步描述。
        3. 标出模型中最容易出错的步骤。
        4. 给出识别这类题的题目信号。
        5. 设计一道检验题，验证我是否掌握了这个模型。

        输出格式：
        【共同结构】
        【通用解题模型】
        【易错步骤】
        【题目信号】
        【检验题】
        【建议回填到 Gaokao Cockpit 的字段】
        """,
        variablesText: "subject\nchapter\nmistakeList\ncommonRootCause"
    ),

    PromptTemplateSeed(
        title: "只给提示不讲答案",
        category: "错题",
        templateDescription: "对一道题只给思路提示，不直接给答案，训练独立思考。",
        templateText: """
        你是我的高考思路提示教练。我现在卡在一道题上，请只给我提示，不要直接给答案。

        科目：{{subject}}
        题目：{{question}}
        我目前的思路：{{myThinking}}
        我卡在哪里：{{stuckPoint}}

        规则：
        1. 不要直接给出完整解法或最终答案。
        2. 先判断我目前的思路是否在正确方向上。
        3. 如果方向对，给一个让我继续推进的最小提示。
        4. 如果方向错，指出方向问题，但不要替我选择新方向。
        5. 如果我需要补充知识点，告诉我需要回顾什么，但不要替我推导。
        6. 最多给 3 层递进提示，每层比上一层更具体一点。

        输出格式：
        【方向判断】
        【提示第 1 层】
        【提示第 2 层（如果需要）】
        【提示第 3 层（如果需要）】
        【你需要回顾的知识点】
        """,
        variablesText: "subject\nquestion\nmyThinking\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "错题回填字段生成",
        category: "错题",
        templateDescription: "根据错题分析结果，生成可直接回填到 Gaokao Cockpit 的字段内容。",
        templateText: """
        你是我的高考错题记录助手。请根据下面的错题分析，帮我生成可以直接回填到 Gaokao Cockpit 错题记录的字段内容。

        科目：{{subject}}
        章节：{{chapter}}
        题目：{{question}}
        我的分析：{{myAnalysis}}

        请生成以下字段内容，每个字段控制在 1-2 句话：
        1. 错误类型（从以下选一个：概念/方法/计算/审题/模型/表达/时间/其他）
        2. 根因（一句话说清楚为什么错）
        3. 题目信号（什么条件应该触发正确思路）
        4. 正确模型（用什么框架解这类题）
        5. 变式任务（明天要做什么来巩固）

        输出格式：
        【错误类型】
        【根因】
        【题目信号】
        【正确模型】
        【变式任务】
        """,
        variablesText: "subject\nchapter\nquestion\nmyAnalysis"
    ),

    // MARK: 数学类 (10)

    PromptTemplateSeed(
        title: "数学概念预习",
        category: "预习",
        templateDescription: "数学新章节预习，建立概念框架和核心问题清单。",
        templateText: """
        你是我的高考数学预习教练。请帮我预习下面这个数学章节。

        章节：{{chapter}}
        我的目标：{{examGoal}}
        我已有的基础：{{knownBase}}

        请完成：
        1. 这个章节在高考数学中的考频和分值。
        2. 核心概念和定义，用一句话说清每个。
        3. 必须掌握的公式或定理，标出易错点。
        4. 这个章节最常见的 3 种题型。
        5. 预习时要重点标记的关键词和结构。
        6. 预习后的自测：3 道基础题（只给题目，不给答案）。

        输出格式：
        【考频与分值】
        【核心概念】
        【公式/定理与易错点】
        【常见题型】
        【关键词和结构】
        【自测题】
        """,
        variablesText: "chapter\nexamGoal\nknownBase"
    ),

    PromptTemplateSeed(
        title: "数学题型归纳",
        category: "整理",
        templateDescription: "对某个数学专题的题型进行归纳分类。",
        templateText: """
        你是我的高考数学题型归纳教练。请帮我归纳这个专题的常见题型。

        专题：{{chapter}}
        我做过的题目摘要：{{questionSummary}}
        我觉得难的地方：{{difficulty}}

        请完成：
        1. 列出这个专题在高考中的 4-6 种常见题型。
        2. 每种题型给出识别信号（看到什么条件就知道是这类题）。
        3. 每种题型给出解题入口（第一步做什么）。
        4. 标出哪些题型之间容易混淆。
        5. 给出一个快速判断题型的决策树。

        输出格式：
        【题型列表】
        【识别信号】
        【解题入口】
        【易混题型】
        【决策树】
        """,
        variablesText: "chapter\nquestionSummary\ndifficulty"
    ),

    PromptTemplateSeed(
        title: "函数题突破",
        category: "错题",
        templateDescription: "针对函数类题目的专项突破训练。",
        templateText: """
        你是我的高考数学函数教练。请帮我突破这道函数题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题属于函数的哪个子题型（定义域、值域、单调性、奇偶性、零点、图像变换等）。
        2. 指出我的解法中的问题。
        3. 给出正确的解题框架，标出关键步骤。
        4. 指出这道题的题目信号。
        5. 给出一道同型变式，只给题目和第一步提示。

        输出格式：
        【题型判断】
        【解法问题】
        【正确框架】
        【题目信号】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "三角函数题突破",
        category: "错题",
        templateDescription: "针对三角函数题的专项突破训练。",
        templateText: """
        你是我的高考数学三角函数教练。请帮我突破这道三角函数题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题需要用到哪些三角公式（和差化积、辅助角、二倍角等）。
        2. 指出我选择公式或变换方向的问题。
        3. 给出正确的变换路径，标出每步为什么这样选。
        4. 总结这类题的公式选择决策规则。
        5. 给出一道同型变式。

        输出格式：
        【公式判断】
        【变换问题】
        【正确路径】
        【决策规则】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "向量题突破",
        category: "错题",
        templateDescription: "针对向量题的专项突破训练。",
        templateText: """
        你是我的高考数学向量教练。请帮我突破这道向量题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题是坐标运算型还是几何意义型。
        2. 指出我的解法中坐标设置或几何关系的问题。
        3. 给出正确的解题路径。
        4. 标出向量题中常见的陷阱（方向、模、共线条件等）。
        5. 给出一道同型变式。

        输出格式：
        【题型判断】
        【解法问题】
        【正确路径】
        【常见陷阱】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "导数题突破",
        category: "错题",
        templateDescription: "针对导数题的专项突破训练。",
        templateText: """
        你是我的高考数学导数教练。请帮我突破这道导数题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题属于导数的哪个子题型（切线、单调性、极值、零点、不等式证明、参数范围等）。
        2. 指出我的解法中的关键失误。
        3. 给出正确的解题框架，特别是分类讨论的节点。
        4. 如果涉及构造函数，说明构造思路从哪里来。
        5. 给出一道同型变式。

        输出格式：
        【题型判断】
        【关键失误】
        【正确框架】
        【构造思路（如适用）】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "解析几何题突破",
        category: "错题",
        templateDescription: "针对解析几何题的专项突破训练。",
        templateText: """
        你是我的高考数学解析几何教练。请帮我突破这道解析几何题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题的核心操作（联立、设点、韦达定理、面积、弦长等）。
        2. 指出我的计算或设元策略的问题。
        3. 给出正确的解题路径，标出计算量最大的步骤如何简化。
        4. 总结这类题的计算检查点。
        5. 给出一道同型变式。

        输出格式：
        【核心操作】
        【策略问题】
        【正确路径】
        【计算检查点】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "数列题突破",
        category: "错题",
        templateDescription: "针对数列题的专项突破训练。",
        templateText: """
        你是我的高考数学数列教练。请帮我突破这道数列题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 判断这道题属于数列的哪个子题型（通项公式、求和、递推、放缩、不等式等）。
        2. 指出我的解法中的问题。
        3. 给出正确的解题路径。
        4. 如果涉及求和技巧，说明选择裂项/错位/分组的判断依据。
        5. 给出一道同型变式。

        输出格式：
        【题型判断】
        【解法问题】
        【正确路径】
        【技巧选择依据】
        【同型变式】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "数学压轴题分层提示",
        category: "错题",
        templateDescription: "对数学压轴题进行分层提示，逐步引导而非直接给答案。",
        templateText: """
        你是我的高考数学压轴题教练。这道题我做不出来，请分层给我提示。

        题目：{{question}}
        我目前能做到的部分：{{myProgress}}
        我卡在哪里：{{stuckPoint}}

        规则：
        1. 不要一次性给出完整解法。
        2. 先判断这道题的难度层次（基础设问 / 中档推导 / 压轴证明）。
        3. 针对我卡住的层次，给出第一层提示（方向性）。
        4. 如果我需要更多帮助，再给第二层提示（具体方法）。
        5. 最后给出这道题的得分策略（哪些步骤能拿步骤分）。

        输出格式：
        【难度层次判断】
        【第一层提示：方向】
        【第二层提示：方法】
        【第三层提示：关键计算（如果需要）】
        【得分策略】
        """,
        variablesText: "question\nmyProgress\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "数学计算失误复盘",
        category: "复盘",
        templateDescription: "专门复盘数学计算失误，找出失误模式。",
        templateText: """
        你是我的高考数学计算教练。请帮我复盘最近的计算失误。

        最近的计算失误列表：{{calculationErrors}}
        失误发生的题型：{{questionTypes}}
        考试/练习时间压力：{{timePressure}}

        请分析：
        1. 这些计算失误有没有共同模式（符号、进位、代入、化简等）。
        2. 失误是否集中在某个题型或某个计算步骤。
        3. 是否与时间压力或疲劳有关。
        4. 给出 3 个具体的计算习惯改进建议。
        5. 设计一个 5 分钟的每日计算训练。

        输出格式：
        【失误模式】
        【集中区域】
        【压力/疲劳因素】
        【改进建议】
        【每日计算训练】
        """,
        variablesText: "calculationErrors\nquestionTypes\ntimePressure"
    ),

    // MARK: 物理类 (6)

    PromptTemplateSeed(
        title: "物理过程分析",
        category: "错题",
        templateDescription: "对物理题进行过程分析，拆解物理情境。",
        templateText: """
        你是我的高考物理过程分析教练。请帮我拆解这道物理题的过程。

        题目：{{question}}
        我的分析：{{myAnalysis}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 把题目拆成几个物理过程（阶段）。
        2. 每个过程的起止条件是什么。
        3. 每个过程适用什么物理规律。
        4. 过程之间的衔接条件（速度、位移、能量等）。
        5. 指出我的分析中遗漏或错误的过程。
        6. 给出完整的过程分析框架。

        输出格式：
        【过程拆分】
        【起止条件】
        【适用规律】
        【衔接条件】
        【我的问题】
        【正确框架】
        """,
        variablesText: "question\nmyAnalysis\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "物理模型识别",
        category: "错题",
        templateDescription: "训练识别物理题中的经典模型。",
        templateText: """
        你是我的高考物理模型识别教练。请帮我识别这道题用了什么物理模型。

        题目：{{question}}
        我认为的模型：{{myGuess}}

        请完成：
        1. 判断这道题对应的经典物理模型（如匀变速直线运动、抛体、圆周、碰撞、电路等）。
        2. 指出题目中哪些关键词或条件指向这个模型。
        3. 如果我的判断有误，说明为什么容易误判。
        4. 给出这个模型的标准解题步骤。
        5. 列出 3 个常见的变体情境。

        输出格式：
        【正确模型】
        【关键信号】
        【误判原因（如适用）】
        【标准步骤】
        【变体情境】
        """,
        variablesText: "question\nmyGuess"
    ),

    PromptTemplateSeed(
        title: "受力分析教练",
        category: "错题",
        templateDescription: "专项训练受力分析，找出遗漏或多余的力。",
        templateText: """
        你是我的高考物理受力分析教练。请帮我检查这道题的受力分析。

        题目：{{question}}
        我画的受力：{{myForces}}
        我的疑问：{{confusion}}

        请按以下步骤检查：
        1. 逐一确认我列出的每个力是否存在（重力、弹力、摩擦力、电场力、安培力等）。
        2. 指出我遗漏的力。
        3. 指出我多画的力（不存在的力）。
        4. 检查力的方向是否正确。
        5. 给出正确的受力分析，并说明判断每个力的依据。
        6. 总结受力分析的检查清单。

        输出格式：
        【逐力检查】
        【遗漏的力】
        【多余的力】
        【方向修正】
        【正确受力分析】
        【检查清单】
        """,
        variablesText: "question\nmyForces\nconfusion"
    ),

    PromptTemplateSeed(
        title: "电磁学题目拆解",
        category: "错题",
        templateDescription: "拆解电磁学综合题，理清电场/磁场/力/运动关系。",
        templateText: """
        你是我的高考物理电磁学教练。请帮我拆解这道电磁学题。

        题目：{{question}}
        我的解法：{{mySolution}}
        我卡住的地方：{{stuckPoint}}

        请按以下步骤分析：
        1. 明确题目中的场（电场/磁场/复合场）和粒子运动状态。
        2. 分析粒子受力（电场力、洛伦兹力、重力等）。
        3. 判断运动类型（匀速、匀变速、圆周等）。
        4. 指出我的解法中的问题。
        5. 给出正确的解题路径。
        6. 标出这类题的常见陷阱。

        输出格式：
        【场与运动状态】
        【受力分析】
        【运动类型】
        【我的问题】
        【正确路径】
        【常见陷阱】
        """,
        variablesText: "question\nmySolution\nstuckPoint"
    ),

    PromptTemplateSeed(
        title: "物理实验题误差分析",
        category: "错题",
        templateDescription: "分析物理实验题中的误差来源和改进方法。",
        templateText: """
        你是我的高考物理实验教练。请帮我分析这道实验题的误差问题。

        实验名称：{{experimentName}}
        题目：{{question}}
        我的回答：{{myAnswer}}

        请分析：
        1. 这个实验的系统误差来源。
        2. 偶然误差的主要因素。
        3. 我的回答中对误差分析的问题。
        4. 正确的误差分析思路。
        5. 减小误差的改进措施。
        6. 高考实验题中误差分析的答题模板。

        输出格式：
        【系统误差】
        【偶然误差】
        【我的问题】
        【正确思路】
        【改进措施】
        【答题模板】
        """,
        variablesText: "experimentName\nquestion\nmyAnswer"
    ),

    PromptTemplateSeed(
        title: "物理图像题分析",
        category: "错题",
        templateDescription: "分析物理图像题，提取图像中的物理信息。",
        templateText: """
        你是我的高考物理图像题教练。请帮我分析这道图像题。

        题目：{{question}}
        图像描述：{{imageDescription}}
        我的理解：{{myUnderstanding}}

        请按以下步骤分析：
        1. 明确图像的横纵坐标物理量及单位。
        2. 从图像中提取关键信息（斜率、截距、面积、拐点等）的物理意义。
        3. 指出我的理解中的错误。
        4. 给出正确的图像解读。
        5. 总结这类图像题的读图步骤。

        输出格式：
        【坐标物理量】
        【关键信息与物理意义】
        【我的错误】
        【正确解读】
        【读图步骤】
        """,
        variablesText: "question\nimageDescription\nmyUnderstanding"
    ),

    // MARK: 化学类 (5)

    PromptTemplateSeed(
        title: "化学概念辨析",
        category: "错题",
        templateDescription: "辨析容易混淆的化学概念。",
        templateText: """
        你是我的高考化学概念教练。请帮我辨析下面这组容易混淆的概念。

        概念组：{{concepts}}
        我的理解：{{myUnderstanding}}
        我混淆的地方：{{confusion}}

        请完成：
        1. 分别用一句话定义每个概念。
        2. 列出它们的关键区别（用对比表格形式）。
        3. 指出我的理解中哪里有偏差。
        4. 给出 2 个高考真题中考查这组概念区别的例子。
        5. 给出一个快速判断的口诀或记忆方法。

        输出格式：
        【概念定义】
        【关键区别】
        【我的偏差】
        【真题例子】
        【记忆方法】
        """,
        variablesText: "concepts\nmyUnderstanding\nconfusion"
    ),

    PromptTemplateSeed(
        title: "化学方程式审查",
        category: "错题",
        templateDescription: "审查化学方程式和离子方程式的书写。",
        templateText: """
        你是我的高考化学方程式教练。请帮我审查下面的方程式。

        反应描述：{{reactionDescription}}
        我写的方程式：{{myEquation}}
        题目要求：{{requirement}}

        请检查：
        1. 化学式是否正确。
        2. 配平是否正确。
        3. 反应条件是否标注。
        4. 如果是离子方程式，拆分是否正确（强电解质拆、弱电解质/沉淀/气体不拆）。
        5. 如果有问题，给出正确写法并说明错误原因。
        6. 给出这类方程式书写的检查清单。

        输出格式：
        【化学式检查】
        【配平检查】
        【条件检查】
        【离子拆分检查（如适用）】
        【正确写法】
        【检查清单】
        """,
        variablesText: "reactionDescription\nmyEquation\nrequirement"
    ),

    PromptTemplateSeed(
        title: "化学实验题拆解",
        category: "错题",
        templateDescription: "拆解化学实验题的操作、现象和结论。",
        templateText: """
        你是我的高考化学实验教练。请帮我拆解这道实验题。

        题目：{{question}}
        我的回答：{{myAnswer}}
        我不确定的地方：{{uncertainty}}

        请按以下步骤分析：
        1. 明确实验目的。
        2. 拆解实验步骤和每步的作用。
        3. 预期现象和对应结论。
        4. 检查我的回答中的问题。
        5. 给出规范的实验题答题语言。
        6. 总结这类实验题的答题模板。

        输出格式：
        【实验目的】
        【步骤与作用】
        【现象与结论】
        【我的问题】
        【规范语言】
        【答题模板】
        """,
        variablesText: "question\nmyAnswer\nuncertainty"
    ),

    PromptTemplateSeed(
        title: "化学工艺流程题分析",
        category: "错题",
        templateDescription: "分析化学工艺流程题的思路和答题方法。",
        templateText: """
        你是我的高考化学工艺流程教练。请帮我分析这道工艺流程题。

        题目：{{question}}
        我的分析：{{myAnalysis}}
        我不理解的步骤：{{confusingSteps}}

        请完成：
        1. 梳理整个工艺流程的目的（从原料到产品）。
        2. 解释每个步骤的化学原理和工艺目的。
        3. 指出我不理解的步骤为什么这样设计。
        4. 标出常见的考点（调 pH、除杂、结晶、洗涤等）。
        5. 给出工艺流程题的通用分析框架。

        输出格式：
        【流程目的】
        【步骤解析】
        【疑难步骤解释】
        【常见考点】
        【分析框架】
        """,
        variablesText: "question\nmyAnalysis\nconfusingSteps"
    ),

    PromptTemplateSeed(
        title: "化学计算题步骤检查",
        category: "错题",
        templateDescription: "检查化学计算题的步骤和单位。",
        templateText: """
        你是我的高考化学计算教练。请帮我检查这道计算题。

        题目：{{question}}
        我的计算过程：{{myCalculation}}

        请检查：
        1. 化学方程式或关系式是否正确。
        2. 物质的量、质量、体积等换算是否正确。
        3. 单位是否统一和正确。
        4. 有效数字或精度是否符合要求。
        5. 如果有错误，指出错在哪一步并给出正确计算。
        6. 给出化学计算的检查步骤。

        输出格式：
        【关系式检查】
        【换算检查】
        【单位检查】
        【精度检查】
        【错误修正（如有）】
        【计算检查步骤】
        """,
        variablesText: "question\nmyCalculation"
    ),

    // MARK: 生物类 (5)

    PromptTemplateSeed(
        title: "生物概念边界辨析",
        category: "错题",
        templateDescription: "辨析生物概念的边界和适用条件。",
        templateText: """
        你是我的高考生物概念教练。请帮我辨析这个概念的边界。

        概念：{{concept}}
        我的理解：{{myUnderstanding}}
        我不确定的边界：{{boundaryQuestion}}

        请完成：
        1. 给出这个概念的准确定义。
        2. 明确它的适用范围和不适用的情况。
        3. 列出容易与之混淆的相关概念。
        4. 指出高考中常见的概念陷阱（绝对化表述、偷换概念等）。
        5. 给出 3 个判断题，训练概念边界识别。

        输出格式：
        【准确定义】
        【适用范围】
        【易混概念】
        【常见陷阱】
        【判断题训练】
        """,
        variablesText: "concept\nmyUnderstanding\nboundaryQuestion"
    ),

    PromptTemplateSeed(
        title: "生物图表题分析",
        category: "错题",
        templateDescription: "分析生物图表题的信息提取和推理。",
        templateText: """
        你是我的高考生物图表题教练。请帮我分析这道图表题。

        题目：{{question}}
        图表描述：{{chartDescription}}
        我的分析：{{myAnalysis}}

        请完成：
        1. 明确图表的类型和表达的生物学信息。
        2. 提取图表中的关键数据点和变化趋势。
        3. 将图表信息与生物学原理对应。
        4. 指出我的分析中的问题。
        5. 给出这类图表题的标准分析步骤。

        输出格式：
        【图表类型与信息】
        【关键数据】
        【对应原理】
        【我的问题】
        【标准分析步骤】
        """,
        variablesText: "question\nchartDescription\nmyAnalysis"
    ),

    PromptTemplateSeed(
        title: "生物实验设计题分析",
        category: "错题",
        templateDescription: "分析生物实验设计题的变量控制和方案设计。",
        templateText: """
        你是我的高考生物实验设计教练。请帮我分析这道实验设计题。

        题目：{{question}}
        我的设计方案：{{myDesign}}
        我不确定的地方：{{uncertainty}}

        请检查：
        1. 实验目的是否明确。
        2. 自变量、因变量、无关变量是否正确识别。
        3. 对照组设置是否合理。
        4. 实验步骤是否完整且可操作。
        5. 预期结果与结论是否对应。
        6. 给出实验设计题的答题框架。

        输出格式：
        【实验目的】
        【变量分析】
        【对照组检查】
        【步骤完整性】
        【结果与结论】
        【答题框架】
        """,
        variablesText: "question\nmyDesign\nuncertainty"
    ),

    PromptTemplateSeed(
        title: "细胞与分子专题复盘",
        category: "复盘",
        templateDescription: "必修一细胞与分子模块的专题复盘。",
        templateText: """
        你是我的高考生物复盘教练。请帮我复盘细胞与分子这个模块。

        我已学完的内容：{{completedContent}}
        我的错题摘要：{{mistakeSummary}}
        我觉得不稳的知识点：{{unstablePoints}}

        请完成：
        1. 梳理细胞与分子模块的核心知识框架。
        2. 标出高考高频考点。
        3. 根据我的错题，诊断薄弱环节。
        4. 给出针对性的复习计划（3 天）。
        5. 每天的最小保底任务。
        6. 给出 5 道自测题（只给题目）。

        输出格式：
        【知识框架】
        【高频考点】
        【薄弱环节】
        【3 天复习计划】
        【每日保底】
        【自测题】
        """,
        variablesText: "completedContent\nmistakeSummary\nunstablePoints"
    ),

    PromptTemplateSeed(
        title: "生物选择题陷阱识别",
        category: "自测",
        templateDescription: "训练识别生物选择题中的常见陷阱。",
        templateText: """
        你是我的高考生物选择题教练。请帮我分析这道选择题的陷阱。

        题目：{{question}}
        选项：{{options}}
        我选的答案：{{myAnswer}}
        正确答案：{{correctAnswer}}

        请分析：
        1. 正确答案为什么对。
        2. 我选的答案为什么错（具体错在哪个知识点或逻辑）。
        3. 这道题用了什么陷阱类型（绝对化、偷换概念、以偏概全、因果倒置等）。
        4. 以后遇到类似陷阱的识别信号。
        5. 给出 2 道同类陷阱的练习题。

        输出格式：
        【正确答案分析】
        【我的错误分析】
        【陷阱类型】
        【识别信号】
        【练习题】
        """,
        variablesText: "question\noptions\nmyAnswer\ncorrectAnswer"
    ),

    // MARK: 英语类 (5)

    PromptTemplateSeed(
        title: "英语阅读精读",
        category: "整理",
        templateDescription: "对英语阅读理解文章进行精读分析。",
        templateText: """
        你是我的高考英语阅读教练。请帮我精读这篇阅读理解。

        文章主题：{{articleTopic}}
        文章内容或关键段落：{{articleContent}}
        我做错的题：{{wrongQuestions}}

        请完成：
        1. 梳理文章结构（总分、对比、因果、时间线等）。
        2. 标出每段的主旨句。
        3. 分析我做错的题对应文章哪个位置。
        4. 指出题目选项中的干扰项设置手法。
        5. 给出这类文章的阅读策略。
        6. 标出值得积累的词汇和表达。

        输出格式：
        【文章结构】
        【段落主旨】
        【错题定位】
        【干扰项分析】
        【阅读策略】
        【词汇积累】
        """,
        variablesText: "articleTopic\narticleContent\nwrongQuestions"
    ),

    PromptTemplateSeed(
        title: "长难句拆解",
        category: "整理",
        templateDescription: "拆解英语长难句的结构。",
        templateText: """
        你是我的高考英语长难句教练。请帮我拆解这个长难句。

        句子：{{sentence}}
        我的理解：{{myTranslation}}
        我看不懂的部分：{{confusingPart}}

        请按以下步骤拆解：
        1. 找出主句的主谓宾。
        2. 标出所有从句及其类型（定语从句、状语从句、名词性从句等）。
        3. 标出修饰成分（介词短语、分词短语、插入语等）。
        4. 给出逐层拆解的结构图。
        5. 给出准确的中文翻译。
        6. 指出我的理解中的偏差。

        输出格式：
        【主句结构】
        【从句标注】
        【修饰成分】
        【结构拆解】
        【准确翻译】
        【我的偏差】
        """,
        variablesText: "sentence\nmyTranslation\nconfusingPart"
    ),

    PromptTemplateSeed(
        title: "完形七选五错因分析",
        category: "错题",
        templateDescription: "分析完形填空或七选五的错因。",
        templateText: """
        你是我的高考英语完形/七选五教练。请帮我分析这道题的错因。

        题型：{{questionType}}
        原文关键段落：{{passage}}
        我选错的题：{{wrongItems}}
        我选的答案和正确答案：{{answerComparison}}

        请分析：
        1. 正确答案的选择依据（上下文线索、逻辑关系、词汇复现等）。
        2. 我选错的原因（忽略线索、理解偏差、词汇不熟等）。
        3. 这道题的解题信号在哪里。
        4. 给出这类题的解题步骤。
        5. 给出需要积累的词汇或搭配。

        输出格式：
        【正确答案依据】
        【我的错因】
        【解题信号】
        【解题步骤】
        【词汇积累】
        """,
        variablesText: "questionType\npassage\nwrongItems\nanswerComparison"
    ),

    PromptTemplateSeed(
        title: "作文表达升级",
        category: "整理",
        templateDescription: "升级英语作文中的表达，从基础句型到高级句型。",
        templateText: """
        你是我的高考英语写作教练。请帮我升级下面这段作文的表达。

        作文题目：{{essayTopic}}
        我的原文：{{myWriting}}
        我想提升的方面：{{improvementGoal}}

        请完成：
        1. 指出原文中可以升级的基础表达。
        2. 给出对应的高级替换（词汇升级、句型升级）。
        3. 保持意思不变，给出升级后的完整段落。
        4. 标出升级后用到的高级句型（倒装、强调、非谓语等）。
        5. 给出 3 个可以在多种话题中复用的万能高级句型。

        输出格式：
        【可升级表达】
        【高级替换】
        【升级后段落】
        【高级句型标注】
        【万能句型】
        """,
        variablesText: "essayTopic\nmyWriting\nimprovementGoal"
    ),

    PromptTemplateSeed(
        title: "读后续写情节推进",
        category: "整理",
        templateDescription: "训练读后续写的情节推进和语言表达。",
        templateText: """
        你是我的高考英语读后续写教练。请帮我推进这篇续写的情节。

        原文摘要：{{originalSummary}}
        续写段落开头句：{{paragraphStarters}}
        我的续写思路：{{myIdea}}

        请完成：
        1. 分析原文的情感线和情节走向。
        2. 判断我的续写思路是否与原文衔接。
        3. 给出情节推进的 2-3 个可选方向。
        4. 对我选择的方向，给出关键情节点。
        5. 给出 5 个适合这个情境的高级表达（动作描写、心理描写、环境描写）。
        6. 不要替我写完整续写，只给框架和表达素材。

        输出格式：
        【原文分析】
        【衔接判断】
        【可选方向】
        【关键情节点】
        【高级表达素材】
        """,
        variablesText: "originalSummary\nparagraphStarters\nmyIdea"
    ),

    // MARK: 语文类 (4)

    PromptTemplateSeed(
        title: "文言文翻译拆解",
        category: "整理",
        templateDescription: "拆解文言文翻译的关键字词和句式。",
        templateText: """
        你是我的高考语文文言文教练。请帮我拆解这段文言文的翻译。

        原文：{{originalText}}
        我的翻译：{{myTranslation}}
        我不确定的字词：{{uncertainWords}}

        请按以下步骤分析：
        1. 逐句标出关键实词的含义（特别是一词多义、古今异义）。
        2. 标出关键虚词的用法。
        3. 标出特殊句式（判断句、被动句、省略句、倒装句等）。
        4. 指出我的翻译中的问题。
        5. 给出准确的翻译，标出得分点。
        6. 总结这段文言文中值得积累的字词。

        输出格式：
        【关键实词】
        【关键虚词】
        【特殊句式】
        【我的问题】
        【准确翻译与得分点】
        【字词积累】
        """,
        variablesText: "originalText\nmyTranslation\nuncertainWords"
    ),

    PromptTemplateSeed(
        title: "古诗鉴赏答题模板",
        category: "整理",
        templateDescription: "训练古诗鉴赏的答题结构和术语使用。",
        templateText: """
        你是我的高考语文古诗鉴赏教练。请帮我分析这道古诗鉴赏题。

        诗歌：{{poem}}
        题目：{{question}}
        我的回答：{{myAnswer}}

        请完成：
        1. 分析诗歌的主题和情感。
        2. 指出题目考查的角度（意象、手法、情感、语言等）。
        3. 检查我的回答是否覆盖了得分点。
        4. 指出我的回答中缺失或不准确的地方。
        5. 给出规范的答题结构（手法 + 分析 + 效果/情感）。
        6. 给出这类题的答题模板。

        输出格式：
        【主题与情感】
        【考查角度】
        【得分点检查】
        【我的问题】
        【规范答案】
        【答题模板】
        """,
        variablesText: "poem\nquestion\nmyAnswer"
    ),

    PromptTemplateSeed(
        title: "现代文阅读结构分析",
        category: "整理",
        templateDescription: "分析现代文阅读的文章结构和答题思路。",
        templateText: """
        你是我的高考语文现代文阅读教练。请帮我分析这篇现代文的结构。

        文章类型：{{articleType}}
        文章内容或关键段落：{{articleContent}}
        题目：{{question}}
        我的回答：{{myAnswer}}

        请完成：
        1. 分析文章的整体结构（线索、层次、手法）。
        2. 标出与题目相关的关键段落和句子。
        3. 分析题目的考查角度和答题方向。
        4. 检查我的回答是否完整、是否用了规范术语。
        5. 给出规范答案的结构。
        6. 总结这类题的答题步骤。

        输出格式：
        【文章结构】
        【关键段落】
        【考查角度】
        【我的问题】
        【规范答案结构】
        【答题步骤】
        """,
        variablesText: "articleType\narticleContent\nquestion\nmyAnswer"
    ),

    PromptTemplateSeed(
        title: "作文立意与素材整理",
        category: "整理",
        templateDescription: "训练作文审题立意和素材组织。",
        templateText: """
        你是我的高考语文作文教练。请帮我分析这道作文题的立意和素材。

        作文题目/材料：{{prompt}}
        我的立意：{{myThesis}}
        我想到的素材：{{myMaterials}}

        请完成：
        1. 分析题目/材料的核心关键词和限定条件。
        2. 给出 3 个可选立意方向，标出哪个最稳、哪个最有深度。
        3. 评价我的立意是否切题、是否有偏题风险。
        4. 对我选择的立意，给出论证结构建议。
        5. 评价我的素材是否匹配立意，补充 2-3 个更好的素材。
        6. 给出开头和结尾的写法建议。

        输出格式：
        【关键词与限定】
        【可选立意】
        【我的立意评价】
        【论证结构】
        【素材评价与补充】
        【开头结尾建议】
        """,
        variablesText: "prompt\nmyThesis\nmyMaterials"
    ),

    // MARK: 预习/整理/诊断/自测类 (5 - 保留原有)

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
    ),

    PromptTemplateSeed(
        title: "考后试卷复盘",
        category: "复盘",
        templateDescription: "考试后对整张试卷进行结构化复盘。",
        templateText: """
        你是我的高考考后复盘教练。请帮我对这次考试做结构化复盘。

        科目：{{subject}}
        考试类型：{{examType}}
        总分/得分：{{score}}
        各题得分情况：{{scoreBreakdown}}
        主要错题摘要：{{mistakeSummary}}

        请分析：
        1. 得分分布是否合理（基础题、中档题、压轴题各拿了多少）。
        2. 丢分主要集中在哪个知识模块或题型。
        3. 丢分原因分类（知识漏洞、模型不熟、计算失误、时间不够、审题不清）。
        4. 最值得优先补的 2-3 个提分点。
        5. 下次考试前的针对性训练计划。
        6. 考试策略调整建议（时间分配、做题顺序等）。

        输出格式：
        【得分分布分析】
        【丢分集中区】
        【丢分原因分类】
        【优先提分点】
        【训练计划】
        【策略调整】
        """,
        variablesText: "subject\nexamType\nscore\nscoreBreakdown\nmistakeSummary"
    ),

    // MARK: 复盘类 (6)

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
        title: "学习计划降载",
        category: "复盘",
        templateDescription: "当状态差或任务过多时，帮助降载学习计划。",
        templateText: """
        你是我的高考计划降载教练。我现在状态不好或任务太多，请帮我降载。

        当前状态评分：{{stateScore}}
        当前待办任务：{{pendingTasks}}
        今天剩余可用时间：{{availableTime}}
        我最担心的事：{{mainWorry}}

        请完成：
        1. 判断我当前的任务量是否超出状态承载能力。
        2. 从待办中选出今天必须完成的 1-2 个保底任务。
        3. 明确哪些任务可以推迟到明天或后天。
        4. 哪些任务可以直接砍掉或简化。
        5. 给出一个"状态差版"的今日计划。
        6. 给出恢复状态的建议（不是鸡汤，是具体动作）。

        输出格式：
        【承载判断】
        【保底任务】
        【可推迟】
        【可砍掉】
        【状态差版计划】
        【恢复建议】
        """,
        variablesText: "stateScore\npendingTasks\navailableTime\nmainWorry"
    ),

    PromptTemplateSeed(
        title: "明日第一步生成",
        category: "复盘",
        templateDescription: "根据今天的复盘结果，生成明天的具体第一步。",
        templateText: """
        你是我的高考明日规划教练。请根据今天的情况，帮我生成明天的第一步。

        今天完成情况：{{todaySummary}}
        今天最大问题：{{biggestProblem}}
        明天可用时间：{{tomorrowTime}}
        明天的考试/测验：{{tomorrowExam}}

        请生成：
        1. 明天起床后的第一个学习动作（必须具体到能立刻开始）。
        2. 这个动作预计需要多少分钟。
        3. 完成这个动作后的下一步。
        4. 如果明天状态差，第一步的简化版。
        5. 明天绝对不能忘的一件事。

        输出格式：
        【明天第一步】
        【预计时间】
        【下一步】
        【简化版】
        【绝对不能忘】
        """,
        variablesText: "todaySummary\nbiggestProblem\ntomorrowTime\ntomorrowExam"
    ),
]
