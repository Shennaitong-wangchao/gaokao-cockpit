# Stage 3 TodayCockpitView Design / 历史设计方案

This document is retained as historical design context for the Today cockpit. It helped shape the early implementation, but the current codebase has moved beyond Stage 3. For the current architecture and release status, see [ARCHITECTURE.md](ARCHITECTURE.md) and [ROADMAP.md](ROADMAP.md).

## 一、信息架构

TodayCockpitView 的核心视觉树：

```
TodayCockpitView (ScrollView)
├── HeaderSection          — 日期 + 定位文案
├── StateSection           — 状态评分 + 主攻科目（可编辑）
├── PlanSection            — Top / Baseline / Bonus 三区（可编辑）
├── ProgressSummarySection — 任务总数/已完成（只读统计）
├── TaskListSection        — 今日学习任务列表 + 快速新增入口
├── TomorrowFirstActionSection — 明日第一步（可编辑）
├── DegradedModeBanner     — 降载提示（条件显示，stateScore <= 4）
└── DebugEntrySection      — 极小的 Debug 入口（仅 Stage 3 保留）
```

注意：DayPlan 模型中 `topTasks`/`baselineTasks`/`bonusTasks` 实际存储为 `topTasksText` 等纯文本字段，不是数组。而 StudyTask 是独立的结构化任务。两者关系是：

- DayPlan 的文本字段是用户的**意图/方向**（早上写的要做什么）
- StudyTask 列表是**实际执行单元**（具体做了什么、状态如何）
- 首页同时展示两者，但编辑逻辑不同

## 二、区块顺序（从上到下）

| 序号 | 区块 | 用途 |
|------|------|------|
| 1 | HeaderSection | 今日日期 + todayKey + App 定位一行文案 |
| 2 | StateSection | stateScore 滑块 + mainSubject 选择/输入 |
| 3 | PlanSection | Top / Baseline / Bonus 三段文本编辑 |
| 4 | ProgressSummarySection | 任务总数、已完成数，一行紧凑统计 |
| 5 | TaskListSection | 今日 StudyTask 列表 + 快速新增按钮 |
| 6 | TomorrowFirstActionSection | 明日第一步文本输入 |
| 7 | DegradedModeBanner | 降载提示（条件显示） |
| 8 | DebugEntrySection | 极小入口，可能是一个 `...` 按钮 |

## 三、每个区块的详细设计

### 3.1 HeaderSection

**显示内容：**

- 日期：`5月18日 星期日`（用中文格式，不显示年份）
- todayKey：`2026-05-18`（灰色小字，辅助定位）
- App 定位一行文案：`每天启动 · 专注 · 错题 · 复盘`（灰色，footnote）

**交互：**

- 无交互，纯展示
- 日期文字使用 `.title2` 粗细

**空状态：**

- 无空状态——日期永远存在

### 3.2 StateSection

**显示内容：**

- 一行横排：`状态` + 评分数字（如 `7/10`）+ Stepper 或点击弹出选择器
- 第二行：`主攻` + 科目文字（如 `数学`）+ 点击可编辑

**交互：**

- stateScore：推荐使用 `Stepper("状态", value: $stateScore, in: 1...10)`，或者点击弹出一个 1-10 的横向点选条（类似苹果健康的心情选择），不推荐自由文本输入
- mainSubject：点击弹出科目选择列表（数学/语文/英语/物理/化学/生物/历史/地理/政治），也可支持手动输入其他科目
- 编辑后自动保存（利用 `@Environment(\.modelContext)` + on-change 触发 save）

**空状态文案：**

- stateScore 未设置时：`状态 —` 灰色占位，轻触即可设置
- mainSubject 未设置时：`主攻科目 未设置` 灰色占位

### 3.3 PlanSection

**显示内容（三个子区块，每个用独立 Section）：**

**Top Tasks（最重要，置顶）：**

