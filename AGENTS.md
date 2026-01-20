# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Codebase Structure
*   **scripts/**: Contains core logic (`GameManager`, `TrialManager`, `GridManager`, `CombatResolver`) and UI logic (`MainUI`, `SurvivorCard`).
*   **scenes/**: Contains the main scenes matching the scripts.
*   **tests/**: Contains test scripts. Legacy tests extend `SceneTree` and run via `godot -s`. CI tests may use GdUnit4, but local setup relies on standalone scripts.
*   **resources/**: Contains custom Resource definitions (`SocietyResource`, `SurvivorResource`, `AICardResource`).
*   The application entry point is `scenes/Main.tscn` (via `scripts/Main.gd`).

## Core Architecture
*   **GameManager**: Singleton managing global state (`active_society`, `current_roster`, `next_encounter_boss`) and phase transitions (`OMEN`, `TRIAL`, `SILT`). Emits signals like `chronicle_log`, `survivor_died`.
*   **TrialManager**: Orchestrates turn-based combat (`PLAYER_PHASE`, `MONSTER_PHASE`). Duplicates resources (`survivor_resource`, `ai_deck`) for uniqueness.
*   **GridManager**: Handles grid logic (`occupancy_map`), input (`_unhandled_input` for camera/selection), and visualization.
*   **CombatResolver**: Helper node in `TrialManager` handling attack logic, hit locations, and injury rolls.
*   **Data-Driven**: Heavy use of `Resource` classes (`SurvivorResource`, `AICardResource`) for game data.

## Combat Mechanics
*   **Phases**: Player Phase (Unit Selection, Movement, Attack) -> Monster Phase (AI Deck, Movement, Attack).
*   **AI**: `AICardResource` defines behavior. Uses Manhattan distance for 'Step-Toward' logic.
*   **Resolution**:
    *   **Survivor Attack**: Draws from Boss `HitLocationResource` deck.
    *   **Boss Attack**: Random D4 location roll. Checks Armor -> Injury -> Severe Injury (D10 roll).
    *   **Severe Injury**: 1-2 Death, 3-9 Maimed (Trait), 10 Survival.

## UI & Visuals
*   **Design System**: "Brutalist Egyptology" aesthetic.
*   **Responsive Layout**: `MainUI` switches between Landscape (Grid/HUD split) and Portrait (Vertical stack) based on aspect ratio (threshold 1.0).
*   **Styling**: `SurvivorCard` uses `add_theme_stylebox_override` with `StyleBoxFlat` for dynamic status colors:
    *   White: Armor > 0
    *   Yellow: Injured
    *   Red: Shattered
    *   Black: Dead
*   **Camera**: `GridManager` handles "Drag-to-Pan" and "Scroll-to-Zoom".

## Testing & CI
*   **Legacy Tests**: Located in `tests/`, extending `SceneTree`. Run with `godot -s tests/test_script_name.gd`. This is the preferred method for local testing.
*   **CI**: GitHub Actions workflow uses `barichello/godot-ci:4.2`. It installs GdUnit4 dynamically. Some tests (`test_grid_manager.gd`) rely on `gut_test.gd` (assumed available in CI).
*   **Godot Binary**: The binary is named `godot4` in the environment.

## Conventions
*   **Signals**: Explicitly disconnect signals in `_exit_tree` to prevent ghosting.
*   **Input**: Use `_unhandled_input` for game logic to allow UI to consume events.
*   **Optimization**: Avoid O(N^2) loops. Use backward iteration (`remove_at`) for array filtering.
*   **Safety**: Check `is_inside_tree()` before scene changes in scripts that might run headless.
