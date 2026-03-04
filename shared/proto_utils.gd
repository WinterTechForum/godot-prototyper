## Utility functions for rapid prototyping.
## Add as autoload singleton named "Proto" for global access.
class_name ProtoUtils
extends Node

## Create a colored rectangle node quickly
static func make_rect(size: Vector2, color: Color) -> ColorRect:
	var rect = ColorRect.new()
	rect.custom_minimum_size = size
	rect.size = size
	rect.color = color
	# Center the pivot
	rect.pivot_offset = size / 2.0
	return rect

## Flash a node's modulate color and return to original
static func flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.1) -> void:
	var original = node.modulate
	node.modulate = color
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", original, duration)

## Spawn a floating text that rises and fades (for score popups, damage numbers, etc.)
static func popup_text(parent: Node, text: String, position: Vector2,
		color: Color = ProtoColors.TEXT, duration: float = 0.8) -> void:
	var label = Label.new()
	label.text = text
	label.position = position
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y - 60, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)

## Simple screen shake — pass a Camera2D
static func shake_camera(camera: Camera2D, intensity: float = 10.0, duration: float = 0.2) -> void:
	var tween = camera.create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

## Wait helper — returns a SceneTreeTimer signal
static func wait(node: Node, seconds: float) -> Signal:
	return node.get_tree().create_timer(seconds).timeout
