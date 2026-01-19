extends PanelContainer

@export var survivor: SurvivorResource

@onready var name_label = $VBoxContainer/NameLabel
@onready var head_panel = $VBoxContainer/BodyParts/HeadPanel
@onready var torso_panel = $VBoxContainer/BodyParts/TorsoPanel
@onready var arms_panel = $VBoxContainer/BodyParts/ArmsPanel
@onready var legs_panel = $VBoxContainer/BodyParts/LegsPanel

func _ready():
	if survivor:
		update_ui()

func set_survivor(s: SurvivorResource):
	survivor = s
	update_ui()

func update_ui():
	if not survivor:
		return

	name_label.text = survivor.survivor_name

	_update_part_color(head_panel, survivor.body_parts.get("Head"))
	_update_part_color(torso_panel, survivor.body_parts.get("Torso"))
	_update_part_color(arms_panel, survivor.body_parts.get("Arms"))
	_update_part_color(legs_panel, survivor.body_parts.get("Legs"))

func _update_part_color(panel: Panel, part_data: Dictionary):
	if not part_data:
		return

	var color = Color.WHITE # Default / Armor > 0

	# Priority: Dead (Black) -> Shattered (Red) -> Injured (Yellow) -> Armor > 0 (White) -> Else (Gray?)
	# Request says: White (Armor > 0), Yellow (Injured), Red (Shattered), Black (Dead).

	# Assuming "Dead" logic is derived from Shattered Head/Torso or external flag.
	# But strictly following part data:

	if part_data.get("is_shattered", false):
		color = Color.RED
	elif part_data.get("is_injured", false):
		color = Color.YELLOW
	elif part_data.get("armor", 0) > 0:
		color = Color.WHITE
	else:
		# Fallback for no armor, healthy.
		# If the requirement implies White is only for Armor > 0, then what is No Armor + Healthy?
		# I'll assume White is Healthy/Armored.
		# But to distinguish No Armor, I might use Light Gray.
		# However, adhering to "White (Armor > 0)", implies strict mapping.
		# If I have 0 armor and am healthy, the prompt doesn't specify.
		# I will use Color.LIGHT_GRAY for healthy but no armor to be safe, or White.
		# Let's use White as "Healthy" general state if the prompt implies White/Yellow/Red/Black are the main states.
		color = Color.LIGHT_GRAY

	# Check for "Dead" condition - effectively if the part is "dead" or the survivor is dead.
	# If I implement a global "is_dead" check for the survivor, I should pass it.
	# But per part:
	# If Head or Torso is shattered, usually dead.
	# The prompt says "Black (Dead)".
	# I will check if the survivor is dead (Head/Torso shattered) and override all to black?
	# Or just the shattered part? "Red (Shattered)".
	# Maybe "Black" is for when the survivor is dead, the whole card status?
	# I'll stick to local part status first. If a part is missing/dead?

	# Let's just implement the requested colors on the panel.
	# If I need to implement "Black (Dead)", I'll add a check.
	# If Head or Torso is shattered, the survivor is dead.

	var is_survivor_dead = false
	if survivor.body_parts.get("Head", {}).get("is_shattered", false) or survivor.body_parts.get("Torso", {}).get("is_shattered", false):
		is_survivor_dead = true

	if is_survivor_dead:
		color = Color.BLACK

	# Override: if the specific part is shattered, it should be Red or Black?
	# "Red (Shattered), Black (Dead)".
	# If I am dead, everything Black? Or just the lethal blow?
	# Let's assume if Dead -> Black.

	# Create a new stylebox to avoid modifying the global theme or shared resource
	var new_style = StyleBoxFlat.new()
	new_style.bg_color = color
	panel.add_theme_stylebox_override("panel", new_style)
