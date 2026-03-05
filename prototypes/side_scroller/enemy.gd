extends CharacterBody2D

## ── Tuning Knobs ──────────────────────────────────────────
@export var patrol_speed: float = 100.0
@export var patrol_range: float = 150.0

## ── State ─────────────────────────────────────────────────
var spawn_x: float = 0.0
var direction: float = 1.0

func _ready() -> void:
	spawn_x = position.x
	# Draw enemy visually
	var rect = ColorRect.new()
	rect.size = Vector2(32, 32)
	rect.position = Vector2(-16, -32)
	rect.color = Color("#ff6b6b")
	add_child(rect)

	# Hitbox area for killing player
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(28, 28)
	shape.shape = box
	shape.position = Vector2(0, -16)
	area.add_child(shape)
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _physics_process(delta: float) -> void:
	# Patrol back and forth
	position.x += patrol_speed * direction * delta

	if position.x > spawn_x + patrol_range:
		direction = -1.0
	elif position.x < spawn_x - patrol_range:
		direction = 1.0

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
