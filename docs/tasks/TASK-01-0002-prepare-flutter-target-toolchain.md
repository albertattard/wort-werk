---
id: TASK-01-0002
title: Prepare Flutter target toolchain
status: planned
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-01-0001]
blocks: [TASK-01-0003]
updated: 2026-09-13
---

## Scope

Install Flutter and only the platform tooling needed for the selected physical target. Resolve target-relevant `flutter doctor` findings and confirm that Flutter detects the target phone. Do not create application source files.

## Completion criteria

- `flutter doctor` has no unresolved findings that prevent launch on the selected target.
- `flutter devices` lists the selected physical device.
- The Flutter SDK version and relevant platform-tool status are recorded.

## Evidence

TASK-01-0001 selected Android on a Google Pixel 8 connected by USB. Toolchain preparation has not started.

## Decisions and blockers

Do not install or configure the other mobile platform merely for future flexibility. This task is limited to the selected target.
