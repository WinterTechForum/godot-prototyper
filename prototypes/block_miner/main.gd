extends Node2D

## --- Tuning ---
@export var block_size: int = 24
@export var world_w: int = 250
@export var world_h: int = 180
@export var move_speed: float = 200.0
@export var jump_force: float = 380.0
@export var gravity_str: float = 900.0
@export var mine_range: float = 4.5  ## in blocks
@export var surface_base: int = 40
@export var dirt_depth: int = 6
@export var cave_freq: float = 0.07
@export var cave_threshold: float = 0.1
## --- End Tuning ---

enum B { AIR = 0, GRASS = 1, DIRT = 2, STONE = 3 }

# World data (flat arrays for performance)
var grid: PackedInt32Array
var vis: PackedByteArray

# Player
var ppos := Vector2.ZERO
var pvel := Vector2.ZERO
const PW := 20.0   # player width (slightly < 1 block)
const PH := 44.0   # player height (~2 blocks)
var on_ground := false

# UI / camera
var hover := Vector2i(-1, -1)
var cam: Camera2D
var depth_label: Label
var hint_label: Label

# Colors
var c_sky := Color("#87CEEB")
var c_underground := Color("#0d0d1a")
var c_grass := Color("#4CAF50")
var c_dirt := Color("#8B6914")
var c_stone := Color("#808080")
var c_hidden := Color("#0a0a14")
var c_player := Color("#4ecdc4")
var c_eye := Color.WHITE
var c_hi_ok := Color(1, 1, 1, 0.3)
var c_hi_bad := Color(1, 0.3, 0.3, 0.25)

const DIRS_8 := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]


# --- Helpers ---

func _gi(x: int, y: int) -> int:
	return x * world_h + y

func _ok(x: int, y: int) -> bool:
	return x >= 0 and x < world_w and y >= 0 and y < world_h

func bget(x: int, y: int) -> int:
	if not _ok(x, y):
		return B.STONE
	return grid[_gi(x, y)]

func bput(x: int, y: int, b: int):
	if _ok(x, y):
		grid[_gi(x, y)] = b

func bsee(x: int, y: int) -> bool:
	if not _ok(x, y):
		return false
	return vis[_gi(x, y)] != 0

func bshow(x: int, y: int):
	if _ok(x, y):
		vis[_gi(x, y)] = 1

func _solid(x: int, y: int) -> bool:
	return bget(x, y) != B.AIR


# --- Setup ---

func _ready():
	cam = Camera2D.new()
	cam.enabled = true
	add_child(cam)

	var canvas := CanvasLayer.new()
	add_child(canvas)

	depth_label = Label.new()
	depth_label.position = Vector2(10, 10)
	depth_label.add_theme_font_size_override("font_size", 20)
	depth_label.add_theme_color_override("font_color", Color("#eee"))
	canvas.add_child(depth_label)

	hint_label = Label.new()
	hint_label.position = Vector2(10, 690)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("#aaa"))
	hint_label.text = "Click to mine  |  Arrows move  |  Space jump  |  R restart  |  Esc quit"
	canvas.add_child(hint_label)

	_generate()


# --- World Generation ---

func _generate():
	grid = PackedInt32Array()
	grid.resize(world_w * world_h)
	vis = PackedByteArray()
	vis.resize(world_w * world_h)

	var t_noise := FastNoiseLite.new()
	t_noise.seed = randi()
	t_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	t_noise.frequency = 0.015

	var c_noise := FastNoiseLite.new()
	c_noise.seed = randi()
	c_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	c_noise.frequency = cave_freq

	var c_noise2 := FastNoiseLite.new()
	c_noise2.seed = randi()
	c_noise2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	c_noise2.frequency = cave_freq * 1.7

	for x in world_w:
		var surf_y: int = surface_base + int(t_noise.get_noise_1d(float(x)) * 12.0)
		surf_y = clampi(surf_y, 10, world_h - 20)

		for y in world_h:
			if y < surf_y:
				bput(x, y, B.AIR)
			elif y == surf_y:
				bput(x, y, B.GRASS)
			elif y < surf_y + dirt_depth:
				bput(x, y, B.DIRT)
			else:
				bput(x, y, B.STONE)

			# Carve caves below surface
			if y > surf_y + 4:
				var depth_f := clampf(float(y - surf_y) / 50.0, 0.0, 1.0)
				var cv := (c_noise.get_noise_2d(float(x), float(y)) +
						   c_noise2.get_noise_2d(float(x), float(y)) * 0.5) / 1.5
				if cv > cave_threshold + depth_f * 0.12:
					bput(x, y, B.AIR)

	# Reveal everything connected to the surface sky
	_flood_reveal_surface()

	# Spawn player on surface near center
	var sx: int = world_w / 2
	for y in world_h:
		if _solid(sx, y):
			ppos = Vector2(sx * block_size + 2, (y - 2) * block_size)
			break
	pvel = Vector2.ZERO
	on_ground = false
	queue_redraw()


