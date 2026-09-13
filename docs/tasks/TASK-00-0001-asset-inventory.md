---
id: TASK-00-0001
title: Asset inventory
status: complete
milestone: content_intake
depends_on: []
blocks: [TASK-00-0002]
updated: 2026-09-13
---

## Scope

Inventory the committed `assets/` tree for the article-practice dataset. Do not add, remove, or rename assets as part of this task.

## Completion criteria

- Enumerate the article records and their referenced image, noun-audio, and answer-audio files.
- Report any missing, mismatched, or ambiguous paths.
- Record the inventory command and its result in this task.

## Evidence

### Article record enumeration

`assets/articles.json` is the canonical inventory. Its `Id`, `Image`, `Audio`, and `AnswerAudio` properties enumerate all article records and their required asset paths.

```sh
jq -r '.[] | "\(.Id) | image=\(.Image) | noun-audio=\(.Audio) | answer-audio=\(.AnswerAudio)"' assets/articles.json
```

Result: the command enumerates 127 article records, each with one image path, one noun-audio path, and one answer-audio path.

### Integrity check

The JSON has seven required properties in every record, 127 unique non-empty IDs, and only the supported articles (`der`, `die`, and `das`). All 381 declared references are safe local `assets/images/` or `assets/audio/` paths that resolve to files. The 127 unique referenced images are readable PNG files and the 249 unique referenced audio files are readable MP3 files.

No paths are missing or mismatched. Five audio references are intentionally shared: `flugticket-01` and `flugticket-02` share both audio files, `zeitung-01` and `zeitung-02` share both audio files, and `speckstreifen` and `speckstreifen-pl` share the noun audio while retaining article-specific answer audio. The image filenames distinguish each corresponding variant.

## Decisions and blockers

Asset availability is established locally; this task does not establish source provenance or redistribution permission. The checks above validate JSON structure, path mapping, and media readability; they do not manually verify the semantic content of each recording or image.