- Section 标题：`Top 任务`（加粗）
- 多行文本编辑区域，placeholder：`今天最重要的 1-3 件事`
- 对应 `DayPlan.topTasksText`

**Baseline Tasks（保底）：**

- Section 标题：`保底任务`（加粗）+ 小字说明 `状态差也要完成`
- 多行文本编辑区域，placeholder：`最少要完成的事`
- 对应 `DayPlan.baselineTasksText`

**Bonus Tasks（加分）：**

- Section 标题：`加分任务`（加粗）+ 小字说明 `状态好时追加`
- 多行文本编辑区域，placeholder：`有余力就多做一点`
- 对应 `DayPlan.bonusTasksText`
- 当降载模式激活时，整个 Bonus 区块隐藏

**交互：**

- 每个文本区点击后进入编辑，使用 `TextEditor` 或 `TextField`（多行用 TextEditor）
- 一行显示时截断文本，点击展开
- 编辑后自动保存

**空状态文案：**

- Top Tasks 为空时：`今天最重要的 1-3 件事`（placeholder 色）
- Baseline Tasks 为空时：`最少要完成的事`（placeholder 色）
- Bonus Tasks 为空时：`有余力就多做一点`（placeholder 色）

### 3.4 ProgressSummarySection

**显示内容：**

- 一行紧凑统计：`今日任务 0 / 0 已完成`
- 数据来源：`StudyTaskStore.countTasks(for: todayKey)` 和 `countCompletedTasks(for: todayKey)`

**交互：**

- 纯展示，无交互
- 当完成数 = 总数且 > 0 时，显示轻微绿色标识（不是大徽章，只是文字颜色微调）

**空状态：**

- 任务数为 0 时：`今日暂无任务`（灰色）

### 3.5 TaskListSection

**显示内容：**

- Section 标题：`今日任务`
- 按创建时间排序的 StudyTask 列表，每行显示：
  - 状态图标（pending = 空心圆、inProgress = 半填充圆、done = 绿色勾、skipped = 灰色横线）
  - 标题
  - 科目标签（小圆角标签）
  - 状态文字（灰色小字）
- 列表最多显示 5-8 条，超出时折叠或显示 `查看全部 n 条` 链接
- 列表底部：`+ 快速新增任务` 按钮

**交互：**

- 点击任务行 → 进入任务详情/编辑（但 Stage 3 可以先只做状态切换：点击切换 pending ↔ done）
- 点击 `+ 快速新增任务` → 弹出 Sheet 或展开内联表单
- 左滑任务行 → 跳过（标记 skipped）/ 删除

**空状态：**

- 今天还没有任务时：显示 `还没有任务，从上面的 Top 任务开始吧`（灰色，带轻微推动感）

### 3.6 TomorrowFirstActionSection

**显示内容：**

- Section 标题：`明日第一步`
- 单行或双行文本输入，placeholder：`明天打开 App 后第一件事`
- 显示当前值或 placeholder
- 小字提示：`明天会出现在首页顶部`

**交互：**

- 点击进入编辑
- 编辑后自动保存

**空状态文案：**

- 为空时：`明天打开 App 后第一件事`（placeholder 色）

### 3.7 DegradedModeBanner

**显示内容（仅当 stateScore <= 4 时显示）：**

- 黄色/橙色背景的轻量横幅
- 文案：`今日降载模式 · 保住链条即可`
- 副文案：`只完成保底任务，推荐 15-25 分钟短专注`
- 一个按钮：`开始保底专注`

**交互：**

- `开始保底专注` → 直接进入 FocusSessionView（带默认 15 分钟计时），但 Stage 3 可以先跳转到 Focus placeholder 或空操作
- 横幅不阻塞正常操作，只是提醒
- 当 Bonus Tasks 区块存在时，降载自动隐藏该区块

**注意：** 降载模式不改变数据，只是 UI 层面的提醒和过滤。用户仍然可以正常编辑所有字段。

### 3.8 DebugEntrySection

