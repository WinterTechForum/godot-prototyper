extends Node2D

# --- Tuning ---
@export var ship_rotation_speed: float = 3.2
@export var ship_thrust_speed: float = 360.0
@export var ship_radius: float = 16.0
@export var bullet_speed: float = 760.0
@export var bullet_radius: float = 4.0
@export var bullet_lifetime: float = 1.8
@export var asteroid_min_speed: float = 90.0
@export var asteroid_max_speed: float = 220.0
@export var asteroid_spawn_interval: float = 1.2
@export var asteroid_max_radius_multiplier: float = 8.0
@export var asteroid_base_color: Color = Color(0.62, 0.62, 0.62)

var ship_position: Vector2
var ship_direction: Vector2 = Vector2.UP
var ship_velocity: Vector2 = Vector2.ZERO
var bullets: Array[Dictionary] = []
var asteroids: Array[Dictionary] = []
var score: int = 0
var game_over: bool = false
var spawn_timer: float = 0.0

func _ready() -> void:
	ship_position = get_viewport_rect().size * 0.5
	randomize()


func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return

	spawn_timer += delta
	if spawn_timer >= asteroid_spawn_interval:
		spawn_timer = 0.0
		spawn_asteroid()

	update_ship(delta)
	update_bullets(delta)
	update_asteroids(delta)
	handle_bullet_asteroid_collisions()
	handle_asteroid_ship_collisions()
	handle_asteroid_asteroid_collisions()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_SPACE and not game_over:
			fire_bullet()


func update_ship(delta: float) -> void:
	var rotate_input: float = Input.get_axis("ui_left", "ui_right")
	if rotate_input != 0.0:
		ship_direction = ship_direction.rotated(rotate_input * ship_rotation_speed * delta).normalized()

	if Input.is_action_just_pressed("ui_up"):
		ship_velocity = ship_direction * ship_thrust_speed

	ship_position += ship_velocity * delta

	var screen: Vector2 = get_viewport_rect().size
	var clamped_x: float = clampf(ship_position.x, ship_radius, screen.x - ship_radius)
	var clamped_y: float = clampf(ship_position.y, ship_radius, screen.y - ship_radius)
	var hit_edge: bool = not is_equal_approx(clamped_x, ship_position.x) or not is_equal_approx(clamped_y, ship_position.y)
	ship_position = Vector2(clamped_x, clamped_y)
	if hit_edge:
		ship_velocity = Vector2.ZERO


func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var b: Dictionary = bullets[i]
		var p: Vector2 = b["position"]
		var v: Vector2 = b["velocity"]
		var life: float = b["life"]
		p += v * delta
		life -= delta
		b["position"] = p
		b["life"] = life
		bullets[i] = b
		if life <= 0.0:
			bullets.remove_at(i)


func update_asteroids(delta: float) -> void:
	for i in range(asteroids.size()):
		var a: Dictionary = asteroids[i]
		var p: Vector2 = a["position"]
		var v: Vector2 = a["velocity"]
		var r: float = a["radius"]
		p += v * delta

		var margin: float = r + 60.0
		var screen: Vector2 = get_viewport_rect().size
		if p.x < -margin:
			p.x = screen.x + margin
		elif p.x > screen.x + margin:
			p.x = -margin

		if p.y < -margin:
			p.y = screen.y + margin
		elif p.y > screen.y + margin:
			p.y = -margin

		a["position"] = p
		asteroids[i] = a


func fire_bullet() -> void:
	bullets.append({
		"position": ship_position + ship_direction * (ship_radius + bullet_radius + 2.0),
		"velocity": ship_direction * bullet_speed,
		"life": bullet_lifetime
	})


func spawn_asteroid() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var margin: float = 90.0
	var side: int = randi() % 4
	var spawn_pos: Vector2 = Vector2.ZERO

	match side:
		0:
			spawn_pos = Vector2(randf_range(0.0, screen.x), -margin)
		1:
			spawn_pos = Vector2(screen.x + margin, randf_range(0.0, screen.y))
		2:
			spawn_pos = Vector2(randf_range(0.0, screen.x), screen.y + margin)
		_:
			spawn_pos = Vector2(-margin, randf_range(0.0, screen.y))

	var target: Vector2 = Vector2(randf_range(0.0, screen.x), randf_range(0.0, screen.y))
	var dir: Vector2 = (target - spawn_pos).normalized()
	if dir.length_squared() == 0.0:
		dir = Vector2.RIGHT

	asteroids.append({
		"position": spawn_pos,
		"velocity": dir * randf_range(asteroid_min_speed, asteroid_max_speed),
		"radius": ship_radius * asteroid_max_radius_multiplier
	})


