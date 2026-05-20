# 文档索引 / Documentation

这里是高考驾驶舱的公开文档目录，面向使用者、贡献者和维护者。读文档的目标不是背完所有设计，而是快速理解：这个 App 解决什么问题、现在做到哪一步、改代码时要守住哪些边界。

## 推荐阅读顺序

1. [产品说明](PRODUCT_SPEC.md)：项目定位、目标用户、MVP 范围和非目标。
2. [架构说明](ARCHITECTURE.md)：App 结构、数据流、Store/helper 边界和备份边界。
3. [数据模型](DATA_MODEL.md)：SwiftData 领域模型、字段和关系策略。
4. [体验流程](UX_FLOW.md)：主要用户旅程和页面意图。
5. [Prompt 模板](PROMPT_TEMPLATES.md)：内置模板、自定义模板和变量规则。
6. [备份格式](BACKUP_FORMAT.md)：本地 JSON 备份 envelope、校验和限制。
7. [恢复策略](RESTORE_STRATEGY.md)：未来导入恢复的安全策略。
8. [Restore Plan 测试说明](RESTORE_PLAN_TESTS.md)：基于 fixture 的手动验证方法。
9. [QA 清单](QA_CHECKLIST.md)：每次迭代或发布前的人工回归清单。
10. [路线图](ROADMAP.md)：已完成阶段和未来方向。
11. [Stage 3 Today 设计](STAGE3_TODAY_DESIGN.md)：历史设计资料，仅作背景参考。

## 文档维护原则

- 明确 local-first 和隐私边界。
- 优先写清楚真实用户流程，不堆抽象平台词。
- 历史阶段文档要标注为历史资料。
- 用户可见行为变化，应同步更新文档和 QA 清单。
- 不提交真实学习记录、真实导出备份、密钥或个人设备路径。

## 当前检查点

当前实现检查点是 Stage 20：已支持自定义 Prompt 模板。

Stage 21 中的 AI API、RAG、云同步、macOS 等方向仍是未来扩展，不代表已经进入开发范围。进入这些方向前，应先拆成更小的设计提案，并继续守住本地优先和隐私边界。
