# 内置 Prompt 模板设计

第一版不接 AI API。Prompt 模板只负责生成完整提示词，并复制到剪贴板，由用户粘贴到自己使用的 AI 工具中。

## 更新机制

- 内置模板（isBuiltIn == true）采用 upsert 策略：每次启动时按 title 匹配，更新内容但保留 usageCount。
- 用户自定义模板（isBuiltIn == false）永远不会被覆盖或删除。
- 新版本新增的内置模板会自动插入。

## 日用增强功能

- **搜索**：支持按 title / description / category 搜索，大小写不敏感，中文正常匹配。
- **分类筛选**：支持按分类筛选，与搜索叠加。
- **常用模板**：按 usageCount 降序显示前 5 个使用过的模板。
- **最近使用**：基于 UserDefaults 轻量记录最近复制的 5 个模板，最多保留 20 条。
- **使用排序**：搜索结果和分类结果按 usageCount 降序排序，更容易找到常用模板。

注意：
- 最近使用不保存变量内容，不保存 AI 返回。
- 最近使用记录存储在 UserDefaults，不纳入备份导出。
- 如果模板被删除或重命名，最近使用列表仍显示快照，点击时会提示模板不存在。

## 模板设计原则

- 每个 Prompt 都服务学习闭环。
- 输入变量尽量少。
- 输出必须结构化，便于回填到错题、任务或复盘。
- AI 的角色是教练组，不是答案机。
- Prompt 要引导用户暴露思路，而不是只索要答案。

## 模板分类

| 分类 | storageValue | 说明 |
|------|-------------|------|
| 错题 | mistake | 错题分析、错因归类、变式训练 |
| 预习 | preview | 新章节预习框架 |
| 整理 | organize | 课后整理、题型归纳、表达升级 |
| 变式 | variant | 同型变式训练 |
| 诊断 | diagnosis | 单元诊断、薄弱点分析 |
| 复盘 | review | 每日/周复盘、考后复盘 |
| 自测 | selfTest | 追问式自测、陷阱识别 |
| 其他 | other | 未归类模板 |

## 内置模板清单 (51 个)

### 错题类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 1 | 错题手术 | 错题 | 做错一道题后拆解错因 | subject, chapter, question, mySolution, correctAnswer, currentConfusion |
| 2 | 错因归类 | 错题 | 对多道错题做错因分类 | subject, mistakeList, timeRange |
| 3 | 同型变式 | 变式 | 围绕同一模型设计变式训练 | subject, originalQuestion, mistakeRootCause, correctModel, difficulty |
| 4 | 二刷检测 | 错题 | 验证已复习错题是否真正掌握 | subject, question, lastMistakeReason, correctModel, mySolution |
| 5 | 错题压缩成模型 | 错题 | 把同类错题压缩成可复用模型 | subject, chapter, mistakeList, commonRootCause |
| 6 | 只给提示不讲答案 | 错题 | 卡题时只给思路提示 | subject, question, myThinking, stuckPoint |
| 7 | 错题回填字段生成 | 错题 | 生成可回填到错题记录的字段 | subject, chapter, question, myAnalysis |

### 数学类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 8 | 数学概念预习 | 预习 | 数学新章节预习 | chapter, examGoal, knownBase |
| 9 | 数学题型归纳 | 整理 | 归纳某专题的常见题型 | chapter, questionSummary, difficulty |
| 10 | 函数题突破 | 错题 | 函数类题目专项突破 | question, mySolution, stuckPoint |
| 11 | 三角函数题突破 | 错题 | 三角函数题专项突破 | question, mySolution, stuckPoint |
| 12 | 向量题突破 | 错题 | 向量题专项突破 | question, mySolution, stuckPoint |
| 13 | 导数题突破 | 错题 | 导数题专项突破 | question, mySolution, stuckPoint |
| 14 | 解析几何题突破 | 错题 | 解析几何题专项突破 | question, mySolution, stuckPoint |
| 15 | 数列题突破 | 错题 | 数列题专项突破 | question, mySolution, stuckPoint |
| 16 | 数学压轴题分层提示 | 错题 | 压轴题分层引导 | question, myProgress, stuckPoint |
| 17 | 数学计算失误复盘 | 复盘 | 复盘计算失误模式 | calculationErrors, questionTypes, timePressure |

### 物理类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 18 | 物理过程分析 | 错题 | 拆解物理题的过程 | question, myAnalysis, stuckPoint |
| 19 | 物理模型识别 | 错题 | 识别经典物理模型 | question, myGuess |
| 20 | 受力分析教练 | 错题 | 检查受力分析 | question, myForces, confusion |
| 21 | 电磁学题目拆解 | 错题 | 拆解电磁学综合题 | question, mySolution, stuckPoint |
| 22 | 物理实验题误差分析 | 错题 | 分析实验误差 | experimentName, question, myAnswer |
| 23 | 物理图像题分析 | 错题 | 分析物理图像题 | question, imageDescription, myUnderstanding |

