# 开发路线文档

路线图按阶段推进。每个阶段都要保持一个原则：先让每日学习闭环稳定跑起来，再考虑自动化和扩展。

## Stage 0：Markdown 产品设计文档

### 目标

明确 MVP 的产品范围、数据模型、体验流程、路线图和内置 Prompt 模板。

### 需要修改/新增的内容

- `README.md`
- `docs/PRODUCT_SPEC.md`
- `docs/DATA_MODEL.md`
- `docs/UX_FLOW.md`
- `docs/ROADMAP.md`
- `docs/PROMPT_TEMPLATES.md`

### 验收标准

- 文档能说明 App 为什么存在。
- 文档能说明 MVP 做什么、不做什么。
- 数据模型包含核心实体和字段解释。
- UX 流程覆盖启动、计划、专注、错题、Prompt、复盘。
- 路线图能指导 Stage 1 开始。

### 不做什么

- 不创建 SwiftUI 页面。
- 不创建 Xcode 工程。
- 不创建数据库。
- 不写 API。
- 不引入依赖。

## Stage 1：创建 SwiftUI + SwiftData 项目骨架

### 目标

建立最小 iOS 原生 App 工程骨架，为后续本地数据和页面实现做准备。

### 需要修改/新增的内容

- 创建 iOS SwiftUI 项目。
- 设置 App 入口。
- 设置基础目录结构，如 `Models`、`Views`、`Stores`、`Resources`。
- 添加基础导航框架。
- 保留示例页面用于验证工程可运行。

### 验收标准

- App 能在 iOS Simulator 启动。
- 工程使用 SwiftUI。
- 工程预留 SwiftData 接入位置。
- 首页可以显示项目名称和 Stage 状态。
- 没有业务逻辑膨胀。

### 不做什么

- 不实现完整页面。
- 不接 AI API。
- 不做账号。
- 不做云同步。
- 不做复杂主题系统。

## Stage 2：实现数据模型与本地存储

### 目标

把核心数据模型落到 SwiftData，并保证本地增删改查稳定。

### 需要修改/新增的内容

- 建立 DayPlan 模型。
- 建立 StudyTask 模型。
- 建立 FocusSession 模型。
- 建立 MistakeRecord 模型。
- 建立 PromptTemplate 模型。
- 建立 ResourceItem 模型。
- 建立 DailyReview 模型。
- 建立 WeeklyReview 模型。
- 初始化内置 PromptTemplate 种子数据。

### 验收标准

- App 离线可创建和读取核心数据。
- 重启 App 后数据仍存在。
- 内置 Prompt 模板只初始化一次。
- 字段与 `docs/DATA_MODEL.md` 基本一致。

### 不做什么

- 不做远程数据库。
- 不做复杂迁移策略。
- 不做加密存储。
- 不做跨设备同步。

## Stage 3：实现今日驾驶舱

### 目标

实现 TodayCockpitView，让用户每天打开后可以完成启动和进入学习。

### 需要修改/新增的内容

- 今日计划创建逻辑。
- 今日状态输入。
- 主攻科目输入。
- Top 任务、保底任务、奖励任务展示。
- 今日进度摘要。
- 明日第一步展示。
- 进入任务、错题、复盘的入口。

### 验收标准

- 当天没有 DayPlan 时可以快速创建。
- 当天已有 DayPlan 时自动加载。
- 用户能在 1 分钟内完成启动。
- 首页信息不拥挤。
- 状态差时能看到保底任务。

### 不做什么

- 不做复杂图表。
- 不做自动学习规划。
- 不做大屏驾驶舱视觉特效。
- 不做天气、日历等无关信息。

## Stage 4：实现学习任务与专注计时

当前进度：Stage 4A TaskListView MVP 已完成；Stage 4B FocusSession 专注计时 MVP 已完成。

### 目标

让用户能围绕学习任务开始、记录并结束一次专注学习。

### 需要修改/新增的内容

