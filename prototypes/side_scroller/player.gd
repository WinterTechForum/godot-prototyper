extends CharacterBody2D

## ── Tuning Knobs ──────────────────────────────────────────
@export var speed: float = 300.0
@export var jump_force: float = -520.0
@export var gravity: float = 1200.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

## ── State ─────────────────────────────────────────────────
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_dead: bool = false

signal died

func _ready() -> void:
	# Draw the player visually
	var rect = ColorRect.new()
	rect.size = Vector2(32, 48)
	rect.position = Vector2(-16, -48)
	rect.color = Color("#4ecdc4")
	add_child(rect)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	velocity.y += gravity * delta

	# Coyote time tracking
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Horizontal movement
	var dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed

	move_and_slide()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	# Flash red
	modulate = Color("#ff6b6b")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): died.emit())
