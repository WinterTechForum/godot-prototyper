extends Node2D

## --- Tuning ---
@export var scroll_speed: float = 150.0
@export var player_speed: float = 300.0
@export var river_segments: int = 300
@export var segment_height: float = 30.0
@export var base_river_width: float = 280.0
@export var min_river_width: float = 160.0
@export var max_river_width: float = 380.0
@export var obstacle_chance: float = 0.12
@export var player_radius: float = 14.0
## --- End Tuning ---

# River data: each entry is {cx, w} (center x, width)
var river: Array = []
# Obstacles: {seg, y, x, w, h, type, swim_dir, swim_speed}
var obstacles: Array = []

var player_pos: Vector2
var game_over: bool = false
var game_won: bool = false
var level: int = 1

# Nodes
var camera: Camera2D
var score_label: Label
var status_label: Label

# Colors
var color_water := Color("#2471a3")
var color_water_deep := Color("#1a5276")
var color_land := Color("#27ae60")
var color_bank := Color("#1e8449")
var color_player := Color("#4ecdc4")
var color_tube := Color("#f39c12")
var color_log := Color("#5d4037")
var color_log_line := Color("#4e342e")
var color_rock := Color("#7f8c8d")
var color_rock_dark := Color("#636e72")
var color_otter := Color("#a0522d")
var color_otter_dark := Color("#8b4513")
var color_finish := Color("#ffe66d")

const SCREEN_W := 1280.0
const SCREEN_H := 720.0


