extends Control

@onready var cards_container = $MarginContainer/VBoxContainer/CardsContainer
@onready var consume_card = $MarginContainer/VBoxContainer/CardsContainer/ConsumeCard
@onready var observe_card = $MarginContainer/VBoxContainer/CardsContainer/ObserveCard
@onready var transition_overlay = $TransitionOverlay

# Colors
const LAPIS_BLUE = Color("#0047ab")
const BORDER_NORMAL = Color(0.3, 0.3, 0.3, 1)

# Aspect Ratio Threshold for layout switching
const ASPECT_RATIO_THRESHOLD = 1.0

func _ready():
	# Connect to resize signal
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_apply_layout()

	# Connect card inputs
	_setup_card_input(consume_card, "CONSUME")
	_setup_card_input(observe_card, "OBSERVE")

	# Set pivot offset for scaling from center
	consume_card.pivot_offset = consume_card.size / 2
	observe_card.pivot_offset = observe_card.size / 2

	# Connect to item_rect_changed to update pivot when size changes
	consume_card.item_rect_changed.connect(func(): consume_card.pivot_offset = consume_card.size / 2)
	observe_card.item_rect_changed.connect(func(): observe_card.pivot_offset = observe_card.size / 2)

func _setup_card_input(card: PanelContainer, choice_type: String):
	# Enable mouse input
	card.gui_input.connect(_on_card_gui_input.bind(card, choice_type))
	card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

func _on_viewport_resized():
	_apply_layout()

func _apply_layout():
	var viewport_size = get_viewport().get_visible_rect().size
	var aspect = viewport_size.x / viewport_size.y

	if aspect > ASPECT_RATIO_THRESHOLD:
		# Landscape: Horizontal
		cards_container.vertical = false
	else:
		# Portrait: Vertical
		cards_container.vertical = true

func _on_card_mouse_entered(card: PanelContainer):
	var style = card.get_theme_stylebox("panel").duplicate()
	style.border_color = LAPIS_BLUE
	card.add_theme_stylebox_override("panel", style)

	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.1)

func _on_card_mouse_exited(card: PanelContainer):
	var style = card.get_theme_stylebox("panel").duplicate()
	style.border_color = BORDER_NORMAL
	card.add_theme_stylebox_override("panel", style)

	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)

func _on_card_gui_input(event: InputEvent, card: PanelContainer, choice_type: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_choice_selected(choice_type)

func _on_choice_selected(choice_type: String):
	# Disable input to prevent double clicks
	consume_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	observe_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Screen Shake (Simple implementation: move root slightly)
	var tween = create_tween()
	var original_pos = position
	for i in range(5):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

	# Fade to Black/Dust
	transition_overlay.visible = true
	transition_overlay.color.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(transition_overlay, "color:a", 1.0, 1.0)
	fade_tween.finished.connect(_execute_choice.bind(choice_type))

func _execute_choice(choice_type: String):
	if choice_type == "CONSUME":
		_process_consume()
	elif choice_type == "OBSERVE":
		_process_observe()

func _process_consume():
	if GameManager:
		for survivor in GameManager.current_roster:
			survivor.temporary_buffs.append("Strength +1")
		GameManager.next_encounter_boss = "Silt-Cutter"
		GameManager.change_phase("TRIAL")

func _process_observe():
	if GameManager and GameManager.active_society:
		var current_points = GameManager.active_society.resources.get("Innovation", 0)
		GameManager.active_society.resources["Innovation"] = current_points + 1
		GameManager.next_encounter_boss = "Silt-Cutter"
		GameManager.change_phase("TRIAL")