- TaskListView。（Stage 4A 已完成）
- 新建和编辑 StudyTask。（Stage 4A 已完成）
- 任务状态切换。（Stage 4A 已完成）
- FocusSessionView。（Stage 4B 已完成）
- 专注开始、暂停、结束。（Stage 4B 已完成）
- 分心次数记录。（Stage 4B 已完成）
- 完成评分、产出备注、下一步记录。（Stage 4B 已完成）

### 验收标准

- 用户能创建任务并立即开始专注。
- 专注结束后生成 FocusSession。
- StudyTask 能记录实际用时和状态。
- 每日复盘可以读取当天任务和专注摘要。

### 不做什么

- 不做复杂番茄钟策略。
- 不做后台长期运行优化。
- 不做 Apple Watch。
- 不做通知系统，除非后续自用测试证明必要。

## Stage 5：实现错题手术

当前进度：Stage 5 Mistake Surgery / 错题手术 MVP 已完成；正式 Prompt 生成和仓库联动留到 Stage 6。

### 目标

实现 MistakeSurgeryView，让错题记录从“收藏”变成“诊断和复练”。

### 需要修改/新增的内容

- 错题列表。
- 错题详情。
- 新建和编辑 MistakeRecord。
- 错误类型选择。
- 根因、题目信号、正确模型、变式任务字段。
- 复习状态。
- 与 Prompt 仓库的入口联动。

### 验收标准

- 用户能在 5 分钟内完成一条错题手术。
- 每条错题至少能记录错误类型、根因、题目信号、正确模型。
- 可以按科目或复习状态查看错题。
- 可以从错题生成对应 Prompt。

### 不做什么

- 不做 OCR。
- 不做自动识别题目。
- 不做自动批改。
- 不做大型错题本排版。
- 不强制每条错题都上传图片。

## Stage 6：实现 Prompt 仓库

当前进度：Stage 6 Prompt Library / Prompt 仓库 MVP 已完成；仅生成和复制 Prompt，不接 AI API。

### 目标

实现内置 Prompt 模板的一键生成和复制。

### 需要修改/新增的内容

- PromptLibraryView。
- Prompt 模板列表。
- Prompt 详情。
- 变量输入表单。
- Prompt 预览。
- 复制到剪贴板。
- 使用次数统计。

### 验收标准

- 内置模板可用。
- 用户能填写变量并生成完整 Prompt。
- 用户能一键复制到剪贴板。
- 不依赖网络和 AI API。
- 可以从错题、每日复盘等场景进入对应模板。

### 不做什么

- 不做聊天窗口。
- 不接任何模型 API。
- 不保存 AI 返回内容，除非用户手动粘贴到记录里。
- 不做复杂 Prompt 版本管理。

## Stage 7：实现每日复盘与周复盘

当前进度：Stage 7 Daily Review / Weekly Review 复盘 MVP 已完成；仅做本地复盘记录、基础汇总和 Prompt 生成，不接 AI API。

### 目标

完成当天闭环与一周结构化回顾。

### 需要修改/新增的内容

- DailyReviewView。
- 每日摘要读取。
- 今日最佳错题选择。
- 明天第一步写入 DayPlan 或 DailyReview。
- WeeklyReviewView。
- 周学习分钟统计。
- 科目分布统计。
- 错题类型统计。
- 下周重点输入。

### 验收标准

- 用户能在 3 分钟内完成每日复盘。
- 用户能在周末完成周复盘。
- 周复盘能自动汇总基础数字。
- 明天第一步能在次日首页出现。

### 不做什么

- 不做复杂 BI 报表。
- 不做预测分数。
- 不做自动生成完整下周计划。
- 不做对外分享海报。

## Stage 8：真实可用性补强

当前进度：Stage 8 Real Usability Fixes / 图片上传与计划转任务已完成。

### 目标

补上真实自用中最容易卡住的两个入口：错题能保存题图，Today 计划能生成正式任务。

### 已完成内容

- 错题编辑支持从相册选择一张题图。
- 错题编辑支持拍照上传题图，无可用相机时按钮禁用。
- 题图压缩后保存到本地 Application Support / MistakeImages，并在 MistakeRecord.questionImagePath 记录相对路径。
- 错题编辑页支持预览、更换、删除题图。
- 错题列表显示小缩略图或题图标记。
- Today 支持把 Top / 保底 / 加分任务按行解析成 StudyTask。
- 生成任务前显示确认 Sheet，同名任务自动跳过。

