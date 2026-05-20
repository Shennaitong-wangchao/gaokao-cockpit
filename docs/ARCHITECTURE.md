# Architecture

Gaokao Cockpit is a single-target SwiftUI iOS app built around a local-first learning loop. The app uses SwiftData for persistence, small store/helper types for data access, and feature-oriented SwiftUI screens.

## Goals

- Keep the core learning loop usable offline.
- Keep data ownership on the device.
- Avoid backend, account, and sync complexity in the MVP.
- Keep SwiftUI views understandable by splitting long screens into components.
- Keep backup and restore planning conservative, inspectable, and reversible.

## High-Level Structure

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

The root navigation is a `TabView` with five user-facing areas:

- Today: daily plan, state, task summary, plan-to-task conversion.
- Tasks: concrete study tasks and status management.
- Mistakes: mistake surgery records and optional local images.
- Prompt: built-in and custom prompt templates.
- Reviews: daily/weekly reviews and backup entry point.

## Persistence

SwiftData models live in `GaokaoCockpit/Models`.

The app intentionally stores simple values such as `UUID`, `String`, `Date`, and day keys instead of relying heavily on SwiftData relationships. This keeps backup export, dry-run validation, and future merge restore easier to reason about.

Common patterns:

- Date-based lookup uses stable `yyyy-MM-dd` day keys.
- Optional cross-model references use stored UUID values.
- User-visible status/category values are wrapped by enum helpers while SwiftData storage remains `String`.
- Backup Codable snapshots are separate from SwiftData `@Model` types.

## Stores And Helpers

Store/helper types live in `GaokaoCockpit/Stores`.

They are deliberately small and feature-specific:

- `DayPlanStore`, `StudyTaskStore`, `FocusSessionStore`, `MistakeRecordStore`, `DailyReviewStore`, and `WeeklyReviewStore` handle focused SwiftData fetch/create/update patterns.
- `PromptTemplateSeeder` safely upserts built-in prompt templates without overwriting custom templates.
- `PromptTemplateStore`, `PromptRenderer`, and `RecentPromptStore` support template discovery, rendering, usage counts, and recent prompt shortcuts.
- `BackupExportStore`, `BackupValidationStore`, `BackupImportDryRunStore`, `BackupRestorePlan`, and `BackupRestorePlanBuilder` support export, validation, dry-run, and safe future restore planning.

Views should prefer these helpers over repeating predicates and save logic inline.

## Backup And Restore Boundary

Current behavior:

- Export writes a local JSON backup envelope.
- Validation checks schema, versions, summary counts, and checksum strategy.
- Import dry-run reads a backup without modifying SwiftData.
- Restore-plan preview estimates inserts, skipped duplicates, reference repairs, and image recovery.

Current non-behavior:

- No true import restore.
- No overwrite restore.
- No image write-back during dry-run.
- No cloud sync.
- No encryption layer.

Any future restore feature should remain `merge-with-new-ids` by default and require a fresh backup before writing local data.

## Prompt System

The prompt system is local rendering only:

- Built-in templates are seeded and upserted.
- Custom templates are user-created SwiftData records.
- Template variables use `{{variableName}}`.
- Rendering replaces missing values with `未提供`.
- Copying increments usage count and records recent prompt metadata.

The app does not call an AI API and does not store AI responses.

## Images

Mistake images are app-local files managed through `MistakeImageStore`. SwiftData records store relative image paths rather than binary blobs. Backup export can embed images as base64 in JSON; dry-run can estimate image recoverability without restoring files.

## Manual QA

The project currently relies on manual QA rather than an XCTest target. Use [QA_CHECKLIST.md](QA_CHECKLIST.md) before release or public milestone work.

Suggested command-line build:

```bash
xcodebuild \
  -project GaokaoCockpit.xcodeproj \
  -scheme GaokaoCockpit \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Design Constraints

- Do not add a backend for MVP convenience.
- Do not make AI API access a hard dependency for core flows.
- Do not commit real student data or exported personal backups.
- Do not change backup schema or SwiftData model semantics without updating docs and QA.
- Do not introduce broad refactors when a focused feature-level change is enough.
