# Wort-Werk — Vision

## One-Line Thesis

Wort-Werk helps learners internalize German noun articles by training direct recall from images.

## Problem

German learners often know nouns but confuse grammatical gender and article usage (`der`, `die`, `das`).

Most practice tools over-rely on translation prompts, which can weaken direct recall of article+noun patterns.

## Solution

Wort-Werk shows object images and asks the learner to choose the correct German article. The product gives immediate feedback and gradually adapts question selection based on past mistakes.

## Workflow

1. Maintain behavior in `docs/spec/`.
2. Create a concrete implementation task in `docs/tasks/`.
3. Implement code for that task.
4. Mark task/spec progress after acceptance criteria pass.

## Scope (Current)

In scope:
- image-only prompt
- three choices (`der`, `die`, `das`)
- German-only feedback
- fixed 10-question sessions

Out of scope (for now):
- translation mode
- grammar cases beyond article selection
- multiplayer and auth
