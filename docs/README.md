# Documentation

This directory contains the public project documentation for Gaokao Cockpit. The docs are written for contributors, maintainers, and users who want to understand the product decisions before changing code.

## Recommended Reading Order

1. [Product spec](PRODUCT_SPEC.md) explains the problem, target user, scope, and non-goals.
2. [Architecture](ARCHITECTURE.md) explains the app structure, data flow, and implementation boundaries.
3. [Data model](DATA_MODEL.md) describes the SwiftData-backed domain model and relationships.
4. [UX flow](UX_FLOW.md) shows the main user journeys and screen-level intent.
5. [Prompt templates](PROMPT_TEMPLATES.md) documents built-in and custom prompt behavior.
6. [Backup format](BACKUP_FORMAT.md) documents the local JSON backup envelope and validation rules.
7. [Restore strategy](RESTORE_STRATEGY.md) explains the safe restore-plan approach.
8. [Restore plan tests](RESTORE_PLAN_TESTS.md) explains fixture-based manual verification.
9. [QA checklist](QA_CHECKLIST.md) is the manual regression checklist for release work.
10. [Roadmap](ROADMAP.md) records completed stages and future directions.
11. [Stage 3 Today design](STAGE3_TODAY_DESIGN.md) is retained as historical design context.

## Documentation Rules

- Keep the local-first privacy boundary explicit.
- Prefer concrete user flows over abstract platform language.
- Mark historical stage documents as historical when behavior has moved on.
- Update docs in the same change as user-facing behavior changes.
- Do not include private study records, real exported backups, secrets, or personal device paths.

## Current Checkpoint

The current implementation checkpoint is Stage 20: custom prompt templates are supported. Stage 21 items such as AI API integration, RAG, cloud sync, and macOS expansion remain future work and should not be treated as accepted scope until a smaller design proposal exists.