### 不做什么

- 不做 OCR。
- 不做 AI 图片识别。
- 不做自动批改。
- 不接 AI API。
- 不做云同步或账号。

## Stage 9：Real Usability Polish 1 / 实战体验修正 1

当前进度：Stage 9 已完成。

### 目标

围绕真实学习使用场景，修正当前最可能影响日用的摩擦点，不扩张成大功能。

### 已完成内容

- 错题题图支持点开大图预览，读取失败时给出明确提示。
- Today 从计划生成任务后显示“已添加 / 跳过重复项”结果，并提供查看任务页入口。
- Focus 结束记录支持快速保存，保留详细记录字段。
- 每日复盘支持快速复盘模板，且不覆盖已有内容。
- 从错题生成 Prompt 时，对“只有题图没有题面文字”和“题面与题图都缺失”的情况给出更清楚提示。

### 验收标准

- 错题图片不再只能看小缩略图。
- Today 计划转任务后用户能明确知道结果，并能进入 Tasks 查看。
- Focus 结束时不强迫填写长文本。
- 每日复盘可以在 3 分钟内完成。
- Prompt 不尝试自动处理本地图片，仍由用户手动上传到 AI 对话。

### 不做什么

- 不接 AI API。
- 不做 OCR。
- 不做自动批改。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不做新数据模型大迁移。

## Stage 10：Stability / Debug Cleanup / QA Checklist / 闭环稳定性与调试入口收口

当前进度：Stage 10 已完成。

### 目标

让 Gaokao Cockpit 更像可以主力使用的 v0.1 App，而不是开发调试版。重点收口调试入口，补强主流程反馈，并留下每次迭代后可人工验收的闭环清单。

### 已完成内容

- Today 页面不再默认展示 Stage 2 Debug 大块入口。
- Stage 2 Debug 能力保留为 DEBUG 构建底部的低调“开发诊断 / Developer Diagnostics”折叠项。
- Release 构建不显示开发诊断入口。
- Today / Tasks / Focus / Mistakes / Prompts / Reviews 的空状态、保存反馈、复制反馈、删除确认文案做了轻量优化。
- 新增 `docs/QA_CHECKLIST.md`，覆盖启动、Today、Tasks、Focus、Mistakes、Prompts、Reviews、持久化和构建验收。

### 不做什么

- 不接 AI API。
- 不做 OCR。
- 不做自动批改。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不做新数据模型迁移。
- 不做复杂统计图表。

## Stage 11：Local Backup Export MVP / 本地数据备份导出

### 目标

给已经进入主力试用阶段的 Gaokao Cockpit 增加本地导出能力，保护用户的学习数据和错题图片。第一版只做“导出备份”，不做导入恢复，避免数据合并和覆盖风险。

### 已完成内容

- 新增 `BackupExportStore`，通过 SwiftData `ModelContext` 读取所有核心模型数据。
- 定义独立 Codable Snapshot 和 `GaokaoBackupEnvelope`，不让 SwiftData `@Model` 直接遵守 Codable。
- 支持导出本地 JSON 文件，文件名格式为 `gaokao-cockpit-backup-YYYYMMDD-HHmmss.json`。
- 导出内容包含 DayPlan、StudyTask、FocusSession、MistakeRecord、PromptTemplate、ResourceItem、DailyReview、WeeklyReview。
- 错题图片从本地 `MistakeImages` 路径读取，只在导出 JSON 中以 base64 嵌入。
- 图片缺失或读取失败时写入 warnings，不中断整体导出。
- 新增 `BackupExportView` 和系统 ShareSheet，用于导出后分享或保存 JSON 文件。
- Reviews 页面底部新增低调“数据与备份”入口。

### 验收标准

