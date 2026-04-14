# Backlog

## Now
- Finalize and approve MVP specification from `project-brief.md`
- Define starter dataset format and file locations
- Prepare 20-item German noun seed list with articles and image filenames
- Set up Spring Boot + Thymeleaf + Maven project scaffold

## Next
- Build UI shell (single page with image and `der/die/das` buttons)
- Implement answer validation and feedback (`Richtig/Falsch` + correct German noun phrase)
- Implement 10-question session flow
- Implement score tracking and final results screen

## Later
- Add local progress persistence (JSON)
- Track per-word performance metrics
- Add adaptive scheduling (mistakes appear sooner)
- Introduce agentic orchestration for word selection and hints

## Parking Lot
- Expand content categories (food, home, travel)
- Add plural training mode
- Add Akkusativ/Dativ drills after nominative mastery
- Make OCI deploy profile configurable with explicit environment/tenant mapping instead of defaulting to `FRANKFURT`
- Replace runtime registry password in Terraform state with OCI-managed secret integration for private OCIR pulls
- Run container e2e verification on both `linux/amd64` and `linux/arm64` (currently validated on one architecture only)
- Restore OCI DevOps runtime image publication for `linux/arm64` by introducing either a native arm64 release builder or a container build layout that does not execute target-architecture binaries during image assembly
