# 高考驾驶舱 / Gaokao Cockpit

高考驾驶舱是一个 **本地优先、隐私优先的 iOS 学习驾驶舱**。它不是题库、课程平台或打卡社区，而是把每天真正要做的学习动作固定成一个闭环：启动、计划、专注、记录、错题手术、Prompt 生成、复盘、明日继续。

English summary: Gaokao Cockpit is a local-first SwiftUI study cockpit for exam planning, focus sessions, mistake review, prompt templates, and local backups.

## 当前状态

当前实现进度：Stage 20 已完成。

已经具备的核心能力：

- 今日驾驶舱：记录今日状态、主攻科目、Top / 保底 / 加分任务、明日第一步。
- 学习任务：新增、编辑、删除、切换状态、记录实际用时和产出备注。
- 专注记录：围绕任务开始专注，支持暂停/继续、分心次数、完成评分、本轮产出和下一步。
- 错题手术：记录题面文字、题图、错因、根因、题目信号、正确模型、变式任务和复习状态。
- Prompt 仓库：内置 51 个学习 Prompt 模板，支持搜索、分类、常用/最近使用、自定义模板、变量提取、生成和复制。
- 每日/周复盘：记录完成情况、未完成原因、最大问题、周复盘重点，并把“明日第一步”带回 Today。
- 本地备份：导出 JSON、校验备份、导入 Dry-run 预检、冲突摘要、图片恢复摘要和未来 restore plan 预览。

暂不支持：

- 真正导入恢复。
- 账号系统。
- 云同步。
- 加密备份。
- OCR。
- 自动批改。
- AI 聊天窗口。
- AI API 调用。

## 为什么做这个项目

很多学习系统最后会变成“又一个需要维护的系统”。高考驾驶舱想解决的是更朴素的问题：每天打开后，马上知道今天怎么开始、接下来做什么、做完如何收束，以及明天第一步是什么。

核心闭环：

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

目标不是做大型教育平台，而是做一个可靠、克制、能每天使用的个人学习操作台。

## 设计原则

- 本地优先：核心学习数据保存在设备上。
- 默认离线可用：没有网络也能完成主要学习闭环。
- MVP 不做账号、不做后端、不做云同步。
- AI 是辅助，不是依赖：App 只在本地生成 Prompt，用户复制到自己使用的 AI 工具中。
- 错题不是收藏夹，而是诊断材料。
- 输入成本要低，流程要能每天跑起来。
- 状态差时也要有保底路径。

## 技术栈

- Swift
- SwiftUI
- SwiftData
- iOS 17+
- Xcode / iOS Simulator

当前没有第三方包依赖。

## 如何运行

1. 克隆仓库。
2. 用 Xcode 打开 `GaokaoCockpit.xcodeproj`。
3. 选择 `GaokaoCockpit` scheme。
4. 选择一个 iOS Simulator。
5. Build & Run。

命令行构建：

```bash
xcodebuild \
  -project GaokaoCockpit.xcodeproj \
  -scheme GaokaoCockpit \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 仓库结构

```text
GaokaoCockpit/
  Models/       SwiftData 模型和状态枚举 wrapper
  Stores/       SwiftData 查询 helper、Prompt 渲染、备份逻辑
  Views/        SwiftUI 页面和组件
  Resources/    App 图标和资源
docs/           产品、架构、数据模型、备份、QA、路线图文档
fixtures/       用于 dry-run / restore plan 的小型合成备份样例
```

## 文档入口

建议从这里开始：

- [文档索引](docs/README.md)
- [架构说明](docs/ARCHITECTURE.md)
- [产品说明](docs/PRODUCT_SPEC.md)
- [数据模型](docs/DATA_MODEL.md)
- [体验流程](docs/UX_FLOW.md)
- [Prompt 模板](docs/PROMPT_TEMPLATES.md)
- [备份格式](docs/BACKUP_FORMAT.md)
- [恢复策略](docs/RESTORE_STRATEGY.md)
- [QA 清单](docs/QA_CHECKLIST.md)
- [路线图](docs/ROADMAP.md)

## 数据与隐私

高考驾驶舱通过 SwiftData 本地保存学习数据。错题图片保存在 App 本地文件目录中，SwiftData 只记录相对路径。备份导出会生成可读 JSON，并可能把错题图片以 base64 嵌入。

请不要公开：

- 真实个人备份。
- 真实学习记录。
- 含隐私的截图。
- 导出的 JSON 备份文件。
- `.env` 文件。
- 证书、provisioning profile、私钥或 token。
- 本地数据库文件。

## 贡献

欢迎贡献。开始前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

当前最有价值的贡献包括：

- 小而明确的 SwiftUI 易用性改进。
- 聚焦的 bug 修复。
- 文档改进。
- 备份校验与 restore plan 安全性改进。
- 带清晰复现步骤的手动 QA 报告。

## 安全

请阅读 [SECURITY.md](SECURITY.md)。不要在公开 issue 里贴真实学生数据、导出备份、token、签名材料或设备本地路径。

## 许可证

MIT，见 [LICENSE](LICENSE)。

## 免责声明

这是一个个人学习流程工具，不是官方教育产品、升学服务、医疗工具或心理健康干预工具。它可以帮助规划和复盘，但不能替代老师、监护人、专业建议和真实练习。
