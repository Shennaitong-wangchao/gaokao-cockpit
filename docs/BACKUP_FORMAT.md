# Backup Format / 备份格式

当前备份格式用于本地 JSON 导出，目标是让学习数据可保存、可阅读、可校验。当前实现支持导出、结构验证、导入 Dry-run 预检和未来恢复计划预览，并能区分 duplicate skipped 与 invalid reference needs review；仍不支持真正导入恢复，不会写入 SwiftData，也不会覆盖现有数据。

Backups can contain private study records and embedded mistake images. Do not publish real exported backups in issues, pull requests, fixtures, or documentation.

恢复策略另见 [RESTORE_STRATEGY.md](RESTORE_STRATEGY.md)。Restore plan 验证说明另见 [RESTORE_PLAN_TESTS.md](RESTORE_PLAN_TESTS.md)。

## 文件形态

- 文件名格式：`gaokao-cockpit-backup-YYYYMMDD-HHmmss.json`
- 文件内容：单个 JSON 对象 `GaokaoBackupEnvelope`
- 编码方式：`JSONEncoder` pretty printed + sorted keys，日期使用 ISO 8601
- 不包含原始 SwiftData sqlite
- 不使用 zip、加密、云同步或第三方依赖

## Envelope 元数据

顶层 envelope 包含：

- `appName`：应用名称。
- `appVersion`：导出时的 App 版本与 build。
- `exportVersion`：备份导出版本，目前为 `1`。
- `schemaName`：固定为 `GaokaoCockpitBackup`。
- `exportSchemaVersion`：更明确的备份结构版本，目前为 `1`。
- `exportedAt`：导出时间。
- `notes`：格式说明与限制。
- `recordSummary`：各类记录数量摘要。
- `integrity`：checksum、图片总大小、缺失图片数、warnings 数。
- `warnings`：导出过程中的非致命提醒，例如题图路径无效或读取失败。

`exportVersion` 和 `exportSchemaVersion` 当前都只支持 `1`。未来如果只增加可选字段，应保持旧字段不重命名、不删除；如果数组结构或字段语义发生不兼容变化，应提升 `exportSchemaVersion` 并在导入恢复前提供迁移策略。

## 导出的数据类型

备份 JSON 保留以下数组：

- `dayPlans`
- `studyTasks`
- `focusSessions`
- `mistakeRecords`
- `promptTemplates`
- `resourceItems`
- `dailyReviews`
- `weeklyReviews`
- `mistakeImages`

`recordSummary` 中的数量应与这些数组的实际长度一致。Stage 12 的本地校验会检查这些数量。

## 错题图片

错题图片不导出为独立文件，而是在 `mistakeImages` 数组中嵌入：

- `relativePath`：原错题记录中的本地相对路径。
- `fileName`：导出时读取到的图片文件名。
- `base64JPEG`：图片数据的 base64 字符串。
- `byteCount`：图片原始字节数。

如果某条错题记录有图片路径，但文件缺失、路径无效或读取失败，该图片不会写入 `mistakeImages`，导出会继续完成，并在 `warnings` 中记录原因。

## Checksum 策略

`integrity` 包含：

- `jsonPayloadSHA256`
- `payloadWithoutChecksumSHA256`
- `imageTotalBytes`
- `missingImageCount`
- `warningCount`

由于 checksum 写入 JSON 本身会改变 JSON 内容，当前采用稳定可实现的策略：先生成 checksum 字段为空的 envelope，encode 成 JSON Data 后计算 SHA256，再把 hash 写回 `payloadWithoutChecksumSHA256`，并同步写入 `jsonPayloadSHA256` 作为可读镜像。

因此，checksum 表示“checksum 字段为空时的备份内容”的 SHA256，用于检测导出流程是否稳定、文件内容是否与记录的 hash 匹配。它不是加密签名，不能证明文件来源，也不能防止人为篡改。

## 导入 Dry-run 与 Restore Plan 策略

当前导入预检只做只读 dry-run。用户选择一个备份 JSON 后，App 会读取文件、解析 `GaokaoBackupEnvelope`，并复用本地校验逻辑检查 schema、version、checksum 和 record summary 是否合理。

