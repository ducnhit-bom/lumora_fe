# AGENTS.md

This file provides guidance to OpenCode when working in the Lumora Flutter frontend repo.

## Repo Role

**Name:** lumora_fe
**Stack:** Flutter, Dart
**Purpose:** Lumora mobile/frontend application.

## Read First

- `./README.md`
- `./pubspec.yaml`
- Product and UX context in `./lumora_brain/documents/` when the task involves flows, screens, copy, or visual decisions.

## Cross-Repo Link

- `./lumora_brain` is a symlink to `../lumora_brain`.
- Use it for product/spec context. Prefer editing brain docs via `../lumora_brain` when possible.

## Flutter Rules

- Keep feature code organized under `lib/`; avoid large all-in-one files as the app grows.
- Prefer stateless widgets until local state is actually needed.
- Do not add dependencies without a clear reason and user-visible benefit.
- Keep UI responsive on phone-sized screens first, then tablet/desktop if required.
- Follow the existing lint rules in `analysis_options.yaml`.

## UI Rules

- Avoid generic template UI when implementing product screens.
- Preserve accessibility basics: readable contrast, tappable controls, semantic labels where relevant.
- Extract repeated colors, spacing, typography, and components once repetition is real.

## Verification

- Run `flutter analyze` after Dart/Flutter changes.
- Run `flutter test` when changing logic, widgets with tests, or behavior covered by tests.
- Run `flutter run` only when runtime verification is needed and the user expects it.
