# Restore Strategy / 恢复策略

This document explains the conservative restore strategy for future import support. Current app behavior is still limited to strategy, fixtures, import dry-run, and restore-plan preview. The app does not perform true restore, does not write SwiftData during dry-run, does not restore mistake image files, and does not overwrite user data.

## 当前能力声明

- 当前实现不做真实恢复。
- 当前实现只做恢复策略文档、fixture、导入 dry-run 和 restore plan 预览。
- Dry-run 不调用 `ModelContext.insert`、`delete` 或 `save`。
- Dry-run 不把图片写入 `Application Support/MistakeImages/`。
- 当前实现不接 AI API、不做云同步、不做账号、不做加密、不做 zip。

## 推荐恢复策略

未来真正恢复的默认策略应采用 `merge-with-new-ids`。

不建议直接覆盖本地数据。覆盖导入很容易误删当前学习记录，也会让用户在恢复前承担过高风险。第一版真实恢复建议只支持“合并导入”，不支持覆盖导入。

也不建议保留备份中的原 UUID 直接插入，除非目标 SwiftData 主库为空，且用户明确选择“完整恢复”。普通恢复应为每条导入记录生成新 UUID，并维护一张临时 oldID -> newID 映射表。

## ID 映射策略

恢复时先生成所有需要插入记录的新 ID，再按依赖顺序更新引用。

- `DayPlan`: `oldID -> newID`。
- `StudyTask.dayPlanId` 根据 `DayPlan` 映射更新；如果目标 DayPlan 被跳过或缺失，任务进入引用修复，不默认等同于跳过。
- `StudyTask`: `oldID -> newID`。
- `FocusSession.taskId` 根据 `StudyTask` 映射更新；如果目标任务被跳过或缺失，专注记录进入引用修复，不默认等同于跳过。
- `MistakeRecord`: `oldID -> newID`。
- `DailyReview.bestMistakeId` 根据 `MistakeRecord` 映射更新；如果目标错题被跳过或缺失，复盘进入引用修复，不默认等同于跳过。
- `WeeklyReview` 独立恢复，不依赖其他 ID。
- `PromptTemplate` 内置模板需要谨慎处理，默认跳过；自定义模板可以导入并生成新 ID。
- `ResourceItem` 可按新 ID 合并导入，URI 是否仍有效只作为 warning。

## 冲突策略

第一版真实恢复建议采用保守策略：宁可跳过疑似重复，也不覆盖本地记录。

### 重复冲突（duplicate conflict）

| 类型 | 冲突判断 | 默认决策 |
| --- | --- | --- |
| `DayPlan` | `dayKey` 重复 | 跳过备份中的重复 DayPlan；未来 UI 可支持 duplicate marker 并让用户选择 |
| `StudyTask` | `dayKey + title` 重复 | 跳过重复任务 |
| `MistakeRecord` | fingerprint 重复 | 跳过疑似重复错题 |
| `PromptTemplate` | `isBuiltIn == true` | 跳过内置模板；自定义模板可导入 |
| `ResourceItem` | ID 或 URI 风险 | 默认按新 ID 导入，URI 失效只作为 warning |
| `DailyReview` | `dayKey` 重复 | 跳过，避免覆盖本地复盘 |
| `WeeklyReview` | `weekStartKey` 重复 | 跳过，避免覆盖本地复盘 |

### Invalid Reference（引用断裂）

当前 restore-plan 语义中，invalid reference 不再默认等同于 skipped。它在 restore plan 中被单独归入 `referenceRepairSummary`（needsReview / referenceRepairNeeded），以便未来真实恢复时可以选择：

- **置空引用后保留记录**：例如 `StudyTask.dayPlanId` 设为 `nil`，`DailyReview.bestMistakeId` 设为 `nil`。
- **重新映射引用**：如果用户先在本地创建了对应记录，可手动把引用指向本地已有 ID。
- **人工确认**：在恢复 UI 中逐条展示断裂引用，让用户决定保留、修复或跳过。
- **跳过**：如果确认不需要这些记录，最后再选择跳过。

