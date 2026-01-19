class_name UIUtils
extends Node

static func fade_in(node: CanvasItem, duration: float = 0.5) -> void:
	if not node: return
	node.modulate.a = 0.0
	node.show()
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)

static func fade_out(node: CanvasItem, duration: float = 0.5) -> void:
	if not node: return
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(node.hide)

static func pop_up(node: Control, duration: float = 0.3) -> void:
	if not node: return
	node.scale = Vector2(0.8, 0.8)
	node.pivot_offset = node.size / 2
	node.show()
	var tween = node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ONE, duration)