**显示内容：**

- 页面最底部
- 一个极小的小点图标 `···` 或 `Debug` 灰色小字
- 点击后展开/跳转到 `Stage2DebugPersistenceView`

**交互：**

- 默认收起，不占据主视觉
- 点击后导航到现有的 Debug 页面（保留 Stage2DebugPersistenceView 作为独立 Sheet 或 NavigationLink 目标）
- 绝对不能让它成为首页的一个大卡片

## 四、快速新增任务表单（建议字段）

在 TaskListSection 的 `+ 快速新增任务` 点击后，弹出 Sheet：

| 字段 | 控件 | 必填 | 说明 |
|------|------|------|------|
| 任务标题 | TextField | 是 | placeholder: `具体要做什么？` |
| 科目 | Picker（从 mainSubject 预填） | 是 | 默认取 DayPlan.mainSubject |
| 类型 | Picker | 否 | 选项：做题/预习/复盘/背诵/整理/其他 |
| 预计分钟 | Stepper 或数字输入 | 否 | 默认 25 分钟 |

两个按钮：`保存`（关闭 Sheet）、`保存并开始专注`（保存后跳转 Focus，Stage 3 可只跳 placeholder）

**设计要点：**

- 表单只有 4 个字段，不吓人
- 科目自动从今日主攻科目预填，减少输入
- 类型提供预设选项，不强制填写
- 整个表单应该在 15 秒内填完

## 五、空状态文案汇总

| 位置 | 空状态文案 |
|------|-----------|
| stateScore 未设置 | `状态 —`（灰色） |
| mainSubject 未设置 | `主攻科目 未设置`（灰色） |
| topTasksText 为空 | `今天最重要的 1-3 件事` |
| baselineTasksText 为空 | `最少要完成的事` |
| bonusTasksText 为空 | `有余力就多做一点` |
| 今日任务数为 0 | `还没有任务，从上面的 Top 任务开始吧` |
| tomorrowFirstAction 为空 | `明天打开 App 后第一件事` |

## 六、降载模式文案

| 元素 | 文案 |
|------|------|
| 横幅标题 | `今日降载模式` |
| 横幅副文案 | `状态不好没关系，保住学习链条就行` |
| 按钮文案 | `开始 15 分钟短专注` |
| 隐藏 Bonus 时的暗示 | Bonus 区块直接消失，不做额外说明（消失本身就是信号） |
| 保底任务区的强调 | 保底任务正常显示，不做额外标记（它是用户自己写的，不是系统指派的） |

## 七、SwiftUI 组件拆分建议

不写完整代码，只给拆分结构：

```
TodayCockpitView.swift              // 主视图，组装所有 Section
├── TodayHeaderSection.swift        // 日期 + 定位文案
├── TodayStateSection.swift         // stateScore + mainSubject 编辑
├── TodayPlanSection.swift          // Top / Baseline / Bonus 三个文本编辑区
├── TodayProgressSummarySection.swift // 任务统计一行
├── TodayTaskListSection.swift      // StudyTask 列表 + 快速新增按钮
├── TodayTomorrowActionSection.swift // 明日第一步编辑
├── TodayDegradedBanner.swift       // 降载条件横幅
└── TodayQuickAddTaskSheet.swift    // 快速新增任务 Sheet

// 复用/移动：
Stage2DebugPersistenceView.swift    // 作为 Debug Sheet 的目标（从 Today 移出）
```

**每个 Section 组件的特点：**

- 都接收 `@Bindable var dayPlan: DayPlan` 或具体的 Binding
- 自动保存通过 `onChange(of: value) { try? modelContext.save() }` 实现
- 不需要单独创建 ViewModel，直接使用 SwiftData 的 `@Query` 和 `@Bindable`

**建议的 Section 容器风格：**

- 每个 Section 用轻量卡片包裹：`.background(.thinMaterial)` + `clipShape(RoundedRectangle(...))`
- Section 之间间距 12-16pt
- 不要用 GroupedList，用 ScrollView + VStack 更灵活
- 整页 padding 水平 16pt

