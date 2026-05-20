# Changelog

All notable public-facing changes should be recorded here.

This project follows a pragmatic changelog format while it is pre-1.0.

## Unreleased

### Added

- Open-source README with project status, setup instructions, documentation links, privacy notes, and contribution entry points.
- Documentation index and architecture overview.
- MIT license, contributing guide, security policy, code of conduct, and GitHub issue/PR templates.
- Expanded `.gitignore` for Xcode artifacts, local app data, exported backups, signing material, logs, and secrets.
- Open-source release checklist items in `docs/QA_CHECKLIST.md`.

### Changed

- Updated documentation language to be suitable for a public repository.
- Aligned docs around the current checkpoint: Stage 20 complete; Stage 21 remains future scope.
- Generalized product positioning to avoid private learner-specific assumptions.

## Stage 20 - Custom Prompt Templates

### Added

- Custom prompt template creation, editing, deletion, and duplication from built-in templates.
- Variable extraction from `{{variableName}}` template placeholders.
- Template type filtering for all, built-in, and custom templates.
- Backup export coverage for custom prompt templates.

## Stage 19 - Prompt Library Daily Usability

### Added

- Frequent prompts based on usage count.
- Recent prompts based on local UserDefaults metadata.
- Usage-sorted search and category results.

## Stage 18 - Prompt Library Expansion

### Added

- Expanded built-in prompt library to 51 templates across mistake analysis, math, physics, chemistry, biology, English, Chinese, review, diagnosis, and self-test workflows.
- Safe built-in template upsert that preserves usage counts and avoids overwriting custom templates.

## Earlier Stages

Earlier stages established the SwiftUI/SwiftData app skeleton, Today cockpit, task management, focus sessions, mistake surgery, prompt rendering, reviews, local backup export, backup validation, import dry-run, restore-plan preview, state value wrappers, and view componentization.