- 用户能从 Reviews 打开数据备份页。
- 用户能导出一个本地 JSON 备份文件。
- 导出完成后显示各类记录数量。
- 导出完成后可以打开系统分享面板保存或转发文件。
- 有图片错题时，导出 JSON 包含 `mistakeImages`。
- 图片缺失时显示 warnings，但不导致备份失败。
- UI 明确说明本阶段不支持导入恢复。

### 不做什么

- 不做导入恢复。
- 不做云同步。
- 不做账号系统。
- 不做自动定时备份。
- 不做 iCloud Drive 自动同步。
- 不引入第三方依赖。
- 不做复杂加密。
- 不做 zip。
- 不导出 SwiftData 原始 sqlite。
- 不接 AI API。
- 不做 OCR。

## Stage 12：Backup Validation / Format Strategy / 备份校验与格式策略

### 目标

让 Stage 11 的本地 JSON 备份更可信、更可读，也为未来导入恢复留下清晰格式边界。本阶段只做导出摘要、结构校验和版本策略，不做导入恢复。

### 已完成内容

- `GaokaoBackupEnvelope` 向后兼容新增 `schemaName`、`exportSchemaVersion`、`recordSummary`、`integrity` 和 `warnings`。
- `BackupRecordSummary` 记录各类数据数组数量。
- `BackupIntegritySummary` 记录 checksum、图片总字节数、缺失图片数和 warnings 数。
- checksum 使用 CryptoKit SHA256，计算对象为 checksum 字段为空时的备份 JSON payload。
- 新增 `BackupValidationStore`，支持验证刚导出的本地备份文件结构。
- `BackupExportView` 导出后显示文件名、导出时间、记录数量、错题图片数量、图片总大小、warnings 数量和 checksum 前 12 位。
- `BackupExportView` 支持一键验证刚导出的备份，显示可读性、schema、version、数量一致性、warnings 和 errors。
- 新增 `docs/BACKUP_FORMAT.md`，说明当前备份格式、版本策略、base64 图片、checksum 策略和未来导入恢复风险。

### 验收标准

- 导出的 JSON 仍保留 Stage 11 的旧数组字段。
- 新导出的 JSON 包含 schema、summary、integrity、warnings 和 checksum。
- 记录数量摘要与实际 JSON 数组数量一致。
- 图片总大小、缺失图片数和 warnings 数显示合理。
- 导出后可验证刚生成的备份文件。
- checksum 能重新计算并匹配。
- UI 和文档明确说明 checksum 不是加密签名。
- UI 和文档明确说明当前只支持导出和校验，不支持导入恢复。

### 不做什么

- 不做导入恢复。
- 不写入 SwiftData。
- 不做云同步。
- 不做账号系统。
- 不做加密。
- 不做 zip。
- 不导出原始 sqlite。
- 不引入第三方依赖。
- 不做数据模型迁移。
- 不接 AI API。

## Stage 13：Backup Import Dry-run / 导入恢复预检

当前进度：Stage 13 已完成。

### 目标

在不写入 SwiftData、不恢复图片文件、不覆盖任何本地数据的前提下，让用户选择备份 JSON 并预检未来恢复风险。

### 已完成内容

- 新增系统 `UIDocumentPickerViewController` SwiftUI wrapper，用于选择单个 JSON 备份文件。
- 新增 `BackupImportDryRunStore`，复用备份校验逻辑读取 schema、version、checksum 和 summary。
- 计算 incoming summary 与当前 local summary。
- 检查各模型 UUID 冲突、`DayPlan.dayKey` 冲突、同日同名任务和错题 fingerprint 疑似重复。
- 统计备份内错题图片数量、base64 可用数量、缺失数量和图片总字节数。
- 在备份页新增“导入预检（Dry-run）”区块，明确说明不会导入或覆盖数据。

### 验收标准

- 用户能选择 JSON 文件并完成 dry-run。
- 刚导出的备份可被解析并显示 summary。
- 错误文件不会导致崩溃。
- Dry-run 后本地数据数量不改变。
- UI 明确说明本阶段不会真正导入。

### 不做什么

- 不做真正导入按钮。
- 不写入 SwiftData。
- 不恢复图片文件。
- 不覆盖任何本地数据。
- 不做云同步、账号、加密、zip。
- 不引入第三方依赖。
- 不做数据模型迁移。
- 不接 AI API。

