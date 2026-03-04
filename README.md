# Godot Rapid Prototype Kit

Turn game ideas into playable prototypes in minutes using Claude Code + Godot.

## Setup (One-Time)

### 1. Prerequisites

- **Godot 4.3+** — Download from https://godotengine.org/download
  - Make sure `godot` is on your PATH (or alias it)
  - Test: `godot --version` should print the version number
- **Claude Code** — Install with `npm install -g @anthropic-ai/claude-code`
  - Test: `claude` should start a session

### 2. Clone / Copy This Kit

```bash
# Copy this folder to wherever you keep projects
cp -r godot-prototype-kit ~/projects/godot-prototype-kit
cd ~/projects/godot-prototype-kit
```

### 3. First Run — Validate Godot Can See the Project

```bash
# This should open and immediately close the editor, importing the project
godot --headless --editor --quit
```

If this works without errors, you're ready.

## Workflow

### The Rapid Prototype Loop

```
 ┌──────────────────────────────────────────────┐
 │  1. Describe game idea to Claude Code        │
 │     (see prompt_guide.md for tips)           │
 ├──────────────────────────────────────────────┤
 │  2. Claude writes .tscn + .gd files          │
 │     and validates with godot --headless       │
 ├──────────────────────────────────────────────┤
 │  3. You playtest:  godot --path . [scene]     │
 │     or just open Godot and hit Play           │
 ├──────────────────────────────────────────────┤
 │  4. Tell Claude what felt good / bad          │
 │     "movement is too floaty"                  │
 │     "the scoring isn't satisfying"            │
 │     "the enemy AI is too predictable"         │
 ├──────────────────────────────────────────────┤
 │  5. Claude iterates → go to step 3           │
 └──────────────────────────────────────────────┘
```

### Starting a Session

```bash
cd ~/projects/godot-prototype-kit
claude

# Then in the Claude Code session:
> Make a prototype: [describe your game idea here]
```

Claude Code will read the CLAUDE.md file automatically and know the conventions.

### Playing a Prototype

```bash
# Run the current main scene
godot --path .

# Or run a specific prototype scene directly
godot --path . prototypes/my_game/main.tscn
```

### Switching Between Prototypes

Tell Claude Code:
> Switch the main scene to the gravity_flip prototype

It will update `project.godot` to point to that prototype's `main.tscn`.

## File Structure

```
godot-prototype-kit/
├── CLAUDE.md              ← Instructions Claude Code reads automatically
├── README.md              ← You are here
├── project.godot          ← Godot project config
├── prompt_guide.md        ← How to describe game ideas effectively
├── shared/                ← Reusable code for all prototypes
│   ├── colors.gd          ← ProtoColors.PLAYER, .ENEMY, .GOAL, etc.
│   ├── debug_overlay.gd   ← FPS counter + custom debug values
│   └── proto_utils.gd     ← Screen shake, popup text, flash, etc.
└── prototypes/            ← Each prototype in its own folder
    ├── idea_one/
    │   ├── main.tscn
    │   └── main.gd
    └── idea_two/
        └── ...
```

## Tips

- **Don't delete prototypes** — keep them around to revisit. They're small.
- **Name prototypes by the mechanic**, not the theme:
  `magnet_collect`, `gravity_flip`, `dual_control` — not `cool_game_3`
- **Playtest for 30 seconds, then iterate.** You'll know within half a minute
  whether the core mechanic has potential.
- **When something feels fun, say so.** Tell Claude what worked so it preserves
  that quality in the next iteration.
- **Export variables are your best friend.** After generating a prototype,
  open Godot and tweak `@export` values in the Inspector while the game runs.
