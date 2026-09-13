---
id: TASK-01-0002
title: Prepare Flutter target toolchain
status: complete
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

TASK-01-0001 selected Android on a Google Pixel 8 connected by USB. On 2026-09-13, Flutter 3.47.4 (stable, Dart 3.13.3) was installed at `/opt/homebrew/share/flutter`. The Android SDK at `/opt/homebrew/share/android-commandlinetools` has platform `android-36`, build-tools `36.0.0`, platform-tools, and all SDK licences accepted. `flutter doctor -v` reports a healthy Android toolchain; its remaining Xcode warning is irrelevant to the Android-only target. `flutter devices` detects the authorized Pixel 8 as `41290DLJH001LG` on Android 17 (API 37).

## Decisions and blockers

Do not install or configure the other mobile platform merely for future flexibility. This task is limited to the selected target.

## Next task

TASK-01-0003: generate the Flutter baseline and declare the existing bundled assets. Keep the Pixel 8 connected for TASK-01-0004.
