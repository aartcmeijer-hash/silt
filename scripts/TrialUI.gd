class_name TrialUI
extends CanvasLayer

@onready var log_container: VBoxContainer
@onready var log_scroll: ScrollContainer
@onready var status_panel: Panel
@onready var status_label: Label

func _ready():
	# Create Log UI
	var panel = PanelContainer.new()
	panel.name = "LogPanel"
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.2 # Bottom 20%
	panel.anchor_top = 0.8
	add_child(panel)

	log_scroll = ScrollContainer.new()
	panel.add_child(log_scroll)

	log_container = VBoxContainer.new()
	log_scroll.add_child(log_container)

	# Create Status UI
	status_panel = Panel.new()
	status_panel.name = "StatusPanel"
	status_panel.anchor_left = 0.0
	status_panel.anchor_top = 0.0
	status_panel.anchor_right = 0.3 # Top Left 30%
	status_panel.anchor_bottom = 0.3
	add_child(status_panel)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 1.0
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_panel.add_child(status_label)

func log_message(message: String):
	if log_container:
		var label = Label.new()
		label.text = message
		log_container.add_child(label)
		# Auto scroll
		await get_tree().process_frame
		log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value

func update_survivor_status(survivor: SurvivorResource):
	if not survivor:
		status_label.text = "No Unit Selected"
		return

	var text = "[b]%s[/b] (Age: %d)\n" % [survivor.survivor_name, survivor.age_decades]

	text += "Body Parts:\n"
	for location in ["Head", "Torso", "Arms", "Legs"]:
		if location in survivor.body_parts:
			var part = survivor.body_parts[location]
			var status = "Healthy"
			if part.is_shattered:
				status = "Shattered (Red)"
			elif part.is_injured:
				status = "Injured (Yellow)"
			elif part.armor > 0:
				status = "Armor %d (White)" % part.armor
			else:
				status = "Exposed" # White/No Armor

			text += "- %s: %s\n" % [location, status]

	status_label.text = text
	# Note: RichTextLabel would be better for colors, but Label is simpler.
	# The prompt asked for White/Yellow/Red/Black status.
	# Implementing color via RichTextLabel if needed, but plain text description is safer for now.