## Stage 14：Restore Strategy / Fixture Tests / 恢复策略与小规模 Fixture 测试

当前进度：Stage 14 已完成。

### 目标

为未来真正导入恢复做准备，但本阶段仍不写入 SwiftData、不恢复图片、不覆盖用户数据。

### 已完成内容

- 新增 `docs/RESTORE_STRATEGY.md`，说明推荐 `merge-with-new-ids`、ID 映射、冲突决策、图片恢复和恢复前后对账策略。
- 新增纯结构 `BackupRestorePlan`，包含 incoming、planned、skipped、ID mapping、image plan、warnings/errors 和 `isSafeToProceed`。
- 新增 `BackupRestorePlanBuilder`，基于 `GaokaoBackupEnvelope` 与 dry-run 结果生成 restore plan，不访问 `ModelContext`，不写文件。
- Dry-run UI 新增“未来恢复计划预览”，显示策略、是否建议继续、预计插入、预计跳过、warnings/errors，并明确本阶段不会写入数据。
- Dry-run 冲突摘要补充 `DailyReview.dayKey` 和 `WeeklyReview.weekStartKey`。
- 新增 `fixtures/backups/minimal-valid-backup.json` 与 `fixtures/backups/duplicate-conflict-backup.json`。
- 新增 `docs/RESTORE_PLAN_TESTS.md`，说明 fixture 手动验证路径和预期结果。

### 验收标准

- Restore plan 默认策略为 `merge-with-new-ids`。
- Restore plan 只做统计，不生成真实 UUID，不写 SwiftData，不恢复图片文件。
- Dry-run 后能看到 planned/skipped counts。
- Fixture JSON 可解析并用于手动验证 summary、冲突和 skipped counts。
- Debug / Release 构建通过。

### 不做什么

- 不做真正导入恢复 UI。
- 不写入 SwiftData 主库。
- 不恢复图片到真实 `MistakeImages` 目录。
- 不覆盖任何用户数据。
- 不接 AI API。
- 不做云同步、账号、加密、zip。
- 不引入第三方依赖。
- 不做数据模型迁移。

## Stage 15：Restore Plan Semantics / 恢复计划语义修正与风险分类

当前进度：Stage 15 已完成。

### 目标

修正 Stage 14 restore plan 对 invalid references 的表达方式：invalid reference 不默认等同于 skipped，而是进入 reference repair / needs review，为未来真实恢复时的置空引用、重新映射或人工确认留下空间。

### 已完成内容

- 新增纯结构 `BackupRestoreReferenceRepairSummary`，统计缺失 DayPlan 的 StudyTask、缺失 Task 的 FocusSession、缺失 Mistake 的 DailyReview，以及总计需要修复的记录数。
- `BackupRestorePlan` 新增 `referenceRepairSummary`，并为旧 plan 解码提供默认空值。
- `BackupRestorePlanBuilder` 不再把 invalid references 计入 skipped，也不再仅因 invalid reference 扣减 planned counts。
- Restore plan warnings 和 dry-run recommendation 明确说明未来真实恢复前需要引用修复策略。
- 备份页“未来恢复计划预览”新增“需要处理的引用”区域，保留 planned / skipped 展示。
- 新增 `fixtures/backups/invalid-reference-backup.json`，用于手动验证 reference repair 区域。
- 更新恢复策略、备份格式、restore plan 测试说明和 QA checklist。

### 验收标准

- duplicate conflict 和内置 Prompt 仍进入 `skippedSummary`。
- invalid reference 进入 `referenceRepairSummary` / needs review，不默认视为 skipped。
- StudyTask、FocusSession、DailyReview 的 planned counts 不会仅因 invalid reference 自动减少。
- UI 明确说明 invalid references 未来需要置空引用、重新映射或人工确认。
- Debug / Release 构建通过。

### 不做什么

- 不做真实导入恢复。
- 不写入 SwiftData。
- 不恢复图片文件。
- 不覆盖任何用户数据。
- 不接 AI API。
- 不做云同步、账号、加密、zip。
- 不引入第三方依赖。
- 不做数据模型迁移。

