# Data Model / 数据模型

This document describes the current public data model for Gaokao Cockpit. The app uses SwiftData for local persistence, but backup export uses separate Codable snapshot structs instead of making SwiftData `@Model` types Codable.

## Modeling Principles

- Local-first: core study data must work offline.
- Stable enough for backups: field names should not change casually.
- Low-friction input: most text fields can be empty.
- Conservative relationships: optional references use stored UUID values instead of hard SwiftData relationships.
- Type-safe UI, stable storage: status/category values are stored as `String` and wrapped by enum helpers in code.
- Privacy-aware export: backup data is readable JSON, so exported files should be treated as private user data.

## Entities

### DayPlan

Represents one day's plan and the Today cockpit state.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `dayKey` | `String` | Yes | `yyyy-MM-dd`, used for day-based lookup |
| `date` | `Date` | Yes | Calendar date for the plan |
| `wakeTime` | `Date?` | No | Start/wake time |
| `stateScore` | `Int?` | No | Suggested range: 1-10 |
| `mainSubject` | `String` | No | Empty string means unset |
| `topTasksText` | `String` | No | User-entered Top tasks, stored as plain text |
| `baselineTasksText` | `String` | No | Minimum viable tasks for low-energy days |
| `bonusTasksText` | `String` | No | Extra tasks if capacity allows |
| `tomorrowFirstAction` | `String` | No | First action to show next day |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

### StudyTask

Represents a concrete executable study task.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `dayPlanId` | `UUID?` | No | Optional reference to a `DayPlan` |
| `dayKey` | `String` | Yes | Day lookup key |
| `title` | `String` | Yes | The action to execute |
| `subject` | `String` | No | Subject name |
| `category` | `String` | No | Stored category value |
| `estimatedMinutes` | `Int?` | No | Planned duration |
| `actualMinutes` | `Int?` | No | Actual duration, often updated from focus sessions |
| `status` | `String` | Yes | Wrapped by `StudyTaskStatus` |
| `outputNote` | `String` | No | Result, notes, or produced work |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

### FocusSession

Represents one focused study block, usually tied to a task.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `taskId` | `UUID?` | No | Optional reference to a `StudyTask` |
| `dayKey` | `String` | Yes | Day lookup key derived from `startTime` unless supplied |
| `subject` | `String` | No | Subject for the session |
| `startTime` | `Date` | Yes | Session start |
| `endTime` | `Date?` | No | Session end |
| `plannedMinutes` | `Int` | Yes | Planned duration |
| `actualMinutes` | `Int?` | No | Saved duration |
| `distractionCount` | `Int` | Yes | Number of distractions recorded |
| `completionScore` | `Int?` | No | Suggested range: 1-5 |
| `sessionNote` | `String` | No | What happened in the session |
| `nextAction` | `String` | No | Next step after this session |
| `createdAt` | `Date` | Yes | Created timestamp |

### MistakeRecord

Represents a mistake surgery record: the problem, what went wrong, and what should happen next.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `subject` | `String` | No | Subject |
| `chapter` | `String` | No | Chapter or topic |
| `source` | `String` | No | Paper, workbook, exam, or other source |
| `questionText` | `String` | No | Problem text |
| `questionImagePath` | `String` | No | Local relative image path |
| `mySolution` | `String` | No | Learner's original attempt |
| `correctSolution` | `String` | No | Correct solution or model answer |
| `mistakeType` | `String` | Yes | Wrapped by `MistakeType` |
| `rootCause` | `String` | No | Why the mistake happened |
| `questionSignal` | `String` | No | Signal that should trigger the right model |
| `correctModel` | `String` | No | Correct method/model |
| `variantTask` | `String` | No | Follow-up practice task |
| `nextReminder` | `Date?` | No | Optional review reminder date |
| `reviewStatus` | `String` | Yes | Wrapped by `ReviewStatus` |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

### PromptTemplate

Represents a built-in or custom prompt template.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `title` | `String` | Yes | Template title |
| `category` | `String` | Yes | Wrapped by `PromptCategory` |
| `templateDescription` | `String` | No | User-facing explanation |
| `templateText` | `String` | Yes | Template body with `{{variableName}}` placeholders |
| `variablesText` | `String` | No | Variables separated by commas or newlines |
| `usageCount` | `Int` | Yes | Incremented after copy/render use |
| `isBuiltIn` | `Bool` | Yes | Built-in templates are seeded and upserted |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

