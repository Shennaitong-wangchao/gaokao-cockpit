# Models

This folder contains the SwiftData `@Model` types and storage-value wrappers for the local learning loop.

Model design rules:

- Store stable primitive values that are easy to export and validate.
- Prefer stored UUID references and day keys over hard SwiftData relationships for now.
- Keep user-visible status/category values as `String` in SwiftData and expose type-safe enum wrappers in UI/store code.
- Update `docs/DATA_MODEL.md` and backup docs when model semantics change.
