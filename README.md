# Gaokao Cockpit

Gaokao Cockpit is a local-first iOS study cockpit for Chinese high-school exam preparation. It helps a learner keep the daily loop visible: plan the day, execute study tasks, run focus sessions, dissect mistakes, generate study prompts, review the day, and carry a concrete first step into tomorrow.

The project is intentionally small and privacy-first. It does not require an account, a backend, cloud sync, or an AI API.

## Project Status

Current checkpoint: Stage 20 complete.

The app currently includes:

- Today cockpit for daily planning, energy/state check-ins, Top / baseline / bonus tasks, and tomorrow's first action.
- Study task management with task creation, editing, deletion, status changes, actual minutes, and output notes.
- Focus sessions tied to study tasks, including pause/resume, distraction count, completion score, session notes, and next action.
- Mistake surgery records with text, optional local images, root-cause analysis, question signals, correct models, variants, and review status.
- Prompt library with 51 built-in templates, search, category filters, frequent/recent prompts, custom template creation, editing, duplication, deletion, variable extraction, prompt rendering, and clipboard copy.
- Daily and weekly reviews with summary cards, review prompts, and tomorrow-first-action handoff.
- Local JSON backup export, validation, import dry-run, conflict summaries, image recovery summaries, and restore-plan preview.

The app does not yet support true import restore, cloud sync, accounts, encryption, OCR, automatic grading, AI chat, or AI API calls.

## Why This Exists

Many study systems become another thing to maintain. Gaokao Cockpit is designed to stay close to the daily work:

```text
Start the day
  -> Plan concrete tasks
  -> Focus on one task
  -> Record what happened
  -> Diagnose mistakes
  -> Generate prompts for external AI tools
  -> Review the day
  -> Decide tomorrow's first action
```

The goal is not to build a large education platform. The goal is a dependable personal operating loop for serious exam preparation.

## Core Principles

- Local-first: core study data lives on the device.
- Offline by default: the app should remain useful without network access.
- No accounts in the MVP.
- No backend in the MVP.
- AI-assisted, not AI-dependent: prompts are generated locally and copied into the user's preferred AI tool.
- Mistakes are not collectibles; they are diagnostic material.
- Low friction beats perfect tracking.
- A bad day still needs a baseline path.

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- iOS 17 or later
- Xcode with iOS Simulator support

There are currently no third-party package dependencies.

## Getting Started

1. Clone the repository.
2. Open `GaokaoCockpit.xcodeproj` in Xcode.
3. Select the `GaokaoCockpit` scheme.
4. Choose an iOS Simulator.
5. Build and run.

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

## Repository Structure

```text
GaokaoCockpit/
  Models/       SwiftData models and typed value wrappers
  Stores/       SwiftData query helpers, prompt rendering, backup logic
  Views/        SwiftUI screens and reusable view components
  Resources/    App icons and bundled assets
docs/           Product, architecture, data model, backup, QA, roadmap docs
fixtures/       Small backup fixtures for dry-run and restore-plan checks
```

## Documentation

Start here:

- [Documentation index](docs/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Product spec](docs/PRODUCT_SPEC.md)
- [Data model](docs/DATA_MODEL.md)
- [UX flow](docs/UX_FLOW.md)
- [Prompt templates](docs/PROMPT_TEMPLATES.md)
- [Backup format](docs/BACKUP_FORMAT.md)
- [Restore strategy](docs/RESTORE_STRATEGY.md)
- [QA checklist](docs/QA_CHECKLIST.md)
- [Roadmap](docs/ROADMAP.md)

## Data And Privacy

Gaokao Cockpit stores study data locally through SwiftData. Mistake images are stored as local app files and referenced by relative paths. Backup export produces a readable JSON file and can embed mistake images as base64 data.

Do not publish personal backups, real study records, private screenshots, exported JSON files, `.env` files, signing certificates, provisioning profiles, or local databases.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

For now, the most valuable contributions are:

- Small SwiftUI usability improvements that preserve the local-first loop.
- Focused bug fixes.
- Documentation improvements.
- Backup validation and restore-plan safety improvements.
- Manual QA reports with clear reproduction steps.

## Security

Please read [SECURITY.md](SECURITY.md). Do not file public issues containing private student data, exported backups, tokens, signing material, or device-specific local paths.

## License

MIT. See [LICENSE](LICENSE).

## Disclaimer

This project is a personal study workflow tool. It is not an official education product, admissions service, medical tool, or mental-health intervention. Use it as a planning and reflection aid, not as a substitute for teachers, guardians, professional advice, or real study practice.
