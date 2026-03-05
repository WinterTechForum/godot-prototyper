extends Node2D

## ── Tuning Knobs ──────────────────────────────────────────
@export var platform_color: Color = Color("#2c3e50")
@export var kill_zone_color: Color = Color("#ff6b6b")
@export var goal_color: Color = Color("#ffe66d")
@export var bg_color: Color = Color("#16213e")

## ── Level Data ────────────────────────────────────────────
## Each level is a dictionary with platforms, enemies, and a goal position.
## Platforms: [x, y, width, height]
## Enemies: [x, y, patrol_range]
## Pits are simply gaps between platforms with a kill zone below.

var current_level: int = 0
var player: CharacterBody2D
var camera: Camera2D
var level_node: Node2D
var ui_layer: CanvasLayer
var level_label: Label
var death_count: int = 0
var death_label: Label

var levels: Array = []

func _ready() -> void:
	# Background color
	RenderingServer.set_default_clear_color(bg_color)

	_build_levels()
	_setup_ui()
	_load_level(current_level)

func _build_levels() -> void:
	var floor_y: float = 600.0
	var plat_h: float = 32.0

	# ── Level 1: Simple intro ──────────────────────────────
	levels.append({
		"platforms": [
			[0, floor_y, 400, plat_h],
			# pit
			[500, floor_y, 300, plat_h],
			# pit
			[900, floor_y, 200, plat_h],
			[1200, floor_y, 400, plat_h],
		],
		"enemies": [
			[650, floor_y, 80],
		],
		"goal_x": 1500,
		"goal_y": floor_y,
		"player_start": Vector2(80, floor_y - 60),
	})

	# ── Level 2: More platforms, more enemies ──────────────
	levels.append({
		"platforms": [
			[0, floor_y, 300, plat_h],
			[200, floor_y - 100, 180, plat_h],
			[450, floor_y, 200, plat_h],
			[500, floor_y - 150, 150, plat_h],
			[750, floor_y, 150, plat_h],
			[950, floor_y - 80, 200, plat_h],
			[1200, floor_y, 500, plat_h],
		],
		"enemies": [
			[500, floor_y, 60],
			[1000, floor_y - 80, 70],
			[1400, floor_y, 100],
		],
		"goal_x": 1600,
		"goal_y": floor_y,
		"player_start": Vector2(80, floor_y - 60),
	})

	# ── Level 3: Vertical challenge ────────────────────────
	levels.append({
		"platforms": [
			[0, floor_y, 250, plat_h],
			[150, floor_y - 100, 150, plat_h],        # 100 up from ground
			[350, floor_y - 190, 150, plat_h],         # 90 up from previous
			[550, floor_y - 100, 200, plat_h],         # drop back down
			[800, floor_y, 150, plat_h],               # ground level
			[850, floor_y - 90, 120, plat_h],          # 90 up from ground
			[1050, floor_y - 180, 150, plat_h],        # 90 up from previous
			[1250, floor_y - 90, 150, plat_h],         # drop back down
			[1450, floor_y, 400, plat_h],              # ground finish
		],
		"enemies": [
			[600, floor_y - 100, 60],
			[900, floor_y - 90, 40],
			[1300, floor_y - 90, 50],
			[1600, floor_y, 80],
		],
		"goal_x": 1750,
		"goal_y": floor_y,
		"player_start": Vector2(80, floor_y - 60),
	})

func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	level_label = Label.new()
	level_label.position = Vector2(20, 20)
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color("#eee"))
	ui_layer.add_child(level_label)

	death_label = Label.new()
	death_label.position = Vector2(20, 55)
	death_label.add_theme_font_size_override("font_size", 18)
	death_label.add_theme_color_override("font_color", Color("#ff6b6b"))
	ui_layer.add_child(death_label)

	_update_ui()

func _update_ui() -> void:
	level_label.text = "Level %d / %d" % [current_level + 1, levels.size()]
	death_label.text = "Deaths: %d" % death_count

