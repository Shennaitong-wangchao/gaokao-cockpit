# Stores

This folder contains small SwiftData helpers and pure domain utilities. These files are not a broad repository abstraction; they keep repeated fetch, save, prompt, backup, and date-key logic out of SwiftUI views.

Key groups:

- `AppModelContainerFactory` creates the SwiftData model container.
- `DateKey` produces stable day/week keys.
- `DayPlanStore`, `StudyTaskStore`, `FocusSessionStore`, `MistakeRecordStore`, `DailyReviewStore`, and `WeeklyReviewStore` provide focused data access helpers.
- `PromptTemplateSeeder`, `PromptTemplateStore`, `PromptRenderer`, and `RecentPromptStore` support built-in/custom prompt workflows.
- `BackupExportStore`, `BackupValidationStore`, `BackupImportDryRunStore`, `BackupRestorePlan`, and `BackupRestorePlanBuilder` support local export, validation, dry-run, and restore-plan preview.

Guidelines:

- Keep store methods narrow and easy to call from SwiftUI.
- Do not write SwiftData during backup dry-run or restore-plan preview.
- Do not overwrite user custom prompt templates from the built-in seeder.
- Update docs and QA when backup semantics or model contracts change.
