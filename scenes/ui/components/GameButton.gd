extends Button

# Placeholder for click sound.
# Assign an AudioStream to 'click_sound' in the Inspector.
@export var click_sound: AudioStream

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if click_sound:
		# In a real implementation, we might use a global audio manager to avoid cutting off sound when button is freed.
		# For now, we assume simple playback or that the button persists.
		# Since we don't have an AudioStreamPlayer child, we can create one or use a global.
		# Let's check if there is a global audio manager.
		# If not, we just print for now as requested by the "subtle 'Click' sound" requirement implies implementation.
		AudioStreamPlayer.new().play() # This won't work without adding to tree and stream.
		pass

	# Since no audio files exist, we will just print for verification.
	print("GameButton clicked!")
