# Gaokao Cockpit / 高考驾驶舱

Gaokao Cockpit 是一个 local-first 的个人学习操作系统，帮助中国高中生把每天的学习固定成“启动、计划、专注、记录、错题手术、Prompt 调用、复盘、明日继续”的稳定闭环。

## 为什么做这个 App

面向 2028 年高考冲击 700 分与清北级别录取的学生，每一天都需要高质量执行，而不是只拥有很多学习想法。

当前 AI 辅助学习的常见问题是：

- 想法很多，但入口分散。
- 计划、计时、错题、Prompt、复盘分散在不同工具里。
- 错题容易变成收藏夹，而不是真正被拆解和复练。
- 状态差时没有保底流程，容易整天失控。
- AI 容易被当作答案机，而不是学习教练组。

这个 App 的目标不是做大型教育平台，而是做一个个人自用的每日学习驾驶舱，让学习流程每天都能重新启动。

## 它解决什么问题

Gaokao Cockpit 解决的是“每天怎么开始、怎么推进、怎么记录、怎么复盘、怎么明天继续”的执行问题。

它把每天真正需要的学习动作固定下来：

```text
启动
  -> 今日计划
  -> 学习任务
  -> 专注计时
  -> 做题记录
  -> 错题手术
  -> Prompt 生成与复制
  -> 每日复盘
  -> 周复盘
  -> 明日第一步
```

## MVP 包含什么

第一版 MVP 聚焦 iOS 原生、本地优先、个人自用：

- 今日驾驶舱：显示今日状态、主攻科目、Top 任务、保底任务、明日第一步。
- 学习任务：创建、编辑、完成、记录实际用时和产出。
- 专注记录：围绕任务开始计时，记录分心次数、完成评分、下一步。
- 错题手术：记录错题，不只是收藏题目，而是拆解错误类型、根因、信号、正确模型和变式任务。
- Prompt 仓库：内置高频学习 Prompt，一键生成并复制到剪贴板。
- 学习资料：保存教材、试卷、讲义、视频、网页等本地或外部资源索引。
- 每日复盘：总结完成、未完成、最大问题、最佳错题、明日第一步。
- 周复盘：统计学习时长、科目分布、错题类型、下周重点。

## MVP 不包含什么

为了让第一版足够稳定、足够自用，以下内容暂不做：

- 不做账号系统。
- 不做云同步。
- 不做社交、排行榜、打卡广场。
- 不接 AI API。
- 不做自动批改。
- 不做 RAG 知识库。
- 不做 GoodNotes / NotebookLM 自动索引。
- 不做 macOS / Web / 后端。
- 不做复杂权限、班级、老师、家长端。
- 不做大型教育平台式课程体系。

## 当前阶段状态

当前已完成 Stage 15：Restore Plan Semantics / 恢复计划语义修正与风险分类。

当前版本保留 local-first SwiftData 存储，Today 页面可以获取或创建今日 DayPlan、编辑今日计划草稿、查看今日 StudyTask 摘要与列表，快速新增今日任务，并把 Top / 保底 / 加分计划按行生成正式 StudyTask；生成后会明确提示已添加和跳过的任务数量，并可跳转 Tasks 页查看。Tasks 页面已成为正式任务管理入口，支持新增、编辑、删除、状态切换、实际用时和产出备注，并可以从任务进入专注计时。专注结束后会生成 FocusSession，并同步 StudyTask 的实际用时、状态和产出备注，同时支持快速保存结束记录。Mistakes 页面已成为正式错题手术入口，支持记录、编辑、筛选、删除错题、上传题图、拍照保存题图、大图查看并维护复习状态，也可以从错题生成“错题手术”Prompt；只有题图没有题面文字时会提醒用户在 AI 对话中手动上传图片或补充题面。Prompt 页面已成为正式 Prompt 仓库入口，支持按分类筛选内置模板、填写变量、生成完整 Prompt 并复制到剪贴板。Reviews 页面已成为正式复盘入口，支持每日复盘快速模板、周复盘、基础汇总和复盘 Prompt 生成，并在底部提供低调的数据备份入口。备份页支持导出 JSON、验证备份结构，并可选择备份 JSON 做导入 Dry-run 预检，显示 schema/version、summary、冲突摘要、图片恢复摘要、未来恢复建议和 restore plan 预览；Stage 15 将 invalid references 单独归入 reference repair / needs review，不再默认等同于 skipped，并补充对应 fixture 与文档说明。Dry-run 和 restore plan 不写入 SwiftData、不恢复图片、不覆盖本地数据。本阶段仍不支持真正导入恢复、云同步、账号、加密、zip 或原始 sqlite 导出。

## 后续路线概览

1. Stage 0：Markdown 产品设计文档。
2. Stage 1：创建 SwiftUI + SwiftData 项目骨架。
3. Stage 2：实现数据模型与本地存储。
4. Stage 3：实现今日驾驶舱。
5. Stage 4：实现学习任务与专注计时。
6. Stage 5：实现错题手术。
7. Stage 6：实现 Prompt 仓库。
8. Stage 7：实现每日复盘与周复盘。
9. Stage 8：真实可用性补强：错题图片上传/拍照上传，Today 计划转任务。
10. Stage 9：实战体验修正：错题大图查看、Today 生成任务反馈、Focus 快速结束、Review 快速模板、错题 Prompt 图片提示。
11. Stage 10：闭环稳定性与调试入口收口：Debug 入口收口、主流程反馈优化、QA_CHECKLIST.md。
12. Stage 11：本地数据备份导出：生成单文件 JSON 备份，错题图片以 base64 嵌入，暂不支持导入恢复。
13. Stage 12：备份校验与格式策略：增加 schema、summary、integrity、checksum、导出摘要和本地结构验证。
14. Stage 13：导入恢复 Dry-run 预检：只读解析备份 JSON，显示冲突、图片可恢复性和未来恢复策略建议。
15. Stage 14：恢复策略与小规模 Fixture 测试：补齐恢复策略文档、merge-with-new-ids restore plan、fixture JSON 和人工验证说明。
16. Stage 15：Restore Plan Semantics：区分 duplicate skipped 与 invalid reference referenceRepair / needs review。
17. Stage 16：未来扩展 AI API、RAG、GoodNotes / NotebookLM 索引、macOS 端、云同步。
