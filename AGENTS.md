# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Codebase Structure & Logic
* General GDScript logic files are located in the `scripts/` directory.
* The application entry point is defined as `scenes/Main.tscn` in `project.godot`, utilizing `scripts/Main.gd` to handle initial game bootstrapping logic.
* The project follows a data-driven architecture using extended `Resource` classes.
* New resource types `InnovationResource`, `SocietyResource`, and `TraditionResource` are defined in the `resources/` directory.
* Other resource definitions including `SurvivorResource`, `AICardResource`, and `HitLocationResource` are located in `scripts/`.
* `UnitEntity.gd` serves as the base node for units on the grid, managing `survivor_resource` data, integrity, and grid positioning.
* `SocietyResource` tracks settlement state including a `resources` Dictionary and `unlocked_innovations` Array.
* `SurvivorResource` tracks structural health via a `body_parts` dictionary and aging via `age_decades`. Survivors are retired when `age_decades > 5`.
* `SurvivorResource` includes a `temporary_buffs` Array to track transient status effects (e.g., Omen buffs) separately from permanent traits.

## Game Loop & Managers
* The game cycle phases are defined as 'OMEN', 'TRIAL', and 'SILT'.
* The `GameManager` singleton (autoloaded from `scripts/GameManager.gd`) manages global state (Society, Survivor roster, Boss ID), scene transitions, and emits `innovation_unlocked`, `survivor_died`, and `chronicle_log` signals.
* The 'Genesis' game start sequence (Decade 1) is orchestrated by `GameManager.start_new_game()`, which initializes the roster and society before transitioning to the `OMEN` phase.
* `TrialManager.gd` acts as the central coordinator for turn-based combat, managing `PLAYER_PHASE` and `MONSTER_PHASE` via a state machine.
* `TrialManager` ensures resource uniqueness by calling `duplicate(true)` on `survivor_resource`, `ai_deck`, and `hit_location_deck` for all units in `grid_manager.occupancy_map` during `_ready()` and `_initialize_resources()`.
* Action economy for survivors is tracked via a `TurnState` object containing `can_move` and `can_act` booleans.
* `GridManager` decouples input from logic by emitting a `move_requested` signal, which is validated and executed by `TrialManager`.
* `SiltPhase` controller (`scripts/SiltPhase.gd`) handles the Settlement layer logic, including innovation prerequisites, resource expenditure, and tradition resolution.

## Combat & AI
* Monster AI behavior is defined by `AICardResource` decks and utilizes Manhattan distance for 'Step-Toward' movement logic.
* `CombatResolver.gd` handles combat mechanics including hit location decks, reaction triggers (`reaction_triggered` signal), and damage logging (`combat_log` signal).
* Severe injuries are determined by a D10 roll when an already injured body part is hit:
    * 1-2: Death.
    * 3-9: Maimed/Trait (Shattered).
    * 10: Survival/No Permanent Effect.
* Tactical movement implements a 'Select-and-Confirm' input flow (Select Unit -> Show Ghost -> Confirm Move).
* Grid navigation logic relies on an `occupancy_map` Dictionary mapping `Vector2i` coordinates to occupying `Node` instances.

## UI & Aesthetics
* The "Brutalist Egyptology" UI aesthetic defines "Dried Silt" (#b5a48b) as the background color and "Lapis Blue" (#0047ab) for accents.
* `MainUI` handles responsive layout switching between landscape (grid/HUD split) and portrait (vertical stack) modes by toggling the `vertical` property of the `MainContainer` (a `BoxContainer`).
* `Omen.gd` handles responsive layout by toggling the `vertical` property of its `BoxContainer` based on an aspect ratio threshold of 1.0.
* Choice cards in the Omen phase are implemented as `PanelContainer` nodes handling `gui_input` for interaction, featuring hover scaling and border color changes, rather than standard Button nodes.
* `SurvivorCard` displays survivor status using body part icons and color codes: White (Armor), Yellow (Injured), Red (Shattered), Black (Dead).
* `Chronicle` UI logs game history by listening to `GameManager` signals and adding text entries to a scrollable container.
* When modifying UI element styles (e.g., in `SurvivorCard`), use `add_theme_stylebox_override` with new `StyleBoxFlat` instances to avoid mutating shared theme resources.
* Grid input logic uses `_unhandled_input` to allow overlapping UI elements to block interaction. UI containers (e.g., `HUDContainer`) must use `mouse_filter = Stop` (0), while non-blocking overlays (e.g., `GridPlaceholder`) use `mouse_filter = Ignore` (2).

## Testing & CI
* Test scripts are located in the `tests/` directory.
* Testing uses a legacy approach where test scripts extend `SceneTree` and are executed via `godot -s tests/test_script.gd`.
* There is no GdUnit4 installed and no `addons/` directory.
* Tests must manually load necessary scripts and instantiate classes (mocks or real) as there is no automatic runner or autoload injection in this mode.
* The project currently lacks a CI/CD configuration (no `.github` directory).
* Benchmark scripts are located in the `benchmarks/` directory.

## Optimization & Best Practices
* To prevent signal ghosting during scene transitions, scripts must explicitly disconnect signals from persistent nodes (e.g., `GameManager`, `get_tree().root`) within the `_exit_tree()` method using `is_connected()` checks.
* The user prioritizes performance optimization, specifically avoiding O(N^2) complexities in loops. Backward iteration using `remove_at()` is preferred over `erase()` for array filtering to eliminate linear search overhead.

## Environment
* The project is a tactical roguelike game configured to target Godot 4.5.
* The project targets Mac and Android platforms, utilizing `_unhandled_input` for cross-platform interaction.
* The binary to run godot is called `godot4`.
* The `godot` command is not available in the default environment `PATH`.
