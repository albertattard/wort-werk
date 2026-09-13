---
id: TASK-01-0001
title: Select initial physical target device
status: planned
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-00-0005]
blocks: [TASK-01-0002]
updated: 2026-09-13
---

## Scope

Choose the single physical platform and device that will prove the first-release baseline: iOS or Android. Record the decision and the device's available connection method. Do not install tooling or generate a Flutter project in this task.

## Completion criteria

- The initial platform is explicitly recorded as iOS or Android, not both.
- A specific physical device is available for the baseline launch.
- The device connection method is recorded: USB or supported wireless debugging.

## Evidence

Not started.

## Decisions and blockers

The first release requires proof on at least one physical device. Supporting both platforms is not required for this milestone and must not delay the baseline.
