# 数据模型草案

本文档描述 Stage 1 到 Stage 2 可落地的本地数据模型草案。第一版优先使用 SwiftData，本文件只定义业务结构，不写 Swift 代码。

## 建模原则

- 本地优先：所有核心数据必须离线可用。
- 够用即可：字段服务每日学习闭环，不为远期平台化预留复杂结构。
- 可迁移：字段命名尽量稳定，后续再补枚举、索引、统计缓存。
- 少输入：字段可以为空时不强迫用户填写。
- 重复盘：任务、专注、错题、复盘之间要能互相追溯。

## DayPlan 今日计划

### 用途

记录某一天的启动信息、主攻方向、任务分层和明日第一步，是今日驾驶舱的核心数据。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| date | Date | 是 | 计划对应日期 |
| wakeTime | Date? | 否 | 起床或开始学习时间 |
| stateScore | Int | 否 | 当前状态评分，建议 1 到 10 |
| mainSubject | String? | 否 | 今日主攻科目 |
| topTasks | [String] | 否 | 今日最重要任务，建议 1 到 3 个 |
| baselineTasks | [String] | 否 | 状态差时也要完成的保底任务 |
| bonusTasks | [String] | 否 | 状态好时追加的奖励任务 |
| tomorrowFirstAction | String? | 否 | 明天打开 App 后第一步 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440001",
  "date": "2026-05-18",
  "wakeTime": "2026-05-18T06:30:00+08:00",
  "stateScore": 7,
  "mainSubject": "数学",
  "topTasks": [
    "导数压轴题 6 题，记录所有卡点",
    "英语阅读精读 1 篇并整理长难句"
  ],
  "baselineTasks": [
    "数学错题手术 1 道",
    "背诵英语高频词 20 个"
  ],
  "bonusTasks": [
    "物理电磁感应小专题复盘 30 分钟"
  ],
  "tomorrowFirstAction": "打开数学导数错题本，先复做昨天第 3 题",
  "createdAt": "2026-05-18T06:35:00+08:00",
  "updatedAt": "2026-05-18T06:40:00+08:00"
}
```

## StudyTask 学习任务

### 用途

记录可执行的学习动作，并承接今日计划、专注计时和每日复盘。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| dayPlanId | UUID? | 否 | 关联的今日计划 |
| title | String | 是 | 任务标题，必须是可执行动作 |
| subject | String | 是 | 科目，如数学、语文、英语、物理 |
| category | String | 否 | 类型，如预习、做题、复盘、背诵、整理 |
| estimatedMinutes | Int | 否 | 预计用时 |
| actualMinutes | Int | 否 | 实际用时，可由专注记录汇总 |
| status | String | 是 | 状态，如 pending、inProgress、done、skipped |
| outputNote | String? | 否 | 产出备注，如完成题数、错因、笔记位置 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440002",
  "dayPlanId": "550E8400-E29B-41D4-A716-446655440001",
  "title": "导数压轴题 6 题，记录所有卡点",
  "subject": "数学",
  "category": "做题",
  "estimatedMinutes": 75,
  "actualMinutes": 82,
  "status": "done",
  "outputNote": "完成 6 题，错 2 题；主要问题是分类讨论漏边界",
  "createdAt": "2026-05-18T06:42:00+08:00",
  "updatedAt": "2026-05-18T09:05:00+08:00"
}
```

## FocusSession 专注记录

### 用途

