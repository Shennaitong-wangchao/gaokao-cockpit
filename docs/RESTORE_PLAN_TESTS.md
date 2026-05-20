# Restore Plan Tests / Restore Plan 测试说明

This document describes manual fixture checks for backup import dry-run and restore-plan preview. Fixture files are intentionally small and synthetic; do not add real exported backups or private study records to this repository.

当前项目没有测试 target。现阶段不为了 restore plan 新增测试 target，避免扩大 Xcode 工程复杂度；验证重点放在 fixture、导入 dry-run UI 和纯函数 `BackupRestorePlanBuilder` 的构建结果。

## 手动验证 fixture

1. 运行 App Debug 构建。
2. 进入 Reviews 页面底部的“数据与备份”。
3. 在“导入预检（Dry-run）”中选择 `fixtures/backups/minimal-valid-backup.json`。
4. 确认 UI 能解析文件，并显示 incoming summary、local summary、冲突摘要、图片恢复摘要和“未来恢复计划预览”。
5. 再选择 `fixtures/backups/duplicate-conflict-backup.json`，确认冲突摘要和 restore plan skipped counts 能显示。
6. 再选择 `fixtures/backups/invalid-reference-backup.json`，确认 `referenceRepairSummary` 区域显示：StudyTask 缺失 DayPlan、FocusSession 缺失 Task、DailyReview 缺失 Mistake，且 planned insert counts 不因 invalid references 而扣减。
7. 再选择 `fixtures/backups/invalid-reference-backup.json`，确认 invalid references 显示在“需要处理的引用”区域，而不是 skipped。

## minimal-valid-backup 预期

`minimal-valid-backup.json` 包含：

- 1 个 `DayPlan`
- 2 个 `StudyTask`
- 1 个 `FocusSession`
- 1 个 `MistakeRecord`
- 1 个 `DailyReview`
- 1 个 `mistakeImage`

在没有本地重复数据时，dry-run 应显示这些 incoming counts。Restore plan 应显示：

- 策略为 `merge-with-new-ids`
- `DayPlans` 预计插入 1
- `StudyTasks` 预计插入 2
- `FocusSessions` 预计插入 1
- `Mistakes` 预计插入 1
- `Reviews` 预计插入 1
- `Images` 预计恢复 1
- 内置 Prompt 跳过 0

fixture 的 checksum 可用于结构测试，不作为正式备份完整性保证。如果 checksum 与当前编码策略不匹配，dry-run 仍应显示 validation error，并且 restore plan 的 `isSafeToProceed` 应为“否”。

## invalid-reference-backup 预期

`invalid-reference-backup.json` 包含：

- 1 个 `StudyTask` 指向不存在的 `DayPlan.id`
- 1 个 `FocusSession` 指向不存在的 `StudyTask.id`
- 1 个 `DailyReview` 的 `bestMistakeId` 指向不存在的 `MistakeRecord.id`
- schema/version 合法

Restore plan 应显示：

- `studyTasksWithMissingDayPlan` = 1
- `focusSessionsWithMissingTask` = 1
- `dailyReviewsWithMissingBestMistake` = 1
- `totalRecordsNeedingRepair` = 3
- `skippedSummary.invalidReferences` = 0（不再计入 skipped）
- `plannedSummary.studyTasksToInsert` 不因为 invalid reference 自动减少
- `plannedSummary.focusSessionsToInsert` 不因为 invalid reference 自动减少
- `plannedSummary.dailyReviewsToInsert` 不因为 invalid reference 自动减少
- warnings 中包含引用修复策略说明

## duplicate-conflict-backup 预期

`duplicate-conflict-backup.json` 使用容易与本地样本冲突的 `dayKey`、任务标题和错题 fingerprint。若本地已有相同日期计划、同日同名任务或相同错题内容，dry-run 应显示：

- `dayKey` 冲突数量增加。
- `同日同名任务` 冲突数量增加。
- `错题 fingerprint` 冲突数量增加。
- Restore plan 中重复 DayPlan、重复任务、重复错题的 skipped counts 增加。

如果本地没有对应样本，fixture 仍可解析，但冲突数量可能为 0。这是 dry-run 与当前本地数据比较的正常结果。

## 不写入验证

当前 dry-run 不写入 SwiftData，也不恢复图片。验证方式：

- Dry-run 前记录导出页显示的 local summary。
- 选择 fixture 完成 dry-run。
- 再次导出或重新进入 dry-run，确认本地 DayPlan、StudyTask、FocusSession、MistakeRecord、Review 数量没有变化。
- 检查 `Application Support/MistakeImages/` 不会因为 dry-run 生成新图片文件。

## Restore Plan 关键逻辑

`BackupRestorePlanBuilder.buildPlan(envelope:dryRun:)` 是纯函数：

- 不访问 `ModelContext`。
- 不写 SwiftData。
- 不写图片文件。
- 不生成真实 UUID。
- 基于 incoming summary、dry-run conflict summary 和 image summary 生成 planned/skipped/mapping/image 统计。
- duplicate conflict 和内置 Prompt 进入 `skippedSummary`。
- invalid reference 进入 `referenceRepairSummary`，不再默认等同于 skipped。
- planned counts 不会仅因为 invalid reference 自动减少。
- 如果 `dryRun.validationErrors` 非空，`isSafeToProceed` 为 `false`，errors 原样带入 plan。
