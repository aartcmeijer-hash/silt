extends CanvasLayer

@onready var main_container = $MainContainer
@onready var grid_placeholder = $MainContainer/GridPlaceholder
@onready var hud_container = $MainContainer/HUDContainer

# Using 1.0 as the threshold for Landscape/Portrait.
# > 1.0 is Landscape, <= 1.0 is Portrait.
const ASPECT_RATIO_THRESHOLD = 1.0

func _ready():
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_apply_layout()

func _exit_tree():
	if get_tree() and get_tree().root and get_tree().root.size_changed.is_connected(_on_viewport_resized):
		get_tree().root.size_changed.disconnect(_on_viewport_resized)

func _on_viewport_resized():
	_apply_layout()

func _apply_layout():
	var viewport_size = get_viewport().get_visible_rect().size
	var aspect = viewport_size.x / viewport_size.y

	if aspect > ASPECT_RATIO_THRESHOLD:
		# Landscape
		main_container.vertical = false

		# Grid: 70%, HUD: 30%
		grid_placeholder.size_flags_stretch_ratio = 0.7
		hud_container.size_flags_stretch_ratio = 0.3
	else:
		# Portrait (Mobile)
		main_container.vertical = true

		# Stack vertically. Usually equal or specific height?
		# Request says: "stack them vertically".
		# I'll keep stretch ratios or reset them if needed.
		# If stacked, usually we want them to fill available height or have fixed height.
		# Let's keep the ratios effectively meaning 70% height for grid, 30% for HUD?
		# Or maybe 50/50? The request doesn't specify Portrait ratios, just "stack them".
		# I'll stick to the same ratios so Grid is bigger.
		grid_placeholder.size_flags_stretch_ratio = 0.7
		hud_container.size_flags_stretch_ratio = 0.3
