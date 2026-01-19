class_name TrialUI
extends CanvasLayer

signal end_turn_pressed

@onready var log_container: VBoxContainer
@onready var log_scroll: ScrollContainer
@onready var status_label: Label
@onready var action_container: HBoxContainer
@onready var end_turn_button: Button
@onready var phase_label: Label

func _ready():
	# Create Main Panel (Right Side)
	var panel = PanelContainer.new()
	panel.name = "RightPanel"
	# Anchor to right 20%
	panel.anchor_left = 0.8
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0

	# Ensure it blocks mouse input to grid
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# "Brutalist Egyptology" Theme: "Dried Silt" (#b5a48b) bg
	var style = StyleBoxFlat.new()
	style.bg_color = Color("b5a48b")
	panel.add_theme_stylebox_override("panel", style)

	add_child(panel)

	# Margin Container for padding
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin_container)

	# Main Vertical Layout
	var vbox = VBoxContainer.new()
	vbox.name = "MainLayout"
	vbox.add_theme_constant_override("separation", 10)
	margin_container.add_child(vbox)

	# 1. Phase Indicator
	phase_label = Label.new()
	phase_label.text = "PLAYER PHASE"
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_color_override("font_color", Color("0047ab")) # Lapis Blue
	# Make it bold/large if possible (using Label settings is complex in code without theme, keeping simple)
	vbox.add_child(phase_label)

	vbox.add_child(HSeparator.new())

	# 2. Status Panel (Unit Info)
	var status_header = Label.new()
	status_header.text = "UNIT STATUS"
	status_header.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(status_header)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "No Unit Selected"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_label.size_flags_stretch_ratio = 1.0
	status_label.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(status_label)

	vbox.add_child(HSeparator.new())

	# 3. Log Panel
	var log_header = Label.new()
	log_header.text = "CHRONICLE"
	log_header.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(log_header)

	# Container for log with background
	var log_bg = PanelContainer.new()
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0, 0, 0, 0.1) # Semi-transparent black
	log_bg.add_theme_stylebox_override("panel", log_style)
	log_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_bg.size_flags_stretch_ratio = 2.0
	vbox.add_child(log_bg)

	log_scroll = ScrollContainer.new()
	log_scroll.name = "LogScroll"
	log_bg.add_child(log_scroll)

	log_container = VBoxContainer.new()
	log_scroll.add_child(log_container)

	vbox.add_child(HSeparator.new())

	# 4. Action Panel
	action_container = HBoxContainer.new()
	action_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_container)

	end_turn_button = Button.new()
	end_turn_button.text = "END TURN"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	# Note: In Godot 4, buttons handle their own sizing, but we can check
	action_container.add_child(end_turn_button)

func _on_end_turn_pressed():
	emit_signal("end_turn_pressed")

func log_message(message: String):
	if log_container:
		var label = Label.new()
		label.text = message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color.BLACK)
		log_container.add_child(label)
		# Auto scroll
		await get_tree().process_frame
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)

func update_survivor_status(survivor: SurvivorResource):
	if not survivor:
		status_label.text = "No Unit Selected"
		return

	var text = "%s (Age: %d)\n\n" % [survivor.survivor_name, survivor.age_decades]

	text += "BODY PARTS:\n"
	for location in ["Head", "Torso", "Arms", "Legs"]:
		if location in survivor.body_parts:
			var part = survivor.body_parts[location]
			var status = "Healthy"
			if part.is_shattered:
				status = "SHATTERED"
			elif part.is_injured:
				status = "Injured"
			elif part.armor > 0:
				status = "Armor %d" % part.armor
			else:
				status = "Exposed"

			text += "- %s: %s\n" % [location, status]

	status_label.text = text

func update_phase_indicator(phase_name: String):
	if phase_label:
		phase_label.text = phase_name.replace("_", " ")

	if end_turn_button:
		# Only enable End Turn button during Player Phase
		end_turn_button.disabled = (phase_name != "PLAYER_PHASE" and phase_name != "PLAYER PHASE")
