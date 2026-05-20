# 贡献指南 / Contributing

谢谢你愿意改进高考驾驶舱。这个项目刻意保持小而克制：本地优先、隐私优先，服务每日学习闭环。贡献也应该尽量保持这个方向。

## 适合入手的贡献

- 修复明确的 SwiftUI bug。
- 优化文案、空状态、可访问性标签或文档。
- 补充聚焦的手动 QA 记录。
- 改进备份校验、导入 Dry-run 提示或 restore plan 安全性。
- 在不引入网络依赖的前提下，改进 Prompt 模板体验。

## 开始之前

1. 阅读 [README.md](README.md)。
2. 阅读 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
3. 查看 [docs/ROADMAP.md](docs/ROADMAP.md)，确认当前范围。
4. 尽量保持改动小、清晰、可回滚。

## 本地开发

用 Xcode 打开 `GaokaoCockpit.xcodeproj`，选择 `GaokaoCockpit` scheme，在 iOS Simulator 上运行。

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

## Pull Request 检查清单

- 改动聚焦，并且有明确的用户价值或维护价值。
- 如果改了 SwiftData 模型，同步更新 `docs/DATA_MODEL.md`。
- 如果改了备份格式或恢复计划，同步更新 `docs/BACKUP_FORMAT.md` 和 `docs/RESTORE_STRATEGY.md`。
- 如果改了用户可见行为，同步更新 `docs/QA_CHECKLIST.md`。
- `git diff --check` 通过。
- Debug simulator build 通过；如果没跑，请在 PR 里说明原因。
- 没有提交私有数据、真实备份、签名文件、token、本地数据库或真实学习记录。

## 代码风格

- 跟随现有 SwiftUI 写法。
- 优先拆出小的业务组件，避免继续堆大 View 文件。
- 优先复用现有 Store/helper，不轻易引入新架构层。
- 注释保持少而有用。
- 不要在没有充分讨论的情况下引入第三方依赖。

## 隐私与安全

不要提交：

- 真实导出的备份 JSON。
- 含真实学习记录的截图。
- SwiftData sqlite/store 文件。
- `.env` 文件。
- API key、token、证书、provisioning profile 或私钥。
- 含私有记录或本地设备路径的日志。

测试和示例请使用合成数据。

## 需要先讨论的范围

以下方向风险更高，动手前请先开 issue 或设计讨论：

- 真正导入恢复。
- AI API 接入。
- OCR 或自动批改。
- 云同步。
- 账号系统。
- macOS / Web 端。
- 备份 schema 版本变化。

这些方向可能有价值，但会带来更高的数据一致性、隐私和维护风险。
