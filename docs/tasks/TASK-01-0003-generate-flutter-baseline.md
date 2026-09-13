---
id: TASK-01-0003
title: Generate Flutter baseline and declare bundled assets
status: complete
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-01-0002]
blocks: [TASK-01-0004]
updated: 2026-09-13
---

## Scope

Generate the Flutter application in this repository while preserving the committed content and documentation. Declare the existing bundled asset directories in `pubspec.yaml`. Keep the generated starter experience otherwise unmodified.

## Completion criteria

- Flutter project files are generated without replacing `assets/` or `docs/`.
- `pubspec.yaml` declares the bundled image and audio asset directories and `assets/articles.json`.
- `flutter pub get` succeeds.
- The focused change contains scaffolding and platform configuration only.

## Evidence

On 2026-09-13, generated the Android-only empty Flutter application with
`flutter create --template app --empty --project-name wort_werk --platforms=android --no-pub .`.
The existing `assets/` and `docs/` directories were retained. `pubspec.yaml`
declares `assets/articles.json`, `assets/images/`, and `assets/audio/`.
`flutter pub get` and `flutter analyze` both succeeded.

## Decisions and blockers

Do not add content parsing, widgets for the exercise, persistence, remote services, or learning behavior. Those belong to later milestones.

## Next task

TASK-01-0004: launch the unmodified Flutter baseline on the connected Google Pixel 8.
