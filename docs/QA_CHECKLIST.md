# Gaokao Cockpit 闭环自测清单

每次迭代后按模块人工打勾。优先验证真实学习闭环，不需要自动化测试。

## 1. 启动与 Today

- [ ] App 首次启动能进入 Today。
- [ ] Today 可创建/读取今日计划。
- [ ] 状态评分、主攻科目、三层任务、明日第一步可保存。
- [ ] 保存今日计划后有轻量成功提示。
- [ ] 从计划生成任务可添加到 Tasks。
- [ ] 重复任务会跳过。
- [ ] 生成任务结果显示已添加/跳过数量。
- [ ] 查看任务页按钮能跳到 Tasks。
- [ ] DEBUG 构建中 Today 底部可展开开发诊断。
- [ ] Release 构建中 Today 不显示开发诊断入口。

## 2. Tasks

- [ ] 可新增任务。
- [ ] 可编辑任务。
- [ ] 可删除任务。
- [ ] 删除任务前有确认提示。
- [ ] 可切换 pending / inProgress / done / skipped。
- [ ] 任务状态切换后显示中文状态，保存后重进页面仍正常。
- [ ] 旧中文任务分类和新英文 category 存储值都能显示为中文分类。
- [ ] Today 生成的任务能显示。
- [ ] 无任务时提示可从 Today 生成或手动添加。
- [ ] 重启 App 后任务仍存在。

## 3. Focus

- [ ] 可从任务进入 Focus。
- [ ] 可开始计时。
- [ ] 可暂停/继续。
- [ ] 可记录分心次数。
- [ ] 快速保存可结束专注。
- [ ] 快速保存会返回任务页。
- [ ] 实际分钟小于 1 时按 1 分钟保存。
- [ ] 实际分钟能同步到 StudyTask。
- [ ] outputNote 追加不覆盖旧内容。

## 4. Mistakes

- [ ] 可新建错题。
- [ ] 可从相册选择题图。
- [ ] 可拍照上传题图。
- [ ] 可预览大图。
- [ ] 图片读取失败时提示清楚。
- [ ] 可删除题图。
- [ ] 删除题图前有确认提示。
- [ ] 可填写根因、题目信号、正确模型、变式任务。
- [ ] 可筛选科目/复习状态。
- [ ] 错题类型 Picker 和复习状态筛选仍正常。
- [ ] 旧中文科目/错题类型/复习状态数据不会导致列表或编辑页崩溃。
- [ ] 可删除错题。
- [ ] 删除错题前有确认提示。
- [ ] 无错题时提示先拍题图、再拆错因。
- [ ] 重启后错题和图片仍可读取。

## 5. Prompts

- [ ] Prompt 模板列表显示。
- [ ] 分类筛选正常。
- [ ] Prompt 分类筛选能兼容内置中文 seed 分类。
- [ ] 变量填写正常。
- [ ] 变量为空时使用“未提供”。
- [ ] 生成 Prompt 正常。
- [ ] 复制到剪贴板正常。
- [ ] 复制成功后提示“已复制，可以粘贴到 AI 工具了。”。
- [ ] 从错题生成 Prompt 能预填变量。
- [ ] 只有题图无题面时提示正确。
- [ ] 无模板时提示检查 seed。

## 6. Reviews

- [ ] 每日复盘可保存。
- [ ] 快速复盘模板只填空字段。
- [ ] 未填写字段显示为空状态/占位文案，不像错误。
- [ ] 保存每日复盘后提示“复盘已保存，明日第一步已回流到 Today。”。
- [ ] 明日第一步能回流 Today。
- [ ] 周复盘可保存。
- [ ] 周统计基础数字显示合理。
- [ ] 每日复盘 Prompt 可生成和复制。
- [ ] 周复盘 Prompt 可生成和复制。

## 7. 数据备份

- [ ] Reviews 底部能打开数据备份页。
- [ ] 能导出 JSON 备份文件。
- [ ] Stage 16 后备份导出仍通过，schema/version/exportVersion 不变。
- [ ] 导出完成后能打开分享面板。
- [ ] 导出结果显示各类记录数量。
- [ ] 导出结果显示文件名、导出时间、错题图片数量、图片总大小和 warnings 数量。
- [ ] 导出结果显示 checksum 前 12 位。
- [ ] checksum 说明清楚：基于 checksum 字段为空时的备份内容，不是加密签名。
- [ ] 导出后可验证刚生成的备份文件。
- [ ] 验证结果能显示可读/不可读、schema、version、数量一致性、warnings 和 errors。
- [ ] `recordSummary` 中的记录数量与 JSON 数组实际数量一致。
- [ ] `mistakeImageCount` 与 `mistakeImages.count` 一致。
- [ ] `warningCount` 与 `warnings.count` 一致。
- [ ] checksum 校验结果显示合理。
- [ ] 有图片错题时，导出文件包含 `mistakeImages`。
- [ ] 图片缺失时显示 warnings，且不导致导出失败。
- [ ] UI 明确说明不支持真正导入恢复。
- [ ] 能选择 JSON 备份文件做导入 Dry-run。
- [ ] 能解析刚导出的备份文件。
- [ ] 能显示 incoming summary 和 local summary。
- [ ] 能显示 ID、dayKey、同日同名任务和错题 fingerprint 冲突摘要。
- [ ] 能显示错题图片恢复摘要。
- [ ] Dry-run 后能看到“未来恢复计划预览”。
- [ ] Restore plan 显示 `merge-with-new-ids` 策略。
- [ ] Restore plan 显示 planned/skipped counts。
- [ ] Restore plan 能区分 duplicate skipped 和 invalid reference needsReview / referenceRepair。
- [ ] invalid references 有明确 UI 文案，说明不会在预检中被直接判定为跳过。
- [ ] invalid references 不会让 planned counts 自动减少。
- [ ] Restore plan 明确说明本阶段不会写入数据。
- [ ] `fixtures/backups/minimal-valid-backup.json` 可解析并显示 summary。
- [ ] `fixtures/backups/duplicate-conflict-backup.json` 可解析；本地存在相同样本时能显示冲突。
- [ ] `fixtures/backups/invalid-reference-backup.json` 可解析，并在“需要处理的引用”区域显示 3 条引用修复。
- [ ] Dry-run 和 restore plan 不改变本地数据数量。
- [ ] Dry-run 后本地数据数量不改变。
- [ ] 导入预检不写入 SwiftData。
- [ ] 选择错误文件或损坏 JSON 不会崩溃。
- [ ] UI 明确说明 Dry-run 不会导入数据。

## 8. 持久化

- [ ] 重启 App 后 Today / Tasks / Mistakes / Reviews 数据仍在。
- [ ] 内置 Prompt 不重复 seed。
- [ ] 图片文件路径可读取。

## 9. 构建

- [ ] `xcodebuild -project GaokaoCockpit.xcodeproj -scheme GaokaoCockpit -configuration Debug -destination 'generic/platform=iOS Simulator' build` 通过。
- [ ] `xcodebuild -project GaokaoCockpit.xcodeproj -scheme GaokaoCockpit -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build` 通过。
- [ ] `xcodebuild -project GaokaoCockpit.xcodeproj -scheme GaokaoCockpit -configuration Release -destination 'generic/platform=iOS Simulator' build` 通过。
- [ ] `git diff --check` 通过。
