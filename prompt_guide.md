# Prompt Guide: Describing Game Ideas for Rapid Prototyping

## The Golden Rule

Describe **what the player DOES**, not what the game looks like.

"The player is a square that jumps between platforms" → slow to prototype, focused on form.
"The player has a double-jump but the second jump goes in whatever direction they're holding" → fast, focused on the interesting mechanic.

---

## The Template

You don't need all of these, but hitting 3-4 of them gives Claude Code enough to build something playable:

```
Game idea: [one sentence — the elevator pitch]

Core mechanic: [what does the player DO on a moment-to-moment basis?]

Tension: [what makes it hard / interesting / forces decisions?]

Win/lose: [how does a round end?]

Reference: [optional — "like X but with Y", or "the movement from X meets the scoring of Y"]
```

### Example: Good Prompt

```
Game idea: A top-down game where you're a magnet trying to collect metal
objects, but collecting makes you bigger and slower.

Core mechanic: Move with WASD. Metal objects are attracted to you from a
short range — you don't pick them up, they drift toward you. The more you
collect, the larger your collision area grows and the slower you move.

Tension: Enemy "demagnetizers" patrol the arena. If they touch you, you
lose half your collected objects. You need to reach a score target before
time runs out.

Win/lose: Collect 50 objects to win. Timer is 60 seconds. Touching a
demagnetizer doesn't kill you but drops your count.
```

### Example: Too Vague

```
Make me a fun platformer.
```

This will produce something generic. Even adding one constraint makes it
dramatically better: "Make me a platformer where the floor is constantly
rising like lava, and you climb upward on procedurally spawning platforms."

---

## Power Moves (Things That Supercharge Prototypes)

### 1. Name the interesting constraint
The fun in most games comes from a limitation or tradeoff. Name it explicitly:
- "You can only shoot while standing still"
- "Jumping costs health"
- "You control two characters simultaneously with the same inputs"
- "Gravity flips every 5 seconds"

### 2. Ask for tuning knobs
Say: "Expose the key variables so I can tweak them while playtesting."
This gets you `@export` variables that show up in the Godot editor, so you
can adjust gravity, speed, spawn rates, etc. without touching code.

### 3. Request a difficulty ramp
Say: "Make it get harder over time." This forces a timer or wave system,
which instantly makes even a simple mechanic feel like a game.

### 4. Ask for juice
Say: "Add screen shake on hit, flash on collect, and a score popup."
Three lines of code each, but they make the prototype 10x more readable
when playtesting.

### 5. Describe what you want to LEARN
The whole point is testing whether an idea is fun. Tell Claude:
- "I want to find out if the magnetic attraction radius feels good"
- "I'm testing whether simultaneous control of two characters is fun or frustrating"
This helps Claude put the tuning knobs in the right places.

---

## Iteration Prompts (After First Playtest)

Once you've played the prototype, these are good follow-up prompts:

- "The player feels too floaty. Increase gravity by 50% and reduce jump height."
- "The enemies are too predictable. Make them occasionally speed up randomly."
- "This is fun but too easy. Add a second enemy type that moves faster but is smaller."
- "The core loop works. Now add a simple 3-level progression where each level
  adds one new element."
- "Scrap the enemy system, it's not fun. Replace it with a timer countdown
  and environmental hazards."
- "I like the movement but the scoring is boring. What if collecting objects
  filled a meter and you could 'spend' the meter on a dash ability?"

---

## Anti-Patterns (Things That Slow You Down)

| Don't say                           | Say instead                                              |
|-------------------------------------|----------------------------------------------------------|
| "Make it look like Celeste"         | "Tight platforming with a dash and coyote time"          |
| "Add beautiful particle effects"    | "Flash the screen white on big hits"                     |
| "Create a full menu system"         | "R to restart, Escape to quit" (already in the template) |
| "Use this sprite sheet I found"     | "Use colored rectangles" (always, for prototyping)       |
| "Make it multiplayer"               | "Two players on one keyboard (WASD + arrows)"            |
| "Implement save/load"               | Skip it — prototypes don't need persistence              |