Dry-run 会比较备份数据与当前本地数据：

- 检查各模型 UUID 是否与本地同类记录冲突。
- 检查 `DayPlan.dayKey` 是否与本地已有日期计划冲突。
- 检查 `StudyTask` 是否存在同 `dayKey + title` 的疑似重复。
- 检查错题 fingerprint 是否疑似重复。fingerprint 使用 `subject + chapter + source + questionText 前 80 字`。
- 检查 `DailyReview.dayKey` 和 `WeeklyReview.weekStartKey` 是否与本地复盘冲突。
- 检查 `mistakeImages` 中有多少图片带有 base64、缺失 base64，以及预计可恢复的图片字节数。

Dry-run 后会生成一个纯结构 `BackupRestorePlan` 预览。该 plan 默认策略为 `merge-with-new-ids`，只统计 incoming、planned inserts、skipped、reference repair、ID mapping 和 image plan，不生成真实新 UUID，不写文件，也不访问 `ModelContext`。

当前 `BackupRestorePlan` 包含 `referenceRepairSummary`：

- `studyTasksWithMissingDayPlan`
- `focusSessionsWithMissingTask`
- `dailyReviewsWithMissingBestMistake`
- `totalRecordsNeedingRepair`

这些字段只存在于 dry-run / restore plan 级别，用于说明未来真实恢复前需要处理的引用修复风险，不改变备份 JSON 文件格式，也不会写入 SwiftData。为保持旧 plan 消费方兼容，`skippedSummary.invalidReferences` 字段保留，但当前 builder 不再把 invalid references 默认归入 skipped。

Dry-run 和 restore plan 不会调用 `context.insert`、`context.delete` 或 `context.save`，不会写入 SwiftData，不会恢复图片文件，也不会覆盖现有数据。未来真正恢复建议优先使用 `merge-with-new-ids`，而不是原 ID 覆盖；同日计划、同名任务、疑似重复错题和重复复盘应默认跳过或进入人工确认。

## Fixture 说明

小规模 fixture 用于结构解析、dry-run 和 restore plan 人工验证：

- `fixtures/backups/minimal-valid-backup.json`：包含 1 个 DayPlan、2 个 StudyTask、1 个 FocusSession、1 个 MistakeRecord、1 个 DailyReview 和 1 个 mistakeImage。
- `fixtures/backups/duplicate-conflict-backup.json`：包含容易与本地样本冲突的 dayKey、任务标题、错题 fingerprint、复盘 key，以及一个内置 PromptTemplate。
- `fixtures/backups/invalid-reference-backup.json`：包含缺失 DayPlan 的 StudyTask、缺失 Task 的 FocusSession 和缺失 Mistake 的 DailyReview，用于验证 `referenceRepairSummary`。

Fixture 文件保持很小，错题图片使用极小 base64 占位。Fixture 的 checksum 字段可为空或占位，仅用于结构测试，不代表真实导出文件的完整性保证。

## 当前限制

- 支持导出、结构验证、导入 Dry-run 预检和 restore plan 预览，不支持真正导入恢复。
- 只支持验证 Gaokao Cockpit 本地 JSON 备份文件结构。
- 不写入 SwiftData。
- 不恢复错题图片文件。
- 不做云同步、账号、加密、zip 或原始 sqlite 导出。
- 不接 AI API。
- invalid references 只在 restore plan 中标记为 needsReview，不做自动修复或跳过。

## 未来导入恢复需要解决的问题

导入恢复不能直接把 JSON 写回数据库。正式支持前至少需要设计：

- ID 冲突：导入数据与本机现有 `UUID` 重复时如何处理。
- 重复数据：同一任务、错题、复盘是否跳过、合并或保留副本。
- 图片文件恢复：base64 图片如何重新写入本地 `MistakeImages` 目录并更新路径。
- 覆盖 vs 合并：用户是否要替换当前数据，还是合并到现有数据。
- 版本迁移：旧 `exportVersion` / `exportSchemaVersion` 如何升级到当前模型。
