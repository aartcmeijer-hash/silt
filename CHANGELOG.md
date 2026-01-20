# Changelog

All notable changes to this project will be documented in this file.

## [2026-01-19]

### Added
- **Trial Phase (Combat)**
  - Implemented core combat loop and logic in `TrialManager`.
  - Added `Trial` scene and `TrialUI` for tactical combat interface.
  - Implemented `GridManager` for grid-based movement, occupancy tracking, and interaction.
  - Added `CombatResolver` for attack resolution, hit locations, and damage calculation.
  - Added `UnitEntity` to represent survivors and monsters on the grid.
  - Added resources: `HitLocationResource` and `AICardResource`.

- **Game Phases & Flow**
  - Implemented `Omen` phase (Event/Choice) with responsive UI logic.
  - Implemented `SiltPhase` (Settlement) for resource management and innovation.
  - Updated `GameManager` to orchestrate transitions between Omen, Trial, and Silt phases.
  - Added `Main` scene and script as the application entry point.

- **UI & Visualization**
  - Added `MainUI` handling responsive layout switching (Landscape/Portrait).
  - Added `SurvivorCard` component for displaying survivor stats and injury status.
  - Added `Chronicle` system for logging game events.
  - Implemented "Brutalist Egyptology" aesthetic via `ColorPalette` and themes.

- **Resources & Data**
  - Added `InnovationResource`, `SocietyResource`, and `TraditionResource`.
  - Added `SurvivorResource` with support for body parts, aging, and temporary buffs.

- **Testing & CI**
  - Added comprehensive unit tests for all new managers (`TrialManager`, `GridManager`, `GameManager`, `SiltPhase`).
  - Added integration tests for main game flow and resource duplication.
  - Added benchmark scripts for roster performance.
  - Updated `AGENTS.md` with architectural details and project knowledge.