## Stage 16：State Type Safety / String Value Consolidation / 状态类型安全化与字符串状态收敛

当前进度：Stage 16 已完成。

### 目标

在不修改 SwiftData `@Model` 字段类型、不做模型迁移、不改变备份格式的前提下，把业务层常见状态值、类型值、分类值和科目候选从裸字符串收敛到类型安全 enum wrapper。

### 已完成内容

- 新增 `ModelValueTypes.swift`，提供 `StudyTaskStatus`、`StudyTaskCategory`、`MistakeType`、`ReviewStatus`、`PromptCategory`、`LearningSubject` 和 `ResourceStatus`。
- `ModelDefaults` 保留旧字符串常量，并提示新代码优先使用 enum wrapper。
- Store 层任务状态计数、错题复习状态计数、Prompt 分类筛选和计划转任务默认值改用 enum storage。
- Tasks、Today、Focus、Mistakes 和 Prompt 主要 Picker/Menu 改用 enum cases 与 `displayName`。
- 兼容已有中文 category、subject、Prompt seed 分类读取。
- 备份导出、导入 dry-run、restore plan 和 fixture schema 不变。

### 验收标准

- SwiftData 字段仍为 `String`，不触发迁移。
- 旧中文任务分类、Prompt 分类和科目数据仍能显示。
- 任务状态切换、错题复习状态筛选、Prompt 分类筛选仍正常。
- 备份导出和 dry-run/restore plan 不受影响。
- Debug / Release 构建通过。

### 不做什么

- 不改 SwiftData 字段类型。
- 不做数据模型迁移。
- 不改变备份 schema 或 `exportVersion`。
- 不做真实导入恢复。
- 不接 AI API。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不做大型 UI 或架构重构。

## Stage 17：View Componentization / File Slimming / 长 View 文件拆分与组件化瘦身

当前进度：Stage 17 已完成。

### 目标

在功能闭环和备份策略稳定后，降低主要 SwiftUI View 文件的维护成本。只做 UI 文件拆分、组件化和轻量命名整理，不改变业务行为、不改数据模型、不改备份格式。

### 已完成内容

- Today 页面拆出 Components 目录，承接 header、低状态提示、计划区、计划转任务 sheet、任务摘要、任务预览、明日动作和 UI primitives。
- Tasks 页面拆出任务摘要、筛选条、任务行、任务编辑 sheet。
- Mistakes 页面拆出列表页摘要、筛选条、错题行，并把列表使用的状态/类型展示 helper 从编辑页移出。
- Reviews 页面拆出 header、每日复盘 section、周复盘 section、备份入口和复盘通用卡片/统计组件。
- Backup 页面拆出导出结果、校验结果、dry-run 结果、restore plan 预览和 summary rows。
- Prompt 详情页拆出变量输入和 Prompt 预览组件。
- Xcode project 已登记新增组件文件，Debug / Release 构建通过。

### 验收标准

- Today 可保存计划并生成 Tasks。
- Tasks 可新增、编辑、删除和切换状态。
- Focus 入口和结束流程不受影响。
- Mistakes 可新增、编辑、筛选、图片预览和生成 Prompt。
- Prompts 可填写变量、生成并复制 Prompt。
- Reviews 可保存每日/周复盘，并打开备份入口。
- Backup 可导出、验证、dry-run 并预览 restore plan。
- 不改 SwiftData `@Model`，不触发数据迁移。
- 不改变备份 schema、`exportVersion` 或 restore plan 语义。

### 不做什么

- 不新增业务功能。
- 不改 SwiftData `@Model`。
- 不做数据模型迁移。
- 不改变备份 schema。
- 不做真实导入恢复。
- 不接 AI API。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不大改 Store/helper。

## Stage 18：Prompt Library Expansion / 内置 Prompt 库扩容

当前进度：Stage 18 已完成。

### 目标

扩充内置 Prompt 模板库，改造 seed 机制为安全 upsert，增加搜索能力，让 Prompt 仓库能支撑真实高考学习工作流。

