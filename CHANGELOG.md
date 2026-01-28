# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-01-28

### Changed
- Update `AGENTS.md` to reflect current project state:
    - Corrected Godot version to 4.5.
    - Updated testing section to reflect legacy SceneTree tests and removal of GdUnit4 references.
    - Updated severe injury logic to match `CombatResolver.gd` (1-2 Death, 3-9 Maimed, 10 Survival).
    - Noted mixed resource naming conventions (snake_case in `scripts/`, PascalCase in `resources/`).
    - Clarified lack of CI/CD configuration.
    - Added note about broken benchmark script path.
