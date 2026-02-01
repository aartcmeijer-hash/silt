# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Codebase Structure & Conventions
* **Directories**:
    * `scripts/`: General GDScript logic. Contains Nodes (PascalCase, e.g., `GameManager.gd`) and some Resources (snake_case, e.g., `survivor_resource.gd`).
    * `resources/`: Contains Settlement Resources (PascalCase, e.g., `SocietyResource.gd`).
    * `scenes/`: Contains `.tscn` scene files.
    * `tests/`: Contains test scripts.
    * `benchmarks/`: Contains performance benchmark scripts.
* **Naming Conventions**:
    * Scripts extending `Node` generally use **PascalCase**.
    * ScriptableObjects/Resources use mixed naming: **PascalCase** in `resources/` and **snake_case** in `scripts/`.
    * Classes use `class_name` definitions (e.g., `class_name UnitEntity`, `class_name SurvivorResource`).
* **Architecture**:
    * The project follows a data-driven architecture using extended `Resource` classes.
    * `GameManager` is the central Autoload singleton, defined in `project.godot`.

## Project Status & Environment
* **Engine Version**: Godot 4.5 (Forward Plus).
* **Binaries**: The binary to run godot is `godot4`. The standard `godot` command is not available.
* **Platforms**: Targets Mac and Android (`_unhandled_input` used for cross-platform interaction).
* **Missing/Broken Components**:
    * `addons/` directory is missing (GdUnit4/GUT are not installed).
    * `tests/gut_test.gd` is missing, causing `tests/test_grid_manager.gd` to fail.
    * `export_presets.cfg` is missing.
    * `DESIGN_SYSTEM.md`, `ColorPalette.gd`, and `resources/main_theme.theme` are missing.

## Game Logic & Managers
* **Game Cycle**: 'OMEN' -> 'TRIAL' -> 'SILT'.
* **GameManager**: Manages global state (Society, Roster, Boss ID) and scene transitions.
    - 'Genesis' start sequence (Decade 1) is orchestrated by `start_new_game()`, initializing roster and society before transitioning to 'OMEN'.
* **TrialManager**: Coordinats turn-based combat (`PLAYER_PHASE` vs `MONSTER_PHASE`).
    - Ensures resource uniqueness by calling `duplicate(true)` on `survivor_resource`, `ai_deck`, and `hit_location_deck` during initialization.
* **GridManager**: Handles grid state, navigation (`occupancy_map`), and camera control.
    - Decouples input via `move_requested` and `interaction_requested` signals.
    - Exposes public methods `move_unit(unit, target_pos)` and `get_unit_at(grid_pos)`.
    - Camera implements 'Drag-to-Pan' and 'Scroll-to-Zoom' via `_unhandled_input`.
* **UnitEntity**: Represents a unit on the grid (`scripts/UnitEntity.gd`).
    - Determines grid coordinates using `TILE_SIZE` from parent node (defaulting to 64).
* **Combat**:
    - `CombatResolver` handles mechanics, hit locations, and damage logging.
    - Severe injuries use a D10 roll: 1-2 (Death), 3-5 (Maimed), 6-10 (Knockdown).
* **Settlement (SiltPhase)**:
    - Managed by `SiltPhase.gd`.
    - `SocietyResource` tracks `resources` (Dictionary) and `unlocked_innovations` (Array).
* **Resources**:
    - `SurvivorResource` (`scripts/survivor_resource.gd`) tracks structural health via `body_parts`, aging via `age_decades`, and transient effects via `temporary_buffs`.

## UI & Aesthetics
* **Style**: "Brutalist Egyptology" (Dried Silt #b5a48b background, Lapis Blue #0047ab accents).
* **Responsiveness**:
    - `MainUI` and `Omen` handle layout switching (Landscape vs Portrait) based on an aspect ratio threshold of 1.0.
    - `Omen.gd` choice cards use `PanelContainer` with custom `gui_input`, scaling, and border color changes for feedback.
* **SurvivorCard**: Visualizes status using body part icons and color codes: White (Armor), Yellow (Injured), Red (Shattered), Black (Dead).
* **Input Blocking**: Blocking UI elements use `mouse_filter = Stop`, while non-blocking overlays use `mouse_filter = Ignore`.

## Testing
* **Legacy Tests**:
    - Standalone GDScript files extending `SceneTree`.
    - Run via: `godot4 --headless -s tests/test_script.gd`.
    - **Note**: `tests/test_gamemanager.gd` contains an incorrect path to `SurvivorResource` (`res://resources/` instead of `res://scripts/`).
* **Frameworks**:
    - GUT/GdUnit4 are referenced but currently non-functional due to missing files.
* **Benchmarks**: Located in `benchmarks/`.

## Optimization & Best Practices
* Avoid O(N^2) complexities in loops.
* Use backward iteration with `remove_at()` for array filtering.
* Explicitly disconnect signals from persistent nodes in `_exit_tree()` to prevent ghosting.
