extends Node2D

# =============================================================================
# Tuning Variables
# =============================================================================
@export var player_move_speed: float = 8.0  # cells per second
@export var enemy_move_speed: float = 5.5   # cells per second
@export var enemy_vulnerable_speed: float = 3.0
@export var power_pip_duration: float = 8.0
@export var enemy_respawn_delay: float = 3.0
@export var stage_clear_delay: float = 1.5
@export var enemy_count: int = 4
@export var starting_lives: int = 3

# =============================================================================
# Constants
# =============================================================================
const CELL_SIZE := 32
const GRID_W := 39  # must be odd
const GRID_H := 21  # must be odd
const GRID_PIXEL_W := GRID_W * CELL_SIZE
const GRID_PIXEL_H := GRID_H * CELL_SIZE
var grid_offset := Vector2((1280 - GRID_PIXEL_W) / 2.0, (720 - GRID_PIXEL_H) / 2.0 + 12)

enum Cell { WALL, PATH, PIP, POWER_PIP, EMPTY }

const VULNERABLE_COLOR := Color("#6666ff")
const VULNERABLE_FLASH_COLOR := Color("#ffffff")
const DEAD_ENEMY_COLOR := Color("#333333")

# =============================================================================
# State
# =============================================================================
var grid: Array = []  # 2D array [x][y]
var score: int = 0
var lives: int = 3
var stage: int = 1
var total_pips: int = 0
var collected_pips: int = 0
var game_over: bool = false
var stage_clearing: bool = false

# Player
var player_grid_pos := Vector2i(1, 1)
var player_visual_pos := Vector2.ZERO
var player_move_progress: float = 1.0  # 1.0 = arrived
var player_move_from := Vector2.ZERO
var player_move_to := Vector2.ZERO
var player_dir := Vector2i.ZERO
var player_queued_dir := Vector2i.ZERO
var player_mouth_anim: float = 0.0  # for simple mouth animation

# Enemies
var enemies: Array = []

# Power pip state
var power_timer: float = 0.0
var power_active: bool = false
var power_kill_streak: int = 0

# Pip pulse animation
var pip_pulse_time: float = 0.0

# UI references
@onready var score_label: Label = $ScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var stage_label: Label = $StageLabel
@onready var message_label: Label = $MessageLabel

# =============================================================================
# Lifecycle
# =============================================================================
func _ready() -> void:
	lives = starting_lives
	_start_stage()
	_update_ui()

func _process(delta: float) -> void:
	if game_over:
		return

	if stage_clearing:
		return

	pip_pulse_time += delta * 3.0
	player_mouth_anim += delta * 12.0

	_process_player(delta)
	_process_enemies(delta)
	_process_power_timer(delta)
	_check_enemy_collisions()

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_restart_game()

# =============================================================================
# Game Flow
# =============================================================================
func _restart_game() -> void:
	score = 0
	lives = starting_lives
	stage = 1
	game_over = false
	stage_clearing = false
	power_active = false
	power_timer = 0.0
	message_label.text = ""
	_start_stage()
	_update_ui()

func _start_stage() -> void:
	_generate_maze()
	_place_pips()
	_init_player()
	_init_enemies()
	power_active = false
	power_timer = 0.0
	power_kill_streak = 0
	stage_clearing = false
	message_label.text = ""
	_update_ui()
	queue_redraw()

func _on_player_death() -> void:
	lives -= 1
	_update_ui()
	if lives <= 0:
		game_over = true
		message_label.text = "GAME OVER\nPress R to restart"
		ProtoUtils.flash(self, Color.RED, 0.3)
	else:
		# Respawn player, keep maze
		ProtoUtils.flash(self, Color.RED, 0.2)
		_init_player()
		# Reset enemies to center
		for e in enemies:
			_reset_enemy(e)

func _on_stage_clear() -> void:
	stage_clearing = true
	message_label.text = "STAGE CLEAR!"
	ProtoUtils.flash(self, ProtoColors.GOAL, 0.3)
	await get_tree().create_timer(stage_clear_delay).timeout
	stage += 1
	_start_stage()