## 八、Stage 3 明确不做的事

| 不做 | 原因 |
|------|------|
| 专注计时器 | Stage 4 的事 |
| 错题手术表单 | Stage 5 的事 |
| Prompt 模板选择和生成 | Stage 6 的事 |
| 每日复盘完整流程 | Stage 7 的事 |
| TaskListView 独立页面 | Stage 4 的事（Today 页的任务列表只做预览） |
| 拖拽排序任务 | 优先级低，先保证 CRUD |
| 日历选择器跳转到其他日期 | 今日驾驶舱只看今天 |
| 统计图表 | 不做 |
| 自动建议任务 | 不做 |
| 推送通知 | Stage 8 |
| Onboarding 流程 | 先跳过，直接进入 Today |
| 复杂动画和转场 | 第一版求稳不求炫 |
| FocusSession 的计时 UI | Stage 4 |
| 从错题手术跳回 Today | Stage 5 |
| 任务筛选（按科目/状态） | Stage 4 的 TaskListView 再做 |

## 九、给 Codex 的实现注意事项

1. **自动保存策略**：DayPlan 的所有字段变更应该自动触发 `modelContext.save()`。推荐使用 `onChange(of: dayPlan.stateScore)` 等逐个监听，或者用一个统一的 debounce save。不要依赖用户手动点保存按钮。

2. **todayKey 的一致性**：整个 TodayCockpitView 应该通过 `DateKey.todayKey()` 获取 todayKey，并在 `onAppear` 时调用 `DayPlanStore.fetchOrCreateToday(in: modelContext)` 确保 DayPlan 一定存在。不存在就创建空计划。

3. **StudyTask 和 DayPlan 的关联**：Stage 3 创建 StudyTask 时，应该把 `dayPlanId` 设为当前 DayPlan 的 id，`dayKey` 设为 todayKey。这样统计和关联不会断。

4. **topTasksText 不是数组**：注意 DayPlan 模型中这三个字段是纯文本字符串（`topTasksText`、`baselineTasksText`、`bonusTasksText`），不是 `[String]`。UI 中使用 TextEditor 编辑多行文本即可。不要在 Stage 3 把它们改成数组——那是数据模型的重构，属于另一个决策。

5. **StudyTask status 常量**：使用 `ModelDefaults.StudyTaskStatus.pending / inProgress / done / skipped`，不要硬编码字符串。

6. **降载模式的触发逻辑**：`stateScore <= 4` 时显示横幅、隐藏 Bonus 区块。这个判断在 TodayCockpitView 的 body 中用 `if` 即可。不需要额外状态管理。

7. **Debug 入口的处理**：把 `Stage2DebugPersistenceView` 从 TodayCockpitPlaceholderView 中移出，改为通过 TodayCockpitView 底部的一个极小按钮以 Sheet 方式呈现。Stage 4 之后可以直接删除这个入口。

8. **首次启动的空 DayPlan**：当 `fetchOrCreateToday` 创建了一个全新 DayPlan 时，所有字段为空。首页应该用 placeholder 文案引导用户逐步填写，而不是显示一片空白。

9. **任务列表的性能**：Today 页的 StudyTask 列表用 `@Query` 按 todayKey 过滤，数据量不大（每天通常不超过 10-20 条），不需要分页或虚拟滚动。

10. **预览数据**：为 `#Preview` 提供 in-memory ModelContainer 并预填充一个示例 DayPlan + 2-3 条 StudyTask，方便在 Xcode Preview 中直接看到效果。

11. **无障碍**：每个可编辑区域添加 `.accessibilityLabel`，Stepper 添加无障碍值描述。降载横幅确保对 VoiceOver 可见。

12. **不要引入第三方依赖**：所有 UI 用原生 SwiftUI 实现。Stage 3 不添加任何 Swift Package。