记录一次围绕具体任务展开的专注学习过程，用于复盘真实投入和状态质量。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| taskId | UUID? | 否 | 关联的学习任务 |
| subject | String | 是 | 本轮学习科目 |
| startTime | Date | 是 | 开始时间 |
| endTime | Date? | 否 | 结束时间 |
| plannedMinutes | Int | 是 | 计划专注时长 |
| actualMinutes | Int | 否 | 实际专注时长 |
| distractionCount | Int | 否 | 分心次数 |
| completionScore | Int | 否 | 完成评分，建议 1 到 5 |
| sessionNote | String? | 否 | 本轮记录 |
| nextAction | String? | 否 | 下一步动作 |
| createdAt | Date | 是 | 创建时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440003",
  "taskId": "550E8400-E29B-41D4-A716-446655440002",
  "subject": "数学",
  "startTime": "2026-05-18T07:30:00+08:00",
  "endTime": "2026-05-18T08:55:00+08:00",
  "plannedMinutes": 75,
  "actualMinutes": 85,
  "distractionCount": 2,
  "completionScore": 4,
  "sessionNote": "最后两题卡在参数分类，已标记为错题手术候选",
  "nextAction": "整理第 5 题的分类讨论边界",
  "createdAt": "2026-05-18T07:30:00+08:00"
}
```

## MistakeRecord 错题手术记录

### 用途

记录一道错题从题面到根因、从正确模型到变式复练的完整手术过程。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| subject | String | 是 | 科目 |
| chapter | String? | 否 | 章节或专题 |
| source | String? | 否 | 来源，如试卷、练习册、模考、教材 |
| questionText | String? | 否 | 题目文字 |
| questionImagePath | String? | 否 | 题目图片本地路径 |
| mySolution | String? | 否 | 我的原解法 |
| correctSolution | String? | 否 | 正确解法或标准思路 |
| mistakeType | String | 是 | 错误类型，如概念、计算、审题、模型、表达、时间 |
| rootCause | String? | 否 | 根因，不只写“粗心” |
| questionSignal | String? | 否 | 题目中触发正确方法的信号 |
| correctModel | String? | 否 | 应使用的知识模型、解题模型或套路 |
| variantTask | String? | 否 | 后续同型变式任务 |
| nextReminder | Date? | 否 | 下次复习提醒时间 |
| reviewStatus | String | 是 | 复习状态，如 new、scheduled、reviewed、mastered |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440004",
  "subject": "数学",
  "chapter": "导数与函数零点",
  "source": "周练 2026-05-18 第 17 题",
  "questionText": "已知函数 f(x)=... 求参数 a 的取值范围。",
  "questionImagePath": "local://mistakes/2026-05-18/math-17.png",
  "mySolution": "直接求导后只讨论了单调递增情况，漏掉临界点重合。",
  "correctSolution": "先分离参数，再结合函数图像与导数符号讨论边界。",
  "mistakeType": "模型",
  "rootCause": "看到参数范围题没有先判断是否适合分离参数，直接进入机械求导。",
  "questionSignal": "题干要求参数取值范围，并出现恒成立结构。",
  "correctModel": "参数范围题：先判断分离参数、端点、极值、边界是否同时需要处理。",
  "variantTask": "明天完成 3 道同型参数范围题，只写触发信号和模型选择。",
  "nextReminder": "2026-05-20T07:30:00+08:00",
  "reviewStatus": "scheduled",
  "createdAt": "2026-05-18T20:10:00+08:00",
  "updatedAt": "2026-05-18T20:25:00+08:00"
}
```

## PromptTemplate Prompt 模板

### 用途

保存内置和自定义 Prompt 模板，用于生成可复制到 AI 工具中的学习提示词。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| title | String | 是 | 模板标题 |
| category | String | 是 | 模板分类，如错题、预习、复盘、诊断 |
| description | String? | 否 | 使用说明 |
| templateText | String | 是 | Prompt 模板正文，包含变量占位符 |
| variables | [String] | 否 | 需要用户填写的变量名 |
| usageCount | Int | 是 | 使用次数 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440005",
  "title": "错题手术",
  "category": "错题",
  "description": "把一道错题拆成错因、根因、信号、模型和变式任务。",
  "templateText": "你是我的高考错题外科医生。科目：{{subject}}。题目：{{question}}。我的解法：{{mySolution}}。请按要求完成错题手术。",
  "variables": [
    "subject",
    "question",
    "mySolution"
  ],
  "usageCount": 12,
  "createdAt": "2026-05-18T06:00:00+08:00",
  "updatedAt": "2026-05-18T20:30:00+08:00"
}
```

## ResourceItem 学习资料

### 用途

记录学习资料的轻量索引，帮助任务、错题和复盘关联到教材、试卷、讲义、视频或网页。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| title | String | 是 | 资料标题 |
| subject | String | 是 | 科目 |
| chapter | String? | 否 | 章节或专题 |
| type | String | 是 | 类型，如 textbook、paper、note、video、web、file |
| uri | String? | 否 | 本地路径、网页链接或外部 App 链接 |
| status | String | 是 | 状态，如 unread、inProgress、done、archived |
| note | String? | 否 | 简短备注 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440006",
  "title": "数学选择性必修二：导数及其应用",
  "subject": "数学",
  "chapter": "导数",
  "type": "textbook",
  "uri": "local://resources/math/textbook-derivative.pdf",
  "status": "inProgress",
  "note": "重点看参数范围和极值应用例题",
  "createdAt": "2026-05-18T06:50:00+08:00",
  "updatedAt": "2026-05-18T06:55:00+08:00"
}
```