# =============================================================================
# Maze Generation (Recursive Backtracker via stack)
# =============================================================================
func _generate_maze() -> void:
	# Init all walls
	grid = []
	for x in range(GRID_W):
		var col: Array = []
		for y in range(GRID_H):
			col.append(Cell.WALL)
		grid.append(col)

	# DFS maze carve — corridors at odd coords
	var visited := {}
	var stack: Array[Vector2i] = []
	var start := Vector2i(1, 1)
	visited[start] = true
	grid[1][1] = Cell.PATH
	stack.push_back(start)

	while stack.size() > 0:
		var current = stack.back()
		var neighbors: Array[Vector2i] = []
		for dir in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			var nx = current.x + dir.x
			var ny = current.y + dir.y
			if nx > 0 and nx < GRID_W - 1 and ny > 0 and ny < GRID_H - 1:
				var npos = Vector2i(nx, ny)
				if not visited.has(npos):
					neighbors.append(npos)

		if neighbors.size() > 0:
			var chosen = neighbors[randi() % neighbors.size()]
			# Carve wall between current and chosen
			var between = Vector2i((current.x + chosen.x) / 2, (current.y + chosen.y) / 2)
			grid[between.x][between.y] = Cell.PATH
			grid[chosen.x][chosen.y] = Cell.PATH
			visited[chosen] = true
			stack.push_back(chosen)
		else:
			stack.pop_back()

	# Clear center area for enemy spawn (5x5)
	var cx = GRID_W / 2
	var cy = GRID_H / 2
	for x in range(cx - 2, cx + 3):
		for y in range(cy - 2, cy + 3):
			if x >= 0 and x < GRID_W and y >= 0 and y < GRID_H:
				grid[x][y] = Cell.PATH

	# Ensure paths connect to center — carve corridors from center outward
	_ensure_center_connected(cx, cy)

	# Remove all dead ends so the player always has an escape route
	_remove_dead_ends()

func _ensure_center_connected(cx: int, cy: int) -> void:
	# Carve a path from center upward until we hit an existing corridor
	for y in range(cy - 3, 0, -1):
		if grid[cx][y] == Cell.PATH:
			break
		grid[cx][y] = Cell.PATH
	# Carve downward
	for y in range(cy + 3, GRID_H):
		if grid[cx][y] == Cell.PATH:
			break
		grid[cx][y] = Cell.PATH
	# Carve left
	for x in range(cx - 3, 0, -1):
		if grid[x][cy] == Cell.PATH:
			break
		grid[x][cy] = Cell.PATH
	# Carve right
	for x in range(cx + 3, GRID_W):
		if grid[x][cy] == Cell.PATH:
			break
		grid[x][cy] = Cell.PATH

func _remove_dead_ends() -> void:
	# Repeatedly find path cells with only 1 path neighbor (dead ends)
	# and carve through a wall to connect them to an adjacent corridor.
	var changed := true
	while changed:
		changed = false
		for x in range(1, GRID_W - 1):
			for y in range(1, GRID_H - 1):
				if grid[x][y] == Cell.WALL:
					continue
				# Count path neighbors
				var path_neighbors := 0
				var wall_dirs: Array[Vector2i] = []
				for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					if nx >= 0 and nx < GRID_W and ny >= 0 and ny < GRID_H:
						if grid[nx][ny] != Cell.WALL:
							path_neighbors += 1
						else:
							wall_dirs.append(dir)
				if path_neighbors == 1 and wall_dirs.size() > 0:
					# Dead end — carve through a wall toward another path
					wall_dirs.shuffle()
					var carved := false
					for dir in wall_dirs:
						# Check if carving 2 cells in this direction reaches a path
						var wx = x + dir.x
						var wy = y + dir.y
						var bx = x + dir.x * 2
						var by = y + dir.y * 2
						if bx >= 1 and bx < GRID_W - 1 and by >= 1 and by < GRID_H - 1:
							if grid[bx][by] != Cell.WALL:
								# Carve through the wall
								grid[wx][wy] = Cell.PATH
								carved = true
								changed = true
								break
					if not carved:
						# Fallback: just carve the wall neighbor to open up
						for dir in wall_dirs:
							var wx = x + dir.x
							var wy = y + dir.y
							if wx >= 1 and wx < GRID_W - 1 and wy >= 1 and wy < GRID_H - 1:
								grid[wx][wy] = Cell.PATH
								changed = true
								break

