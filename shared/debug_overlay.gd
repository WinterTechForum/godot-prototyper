## Add this as an autoload singleton named "DebugOverlay"
## It shows FPS and lets any script push debug text to the screen.
extends CanvasLayer

var _label: Label
var _custom_lines: Dictionary = {}

func _ready():
	layer = 100
	_label = Label.new()
	_label.position = Vector2(10, 10)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", ProtoColors.TEXT)
	add_child(_label)

func _process(_delta):
	var text = "FPS: %d" % Engine.get_frames_per_second()
	for key in _custom_lines:
		text += "\n%s: %s" % [key, str(_custom_lines[key])]
	_label.text = text

## Call from anywhere: DebugOverlay.track("Health", player.health)
func track(key: String, value) -> void:
	_custom_lines[key] = value

## Remove a tracked value
func untrack(key: String) -> void:
	_custom_lines.erase(key)
