# Godot Rapid Prototype Kit — Claude Code Instructions

## Purpose
This project is a **rapid game prototyping** workspace. The goal is to turn natural language
game ideas into playable Godot prototypes as fast as possible. Prototypes should be playable
within minutes, not hours. Polish, art, and sound are irrelevant — only the **core mechanic**
matters.

## Tech Stack
- **Godot 4.x** (GDScript only, no C#)
- **2D games only**
- All prototypes live in their own subfolder under `prototypes/`

## Project Structure
```
godot-prototype-kit/
├── CLAUDE.md                  # (this file)
├── project.godot              # Godot project file
├── shared/                    # Reusable building blocks
│   ├── colors.gd              # Color palette constants
│   ├── debug_overlay.gd       # FPS + state display
│   └── proto_utils.gd         # Helper functions
├── prototypes/                # Each prototype gets its own folder
│   └── example_sokoban/
│       ├── main.tscn          # Entry scene
│       ├── main.gd            # Main script
│       └── ...
└── prompt_guide.md            # How to describe game ideas
```

## Rules for Generating Prototypes

### Speed Over Quality
- Use **ColorRect**, **Polygon2D**, or simple **draw_*()** calls for all visuals
- Never search for or reference external assets (images, sounds, fonts)
- Use Godot's default font for any text
- Hardcode values first; only extract to variables if iteration demands it

### Structure
- Each prototype gets a folder: `prototypes/<snake_case_name>/`
- Each prototype is its own Godot game, with a project.godot file
  - Use the project.godot at the root as the template for new games

- Every prototype MUST have a `main.tscn` as its entry scene
- Keep it to as few files as possible — ideally 1 scene + 1-3 scripts

### Game Feel Priorities
When prototyping, focus on these in order:
1. **Core loop** — Can the player do the one interesting thing?
2. **Feedback** — Does the player know what happened? (screen shake, color flash, score text)
3. **Fail state** — Can the player lose / need to retry?
4. **Win state** — Can the player succeed / feel satisfaction?
5. **Tuning knobs** — Expose key variables (speed, gravity, spawn rate) at the top of scripts

### Coding Conventions
- Use `@export` for tuning variables so they show in the editor
- Group tuning variables at the top of each script with a comment block
- Use `class_name` for any node that other scripts reference
- Prefer signals over direct references between nodes
- Add a restart keybind (R key) to every prototype
- Add a quit keybind (Escape) to every prototype
- Target 1920x1080 or 1280x720 resolution, set in project.godot

### Validation
After writing files, run:
```bash
# Import/validate the project
godot --headless --import

# If there's a script you want to syntax-check, open editor briefly:
godot --headless --editor --quit
```
Check stderr for errors. Fix any errors before declaring the prototype ready.

## How to Handle a Game Idea Prompt

When the user describes a game idea:

1. **Identify the core mechanic** — What is the ONE interesting verb/action?
2. **Identify the core tension** — What makes it challenging or interesting?
3. **Identify the minimum viable prototype** — What's the least you can build to test if it's fun?
4. **Build it** — Write the scene(s) and script(s)
5. **Add tuning knobs** — Expose the 3-5 most important variables with @export
6. **Add restart** — R to restart, Escape to quit
7. **Update project.godot** — Set main_scene to this prototype
8. **Validate** — Run headless import, fix errors

## Common Patterns

### Player Movement (Top-Down)
```gdscript
@export var speed: float = 300.0
func _physics_process(delta):
    var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = input * speed
    move_and_slide()
```

### Player Movement (Platformer)
```gdscript
@export var speed: float = 300.0
@export var jump_force: float = -600.0
@export var gravity: float = 1200.0
func _physics_process(delta):
    velocity.y += gravity * delta
    if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
        velocity.y = jump_force
    velocity.x = Input.get_axis("ui_left", "ui_right") * speed
    move_and_slide()
```

### Screen Shake
```gdscript
func shake(intensity: float = 10.0, duration: float = 0.2):
    var tween = create_tween()
    for i in range(int(duration / 0.05)):
        tween.tween_property(camera, "offset",
            Vector2(randf_range(-1,1), randf_range(-1,1)) * intensity, 0.05)
    tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
```

### Simple Score Display
```gdscript
var score: int = 0
@onready var label = $ScoreLabel  # a Label node
func add_score(amount: int):
    score += amount
    label.text = "Score: %d" % score
```

### Restart / Quit
```gdscript
func _unhandled_input(event):
    if event.is_action_pressed("ui_cancel"):
        get_tree().quit()
    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        get_tree().reload_current_scene()
```