# =============================================================================
# Pip Placement
# =============================================================================
func _place_pips() -> void:
	total_pips = 0
	collected_pips = 0
	var cx = GRID_W / 2
	var cy = GRID_H / 2

	for x in range(GRID_W):
		for y in range(GRID_H):
			if grid[x][y] == Cell.PATH:
				# Skip player start
				if x == 1 and y == 1:
					grid[x][y] = Cell.EMPTY
					continue
				# Skip center spawn area
				if abs(x - cx) <= 2 and abs(y - cy) <= 2:
					grid[x][y] = Cell.EMPTY
					continue
				grid[x][y] = Cell.PIP
				total_pips += 1

	# Place 4 power pips in corner regions
	var power_positions: Array[Vector2i] = []
	power_positions.append(_find_path_near(Vector2i(1, 1), Vector2i(GRID_W / 4, GRID_H / 4)))
	power_positions.append(_find_path_near(Vector2i(GRID_W - 2, 1), Vector2i(GRID_W * 3 / 4, GRID_H / 4)))
	power_positions.append(_find_path_near(Vector2i(1, GRID_H - 2), Vector2i(GRID_W / 4, GRID_H * 3 / 4)))
	power_positions.append(_find_path_near(Vector2i(GRID_W - 2, GRID_H - 2), Vector2i(GRID_W * 3 / 4, GRID_H * 3 / 4)))

	for pp in power_positions:
		if pp.x >= 0 and grid[pp.x][pp.y] == Cell.PIP:
			grid[pp.x][pp.y] = Cell.POWER_PIP
			# Power pips still count toward total (already counted as PIP)

func _find_path_near(corner: Vector2i, search_center: Vector2i) -> Vector2i:
	# Find a PATH/PIP cell closest to search_center in the quadrant near corner
	var best := Vector2i(-1, -1)
	var best_dist := 999999.0
	var qx_min = 1 if corner.x < GRID_W / 2 else GRID_W / 2
	var qx_max = GRID_W / 2 if corner.x < GRID_W / 2 else GRID_W - 1
	var qy_min = 1 if corner.y < GRID_H / 2 else GRID_H / 2
	var qy_max = GRID_H / 2 if corner.y < GRID_H / 2 else GRID_H - 1
	for x in range(qx_min, qx_max):
		for y in range(qy_min, qy_max):
			if grid[x][y] == Cell.PIP:
				var d = Vector2(x, y).distance_to(Vector2(search_center))
				if d < best_dist:
					best_dist = d
					best = Vector2i(x, y)
	# Fallback: if nothing found in quadrant, search wider
	if best.x < 0:
		for x in range(1, GRID_W - 1):
			for y in range(1, GRID_H - 1):
				if grid[x][y] == Cell.PIP:
					return Vector2i(x, y)
	return best

# =============================================================================
# Player
# =============================================================================
func _init_player() -> void:
	player_grid_pos = Vector2i(1, 1)
	player_visual_pos = _grid_to_pixel(player_grid_pos)
	player_move_progress = 1.0
	player_dir = Vector2i.ZERO
	player_queued_dir = Vector2i.ZERO