### 化学类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 24 | 化学概念辨析 | 错题 | 辨析混淆概念 | concepts, myUnderstanding, confusion |
| 25 | 化学方程式审查 | 错题 | 审查方程式书写 | reactionDescription, myEquation, requirement |
| 26 | 化学实验题拆解 | 错题 | 拆解实验题 | question, myAnswer, uncertainty |
| 27 | 化学工艺流程题分析 | 错题 | 分析工艺流程题 | question, myAnalysis, confusingSteps |
| 28 | 化学计算题步骤检查 | 错题 | 检查计算步骤 | question, myCalculation |

### 生物类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 29 | 生物概念边界辨析 | 错题 | 辨析概念边界 | concept, myUnderstanding, boundaryQuestion |
| 30 | 生物图表题分析 | 错题 | 分析图表题 | question, chartDescription, myAnalysis |
| 31 | 生物实验设计题分析 | 错题 | 分析实验设计题 | question, myDesign, uncertainty |
| 32 | 细胞与分子专题复盘 | 复盘 | 必修一模块复盘 | completedContent, mistakeSummary, unstablePoints |
| 33 | 生物选择题陷阱识别 | 自测 | 识别选择题陷阱 | question, options, myAnswer, correctAnswer |

### 英语类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 34 | 英语阅读精读 | 整理 | 精读阅读理解文章 | articleTopic, articleContent, wrongQuestions |
| 35 | 长难句拆解 | 整理 | 拆解长难句结构 | sentence, myTranslation, confusingPart |
| 36 | 完形七选五错因分析 | 错题 | 分析完形/七选五错因 | questionType, passage, wrongItems, answerComparison |
| 37 | 作文表达升级 | 整理 | 升级作文表达 | essayTopic, myWriting, improvementGoal |
| 38 | 读后续写情节推进 | 整理 | 训练读后续写 | originalSummary, paragraphStarters, myIdea |

### 语文类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 39 | 文言文翻译拆解 | 整理 | 拆解文言文翻译 | originalText, myTranslation, uncertainWords |
| 40 | 古诗鉴赏答题模板 | 整理 | 训练古诗鉴赏答题 | poem, question, myAnswer |
| 41 | 现代文阅读结构分析 | 整理 | 分析现代文结构 | articleType, articleContent, question, myAnswer |
| 42 | 作文立意与素材整理 | 整理 | 训练审题立意 | prompt, myThesis, myMaterials |

### 预习/整理/诊断/自测类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 43 | 教材预习 | 预习 | 新章节预习框架 | subject, textbookSection, examGoal, knownBase |
| 44 | 课后整理 | 整理 | 课后内容结构化 | subject, lessonTopic, rawNotes, unclearPoints |
| 45 | 单元诊断 | 诊断 | 章节薄弱点诊断 | subject, unitName, completedWork, mistakesSummary, selfRating |
| 46 | 拍图自测 | 自测 | 基于图片追问式自测 | subject, imageContent, testGoal, currentLevel |
| 47 | 考后试卷复盘 | 复盘 | 考试后结构化复盘 | subject, examType, score, scoreBreakdown, mistakeSummary |

### 复盘类

| # | title | category | 使用场景 | variables |
|---|-------|----------|----------|-----------|
| 48 | 每日复盘 | 复盘 | 每日学习复盘 | date, completedTasks, unfinishedTasks, focusSummary, mistakeSummary, stateScoreEnd |
| 49 | 周复盘 | 复盘 | 一周结构化回顾 | weekRange, totalStudyMinutes, subjectBreakdown, completedTaskCount, mistakeTypeBreakdown, keyDailyProblems |
| 50 | 学习计划降载 | 复盘 | 状态差时降载计划 | stateScore, pendingTasks, availableTime, mainWorry |
| 51 | 明日第一步生成 | 复盘 | 生成明天具体第一步 | todaySummary, biggestProblem, tomorrowTime, tomorrowExam |

## 变量填写策略

变量输入根据变量名关键词自动判断输入控件：
- 包含 question/solution/notes/summary/text/content/answer/confusion/raw/thinking/analysis/design/writing/translation/calculation/list/progress/breakdown/problems/items/comparison/description/forces/understanding/guess/materials/idea 的变量使用多行 TextEditor。
- 其他变量使用单行 TextField。

生成 Prompt 时，如果变量为空，保留"未提供"，让 AI 知道信息缺失。
