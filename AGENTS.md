# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Environment & Status
*   The project is a tactical roguelike game configured to target **Godot 4.5** (Forward Plus).
*   The binary to run godot is called `godot4`.
*   **CI/CD**: The project currently lacks a CI/CD configuration (no `.github` directory).
*   **Addons**: The `addons/` directory is currently missing, which affects the functionality of GdUnit4 tests.

## Codebase Structure & Conventions
*   **File Naming Conventions**:
    *   **PascalCase**: Used for Nodes, Scenes, and Settlement Resources (e.g., `TrialManager.gd`, `Main.tscn`, `SocietyResource.gd`).
    *   **snake_case**: Used for Core Logic Resources located in `scripts/` (e.g., `survivor_resource.gd`, `ai_card_resource.gd`, `hit_location_resource.gd`).
*   **Directories**:
    *   `scripts/`: Contains core logic, managers (`GameManager`, `TrialManager`), entity scripts (`UnitEntity`), and logic resources.
    *   `resources/`: Contains Settlement layer resources (`InnovationResource`, `SocietyResource`, `TraditionResource`).
    *   `scenes/`: Contains all `.tscn` scene files.
    *   `tests/`: Contains test scripts.
    *   `benchmarks/`: Contains performance benchmark scripts.
*   **Entry Point**: `scenes/Main.tscn` (via `scripts/Main.gd`) handles initial bootstrapping.

## Architecture & Logic
*   **Data-Driven**: The project relies heavily on extended `Resource` classes for game data.
*   **Game Loop**:
    *   Phases: 'OMEN', 'TRIAL', 'SILT'.
    *   `GameManager` (Autoload) manages global state (Society, Roster, Boss ID), scene transitions, and emits `innovation_unlocked`, `survivor_died`, and `chronicle_log` signals.
    *   `TrialManager.gd` coordinates turn-based combat (PLAYER_PHASE <-> MONSTER_PHASE) and ensures resource uniqueness for units.
    *   `SiltPhase.gd` handles the Settlement layer logic.
*   **Grid System**:
    *   `GridManager.gd` handles input, camera controls (Drag-to-Pan, Scroll-to-Zoom), and unit placement via an `occupancy_map` Dictionary.
    *   It decouples input from logic by emitting `move_requested` and `interaction_requested` signals.
    *   Input is handled via `_unhandled_input`.
*   **Combat**:
    *   `CombatResolver.gd` handles combat mechanics, hit locations, reaction triggers, and logging (`combat_log` signal).
    *   `UnitEntity.gd` represents units on the grid, holding `survivor_resource`, `integrity`, and decks (AI/Hit Location).
    *   Severe injuries use a D10 roll logic (Death, Maim/Trait, Knockdown).
    *   Action economy is tracked via a `TurnState` object (can_move, can_act).
*   **Decoupling**:
    *   Managers find each other dynamically (e.g., `TrialManager` looks for sibling `GridManager` and `TrialUI`).
    *   Scripts explicitly disconnect signals in `_exit_tree()` to prevent ghosting using `is_connected()` checks.

## UI & Aesthetics
*   **Style**: "Brutalist Egyptology" (Dried Silt #b5a48b background, Lapis Blue #0047ab accents).
*   **Responsiveness**:
    *   `MainUI` and `Omen.gd` switch layouts (Horizontal vs Vertical) based on aspect ratio (threshold 1.0).
*   **Construction**:
    *   `TrialUI` constructs elements (LogPanel, StatusPanel) procedurally in `_ready()`.
    *   `Omen` choice cards are `PanelContainer` nodes with custom `gui_input`.
    *   `SurvivorCard` displays status using icons and color codes (White/Yellow/Red/Black).
    *   `Chronicle` UI logs game history.
*   **Interaction**: Blocking UI uses `mouse_filter = Stop` (0); overlays use `mouse_filter = Ignore` (2).

## Testing
*   **Frameworks**:
    *   **Legacy/SceneTree Tests**: The primary working tests. These extend `SceneTree` and are run via `godot4 -s tests/test_script.gd`.
    *   **GdUnit4**: Tests extending `GdUnitTestSuite` (e.g., `test_grid_manager.gd`) are **currently non-functional** due to missing `addons/`.
*   **Known Issues**:
    *   `tests/test_gamemanager.gd` and `benchmarks/benchmark_roster.gd` currently reference incorrect file paths for `SurvivorResource` (pointing to `resources/` instead of `scripts/`). These must be fixed before running.
*   **Benchmarks**: Located in `benchmarks/`, focused on performance (e.g., array iteration optimization).

## Optimization & Best Practices
*   **Performance**: Backward iteration (`remove_at`) is preferred over `erase()` for array filtering to avoid O(N^2) complexity.