func _process_player(delta: float) -> void:
	# Read input for direction
	var input_dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_left"):
		input_dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		input_dir = Vector2i(1, 0)
	elif Input.is_action_pressed("ui_up"):
		input_dir = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2i(0, 1)

	if input_dir != Vector2i.ZERO:
		player_queued_dir = input_dir

	if player_move_progress < 1.0:
		# Moving between cells
		player_move_progress += delta * player_move_speed
		if player_move_progress >= 1.0:
			player_move_progress = 1.0
			player_visual_pos = player_move_to
			_on_player_arrive()
		else:
			player_visual_pos = player_move_from.lerp(player_move_to, player_move_progress)
	else:
		# At a cell, try to move
		var moved := false
		# Try queued direction first
		if player_queued_dir != Vector2i.ZERO and _can_move(player_grid_pos, player_queued_dir):
			player_dir = player_queued_dir
			player_queued_dir = Vector2i.ZERO
			_start_player_move(player_dir)
			moved = true
		elif player_dir != Vector2i.ZERO and _can_move(player_grid_pos, player_dir):
			_start_player_move(player_dir)
			moved = true

		if not moved:
			# Try queued direction for next frame
			if player_queued_dir != Vector2i.ZERO and not _can_move(player_grid_pos, player_queued_dir):
				# Keep queued dir for a bit in case we reach a turn
				pass

func _start_player_move(dir: Vector2i) -> void:
	var target = player_grid_pos + dir
	player_move_from = _grid_to_pixel(player_grid_pos)
	player_move_to = _grid_to_pixel(target)
	player_grid_pos = target
	player_move_progress = 0.0

func _on_player_arrive() -> void:
	var x = player_grid_pos.x
	var y = player_grid_pos.y
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	var cell = grid[x][y]
	if cell == Cell.PIP:
		grid[x][y] = Cell.EMPTY
		score += 10
		collected_pips += 1
		_update_ui()
		_check_all_pips_collected()
	elif cell == Cell.POWER_PIP:
		grid[x][y] = Cell.EMPTY
		score += 50
		collected_pips += 1
		_activate_power_mode()
		_update_ui()
		_check_all_pips_collected()

func _check_all_pips_collected() -> void:
	if collected_pips >= total_pips:
		_on_stage_clear()

func _can_move(from: Vector2i, dir: Vector2i) -> bool:
	var target = from + dir
	if target.x < 0 or target.x >= GRID_W or target.y < 0 or target.y >= GRID_H:
		return false
	return grid[target.x][target.y] != Cell.WALL

# =============================================================================
# Enemies
# =============================================================================
func _init_enemies() -> void:
	enemies.clear()
	var cx = GRID_W / 2
	var cy = GRID_H / 2
	var offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
	for i in range(enemy_count):
		var offset = offsets[i % offsets.size()]
		var e = {
			"grid_pos": Vector2i(cx + offset.x, cy + offset.y),
			"visual_pos": _grid_to_pixel(Vector2i(cx + offset.x, cy + offset.y)),
			"move_from": Vector2.ZERO,
			"move_to": Vector2.ZERO,
			"move_progress": 1.0,
			"state": "normal",  # normal, vulnerable, dead
			"respawn_timer": 0.0,
			"color_index": i,
		}
		enemies.append(e)

func _reset_enemy(e: Dictionary) -> void:
	var cx = GRID_W / 2
	var cy = GRID_H / 2
	e["grid_pos"] = Vector2i(cx, cy)
	e["visual_pos"] = _grid_to_pixel(Vector2i(cx, cy))
	e["move_progress"] = 1.0
	e["state"] = "normal"
	e["respawn_timer"] = 0.0