Built-in templates are updated by title and `isBuiltIn == true`. Custom templates are never overwritten by the seeder.

### ResourceItem

Represents a lightweight reference to study material.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `title` | `String` | Yes | Material title |
| `subject` | `String` | No | Subject |
| `chapter` | `String` | No | Chapter or topic |
| `type` | `String` | Yes | Raw material type value such as textbook, paper, note, video, web, or file |
| `uri` | `String` | No | Local path, URL, or external reference |
| `status` | `String` | Yes | Wrapped by `ResourceStatus` |
| `note` | `String` | No | Short note |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

### DailyReview

Represents a short end-of-day review.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `dayKey` | `String` | Yes | Day lookup key |
| `date` | `Date` | Yes | Review date |
| `completedSummary` | `String` | No | What was completed |
| `unfinishedSummary` | `String` | No | What was not completed and why |
| `biggestProblem` | `String` | No | Main blocker or pattern |
| `bestMistakeId` | `UUID?` | No | Optional reference to a `MistakeRecord` |
| `stateScoreEnd` | `Int?` | No | Suggested range: 1-10 |
| `tomorrowFirstAction` | `String` | No | First action for tomorrow |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

### WeeklyReview

Represents a week-level reflection and planning record.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `UUID` | Yes | Stable local identifier |
| `weekStartKey` | `String` | Yes | Week lookup key |
| `weekEndKey` | `String` | Yes | End day key |
| `weekStartDate` | `Date` | Yes | Week start |
| `weekEndDate` | `Date` | Yes | Week end |
| `totalStudyMinutes` | `Int` | Yes | Aggregated or user-confirmed total |
| `subjectBreakdownText` | `String` | No | Human-readable subject distribution |
| `completedTaskCount` | `Int` | Yes | Completed task count |
| `mistakeCount` | `Int` | Yes | Mistake record count |
| `mistakeTypeBreakdownText` | `String` | No | Human-readable mistake distribution |
| `keyProblemsText` | `String` | No | Key weekly problems |
| `nextWeekFocusText` | `String` | No | Focus for next week |
| `createdAt` | `Date` | Yes | Created timestamp |
| `updatedAt` | `Date` | Yes | Updated timestamp |

## Relationship Strategy

```text
DayPlan 1 -> many StudyTask by dayKey/dayPlanId
StudyTask 1 -> many FocusSession by taskId
DailyReview 0/1 -> 1 DayPlan by dayKey
DailyReview 0/1 -> 1 MistakeRecord by bestMistakeId
WeeklyReview aggregates records by date range
PromptTemplate is standalone
ResourceItem is standalone in the MVP
```

Hard SwiftData relationships are intentionally avoided for now. This makes backup export, dry-run, and future merge restore easier to inspect and test.

## Backup Snapshot Notes

Backup JSON uses separate snapshot structs. Do not assume changing a SwiftData field automatically updates the public backup contract. When a model changes:

1. Update the SwiftData model.
2. Update the backup snapshot structs and validation rules if needed.
3. Update [BACKUP_FORMAT.md](BACKUP_FORMAT.md).
4. Update [QA_CHECKLIST.md](QA_CHECKLIST.md).
5. Decide whether `exportSchemaVersion` must change.

## Example Record

```json
{
  "id": "550E8400-E29B-41D4-A716-446655440004",
  "subject": "数学",
  "chapter": "导数与函数零点",
  "source": "周练第 17 题",
  "questionText": "已知函数 f(x)=... 求参数 a 的取值范围。",
  "questionImagePath": "MistakeImages/example-math-17.jpg",
  "mySolution": "直接求导后只讨论了单调递增情况。",
  "correctSolution": "先分离参数，再结合函数图像与导数符号讨论边界。",
  "mistakeType": "model",
  "rootCause": "看到参数范围题没有先判断是否适合分离参数。",
  "questionSignal": "参数取值范围 + 恒成立结构。",
  "correctModel": "参数范围题先判断分离参数、端点、极值和边界。",
  "variantTask": "完成 3 道同型参数范围题，只写触发信号和模型选择。",
  "reviewStatus": "scheduled"
}
```