func _ready():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)

	var canvas := CanvasLayer.new()
	add_child(canvas)

	score_label = Label.new()
	score_label.position = Vector2(10, 10)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color("#eee"))
	canvas.add_child(score_label)

	# Full-screen container for centered status text
	var status_bg := ColorRect.new()
	status_bg.color = Color(0, 0, 0, 0.0)
	status_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	status_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_bg)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 36)
	status_label.add_theme_color_override("font_color", Color("#ffe66d"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	status_bg.add_child(status_label)

	generate_river()


func generate_river():
	river.clear()
	obstacles.clear()

	var cx := SCREEN_W * 0.5
	var w := base_river_width
	var drift := 0.0

	for i in river_segments:
		# First 15 segments are straight to give player time to orient
		var turn_intensity := clampf(float(i - 15) / 10.0, 0.0, 1.0)
		drift += randf_range(-10.0, 10.0) * turn_intensity
		drift = clamp(drift, -30.0, 30.0)
		drift *= 0.97  # damping

		cx += drift
		# Keep river on screen with some margin
		cx = clamp(cx, w * 0.5 + 50, SCREEN_W - w * 0.5 - 50)

		w += randf_range(-4.0, 4.0)
		w = clamp(w, min_river_width, max_river_width)

		river.append({"cx": cx, "w": w})

		# Place obstacles (skip first 10 and last 10 segments)
		if i > 10 and i < river_segments - 10 and randf() < obstacle_chance:
			_place_obstacle(i, cx, w)

	player_pos = Vector2(river[0]["cx"], segment_height * 3.0)
	camera.position = Vector2(SCREEN_W * 0.5, player_pos.y)
	game_over = false
	game_won = false
	_update_ui()
	queue_redraw()


func _place_obstacle(seg_idx: int, cx: float, w: float):
	var y_pos := seg_idx * segment_height
	var left_edge := cx - w * 0.5
	var right_edge := cx + w * 0.5
	var obs_type := randi() % 3  # 0=log, 1=rock, 2=otter

	var obs := {
		"seg": seg_idx,
		"y": y_pos,
		"type": obs_type,
		"x": 0.0,
		"w": 0.0,
		"h": 0.0,
		"swim_dir": 1.0,
		"swim_speed": 0.0,
	}

	match obs_type:
		0:  # Log — half river width, on one side
			obs["w"] = w * 0.5
			obs["h"] = segment_height * 0.7
			if randi() % 2 == 0:
				obs["x"] = left_edge
			else:
				obs["x"] = right_edge - obs["w"]
		1:  # Rock — 1/4 river width
			obs["w"] = w * 0.25
			obs["h"] = w * 0.25
			obs["x"] = left_edge + randf_range(0, w - obs["w"])
		2:  # Otter — 1/4 river width, swims
			obs["w"] = w * 0.25
			obs["h"] = segment_height * 0.5
			obs["x"] = left_edge + randf_range(0, w * 0.5)
			obs["swim_speed"] = randf_range(60.0, 120.0)
			obs["swim_dir"] = [-1.0, 1.0][randi() % 2]

	obstacles.append(obs)


func _process(delta: float):
	if game_over or game_won:
		return

	# Auto-scroll downriver
	player_pos.y += scroll_speed * delta

	# Player steers left/right
	var input_x := Input.get_axis("ui_left", "ui_right")
	player_pos.x += input_x * player_speed * delta

	# Camera follows player Y, centered X
	camera.position = Vector2(SCREEN_W * 0.5, player_pos.y)

	# Win condition: reached end of river
	var max_y := (river_segments - 2) * segment_height
	if player_pos.y >= max_y:
		game_won = true
		level += 1
		_update_ui()
		queue_redraw()
		get_tree().create_timer(2.5).timeout.connect(generate_river)
		return

	# River bounds check
	var seg_f := player_pos.y / segment_height
	var seg_i := clampi(int(seg_f), 0, river.size() - 2)
	var t := seg_f - float(seg_i)
	var cx: float = lerp(float(river[seg_i]["cx"]), float(river[seg_i + 1]["cx"]), t)
	var w: float = lerp(float(river[seg_i]["w"]), float(river[seg_i + 1]["w"]), t)
	var left_bound := cx - w * 0.5 + player_radius
	var right_bound := cx + w * 0.5 - player_radius

	if player_pos.x < left_bound or player_pos.x > right_bound:
		_die()
		return

	# Update otters and check all obstacle collisions
	for obs in obstacles:
		# Skip far-away obstacles for performance
		if abs(obs["y"] - player_pos.y) > SCREEN_H:
			continue

		# Otter swimming
		if obs["type"] == 2:
			var o_seg: int = clampi(obs["seg"], 0, river.size() - 1)
			var o_cx: float = river[o_seg]["cx"]
			var o_w: float = river[o_seg]["w"]
			var o_left := o_cx - o_w * 0.5
			var o_right := o_cx + o_w * 0.5

			obs["x"] += obs["swim_speed"] * obs["swim_dir"] * delta
			if obs["x"] + obs["w"] > o_right:
				obs["swim_dir"] = -1.0
			elif obs["x"] < o_left:
				obs["swim_dir"] = 1.0

		# Collision: AABB vs circle
		if abs(obs["y"] - player_pos.y) < obs["h"] + player_radius:
			var ox: float = obs["x"]
			var ow: float = obs["w"]
			var oh: float = obs["h"]
			var oy: float = obs["y"]

			var nearest_x := clampf(player_pos.x, ox, ox + ow)
			var nearest_y := clampf(player_pos.y, oy, oy + oh)
			var dist := player_pos.distance_to(Vector2(nearest_x, nearest_y))
			if dist < player_radius:
				_die()
				return

	_update_ui()
	queue_redraw()


func _die():
	game_over = true
	_update_ui()
	queue_redraw()


func _update_ui():
	var progress := int(player_pos.y / segment_height)
	score_label.text = "Level: %d  |  Distance: %d / %d" % [level, progress, river_segments]
	if game_over:
		status_label.text = "CRASHED!\nPress R to restart"
	elif game_won:
		status_label.text = "LEVEL COMPLETE!\nGenerating new river..."
	else:
		status_label.text = ""


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if game_over:
			player_pos = Vector2(river[0]["cx"], segment_height * 3.0)
			game_over = false
			_update_ui()
			queue_redraw()
		else:
			level = 1
			generate_river()


func _draw():
	var view_top := camera.position.y - SCREEN_H * 0.5 - 50.0
	var view_bottom := camera.position.y + SCREEN_H * 0.5 + 50.0
	var seg_start := maxi(0, int(view_top / segment_height) - 1)
	var seg_end := mini(river.size() - 1, int(view_bottom / segment_height) + 2)

	if seg_start >= seg_end or river.is_empty():
		return

	# Background: land
	draw_rect(Rect2(-200, view_top - 100, SCREEN_W + 400, view_bottom - view_top + 200), color_land)

	# River water polygon
	var water_left: PackedVector2Array = []
	var water_right: PackedVector2Array = []

	for i in range(seg_start, seg_end + 1):
		var y_pos := float(i) * segment_height
		var cx: float = river[i]["cx"]
		var hw: float = river[i]["w"] * 0.5
		water_left.append(Vector2(cx - hw, y_pos))
		water_right.append(Vector2(cx + hw, y_pos))

	# Build polygon: left side down, right side back up
	var water_poly: PackedVector2Array = []
	water_poly.append_array(water_left)
	water_right.reverse()
	water_poly.append_array(water_right)

	if water_poly.size() >= 3:
		draw_colored_polygon(water_poly, color_water)

	# Flow lines (decorative)
	for i in range(seg_start, seg_end + 1, 3):
		var y_pos := float(i) * segment_height
		var cx: float = river[i]["cx"]
		var hw: float = river[i]["w"] * 0.3
		draw_line(
			Vector2(cx - hw * 0.2, y_pos),
			Vector2(cx - hw * 0.2, y_pos + segment_height * 2),
			color_water_deep, 1.0)
		draw_line(
			Vector2(cx + hw * 0.4, y_pos + segment_height),
			Vector2(cx + hw * 0.4, y_pos + segment_height * 2.5),
			color_water_deep, 1.0)

	# Bank edges
	for i in range(seg_start, seg_end):
		var y0 := float(i) * segment_height
		var y1 := float(i + 1) * segment_height
		var cx0: float = river[i]["cx"]
		var cx1: float = river[i + 1]["cx"]
		var hw0: float = river[i]["w"] * 0.5
		var hw1: float = river[i + 1]["w"] * 0.5

		# Left bank
		draw_line(Vector2(cx0 - hw0, y0), Vector2(cx1 - hw1, y1), color_bank, 4.0)
		# Right bank
		draw_line(Vector2(cx0 + hw0, y0), Vector2(cx1 + hw1, y1), color_bank, 4.0)

	# Finish line
	var finish_y := float(river_segments - 2) * segment_height
	if finish_y > view_top and finish_y < view_bottom:
		var fin_cx: float = river[river_segments - 2]["cx"]
		var fin_hw: float = river[river_segments - 2]["w"] * 0.5
		for stripe in range(10):
			var sx := fin_cx - fin_hw + stripe * (fin_hw * 2.0 / 10.0)
			var sw := fin_hw * 2.0 / 10.0
			var col := color_finish if stripe % 2 == 0 else Color.WHITE
			draw_rect(Rect2(sx, finish_y - 5, sw, 10), col)

	# Obstacles
	for obs in obstacles:
		var oy: float = obs["y"]
		if oy < view_top - 50 or oy > view_bottom + 50:
			continue
		var ox: float = obs["x"]
		var ow: float = obs["w"]
		var oh: float = obs["h"]

		match obs["type"]:
			0:  # Log — brown rectangle with grain lines
				draw_rect(Rect2(ox, oy, ow, oh), color_log)
				for j in range(1, 4):
					var lx := ox + ow * j * 0.25
					draw_line(Vector2(lx, oy + 2), Vector2(lx, oy + oh - 2), color_log_line, 1.0)
				# Bark edges
				draw_rect(Rect2(ox, oy, ow, oh), color_log_line, false, 2.0)
			1:  # Rock — gray circle
				var center := Vector2(ox + ow * 0.5, oy + oh * 0.5)
				draw_circle(center, ow * 0.5, color_rock)
				draw_circle(center + Vector2(-ow * 0.1, -oh * 0.1), ow * 0.2, color_rock_dark)
				draw_arc(center, ow * 0.5, 0, TAU, 32, color_rock_dark, 2.0)
			2:  # Otter — brown body with eyes
				# Body
				var center := Vector2(ox + ow * 0.5, oy + oh * 0.5)
				draw_circle(center, minf(ow, oh) * 0.5, color_otter)
				# Head
				var head_x := ox + ow * 0.7 if obs["swim_dir"] > 0 else ox + ow * 0.3
				draw_circle(Vector2(head_x, oy + oh * 0.3), oh * 0.25, color_otter_dark)
				# Eyes
				draw_circle(Vector2(head_x, oy + oh * 0.25), 2.0, Color.WHITE)

	# Player (tube)
	if not game_over:
		# Tube ring
		draw_arc(player_pos, player_radius + 3, 0, TAU, 32, color_tube, 6.0)
		# Player body inside tube
		draw_circle(player_pos, player_radius - 3, color_player)
		# Highlight
		draw_circle(player_pos + Vector2(-3, -3), 4.0, Color(1, 1, 1, 0.3))
	else:
		# Splash effect
		for i in range(8):
			var angle := TAU * i / 8.0
			var splash_pos := player_pos + Vector2(cos(angle), sin(angle)) * (player_radius + 10)
			draw_circle(splash_pos, 3.0, Color(1, 1, 1, 0.5))