func _process_enemies(delta: float) -> void:
	var speed = enemy_move_speed + (stage - 1) * 0.3  # speed up each stage
	for e in enemies:
		if e["state"] == "dead":
			e["respawn_timer"] -= delta
			if e["respawn_timer"] <= 0:
				_reset_enemy(e)
			continue

		var current_speed = speed
		if e["state"] == "vulnerable":
			current_speed = enemy_vulnerable_speed

		if e["move_progress"] < 1.0:
			e["move_progress"] += delta * current_speed
			if e["move_progress"] >= 1.0:
				e["move_progress"] = 1.0
				e["visual_pos"] = e["move_to"]
			else:
				e["visual_pos"] = (e["move_from"] as Vector2).lerp(e["move_to"], e["move_progress"])
		else:
			# Decide next move
			var next_dir: Vector2i
			if e["state"] == "vulnerable":
				next_dir = _bfs_flee(e["grid_pos"], player_grid_pos)
			else:
				next_dir = _bfs_chase(e["grid_pos"], player_grid_pos)

			if next_dir != Vector2i.ZERO and _can_move(e["grid_pos"], next_dir):
				var target = e["grid_pos"] + next_dir
				e["move_from"] = _grid_to_pixel(e["grid_pos"])
				e["move_to"] = _grid_to_pixel(target)
				e["grid_pos"] = target
				e["move_progress"] = 0.0

func _bfs_chase(from: Vector2i, target: Vector2i) -> Vector2i:
	# BFS to find shortest path from 'from' to 'target'
	if from == target:
		return Vector2i.ZERO
	var queue: Array[Vector2i] = [from]
	var came_from := {}
	came_from[from] = from
	var found := false
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == target:
			found = true
			break
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next = current + dir
			if next.x >= 0 and next.x < GRID_W and next.y >= 0 and next.y < GRID_H:
				if grid[next.x][next.y] != Cell.WALL and not came_from.has(next):
					came_from[next] = current
					queue.append(next)
	if not found:
		return _random_valid_dir(from)
	# Trace back to find first step
	var step = target
	while came_from.get(step, from) != from:
		step = came_from[step]
	return step - from

func _bfs_flee(from: Vector2i, threat: Vector2i) -> Vector2i:
	# Move in the direction that maximizes distance from threat
	var best_dir := Vector2i.ZERO
	var best_dist := -1.0
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for dir in dirs:
		var next = from + dir
		if next.x >= 0 and next.x < GRID_W and next.y >= 0 and next.y < GRID_H:
			if grid[next.x][next.y] != Cell.WALL:
				var d = Vector2(next).distance_to(Vector2(threat))
				if d > best_dist:
					best_dist = d
					best_dir = dir
	return best_dir

func _random_valid_dir(from: Vector2i) -> Vector2i:
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for dir in dirs:
		if _can_move(from, dir):
			return dir
	return Vector2i.ZERO

# =============================================================================
# Power Mode
# =============================================================================
func _activate_power_mode() -> void:
	power_active = true
	power_timer = power_pip_duration
	power_kill_streak = 0
	for e in enemies:
		if e["state"] == "normal":
			e["state"] = "vulnerable"
	ProtoUtils.flash(self, ProtoColors.PICKUP, 0.2)

func _process_power_timer(delta: float) -> void:
	if not power_active:
		return
	power_timer -= delta
	if power_timer <= 0:
		power_active = false
		power_timer = 0.0
		for e in enemies:
			if e["state"] == "vulnerable":
				e["state"] = "normal"

# =============================================================================
# Collision
# =============================================================================
func _check_enemy_collisions() -> void:
	for e in enemies:
		if e["state"] == "dead":
			continue
		# Check grid proximity (same cell or close visual positions)
		var dist = (e["visual_pos"] as Vector2).distance_to(player_visual_pos)
		if dist < CELL_SIZE * 0.7:
			if e["state"] == "vulnerable":
				_kill_enemy(e)
			elif e["state"] == "normal":
				_on_player_death()
				return

func _kill_enemy(e: Dictionary) -> void:
	e["state"] = "dead"
	e["respawn_timer"] = enemy_respawn_delay
	power_kill_streak += 1
	var points = 200 * int(pow(2, power_kill_streak - 1))
	score += points
	_update_ui()
	ProtoUtils.popup_text(self, str(points), e["visual_pos"] + grid_offset - Vector2(20, 20), ProtoColors.TEXT_ACCENT)