| 断裂类型 | 判断方式 | 当前处理 |
| --- | --- | --- |
| `StudyTask.dayPlanId` 指向备份内不存在的 DayPlan | 遍历 `studyTasks`，检查 `dayPlanId` 是否在 `dayPlans.id` 集合中 | 计入 `studyTasksWithMissingDayPlan`，planned insert 不扣减 |
| `FocusSession.taskId` 指向备份内不存在的 StudyTask | 遍历 `focusSessions`，检查 `taskId` 是否在 `studyTasks.id` 集合中 | 计入 `focusSessionsWithMissingTask`，planned insert 不扣减 |
| `DailyReview.bestMistakeId` 指向备份内不存在的 MistakeRecord | 遍历 `dailyReviews`，检查 `bestMistakeId` 是否在 `mistakeRecords.id` 集合中 | 计入 `dailyReviewsWithMissingBestMistake`，planned insert 不扣减 |

### 不支持的版本与图片恢复失败

| 类型 | 判断方式 | 默认决策 |
| --- | --- | --- |
| `unsupported version` | `exportVersion` 或 `exportSchemaVersion` 不是当前支持的值 | `validationErrors` 非空，`isSafeToProceed` 为 `false` |
| `image restore failure` | `mistakeImages` 中缺少 `base64JPEG` 或 decode 失败 | 文本记录仍可恢复，图片缺失写入 warnings |

错题 fingerprint 使用 Stage 13 dry-run 的轻量规则：`subject + chapter + source + questionText 前 80 字`。它只用于疑似重复提示，不应作为强一致身份。

## 风险分类表

| 类型 | 判断方式 | 当前分类 | 默认决策 |
| --- | --- | --- | --- |
| duplicate conflict | `dayKey`、同日同名任务、错题 fingerprint、复盘 key 或内置 Prompt 重复 | `skippedSummary` | 默认跳过疑似重复，避免覆盖本地记录 |
| invalid reference | 记录引用了备份中不存在的 DayPlan、StudyTask 或 MistakeRecord | `referenceRepairSummary` / needs review | 不默认跳过；未来恢复前选择置空、重新映射或人工确认 |
| unsupported version | `schemaName`、`exportVersion` 或 `exportSchemaVersion` 不支持 | `errors`，`isSafeToProceed = false` | 不建议继续恢复，需迁移或重新导出 |
| image restore failure | 图片缺少 base64、decode 失败或文件写入失败 | `imagePlanSummary` / warnings | 不阻塞文本记录恢复，图片失败单独提示 |

## 图片恢复策略

未来真实恢复图片时，应在文本记录恢复计划之外单独处理图片文件。

- 从 `mistakeImages[].base64JPEG` decode 成 `Data`。
- 保存到 `Application Support/MistakeImages/`。
- 文件名必须重新生成，例如 `mistake-<newMistakeId>-<timestamp>.jpg`，避免覆盖本地已有图片。
- 恢复后的 `MistakeRecord.questionImagePath` 更新为新的相对路径，例如 `MistakeImages/<new-file-name>.jpg`。
- 图片 decode 或写入失败不阻塞文本记录恢复，但必须写入 warnings。
- 图片文件不写入 SwiftData；SwiftData 只保存恢复后的相对路径。
- 如果某条 `MistakeRecord.questionImagePath` 在备份中找不到对应 `mistakeImages.relativePath`，文本记录仍可恢复，但图片缺失需要 warning。

当前 dry-run 不执行以上文件写入，只统计 `incomingImages`、`validImages`、`missingImages` 和 `estimatedBytes`。

## 恢复前后对账

真实恢复前后都应生成对账摘要：

- incoming counts：备份中各类记录数量。
- planned insert counts：计划插入的各类记录数量。
- skipped counts：按原因跳过的数量。
- warning counts：非阻塞风险数量。
- restored image counts：成功恢复的图片数量。
- failed image counts：失败的图片数量。

恢复后应再次读取本地 SwiftData 计数，与计划插入数量对账。任何失败都应展示为可复制的错误/警告摘要。

## 安全策略

- 恢复前要求用户手动导出当前备份。
- 恢复操作需要二次确认。
- 第一版真实恢复只支持“合并导入”，不支持覆盖导入。
- 默认使用 `merge-with-new-ids`。
- 不在恢复过程中删除或覆盖本地现有记录。
- 不把图片写入 SwiftData，只保存图片相对路径。
- 如果 dry-run 存在 schema、version、summary 或 checksum 错误，不建议继续恢复。