func _load_level(idx: int) -> void:
	# Clean up previous level
	if level_node:
		level_node.queue_free()
		await get_tree().process_frame

	var data = levels[idx]
	level_node = Node2D.new()
	add_child(level_node)

	# ── Create platforms ───────────────────────────────────
	for p in data["platforms"]:
		_create_platform(p[0], p[1], p[2], p[3])

	# ── Create kill zone below all platforms ───────────────
	_create_kill_zone()

	# ── Create enemies ─────────────────────────────────────
	for e in data["enemies"]:
		_create_enemy(e[0], e[1], e[2])

	# ── Create goal ────────────────────────────────────────
	_create_goal(data["goal_x"], data["goal_y"])

	# ── Create player ──────────────────────────────────────
	_create_player(data["player_start"])

	_update_ui()

func _create_platform(x: float, y: float, w: float, h: float) -> void:
	var body = StaticBody2D.new()
	body.position = Vector2(x, y)

	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(w, h)
	shape.shape = box
	shape.position = Vector2(w / 2.0, h / 2.0)
	body.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(w, h)
	rect.color = platform_color
	body.add_child(rect)

	level_node.add_child(body)

func _create_kill_zone() -> void:
	var area = Area2D.new()
	area.position = Vector2(-500, 750)
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(5000, 100)
	shape.shape = box
	shape.position = Vector2(2500, 50)
	area.add_child(shape)
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	area.body_entered.connect(_on_kill_zone_entered)
	level_node.add_child(area)

func _create_enemy(x: float, y: float, patrol_range: float) -> void:
	var enemy_scene = preload("res://enemy.gd")
	var enemy = CharacterBody2D.new()
	enemy.position = Vector2(x, y)
	enemy.set_script(enemy_scene)
	enemy.patrol_range = patrol_range

	# Collision shape for enemy body (so it sits on platforms if needed)
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(28, 28)
	shape.shape = box
	shape.position = Vector2(0, -16)
	enemy.add_child(shape)
	# Enemies don't need to collide with platforms for patrol, set to layer 4
	enemy.collision_layer = 4
	enemy.collision_mask = 0

	level_node.add_child(enemy)

func _create_goal(x: float, y: float) -> void:
	var area = Area2D.new()
	area.position = Vector2(x, y)

	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(40, 80)
	shape.shape = box
	shape.position = Vector2(0, -40)
	area.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(40, 80)
	rect.position = Vector2(-20, -80)
	rect.color = goal_color
	area.add_child(rect)

	# Pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(rect, "modulate:a", 0.5, 0.6)
	tween.tween_property(rect, "modulate:a", 1.0, 0.6)

	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	area.body_entered.connect(_on_goal_reached)
	level_node.add_child(area)

func _create_player(start_pos: Vector2) -> void:
	var player_script = preload("res://player.gd")
	player = CharacterBody2D.new()
	player.position = start_pos
	player.set_script(player_script)

	# Collision shape
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(28, 44)
	shape.shape = box
	shape.position = Vector2(0, -24)
	player.add_child(shape)

	# Player on layer 2
	player.collision_layer = 2
	player.collision_mask = 1  # Collide with platforms

	player.died.connect(_on_player_died)
	level_node.add_child(player)

	# Camera follows player
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_bottom = 800
	camera.limit_top = -200
	player.add_child(camera)

func _on_kill_zone_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()

func _on_player_died() -> void:
	death_count += 1
	_update_ui()
	# Reload level after short delay
	await get_tree().create_timer(0.5).timeout
	_load_level(current_level)

func _on_goal_reached(body: Node2D) -> void:
	if body != player or player.is_dead:
		return
	current_level += 1
	if current_level >= levels.size():
		_show_win_screen()
	else:
		_load_level(current_level)

func _show_win_screen() -> void:
	if level_node:
		level_node.queue_free()
	level_label.text = "You Win!"
	var win_label = Label.new()
	win_label.text = "All levels complete!\nDeaths: %d\n\nPress R to play again" % death_count
	win_label.add_theme_font_size_override("font_size", 36)
	win_label.add_theme_color_override("font_color", Color("#ffe66d"))
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_label.anchors_preset = Control.PRESET_CENTER
	win_label.position = Vector2(400, 250)
	ui_layer.add_child(win_label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		current_level = 0
		death_count = 0
		_load_level(current_level)
		_update_ui()
