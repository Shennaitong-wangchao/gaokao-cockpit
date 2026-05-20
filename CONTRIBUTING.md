# Contributing

Thanks for helping improve Gaokao Cockpit. The project is intentionally small, local-first, and focused on the daily study loop. Contributions should preserve that shape.

## Good First Contributions

- Fix clear SwiftUI bugs.
- Improve copy, empty states, accessibility labels, or documentation.
- Add focused manual QA notes.
- Improve backup validation, dry-run clarity, or restore-plan safety.
- Refine prompt-template usability without introducing network dependencies.

## Before You Start

1. Read [README.md](README.md).
2. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
3. Check [docs/ROADMAP.md](docs/ROADMAP.md) for current scope.
4. Keep changes small and focused.

## Development Setup

Open `GaokaoCockpit.xcodeproj` in Xcode and run the `GaokaoCockpit` scheme on an iOS Simulator.

Command-line build:

```bash
xcodebuild \
  -project GaokaoCockpit.xcodeproj \
  -scheme GaokaoCockpit \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Pull Request Checklist

- The change is focused and has a clear user or maintainer benefit.
- SwiftData model changes are documented in `docs/DATA_MODEL.md`.
- Backup format or restore-plan changes are documented in `docs/BACKUP_FORMAT.md` and `docs/RESTORE_STRATEGY.md`.
- User-facing behavior changes are reflected in `docs/QA_CHECKLIST.md`.
- `git diff --check` passes.
- A Debug simulator build passes, or the PR explains why it could not be run.
- No private data, exported personal backups, signing files, tokens, local databases, or real study records are included.

## Code Style

- Follow the existing SwiftUI style.
- Prefer small feature-specific components over large view files.
- Prefer existing store/helper patterns over new architecture layers.
- Keep comments sparse and useful.
- Do not introduce third-party dependencies without a clear discussion.

## Privacy And Safety

Do not commit:

- Real exported backup JSON files.
- Screenshots with private learner data.
- SwiftData sqlite/store files.
- `.env` files.
- API keys, tokens, certificates, provisioning profiles, or private keys.
- Logs that include private records or local device paths.

Use synthetic fixture data for tests and examples.

## Scope Boundaries

Please open a design discussion before working on:

- True import restore.
- AI API integration.
- OCR or automatic grading.
- Cloud sync.
- Account systems.
- macOS or web ports.
- Backup schema version changes.

These areas can be valuable, but they carry larger privacy and data-integrity risks.