# =============================================================================
# Coordinate Helpers
# =============================================================================
func _grid_to_pixel(gpos: Vector2i) -> Vector2:
	return Vector2(gpos.x * CELL_SIZE + CELL_SIZE / 2.0, gpos.y * CELL_SIZE + CELL_SIZE / 2.0)

# =============================================================================
# Drawing
# =============================================================================
func _draw() -> void:
	# Background fill
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), ProtoColors.BACKGROUND)

	# Draw grid
	for x in range(GRID_W):
		for y in range(GRID_H):
			var rect = Rect2(grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
			var cell = grid[x][y] if grid.size() > x and grid[x].size() > y else Cell.WALL
			if cell == Cell.WALL:
				draw_rect(rect, ProtoColors.WALL)
			else:
				draw_rect(rect, ProtoColors.FLOOR)
				if cell == Cell.PIP:
					var center = grid_offset + Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, y * CELL_SIZE + CELL_SIZE / 2.0)
					draw_circle(center, 3.0, ProtoColors.GOAL)
				elif cell == Cell.POWER_PIP:
					var center = grid_offset + Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, y * CELL_SIZE + CELL_SIZE / 2.0)
					var pulse = 5.0 + sin(pip_pulse_time) * 2.0
					draw_circle(center, pulse, ProtoColors.PICKUP)

	# Draw enemies
	for e in enemies:
		if e["state"] == "dead":
			continue
		var pos = grid_offset + (e["visual_pos"] as Vector2)
		var ecolor: Color
		if e["state"] == "vulnerable":
			if power_timer < 2.0 and fmod(power_timer, 0.4) < 0.2:
				ecolor = VULNERABLE_FLASH_COLOR
			else:
				ecolor = VULNERABLE_COLOR
		else:
			ecolor = ProtoColors.ENEMY
		draw_circle(pos, CELL_SIZE / 2.0 - 2.0, ecolor)
		# Eyes
		var eye_offset_l = Vector2(-4, -3)
		var eye_offset_r = Vector2(4, -3)
		draw_circle(pos + eye_offset_l, 3.0, Color.WHITE)
		draw_circle(pos + eye_offset_r, 3.0, Color.WHITE)
		draw_circle(pos + eye_offset_l + Vector2(1, 0), 1.5, Color.BLACK)
		draw_circle(pos + eye_offset_r + Vector2(1, 0), 1.5, Color.BLACK)

	# Draw player
	var ppos = grid_offset + player_visual_pos
	var mouth_angle = abs(sin(player_mouth_anim)) * 0.8  # 0 to ~0.8 radians
	# Draw as a circle with a wedge mouth
	var radius = CELL_SIZE / 2.0 - 2.0
	# Determine facing angle
	var facing = 0.0
	if player_dir == Vector2i(-1, 0):
		facing = PI
	elif player_dir == Vector2i(0, -1):
		facing = -PI / 2.0
	elif player_dir == Vector2i(0, 1):
		facing = PI / 2.0

	# Draw pie-slice circle (simple approach: draw full circle, then draw mouth wedge in floor color)
	draw_circle(ppos, radius, ProtoColors.PLAYER)
	if mouth_angle > 0.05:
		# Draw mouth as a triangle in background color
		var mouth_p1 = ppos
		var mouth_p2 = ppos + Vector2(cos(facing - mouth_angle), sin(facing - mouth_angle)) * (radius + 2)
		var mouth_p3 = ppos + Vector2(cos(facing + mouth_angle), sin(facing + mouth_angle)) * (radius + 2)
		draw_colored_polygon(PackedVector2Array([mouth_p1, mouth_p2, mouth_p3]), ProtoColors.FLOOR)

# =============================================================================
# UI
# =============================================================================
func _update_ui() -> void:
	if score_label:
		score_label.text = "SCORE: %d" % score
	if lives_label:
		var hearts = ""
		for i in range(lives):
			hearts += "<3 "
		lives_label.text = hearts.strip_edges()
	if stage_label:
		stage_label.text = "STAGE %d" % stage
