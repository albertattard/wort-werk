---
id: TASK-01-0004
title: Launch Flutter baseline on selected physical device
status: blocked
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-01-0003]
blocks: []
updated: 2026-09-13
---

## Scope

Launch the generated, unmodified Flutter starter application on the selected physical device and verify that it can be opened from the device home screen. Do not begin application feature work.

## Completion criteria

- The application launches successfully on the selected physical device.
- The app can be opened from the device home screen after installation.
- The target device, launch command, and observed result are recorded.

## Evidence

Blocked by TASK-01-0003.

## Decisions and blockers

An emulator or simulator does not satisfy this task. The release acceptance criterion requires a physical-device launch.