## DailyReview 每日复盘

### 用途

记录当天复盘，帮助用户收束今天并明确明天第一步。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| date | Date | 是 | 复盘日期 |
| completedSummary | String? | 否 | 今日完成总结 |
| unfinishedSummary | String? | 否 | 未完成内容与原因 |
| biggestProblem | String? | 否 | 今日最大问题 |
| bestMistakeId | UUID? | 否 | 今日最值得复盘的一条错题 |
| stateScoreEnd | Int | 否 | 晚间状态评分，建议 1 到 10 |
| tomorrowFirstAction | String? | 否 | 明天第一步 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440007",
  "date": "2026-05-18",
  "completedSummary": "完成数学导数 6 题、英语阅读 1 篇、错题手术 1 道。",
  "unfinishedSummary": "物理电磁感应复盘未完成，因为数学任务超时。",
  "biggestProblem": "参数范围题模型选择慢，容易直接机械求导。",
  "bestMistakeId": "550E8400-E29B-41D4-A716-446655440004",
  "stateScoreEnd": 6,
  "tomorrowFirstAction": "先复做导数错题第 17 题，再做 3 道同型题。",
  "createdAt": "2026-05-18T22:20:00+08:00",
  "updatedAt": "2026-05-18T22:35:00+08:00"
}
```

## WeeklyReview 周复盘

### 用途

记录一周学习投入和问题结构，用于确定下周重点。

### 字段列表

| 字段 | 类型建议 | 必填 | 解释 |
| --- | --- | --- | --- |
| id | UUID | 是 | 唯一标识 |
| weekStartDate | Date | 是 | 周开始日期 |
| weekEndDate | Date | 是 | 周结束日期 |
| totalStudyMinutes | Int | 是 | 本周总学习分钟数 |
| subjectBreakdown | [String: Int] | 否 | 科目到学习分钟数的映射 |
| completedTaskCount | Int | 是 | 完成任务数 |
| mistakeCount | Int | 是 | 错题手术数量 |
| mistakeTypeBreakdown | [String: Int] | 否 | 错误类型分布 |
| keyProblems | [String] | 否 | 本周关键问题 |
| nextWeekFocus | [String] | 否 | 下周重点 |
| createdAt | Date | 是 | 创建时间 |
| updatedAt | Date | 是 | 更新时间 |

### 示例数据

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440008",
  "weekStartDate": "2026-05-18",
  "weekEndDate": "2026-05-24",
  "totalStudyMinutes": 1980,
  "subjectBreakdown": {
    "数学": 720,
    "英语": 420,
    "物理": 480,
    "语文": 360
  },
  "completedTaskCount": 31,
  "mistakeCount": 12,
  "mistakeTypeBreakdown": {
    "模型": 5,
    "计算": 3,
    "审题": 2,
    "表达": 2
  },
  "keyProblems": [
    "数学参数范围题模型选择慢",
    "英语阅读长难句拆解不稳定",
    "物理综合题条件提取容易漏"
  ],
  "nextWeekFocus": [
    "数学导数参数范围专题",
    "英语阅读长难句每日 1 句",
    "物理电磁感应模型触发信号"
  ],
  "createdAt": "2026-05-24T21:30:00+08:00",
  "updatedAt": "2026-05-24T22:00:00+08:00"
}
```

## 实体关系草案

```text
DayPlan 1 -> many StudyTask
StudyTask 1 -> many FocusSession
DailyReview 0/1 -> 1 DayPlan by date
DailyReview 0/1 -> 1 MistakeRecord as bestMistake
WeeklyReview aggregates StudyTask, FocusSession, MistakeRecord, DailyReview by date range
ResourceItem can be referenced manually from StudyTask or MistakeRecord notes in MVP
PromptTemplate is standalone in MVP
```

MVP 中不强制建立所有硬关联。为了降低实现复杂度，`ResourceItem` 和 `PromptTemplate` 可以先独立存在，靠标题、备注和复制内容参与学习流程。

