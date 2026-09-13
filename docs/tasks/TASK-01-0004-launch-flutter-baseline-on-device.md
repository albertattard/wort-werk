---
id: TASK-01-0004
title: Launch Flutter baseline on selected physical device
status: complete
milestone: flutter_baseline_and_physical_device_launch
depends_on: [TASK-01-0003]
blocks: []
updated: 2026-09-13
---

## Scope

Launch the generated Flutter starter application, with its configured Android application ID, on the selected physical device and verify that it can be opened from the device home screen. Do not begin application feature work.

## Completion criteria

- The application launches successfully on the selected physical device.
- The app can be opened from the device home screen after installation.
- The target device, launch command, and observed result are recorded.

## Evidence

On 2026-09-13, the generated baseline was launched on the USB-connected Google Pixel 8 (`41290DLJH001LG`, Android 17 / API 37) with:

```text
flutter run -d 41290DLJH001LG
```

Flutter built `build/app/outputs/flutter-apk/app-debug.apk`, installed it, and started `io.github.albertattard.wortwerk.MainActivity`; the Dart VM service became available on the device. `flutter analyze` also completed with no issues before the launch.

The phone was returned to its home screen and the installed app was manually reopened from its launcher icon. Android Debug Bridge also reported `Status: ok` for `io.github.albertattard.wortwerk/.MainActivity`.

## Decisions and blockers

An emulator or simulator does not satisfy this task. The release acceptance criterion requires a physical-device launch.

## Next task

Complete TASK-02-0001 to define the article domain model and map JSON records before beginning repository implementation.
