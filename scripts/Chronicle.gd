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
		GameManager.chronicle_log.connect(_on_chronicle_log)
	else:
		push_error("GameManager singleton not found")

func _exit_tree():
	if GameManager:
		if GameManager.innovation_unlocked.is_connected(_on_innovation_unlocked):
			GameManager.innovation_unlocked.disconnect(_on_innovation_unlocked)
		if GameManager.survivor_died.is_connected(_on_survivor_died):
			GameManager.survivor_died.disconnect(_on_survivor_died)

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

func _on_chronicle_log(message: String):
	add_entry(message)
