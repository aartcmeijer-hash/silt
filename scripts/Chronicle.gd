extends ScrollContainer

@onready var log_container = $LogContainer

# Reference to GameManager logic (assuming GameManager singleton exists or is passed)
# In Godot, singletons are usually accessed globally.
# But for testability, I'll allow injection or rely on global "GameManager" name if it's an autoload.
# The memory says "The GameManager singleton manages global state".

func _ready():
	# Connect signals
	if GameManager:
		GameManager.innovation_unlocked.connect(_on_innovation_unlocked)
		GameManager.survivor_died.connect(_on_survivor_died)
	else:
		push_error("GameManager singleton not found")

func add_entry(text: String):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_container.add_child(label)

	# Auto-scroll to bottom
	await get_tree().process_frame
	set_v_scroll(get_v_scroll_bar().max_value)

func _get_decade_prefix() -> String:
	var decade = 0
	if GameManager and GameManager.active_society:
		decade = GameManager.active_society.current_decade
	return "Decade " + str(decade) + ": "

func _on_innovation_unlocked(innovation_name: String):
	add_entry(_get_decade_prefix() + "Innovation unlocked: " + innovation_name)

func _on_survivor_died(survivor_name: String, cause: String):
	add_entry(_get_decade_prefix() + survivor_name + " was shattered by the " + cause + ".")
