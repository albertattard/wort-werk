# Decision Log

This file is a high-level index. Canonical architectural decisions live in ADRs.

- ADR index: `docs/decisions/README.md`
- ADR template: `docs/decisions/ADR-TEMPLATE.md`

## Active Decisions (Summary)

## 2026-03-29

### D-001: Start with an incremental, phase-based delivery
- Decision: Build in phases (MVP quiz first, agentic features later)
- Why: Fast feedback loop and lower implementation risk
- Tradeoff: Advanced adaptive behavior comes later
- Status: Active

### D-002: Start with a tiny vertical slice before expanding
- Decision: Implement a minimal end-to-end flow first
- Why: Validate core loop quickly
- Tradeoff: Initial version will be intentionally simple
- Status: Active

### D-003: English must be excluded from learner-facing experience
- Decision: Do not show English words/translations in prompts or feedback
- Why: Increase direct German recall and immersion
- Tradeoff: Slightly higher difficulty for early sessions
- Status: Active

### D-004: MVP quiz session structure
- Decision: Use fixed 10-question sessions with immediate feedback and final score
- Why: Simple, measurable unit for iteration
- Tradeoff: Less flexibility than custom session lengths
- Status: Active

### D-005: Initial data model and media strategy
- Decision: Begin with 20 curated German nouns and local images
- Why: Avoid external API complexity and keep setup stable
- Tradeoff: Limited initial vocabulary set
- Status: Active

### D-006: Context preservation workflow
- Decision: Maintain three living docs (`project-brief.md`, `decision-log.md`, `backlog.md`)
- Why: Keep product direction and priorities explicit across sessions
- Tradeoff: Small ongoing documentation overhead
- Status: Active

### D-007: Java web stack selected
- Decision: Use Java with Spring Boot, Thymeleaf, and Maven
- Why: Aligns with Java-first workflow and keeps MVP implementation simple
- Tradeoff: Less frontend flexibility than SPA stack
- Status: Active
- ADR: `docs/decisions/ADR-0001-use-java-spring-boot-thymeleaf-maven.md`
