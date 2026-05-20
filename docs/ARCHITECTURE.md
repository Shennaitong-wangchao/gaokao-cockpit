# 架构说明 / Architecture

高考驾驶舱是一个单 target 的 SwiftUI iOS App，围绕本地优先的学习闭环构建。当前使用 SwiftData 做本地持久化，用小型 Store/helper 承接数据访问和纯逻辑，用按功能拆分的 SwiftUI 页面承接交互。

## 架构目标

- 核心学习闭环离线可用。
- 数据所有权尽量留在设备本地。
- MVP 阶段避免后端、账号和同步复杂度。
- 长 SwiftUI 页面拆成可维护的小组件。
- 备份与恢复计划保持保守、可检查、可回滚。

## 顶层结构

```text
GaokaoCockpitApp
  -> AppModelContainerFactory
  -> PromptTemplateSeeder
  -> AppRootView
      -> TodayCockpitView
      -> TaskListView
      -> MistakeSurgeryView
      -> PromptLibraryView
      -> ReviewView
```

根导航是一个 `TabView`，包含五个主要区域：

- 今日：今日计划、状态、任务摘要、计划转任务。
- 任务：具体学习任务和状态管理。
- 错题：错题手术记录和可选本地题图。
- Prompt：内置和自定义 Prompt 模板。
- 复盘：每日/周复盘，以及数据备份入口。

## 持久化策略

SwiftData 模型位于 `GaokaoCockpit/Models`。

项目刻意使用相对简单的值类型字段，例如 `UUID`、`String`、`Date` 和 day key，而不是大量依赖 SwiftData relationship。这样做是为了让备份导出、导入 Dry-run 和未来 merge restore 更容易检查。

常见模式：

- 按日期查询使用稳定的 `yyyy-MM-dd` day key。
- 跨模型可选引用使用存储的 UUID。
- 用户可见的状态/分类在 UI 和 Store 层用 enum wrapper 收敛，但 SwiftData 中仍保存 `String`。
- 备份使用独立 Codable snapshot，不让 SwiftData `@Model` 直接承担备份格式。

## Stores 与 Helpers

Store/helper 位于 `GaokaoCockpit/Stores`。

这些类型刻意保持小而具体：

- `DayPlanStore`、`StudyTaskStore`、`FocusSessionStore`、`MistakeRecordStore`、`DailyReviewStore`、`WeeklyReviewStore` 负责聚焦的 SwiftData 查询、创建和更新。
- `PromptTemplateSeeder` 负责安全 upsert 内置模板，不覆盖用户自定义模板。
- `PromptTemplateStore`、`PromptRenderer`、`RecentPromptStore` 支持模板查询、渲染、使用次数和最近使用。
- `BackupExportStore`、`BackupValidationStore`、`BackupImportDryRunStore`、`BackupRestorePlan`、`BackupRestorePlanBuilder` 支持导出、校验、Dry-run 和未来恢复计划预览。

SwiftUI 页面应优先复用这些 helper，避免重复写 predicate、排序和保存逻辑。

## 备份与恢复边界

当前已经支持：

- 导出本地 JSON 备份。
- 校验 schema、version、数量摘要和 checksum 策略。
- 选择备份文件做导入 Dry-run，但不写入 SwiftData。
- 生成 restore plan 预览，估算 planned inserts、skipped duplicates、reference repairs 和 image recovery。

当前不支持：

- 真正导入恢复。
- 覆盖式恢复。
- Dry-run 阶段写回图片文件。
- 云同步。
- 加密层。

未来如果做真正恢复，默认策略应继续保持 `merge-with-new-ids`，并在写入前要求用户先导出一份当前备份。

## Prompt 系统

Prompt 系统只做本地渲染：

- 内置模板由 seeder 初始化和 upsert。
- 自定义模板是用户创建的 SwiftData 记录。
- 模板变量使用 `{{variableName}}`。
- 渲染时缺失变量会写成 `未提供`。
- 复制 Prompt 后会增加使用次数，并记录最近使用元数据。

App 当前不调用 AI API，也不保存 AI 返回内容。

## 图片策略

错题图片由 `MistakeImageStore` 管理为 App 本地文件。SwiftData 记录只保存相对路径，不直接存二进制图片。备份导出可以把图片 base64 嵌入 JSON；Dry-run 只估算图片可恢复性，不恢复文件。

## QA 策略

当前项目还没有 XCTest target，主要依赖手动 QA。发布或重要里程碑前，请使用 [QA_CHECKLIST.md](QA_CHECKLIST.md)。

建议的命令行构建：

```bash
xcodebuild \
  -project GaokaoCockpit.xcodeproj \
  -scheme GaokaoCockpit \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 设计约束

- 不为了 MVP 便利而引入后端。
- 不让 AI API 成为核心流程的硬依赖。
- 不提交真实学生数据或个人导出备份。
- 不在未更新文档和 QA 的情况下改变备份 schema 或 SwiftData 模型语义。
- 能做聚焦改动时，不做大范围重构。
