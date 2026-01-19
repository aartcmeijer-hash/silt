extends Control
class_name SiltPhase

signal phase_completed

# Reference to the Game Manager to access active_society
var game_manager: Node

# State
var mandatory_events_resolved: bool = true # Placeholder for events
var tradition_choice_pending: bool = false
var available_innovations: Array[InnovationResource] = []

func _ready():
    # Attempt to find GameManager. Logic might need adjustment based on scene tree
    game_manager = get_node_or_null("/root/GameManager")
    if not game_manager:
        # Fallback if singleton is not at root (e.g. testing)
        # In a real game, this might fail if not properly set up.
        # We assume for now the user will ensure GameManager is available or we find it.
        pass

    _setup_ui()

func _setup_ui():
    # Placeholder for UI setup
    update_innovations_ui()

    # Connect Tradition Popup buttons if they exist in the scene tree
    var button_a = get_node_or_null("TraditionPopup/HBoxContainer/ButtonA")
    var button_b = get_node_or_null("TraditionPopup/HBoxContainer/ButtonB")

    if button_a:
        button_a.pressed.connect(func(): _on_tradition_selected(0))
    if button_b:
        button_b.pressed.connect(func(): _on_tradition_selected(1))

func spend_resources(cost_dict: Dictionary) -> bool:
    if not game_manager or not game_manager.active_society:
        push_error("GameManager or active_society not found")
        return false

    var society = game_manager.active_society

    # First, verify we have enough resources
    for res_name in cost_dict:
        if not society.resources.has(res_name) or society.resources[res_name] < cost_dict[res_name]:
            return false

    # Then decrement
    for res_name in cost_dict:
        society.resources[res_name] -= cost_dict[res_name]

    return true

func check_innovation_requirements(innovation: InnovationResource) -> bool:
    if not game_manager or not game_manager.active_society:
        return false

    var society = game_manager.active_society

    # Check if already unlocked
    if innovation.name in society.unlocked_innovations:
        return false

    # Check requirements
    for req in innovation.requirements:
        if not req in society.unlocked_innovations:
            return false

    return true

func purchase_innovation(innovation: InnovationResource) -> bool:
    if not game_manager or not game_manager.active_society:
        return false

    if not check_innovation_requirements(innovation):
        return false

    if spend_resources(innovation.cost):
        game_manager.active_society.unlocked_innovations.append(innovation.name)
        update_innovations_ui()
        return true

    return false

func update_innovations_ui():
    # This would populate the tree UI
    # For now, we just print
    pass

func generate_tradition_prompt():
    tradition_choice_pending = true
    # UI logic to show popup
    var popup = get_node_or_null("TraditionPopup")
    if popup:
        popup.visible = true
        popup.popup_centered()

func _on_tradition_selected(index: int):
    # Mock logic: index 0 is first choice, index 1 is second
    # In a real scenario, we would map these to the actual TraditionResource objects generated
    var dummy_tradition = TraditionResource.new()
    dummy_tradition.name = "Selected Tradition " + str(index)
    resolve_tradition(dummy_tradition)

func resolve_tradition(choice: TraditionResource):
    if not tradition_choice_pending:
        return

    # Apply effects of the tradition
    # choice.apply_effects(game_manager.active_society) # Mock call
    print("Resolved tradition: " + choice.name)

    tradition_choice_pending = false
    # Hide popup
    var popup = get_node_or_null("TraditionPopup")
    if popup:
        popup.visible = false

func begin_next_decade():
    if not mandatory_events_resolved:
        print("Cannot advance: Mandatory events not resolved.")
        return

    if tradition_choice_pending:
        print("Cannot advance: Tradition choice pending.")
        return

    if game_manager:
        game_manager.advance_decade()
        emit_signal("phase_completed")
