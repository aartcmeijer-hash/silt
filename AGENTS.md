# Project Knowledge Base

This file contains verified architectural details and conventions for the project.

## Codebase Structure & Logic
* **Directory Structure**:
    *   `scripts/`: General GDScript logic files and custom Resource definitions.
    *   `scenes/`: Scene files (`.tscn`).
    *   `resources/`: Instantiated Resource files (e.g., specific Innovations, Traditions).
    *   `tests/`: Test scripts.
    *   `benchmarks/`: Performance benchmark scripts.
* **Entry Point**: The application entry point is `scenes/Main.tscn` (defined in `project.godot`), utilizing `scripts/Main.gd` to handle initial bootstrapping.
* **Architecture**: The project follows a data-driven architecture where game entities and logic configurations are primarily defined using extended `Resource` classes (e.g., `SurvivorResource`, `AICardResource`).
* **Conventions**:
    *   Class names use PascalCase (e.g., `GameManager`).
    *   Resource definitions use snake_case filenames (e.g., `survivor_resource.gd`).
    *   Variable and function names use snake_case.

## Game Loop & Managers
* The game cycle consists of three main phases: **OMEN**, **TRIAL**, and **SILT**.
* **GameManager**: A singleton (`Autoload`) that manages global state (Society, Survivor roster, Boss ID), scene transitions, and emits global signals like `innovation_unlocked`, `survivor_died`, and `chronicle_log`.
* **Genesis**: The 'Genesis' start sequence (Decade 1) is orchestrated by `GameManager.start_new_game()`, initializing the roster/society before transitioning to the `OMEN` phase.
* **TrialManager**: Acts as the central coordinator for turn-based combat, managing the state machine between `PLAYER_PHASE` and `MONSTER_PHASE`.
* **SiltPhase**: Handles the Settlement layer logic, including innovation prerequisites, resource expenditure, and tradition resolution.

## Combat & AI
* **AI Logic**: Monster AI behavior is defined by `AICardResource` decks and utilizes Manhattan distance for 'Step-Toward' movement logic.
* **CombatResolver**: Handles combat mechanics, including hit location decks, reaction triggers (`reaction_triggered` signal), and damage logging.
* **Damage System**:
    *   `SurvivorResource` tracks structural health via a `body_parts` dictionary.
    *   Severe injuries use a D10 roll when an injured part is hit: 1-2 (Death), 3-5 (Maimed/Trait), 6-10 (Knockdown).
* **Grid System**:
    *   Navigation relies on an `occupancy_map` Dictionary mapping `Vector2i` coordinates to `Node` instances.
    *   `GridManager` decouples input from logic by emitting signals like `move_requested`.

## UI & Aesthetics
* **Style**: The "Brutalist Egyptology" aesthetic uses "Dried Silt" (#b5a48b) for backgrounds and "Lapis Blue" (#0047ab) for accents.
* **Responsiveness**:
    *   `MainUI` and `Omen` scripts handle layout switching between Landscape and Portrait modes based on an aspect ratio threshold of 1.0.
* **Components**:
    *   `SurvivorCard` displays status using color codes: White (Armor), Yellow (Injured), Red (Shattered), Black (Dead).
    *   `Chronicle` logs game history via a scrollable container listening to `GameManager`.
* **Input**: Grid input uses `_unhandled_input` to allow overlapping UI elements to block interaction (using `mouse_filter = Stop`).

## Testing & Quality Assurance
* **Framework**: The project uses a custom legacy testing approach.
* **Location**: Test scripts are located in the `tests/` directory.
* **Format**: Tests are GDScript files that extend `SceneTree`. They are designed to be self-executing.
* **Execution**: Run tests from the command line using the Godot binary (use `--headless` for CI or no-display environments):
    ```bash
    godot4 --headless -s tests/test_script_name.gd
    ```
    *Note: Since these run as standalone scripts:*
    1.  *Autoloads (Singletons) are not automatically initialized and must be mocked or manually instantiated if needed.*
    2.  *Global `class_name` definitions are not resolved. Scripts must explicitly `load()` the resources they reference (e.g., `const CombatResolver = preload("res://scripts/CombatResolver.gd")`).*
* **CI/CD**: There is currently no CI/CD configuration (no `.github` directory).
* **Benchmarks**: located in `benchmarks/`.

## Optimization & Best Practices
* **Signal Safety**: To prevent signal ghosting, scripts must explicitly disconnect signals from persistent nodes (e.g., `GameManager`) within `_exit_tree()` using `is_connected()` checks.
* **Performance**: Avoid O(N^2) complexities. Prefer backward iteration (`remove_at()`) over `erase()` for array filtering.

## Environment
* **Engine Version**: Godot 4.5 ("Forward Plus" renderer).
* **Binary Name**: `godot4`.
* **Platforms**: Targets Mac and Android, utilizing `_unhandled_input` for cross-platform interaction.
* **Missing Config**: `export_presets.cfg` is missing from the repository.
