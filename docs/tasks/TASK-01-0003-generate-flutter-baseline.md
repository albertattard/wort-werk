---
id: TASK-01-0003
title: Generate Flutter baseline and declare bundled assets
status: blocked
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-01-0002]
blocks: [TASK-01-0004]
updated: 2026-09-13
---

## Scope

Generate the Flutter application in this repository while preserving the committed content and documentation. Declare the existing bundled asset directories in `pubspec.yaml`. Keep the generated starter experience otherwise unmodified.

## Completion criteria

- Flutter project files are generated without replacing `assets/` or `docs/`.
- `pubspec.yaml` declares the bundled image and audio asset directories and `assets/articles.csv`.
- `flutter pub get` succeeds.
- The focused change contains scaffolding and platform configuration only.

## Evidence

Blocked by TASK-01-0002.

## Decisions and blockers

Do not add content parsing, widgets for the exercise, persistence, remote services, or learning behavior. Those belong to later milestones.
