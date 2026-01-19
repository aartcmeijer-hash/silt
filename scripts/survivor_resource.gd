class_name SurvivorResource
extends Resource

@export var survivor_name: String = ""
@export var age_decades: int = 0
@export var traits: Array = []
@export var temporary_buffs: Array = []
@export var body_parts: Dictionary = {
	"Head": {
		"armor": 0,
		"is_injured": false,
		"is_shattered": false
	},
	"Torso": {
		"armor": 0,
		"is_injured": false,
		"is_shattered": false
	},
	"Arms": {
		"armor": 0,
		"is_injured": false,
		"is_shattered": false
	},
	"Legs": {
		"armor": 0,
		"is_injured": false,
		"is_shattered": false
	}
}
