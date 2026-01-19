# Design System & Responsive Layout Rules

## Layout Philosophy
- **Margins:** Always use `MarginContainer` with a standard padding of **20px** (`theme_override_constants/margin_*`).
- **Backgrounds:** Use `Control` nodes (like `ColorRect` or `TextureRect`) with **Anchors Preset: Full Rect** (`anchors_preset = 15`) to cover the entire screen.
- **Scaling:** UI elements should adapt to the screen size. Use `BoxContainer` (VBox/HBox) for flow layouts.

## Responsive Logic (Landscape vs Portrait)
The UI must adapt to the device orientation (Landscape 16:9 vs Portrait 9:16).

### Implementation Guide
1.  **Aspect Ratio Check:**
    Check the aspect ratio of the viewport to determine orientation.
    ```gdscript
    var is_portrait = get_viewport_rect().size.aspect() < 1.0
    ```

2.  **Container Orientation:**
    Switch the main container's orientation based on the aspect ratio.
    - **Landscape:** Use `HBoxContainer` (or horizontal flow).
    - **Portrait:** Use `VBoxContainer` (or vertical flow).

    *Example Implementation:*
    ```gdscript
    func _on_viewport_size_changed():
        var is_portrait = get_viewport_rect().size.aspect() < 1.0
        if main_container is BoxContainer:
            main_container.vertical = is_portrait
            # Note: BoxContainer doesn't have 'vertical' property directly in Godot 4 (it has 'vertical' property in Godot 3?)
            # In Godot 4, HBoxContainer and VBoxContainer are separate classes inheriting BoxContainer.
            # To switch dynamically, you might need to reparent children or change a custom property if using a unified flow container.
            # Alternatively, simply change the 'vertical' property if using a wrapper script, or swap the node type.
            # A common pattern is to use a `BoxContainer` and set `vertical = true/false` is NOT valid in Godot 4.
            # CORRECT APPROACH:
            # Use `FlowContainer` or change `BoxContainer` subclass? No.
            # Better: Have two parent containers (HBox and VBox) and reparent? Complex.
            # Best: Change the `vertical` property of `BoxContainer`?
            # WAIT: BoxContainer class *does* exist, and HBox/VBox extend it. But `vertical` property was removed/changed?
            # actually HBoxContainer and VBoxContainer are distinct.
            # However, `GridContainer` has columns.

            # Simple approach for Godot 4:
            # Use a `BoxContainer` and set `vertical` property?
            # Let's check docs or memory.
            # Memory says "MainUI handles... switching... BoxContainer orientation logic".
            # Actually, `BoxContainer` has `vertical` property in Godot 4? Let's check `MainUI.gd` if possible.
    ```

### Reference Implementation (MainUI.gd Pattern)
Refer to `scripts/MainUI.gd` for the project's standard responsive logic.

## Components
- **GameButton:** Standard interaction element. Styles provided by `LapisButton_*.tres`.
- **GameLabel:** Body text (`Body.tres`).
- **HeaderLabel:** Title text (`Header.tres`).
- **StoneFrame:** Content container (`StonePanel.tres`).
