extends Node2D

# --- Tuning Variables ---
@export var paddle_speed: float = 400.0
@export var ball_speed: float = 350.0
@export var ball_speed_increase: float = 15.0
@export var ai_speed: float = 300.0
@export var winning_score: int = 7
@export var paddle_width: float = 16.0
@export var paddle_height: float = 100.0
@export var ball_size: float = 12.0
@export var paddle_margin: float = 40.0

var screen_size: Vector2

# Paddle y positions (center)
var left_paddle_y: float
var right_paddle_y: float

# Ball
var ball_pos: Vector2
var ball_vel: Vector2
var current_ball_speed: float

# Score
var left_score: int = 0
var right_score: int = 0
var game_over: bool = false

@onready var left_score_label: Label = $LeftScoreLabel
@onready var right_score_label: Label = $RightScoreLabel
@onready var message_label: Label = $MessageLabel


func _ready():
	screen_size = get_viewport_rect().size
	left_paddle_y = screen_size.y / 2.0
	right_paddle_y = screen_size.y / 2.0
	message_label.visible = false
	_reset_ball()
	_update_score_display()


func _reset_ball():
	ball_pos = screen_size / 2.0
	current_ball_speed = ball_speed
	var angle = randf_range(-PI / 4, PI / 4)
	if randi() % 2 == 0:
		angle += PI
	ball_vel = Vector2(cos(angle), sin(angle)) * current_ball_speed


func _physics_process(delta):
	if game_over:
		return

	# Player input
	var input_dir = 0.0
	if Input.is_action_pressed("ui_up"):
		input_dir -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_dir += 1.0
	left_paddle_y += input_dir * paddle_speed * delta
	left_paddle_y = clamp(left_paddle_y, paddle_height / 2.0, screen_size.y - paddle_height / 2.0)

	# AI movement - follows ball with limited speed
	var ai_target = ball_pos.y
	var ai_diff = ai_target - right_paddle_y
	var ai_move = sign(ai_diff) * min(abs(ai_diff), ai_speed * delta)
	right_paddle_y += ai_move
	right_paddle_y = clamp(right_paddle_y, paddle_height / 2.0, screen_size.y - paddle_height / 2.0)

	# Move ball
	ball_pos += ball_vel * delta

	# Top/bottom wall bounce
	if ball_pos.y - ball_size / 2.0 <= 0:
		ball_pos.y = ball_size / 2.0
		ball_vel.y = abs(ball_vel.y)
	elif ball_pos.y + ball_size / 2.0 >= screen_size.y:
		ball_pos.y = screen_size.y - ball_size / 2.0
		ball_vel.y = -abs(ball_vel.y)

	# Paddle collision rects
	var ball_rect = Rect2(
		ball_pos.x - ball_size / 2.0,
		ball_pos.y - ball_size / 2.0,
		ball_size, ball_size
	)

	# Left paddle
	var left_rect = Rect2(
		paddle_margin - paddle_width / 2.0,
		left_paddle_y - paddle_height / 2.0,
		paddle_width, paddle_height
	)
	if left_rect.intersects(ball_rect) and ball_vel.x < 0:
		ball_pos.x = paddle_margin + paddle_width / 2.0 + ball_size / 2.0
		var hit_ratio = (ball_pos.y - left_paddle_y) / (paddle_height / 2.0)
		_bounce_ball(1.0, hit_ratio)

	# Right paddle
	var right_x = screen_size.x - paddle_margin
	var right_rect = Rect2(
		right_x - paddle_width / 2.0,
		right_paddle_y - paddle_height / 2.0,
		paddle_width, paddle_height
	)
	if right_rect.intersects(ball_rect) and ball_vel.x > 0:
		ball_pos.x = right_x - paddle_width / 2.0 - ball_size / 2.0
		var hit_ratio = (ball_pos.y - right_paddle_y) / (paddle_height / 2.0)
		_bounce_ball(-1.0, hit_ratio)

	# Scoring
	if ball_pos.x < 0:
		right_score += 1
		_on_score()
	elif ball_pos.x > screen_size.x:
		left_score += 1
		_on_score()

	queue_redraw()


func _bounce_ball(x_dir: float, hit_ratio: float):
	current_ball_speed += ball_speed_increase
	var max_angle = PI / 3.0
	var angle = hit_ratio * max_angle
	ball_vel = Vector2(x_dir * cos(angle), sin(angle)).normalized() * current_ball_speed


func _on_score():
	_update_score_display()
	if left_score >= winning_score:
		game_over = true
		message_label.text = "Player Wins!\nPress R to restart"
		message_label.visible = true
	elif right_score >= winning_score:
		game_over = true
		message_label.text = "Computer Wins!\nPress R to restart"
		message_label.visible = true
	else:
		_reset_ball()


func _update_score_display():
	left_score_label.text = str(left_score)
	right_score_label.text = str(right_score)


func _draw():
	# Background
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.05, 0.05, 0.1))

	# Center dashed line
	for i in range(0, int(screen_size.y), 24):
		draw_rect(Rect2(screen_size.x / 2.0 - 1, i, 2, 12), Color(0.25, 0.25, 0.35))

	# Left paddle
	draw_rect(Rect2(
		paddle_margin - paddle_width / 2.0,
		left_paddle_y - paddle_height / 2.0,
		paddle_width, paddle_height
	), Color.WHITE)

	# Right paddle
	draw_rect(Rect2(
		screen_size.x - paddle_margin - paddle_width / 2.0,
		right_paddle_y - paddle_height / 2.0,
		paddle_width, paddle_height
	), Color.WHITE)

	# Ball
	draw_rect(Rect2(
		ball_pos.x - ball_size / 2.0,
		ball_pos.y - ball_size / 2.0,
		ball_size, ball_size
	), Color.WHITE)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