### 已完成内容

- 内置 Prompt 模板从 8 个扩充到 51 个，覆盖错题、数学、物理、化学、生物、英语、语文、复盘八大分类。
- PromptTemplateSeeder 改造为安全 upsert：按 title + isBuiltIn 匹配，更新内容但保留 usageCount，不覆盖用户自定义模板。
- PromptLibraryView 新增搜索框，支持按 title / description / category 搜索，与分类筛选叠加。
- PromptVariableInput 改为关键词匹配判断长文本变量，支持新模板中的所有变量名。
- 不接 AI API，不做聊天窗口，不保存 AI 返回。

### 验收标准

- 内置模板数量不少于 35。
- 旧模板能 upsert 更新，usageCount 不丢失。
- 用户自定义模板不被覆盖。
- 搜索正常，分类筛选正常，组合正常。
- 错题/复盘 Prompt 入口仍能找到对应模板。
- 备份 schema 和 exportVersion 不变。
- Debug / Release 构建通过。

### 不做什么

- 不接 AI API。
- 不做聊天窗口。
- 不保存 AI 返回。
- 不做模型选择器。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不改 SwiftData 模型字段类型。
- 不改变备份 schema。

## Stage 19：Prompt Library Daily Usability Polish / Prompt 库日用体验增强

当前进度：Stage 19 已完成。

### 目标

提升 Prompt Library 日用效率，让常用模板更容易找到，增加最近使用记录，不接 AI API，不改变 SwiftData 模型。

### 已完成内容

- 新增 `RecentPromptStore`，基于 UserDefaults 轻量记录最近使用的 Prompt 模板，最多保留 20 条。
- 复制 Prompt 后自动调用 `RecentPromptStore.recordUse`，记录最近使用。
- PromptLibraryView 新增"常用 Prompt"区域，按 usageCount 降序显示前 5 个使用过的模板。
- PromptLibraryView 新增"最近使用"区域，显示最近复制的 5 个模板，支持点击打开详情。
- 搜索结果和分类结果按 usageCount 降序排序，更容易找到常用模板。
- 最近使用模板被删除后点击提示"这个模板当前不存在，可能已被移除或重命名。"。
- 搜索或分类筛选时不显示常用/最近使用区域，避免页面混乱。
- 不接 AI API，不保存 AI 返回，不保存变量输入历史。

### 验收标准

- 复制 Prompt 后 usageCount 增加。
- 复制 Prompt 后最近使用出现。
- 常用 Prompt 区按 usageCount 显示前 5 个使用过的模板。
- 最近使用点击能打开模板详情。
- 搜索 + 分类筛选仍正常。
- 错题/复盘 initialValues 入口不受影响。
- 备份 schema 和 exportVersion 不变。
- Debug / Release 构建通过。

### 不做什么

- 不接 AI API。
- 不做聊天窗口。
- 不保存 AI 返回。
- 不保存变量输入历史。
- 不做模型选择器。
- 不做云同步或账号。
- 不引入第三方依赖。
- 不改 SwiftData 模型字段类型。
- 不改变备份 schema。
- 不改变 exportVersion。
- RecentPromptStore 不纳入备份导出。

## Stage 20：未来扩展：AI API、RAG、GoodNotes/NotebookLM 索引、macOS 端、云同步

### 目标

在本地学习闭环、备份导出和备份校验稳定后，再评估更强的自动化和跨端能力。

### 需要修改/新增的内容

- AI API 接入。
- Prompt 结果回写。
- 本地资料索引或 RAG。
- GoodNotes / NotebookLM 资料索引。
- macOS 端。
- iCloud 或其他云同步。

### 验收标准

- 任何扩展都不破坏离线核心流程。
- AI 能提升错题手术和复盘质量，而不是替代思考。
- 云同步不会引入账号和隐私负担。
- macOS / Web 端明确服务真实使用场景。

### 不做什么

- 不在基础流程稳定前引入 AI API。
- 不为了技术好看而做 RAG。
- 不把个人自用 App 变成大型平台。
- 不牺牲本地优先和隐私边界。
