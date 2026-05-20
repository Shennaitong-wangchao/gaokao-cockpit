# Gaokao Cockpit 恢复策略设计

Stage 14 的目标是为未来真正导入恢复做准备，但当前阶段仍然只做策略、fixture、预检与 restore plan。本阶段不做真实恢复，不写入 SwiftData，不恢复错题图片文件，也不覆盖任何用户数据。

## 当前阶段声明

- Stage 14 不做真实恢复。
- Stage 14 只做恢复策略文档、fixture、导入 dry-run 和 restore plan 预览。
- Stage 14 不调用 `ModelContext.insert`、`delete` 或 `save`。
- Stage 14 不把图片写入 `Application Support/MistakeImages/`。
- Stage 14 不接 AI API、不做云同步、不做账号、不做加密、不做 zip。

## 推荐恢复策略

未来真正恢复的默认策略应采用 `merge-with-new-ids`。

不建议直接覆盖本地数据。覆盖导入很容易误删当前学习记录，也会让用户在恢复前承担过高风险。第一版真实恢复建议只支持“合并导入”，不支持覆盖导入。

也不建议保留备份中的原 UUID 直接插入，除非目标 SwiftData 主库为空，且用户明确选择“完整恢复”。普通恢复应为每条导入记录生成新 UUID，并维护一张临时 oldID -> newID 映射表。

## ID 映射策略

恢复时先生成所有需要插入记录的新 ID，再按依赖顺序更新引用。

- `DayPlan`: `oldID -> newID`。
- `StudyTask.dayPlanId` 根据 `DayPlan` 映射更新；如果目标 DayPlan 被跳过或缺失，任务需要跳过或把 `dayPlanId` 置空并提示用户。
- `StudyTask`: `oldID -> newID`。
- `FocusSession.taskId` 根据 `StudyTask` 映射更新；如果目标任务被跳过或缺失，专注记录需要跳过或作为 warning 进入人工确认。
- `MistakeRecord`: `oldID -> newID`。
- `DailyReview.bestMistakeId` 根据 `MistakeRecord` 映射更新；如果目标错题被跳过或缺失，复盘需要跳过或清空 bestMistakeId 并提示用户。
- `WeeklyReview` 独立恢复，不依赖其他 ID。
- `PromptTemplate` 内置模板需要谨慎处理，默认跳过；自定义模板可以导入并生成新 ID。
- `ResourceItem` 可按新 ID 合并导入，URI 是否仍有效只作为 warning。

## 冲突策略

第一版真实恢复建议采用保守策略：宁可跳过疑似重复，也不覆盖本地记录。

| 类型 | 冲突判断 | 默认决策 |
| --- | --- | --- |
| `DayPlan` | `dayKey` 重复 | 跳过备份中的重复 DayPlan；未来 UI 可支持 duplicate marker 并让用户选择 |
| `StudyTask` | `dayKey + title` 重复 | 跳过重复任务 |
| `MistakeRecord` | fingerprint 重复 | 跳过疑似重复错题 |
| `PromptTemplate` | `isBuiltIn == true` | 跳过内置模板；自定义模板可导入 |
| `ResourceItem` | ID 或 URI 风险 | 默认按新 ID 导入，URI 失效只作为 warning |
| `DailyReview` | `dayKey` 重复 | 跳过，避免覆盖本地复盘 |
| `WeeklyReview` | `weekStartKey` 重复 | 跳过，避免覆盖本地复盘 |

错题 fingerprint 使用 Stage 13 dry-run 的轻量规则：`subject + chapter + source + questionText 前 80 字`。它只用于疑似重复提示，不应作为强一致身份。

## 图片恢复策略

未来真实恢复图片时，应在文本记录恢复计划之外单独处理图片文件。

- 从 `mistakeImages[].base64JPEG` decode 成 `Data`。
- 保存到 `Application Support/MistakeImages/`。
- 文件名必须重新生成，例如 `mistake-<newMistakeId>-<timestamp>.jpg`，避免覆盖本地已有图片。
- 恢复后的 `MistakeRecord.questionImagePath` 更新为新的相对路径，例如 `MistakeImages/<new-file-name>.jpg`。
- 图片 decode 或写入失败不阻塞文本记录恢复，但必须写入 warnings。
- 图片文件不写入 SwiftData；SwiftData 只保存恢复后的相对路径。
- 如果某条 `MistakeRecord.questionImagePath` 在备份中找不到对应 `mistakeImages.relativePath`，文本记录仍可恢复，但图片缺失需要 warning。

Stage 14 不执行以上文件写入，只统计 `incomingImages`、`validImages`、`missingImages` 和 `estimatedBytes`。

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
