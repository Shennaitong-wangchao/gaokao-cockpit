# Stores

Stage 2B keeps storage deliberately small. These files are lightweight SwiftData query helpers, not a full Repository layer.

- `AppModelContainerFactory` builds the SwiftData `ModelContainer`.
- `PromptTemplateSeeder` inserts built-in templates once for a fresh local store.
- `DateKey` creates stable `yyyy-MM-dd` keys and simple week key ranges.
- `DayPlanStore` fetches or creates a `DayPlan` by `dayKey`.
- `StudyTaskStore` creates and counts tasks by `dayKey`.
- `PromptTemplateStore` fetches built-in templates and tracks template usage.
- `DailyReviewStore` reserves simple daily review fetch/create helpers for Stage 7.

Current association strategy:

- Records use `dayKey` for day-based lookup.
- Optional model references use stored `UUID` values such as `dayPlanId` or `bestMistakeId`.
- SwiftData relationships are intentionally not used yet.
- `@Attribute(.unique)` is intentionally not used yet; duplicate prevention is handled by fetch-or-create helper logic where needed.

Stage 3, Stage 4, and Stage 5 screens should reuse these helpers so SwiftUI views do not repeat the same SwiftData predicates and sort descriptors.
