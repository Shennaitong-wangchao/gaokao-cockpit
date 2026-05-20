# Security Policy

Gaokao Cockpit is local-first and currently has no backend, account system, cloud sync, or AI API integration. The highest-risk data in this project is user-created local study data and exported backup files.

## Supported Versions

This repository is early-stage. Security fixes should target the `main` branch unless a release branch is created later.

## Reporting A Vulnerability

If the repository is hosted on GitHub, please use GitHub Security Advisories when available. If advisories are not available, open a public issue with a high-level description only and avoid including sensitive details.

Do not post:

- Real student or learner data.
- Exported backup JSON files.
- Mistake images from real study records.
- Tokens, API keys, certificates, provisioning profiles, or private keys.
- Device-specific local database files.

If you need to describe a problem, use synthetic data and redact private paths or identifiers.

## Security-Relevant Areas

- Backup export and validation.
- Import dry-run and restore-plan preview.
- Future true restore support.
- Local image storage and relative image paths.
- Any future AI API, cloud sync, account, or encryption work.

## Current Boundaries

The app currently:

- Stores core data locally through SwiftData.
- Stores mistake images as local app files.
- Exports readable JSON backups.
- Can embed images in backup JSON as base64.
- Does not perform true import restore.
- Does not call remote AI services.
- Does not include server-side authentication or authorization.

Because exported backups are readable JSON and may contain embedded images, users should treat backup files as private.