func handle_bullet_asteroid_collisions() -> void:
	for bi in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[bi]
		var bpos: Vector2 = bullet["position"]
		var consumed: bool = false

		for ai in range(asteroids.size() - 1, -1, -1):
			var asteroid: Dictionary = asteroids[ai]
			var apos: Vector2 = asteroid["position"]
			var aradius: float = asteroid["radius"]
			var dist_sq: float = bpos.distance_squared_to(apos)
			var hit_dist: float = bullet_radius + aradius
			if dist_sq > hit_dist * hit_dist:
				continue

			score += 1
			consumed = true
			asteroids.remove_at(ai)
			if aradius > ship_radius + 0.01:
				spawn_split_asteroids(asteroid)
			break

		if consumed:
			bullets.remove_at(bi)


func spawn_split_asteroids(asteroid: Dictionary) -> void:
	var velocity: Vector2 = asteroid["velocity"]
	var original_dir: Vector2 = velocity.normalized()
	if original_dir.length_squared() == 0.0:
		original_dir = Vector2.RIGHT

	var ortho_a: Vector2 = Vector2(-original_dir.y, original_dir.x)
	var ortho_b: Vector2 = -ortho_a
	var radius: float = asteroid["radius"]
	var child_radius: float = maxf(ship_radius, radius * 0.5)
	var speed: float = clampf(velocity.length() * 1.1, asteroid_min_speed, asteroid_max_speed * 1.5)
	var pos: Vector2 = asteroid["position"]

	asteroids.append({
		"position": pos + ortho_a * child_radius * 0.5,
		"velocity": ortho_a * speed,
		"radius": child_radius
	})
	asteroids.append({
		"position": pos + ortho_b * child_radius * 0.5,
		"velocity": ortho_b * speed,
		"radius": child_radius
	})


func handle_asteroid_ship_collisions() -> void:
	for asteroid in asteroids:
		var apos: Vector2 = asteroid["position"]
		var aradius: float = asteroid["radius"]
		var hit_dist: float = ship_radius + aradius
		if ship_position.distance_squared_to(apos) <= hit_dist * hit_dist:
			game_over = true
			return


func handle_asteroid_asteroid_collisions() -> void:
	for i in range(asteroids.size()):
		for j in range(i + 1, asteroids.size()):
			var a: Dictionary = asteroids[i]
			var b: Dictionary = asteroids[j]
			var apos: Vector2 = a["position"]
			var bpos: Vector2 = b["position"]
			var aradius: float = a["radius"]
			var bradius: float = b["radius"]
			var min_dist: float = aradius + bradius
			var delta: Vector2 = bpos - apos
			if delta.length_squared() > min_dist * min_dist:
				continue

			var normal: Vector2 = delta.normalized()
			if normal.length_squared() == 0.0:
				normal = Vector2.RIGHT

			var av: Vector2 = a["velocity"]
			var bv: Vector2 = b["velocity"]
			a["velocity"] = av.bounce(normal)
			b["velocity"] = bv.bounce(-normal)
			asteroids[i] = a
			asteroids[j] = b


func _draw() -> void:
	draw_ship()
	for asteroid in asteroids:
		var p: Vector2 = asteroid["position"]
		var r: float = asteroid["radius"]
		draw_circle(p, r, asteroid_base_color)
		draw_arc(p, r, 0.0, TAU, 24, Color.BLACK, 2.0)

	for bullet in bullets:
		draw_circle(bullet["position"], bullet_radius, Color(1.0, 0.92, 0.2))

	draw_string(ThemeDB.fallback_font, Vector2(20, 40), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)

	if game_over:
		var text: String = "GAME OVER  |  R: Restart  Esc: Quit"
		var font: Font = ThemeDB.fallback_font
		var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
		var pos: Vector2 = get_viewport_rect().size * 0.5 - Vector2(size.x * 0.5, 0.0)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(1.0, 0.3, 0.3))


func draw_ship() -> void:
	var forward: Vector2 = ship_direction.normalized()
	if forward.length_squared() == 0.0:
		forward = Vector2.UP
	var right: Vector2 = Vector2(forward.y, -forward.x)

	var nose: Vector2 = ship_position + forward * ship_radius * 1.4
	var rear_left: Vector2 = ship_position - forward * ship_radius + right * ship_radius * 0.8
	var rear_right: Vector2 = ship_position - forward * ship_radius - right * ship_radius * 0.8
	var points: PackedVector2Array = PackedVector2Array([nose, rear_left, rear_right])

	draw_colored_polygon(points, Color(0.3, 0.9, 1.0))
	draw_polyline(points + PackedVector2Array([nose]), Color.BLACK, 2.0)