func _flood_reveal_surface():
	var queue: Array[Vector2i] = []
	for x in world_w:
		if bget(x, 0) == B.AIR:
			bshow(x, 0)
			queue.append(Vector2i(x, 0))

	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in DIRS_8:
			var nx: int = p.x + d.x
			var ny: int = p.y + d.y
			if not _ok(nx, ny) or bsee(nx, ny):
				continue
			bshow(nx, ny)
			if bget(nx, ny) == B.AIR:
				queue.append(Vector2i(nx, ny))


func _reveal_around(bx: int, by: int):
	var queue: Array[Vector2i] = [Vector2i(bx, by)]
	bshow(bx, by)
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in DIRS_8:
			var nx: int = p.x + d.x
			var ny: int = p.y + d.y
			if not _ok(nx, ny) or bsee(nx, ny):
				continue
			bshow(nx, ny)
			if bget(nx, ny) == B.AIR:
				queue.append(Vector2i(nx, ny))


# --- Player Physics ---

func _process(delta: float):
	_player_move(delta)
	_update_hover()

	cam.position = ppos + Vector2(PW * 0.5, PH * 0.5)

	var depth_blocks := maxi(0, int(ppos.y / block_size) - surface_base)
	depth_label.text = "Depth: %d" % depth_blocks

	queue_redraw()


func _player_move(delta: float):
	var ix := Input.get_axis("ui_left", "ui_right")
	pvel.x = ix * move_speed

	if Input.is_action_just_pressed("ui_accept") and on_ground:
		pvel.y = -jump_force

	pvel.y += gravity_str * delta
	pvel.y = minf(pvel.y, 600.0)

	# Move X, resolve
	ppos.x += pvel.x * delta
	_collide_x()

	# Move Y, resolve
	ppos.y += pvel.y * delta
	on_ground = _collide_y()

	# World bounds
	ppos.x = clampf(ppos.x, 0.0, world_w * block_size - PW)
	ppos.y = clampf(ppos.y, 0.0, world_h * block_size - PH)


func _collide_x():
	var m := 0.5
	var top_b := int((ppos.y + m) / block_size)
	var bot_b := int((ppos.y + PH - m) / block_size)

	if pvel.x > 0:
		var rb := int((ppos.x + PW) / block_size)
		for by in range(top_b, bot_b + 1):
			if _solid(rb, by):
				ppos.x = rb * block_size - PW
				pvel.x = 0
				return
	elif pvel.x < 0:
		var lb := int(ppos.x / block_size)
		for by in range(top_b, bot_b + 1):
			if _solid(lb, by):
				ppos.x = (lb + 1) * block_size
				pvel.x = 0
				return


func _collide_y() -> bool:
	var m := 0.5
	var left_b := int((ppos.x + m) / block_size)
	var right_b := int((ppos.x + PW - m) / block_size)
	var grounded := false

	if pvel.y > 0:
		var bb := int((ppos.y + PH) / block_size)
		for bx in range(left_b, right_b + 1):
			if _solid(bx, bb):
				ppos.y = bb * block_size - PH
				pvel.y = 0
				grounded = true
				break
	elif pvel.y < 0:
		var tb := int(ppos.y / block_size)
		for bx in range(left_b, right_b + 1):
			if _solid(bx, tb):
				ppos.y = (tb + 1) * block_size
				pvel.y = 0
				break

	return grounded


