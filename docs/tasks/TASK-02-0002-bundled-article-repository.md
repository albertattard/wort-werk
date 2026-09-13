---
id: TASK-02-0002
title: Load bundled articles through a repository
status: blocked
milestone: content_model_and_validation
depends_on: [TASK-02-0001]
blocks: [TASK-02-0003, TASK-02-0004]
updated: 2026-09-13
---

## Scope

Add a repository that loads `assets/articles.json` from Flutter's bundled assets and returns typed `Article` records using the JSON-record mapper from TASK-02-0001. Keep asset I/O and content loading outside widgets.

## Completion criteria

- The repository loads the declared JSON asset through an asset-bundle boundary.
- It accepts only a top-level JSON array of article objects.
- It returns typed `Article` records rather than JSON strings or maps.
- Invalid JSON or any other top-level JSON value fails fast with a `FormatException`; it does not return partial data.
- Unit tests cover successful loading with a controlled asset-bundle double.
- Widgets, image rendering, audio playback, answer buttons, and content-policy validation are not added.

## Evidence

Blocked by TASK-02-0001.

## Decisions and blockers

The repository is the only Milestone 2 component that knows how to read the bundled JSON. It reports the bundled asset path when rethrowing a JSON-decoding `FormatException`, and does not silently skip malformed content. The developer-facing exception includes record context where available; any later learner-facing UI should simply report malformed or unavailable bundled content. TASK-02-0003 adds collection-level validation to this loading path.

## Next task

TASK-02-0003: reject invalid article content predictably.
