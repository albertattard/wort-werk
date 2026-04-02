# Project Brief: German Article Trainer (Agentic Experiment)

## Goal
Build a small experimental program that helps the learner practice German noun articles (`der`, `die`, `das`) using object images.

## Product Vision
A focused learning tool where the learner sees an image and must choose the correct German article. The system gives immediate feedback and adapts practice over time.

## Primary User
- Single learner (project owner)
- Learning German through repeated, active recall of noun + article pairs

## Current Scope (MVP)
- Show one object image at a time
- Provide exactly three answer options: `der`, `die`, `das`
- Show immediate feedback after each answer
- Feedback includes only German, e.g. `Richtig: der Apfel`
- No English words in UI or feedback
- Run a fixed 10-question session
- Show final score at the end of the session

## Explicit Content Rules
- No English translation fields shown to learner
- Prompt is image-only
- Feedback is German-only

## Data Rules (Initial)
- Start with a small curated noun list (20 items)
- Each item should include:
  - `noun` (German noun)
  - `article` (`der` | `die` | `das`)
  - `image` (local path)
- Keep images local in the first version

## Selected Architecture
- Language: Java
- Framework: Spring Boot
- Templating/UI: Thymeleaf
- Build tool: Maven
- Decision record: `docs/decisions/ADR-0001-use-java-spring-boot-thymeleaf-maven.md`

## Recommended Delivery Plan (Phased)
1. Tiny vertical slice
   - Hardcoded single word + article check
2. MVP quiz loop
   - Dataset-driven quiz, 10-question session, scoring
3. Basic persistence
   - Save progress locally (JSON first)
4. Agentic layer
   - Agent chooses next word based on mistakes
   - Agent gives short German hint after mistakes
   - Agent updates learner profile

## Non-Goals (for now)
- No grammar cases beyond nominative article choice
- No multiplayer or authentication
- No heavy infrastructure
- No external image API dependency

## Collaboration Model
- User steers product decisions via chat
- Codex implements in small increments
- Each increment includes:
  - what changed
  - how to run
  - what decision is needed next

## Milestones
1. MVP v0
   - Image-only prompts
   - `der/die/das` selection
   - 10-question scoring session
2. MVP v1
   - Session history + per-word stats
3. Experimental v2
   - Agent-driven word scheduling and hinting

## Open Questions
- Source/licensing strategy for local images
- Desired visual style and tone of UI