# --- Mining ---

func _update_hover():
	var mw := get_global_mouse_position()
	hover = Vector2i(int(mw.x / block_size), int(mw.y / block_size))


func _try_mine(block: Vector2i):
	if not _ok(block.x, block.y):
		return
	if bget(block.x, block.y) == B.AIR:
		return
	if not bsee(block.x, block.y):
		return

	var pc := ppos + Vector2(PW * 0.5, PH * 0.5)
	var bc := Vector2((block.x + 0.5) * block_size, (block.y + 0.5) * block_size)
	if pc.distance_to(bc) / block_size > mine_range:
		return

	bput(block.x, block.y, B.AIR)
	_reveal_around(block.x, block.y)


# --- Input ---

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_generate()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_update_hover()
			_try_mine(hover)


# --- Rendering ---

func _draw():
	var vc := cam.position
	var hw := 660.0  # half viewport + margin
	var hh := 380.0

	var x0 := maxi(0, int((vc.x - hw) / block_size))
	var x1 := mini(world_w - 1, int((vc.x + hw) / block_size))
	var y0 := maxi(0, int((vc.y - hh) / block_size))
	var y1 := mini(world_h - 1, int((vc.y + hh) / block_size))

	# Sky background
	var sky_bottom := surface_base * block_size + block_size * 15
	draw_rect(Rect2(x0 * block_size, y0 * block_size,
		(x1 - x0 + 1) * block_size, sky_bottom - y0 * block_size), c_sky)

	# Underground background
	if y1 * block_size > sky_bottom:
		var ug_top := maxi(y0 * block_size, sky_bottom)
		draw_rect(Rect2(x0 * block_size, ug_top,
			(x1 - x0 + 1) * block_size, (y1 + 1) * block_size - ug_top), c_underground)

	# Draw blocks
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var rect := Rect2(x * block_size, y * block_size, block_size, block_size)

			if not bsee(x, y):
				draw_rect(rect, c_hidden)
				continue

			var b := bget(x, y)
			if b == B.AIR:
				continue

			var color: Color
			match b:
				B.GRASS:
					color = c_grass
				B.DIRT:
					color = c_dirt
				B.STONE:
					# Darken stone with depth
					var depth_f := clampf(float(y - surface_base) / float(world_h - surface_base), 0.0, 0.5)
					color = c_stone.darkened(depth_f * 0.4)
				_:
					color = c_stone

			draw_rect(rect, color)
			# Block outline for grid feel
			draw_rect(rect, color.darkened(0.2), false, 1.0)

	# Mining range circle
	var pc := ppos + Vector2(PW * 0.5, PH * 0.5)
	draw_arc(pc, mine_range * block_size, 0, TAU, 64, Color(1, 1, 1, 0.08), 1.5)

	# Hover highlight
	if _ok(hover.x, hover.y) and bsee(hover.x, hover.y) and bget(hover.x, hover.y) != B.AIR:
		var hr := Rect2(hover.x * block_size, hover.y * block_size, block_size, block_size)
		var bc := Vector2((hover.x + 0.5) * block_size, (hover.y + 0.5) * block_size)
		var dist := pc.distance_to(bc) / block_size
		var hi_color := c_hi_ok if dist <= mine_range else c_hi_bad
		draw_rect(hr, hi_color)
		draw_rect(hr, Color(1, 1, 1, 0.5), false, 2.0)

	# Player
	draw_rect(Rect2(ppos.x, ppos.y, PW, PH), c_player)
	# Eyes (face the mouse)
	var eye_y := ppos.y + 8.0
	var eye_cx := ppos.x + PW * 0.5
	var face_dir := signf(get_global_mouse_position().x - eye_cx)
	draw_circle(Vector2(eye_cx - 3 + face_dir * 2, eye_y), 2.5, c_eye)
	draw_circle(Vector2(eye_cx + 3 + face_dir * 2, eye_y), 2.5, c_eye)
	# Pupils
	draw_circle(Vector2(eye_cx - 3 + face_dir * 3, eye_y), 1.2, Color("#333"))
	draw_circle(Vector2(eye_cx + 3 + face_dir * 3, eye_y), 1.2, Color("#333"))
