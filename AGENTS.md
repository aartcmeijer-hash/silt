# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Codebase Structure & Logic
* General GDScript logic files are located in the `scripts/` directory.
* The application entry point is defined as `scenes/Main.tscn` in `project.godot`, utilizing `scripts/Main.gd` (if present) or `MainUI` to handle initial game bootstrapping logic.
* The project follows a data-driven architecture using extended `Resource` classes.
* `SurvivorResource` (`scripts/survivor_resource.gd`) tracks structural health via a `body_parts` dictionary and aging via `age_decades`.
* `SocietyResource` (`resources/SocietyResource.gd`) tracks settlement state including a `resources` Dictionary and `unlocked_innovations` Array.
* `UnitEntity` (`scripts/UnitEntity.gd`) represents objects on the grid, holding references to `SurvivorResource`, `ai_deck`, and `hit_location_deck`.

## Game Loop & Managers
* `GameManager` (Autoload) manages global state (Society, Survivor roster, Boss ID), scene transitions, and emits `innovation_unlocked`, `survivor_died`, and `chronicle_log` signals.
* `TrialManager.gd` acts as the central coordinator for turn-based combat, managing `PLAYER_PHASE` and `MONSTER_PHASE` via a state machine.
* `GridManager.gd` handles grid logic, occupancy mapping, camera control, and input, decoupling input from logic by emitting `move_requested` and `interaction_requested` signals.
* `TrialManager` coordinates with `GridManager` to spawn units and handle turn logic.
* `CombatResolver.gd` (instantiated by `TrialManager`) handles combat mechanics, though currently mocked in `TrialManager`.

## Combat & AI
* Monster AI behavior is defined by `AICardResource` decks and utilizes Manhattan distance for 'Step-Toward' movement logic.
* Boss logic in `TrialManager` implements a simple AI loop: Play Card -> Select Target -> Move -> Attack.
* `UnitEntity` holds `integrity` for bosses and `survivor_resource` for players.

## UI & Aesthetics
* `MainUI.gd` handles responsive layout switching between landscape (grid/HUD split) and portrait (vertical stack) modes based on an aspect ratio threshold of 1.0.
* `TrialUI.gd` manages the HUD, including a 'StatusPanel' and 'LogPanel' for combat feedback.
* `SurvivorCard` (if present) displays survivor status using body part icons and color codes: White (Armor), Yellow (Injured), Red (Shattered), Black (Dead).
* Input logic in `GridManager` uses `_unhandled_input` to allow overlapping UI elements to block interaction.

## Testing & CI
* Test scripts are located in the `tests/` directory.
* **Current State:** Tests are legacy GDScript files extending `SceneTree` (e.g., `tests/test_combat_resolver.gd`).
* `GdUnit4` is **not currently installed** in the project, despite previous references. `addons/` directory is missing.
* CI configuration (GitHub Actions) is **not present** in the repository root.

## Conventions
* **Class Names:** Use `class_name` for core logic scripts (e.g., `class_name TrialManager`).
* **Signal Connections:** Explicitly connect signals in `_ready()` or via editor.
* **Input Handling:** Use `_unhandled_input` for game world interaction to respect UI blocking.
* **Resources:** Store data in `Resource` derivatives.

## Project Status
* **Godot Version:** Project configuration targets Godot 4.x (features "4.5" listed in `project.godot` needs verification/correction to standard 4.2/4.3).
* **Missing Components:** `addons/` folder (GdUnit4), `export_presets.cfg`, CI workflows.
* **To-Do:** Restore GdUnit4, fix `project.godot` version string, implement actual Scene files (`omen.tscn`, `trial.tscn`, etc.) referenced in `GameManager`.
