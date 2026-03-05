extends Control

## --- Tuning ---
@export var typing_speed: float = 0.02  ## seconds per character for typewriter effect
## --- End Tuning ---

# ─── Theme Colors ───
const BG_COLOR := Color("#1a1a2e")
const PANEL_COLOR := Color("#16213e")
const PANEL_LIGHT := Color("#1c2a4a")
const HEADER_COLOR := Color("#0f3460")
const ACCENT := Color("#4ecdc4")
const ACCENT_DIM := Color("#3ba89f")
const TEXT_COLOR := Color("#e8e8e8")
const TEXT_DIM := Color("#8899aa")
const TEXT_WARM := Color("#f0d9b5")
const GREEN := Color("#66bb6a")
const AMBER := Color("#ffb74d")
const RED := Color("#ef5350")
const GOLD := Color("#ffd54f")

# ─── NVC Word Banks ───
const FEELING_WORDS := [
	"frustrated", "annoyed", "hurt", "sad", "disappointed", "anxious",
	"overwhelmed", "upset", "worried", "lonely", "confused", "embarrassed",
	"exhausted", "uncomfortable", "uneasy", "concerned", "distressed",
	"happy", "grateful", "relieved", "hopeful", "excited", "calm",
	"comfortable", "pleased", "satisfied", "touched", "glad",
]

const NEED_WORDS := [
	"respect", "understanding", "connection", "cooperation", "consideration",
	"autonomy", "honesty", "trust", "fairness", "support", "appreciation",
	"space", "rest", "safety", "belonging", "acknowledgment", "reliability",
	"predictability", "clarity", "harmony", "peace", "care", "empathy",
	"recognition", "mutuality", "inclusion", "order", "competence",
]

const REQUEST_PATTERNS := [
	"would you be willing", "could you", "would you", "i'd like to ask",
	"would it work for you", "how would you feel about", "i would appreciate if",
	"i'd appreciate it if", "can we", "could we", "would it be possible",
	"i'd like to request", "i'm wondering if you'd",
]

const BLAME_PATTERNS := [
	"you always", "you never", "you should", "you make me", "you're being",
	"it's your fault", "why can't you", "why don't you", "you need to",
	"you have to", "you must", "you ought to",
]

const JUDGMENT_PATTERNS := [
	"you're so ", "you are so ", "that's so ", "you're a ", "you are a ",
	"how dare you", "what's wrong with you", "you're the worst",
	"you don't care", "you're selfish", "you're lazy", "you're rude",
	"you're inconsiderate", "you're irresponsible",
]

const OBSERVATION_PATTERNS := [
	"when i see", "when i hear", "when i notice", "i noticed that",
	"i observed", "when i saw", "i see that", "i hear that",
	"the last time", "this morning when", "yesterday when",
	"when you said", "when you did",
]

const FEELING_PATTERNS := [
	"i feel ", "i'm feeling ", "i felt ", "i've been feeling ",
	"it makes me feel ", "i am feeling ", "that leaves me feeling ",
]

const NEED_PATTERNS := [
	"i need ", "i value ", "because i need", "because i value",
	"what i need is", "it's important to me", "i have a need for",
	"because my need for",
]

# ─── Sentiment Lexicon (AFINN-style, -5 to +5) ───
# Focused on interpersonal/NVC-relevant language
var SENTIMENT_LEXICON := {
	# --- Strong Negative (-5 to -3) ---
	"hate": -4, "hatred": -4, "despise": -4, "loathe": -4, "detest": -4,
	"idiot": -5, "stupid": -4, "moron": -5, "pathetic": -4, "worthless": -4,
	"disgusting": -4, "repulsive": -3, "vile": -4, "toxic": -3, "abusive": -4,
	"destroy": -3, "ruined": -3, "horrible": -3, "terrible": -3, "awful": -3,
	"atrocious": -4, "worst": -3, "nightmare": -3, "hell": -3,
	"furious": -3, "enraged": -3, "livid": -3, "outraged": -3,
	"betray": -4, "betrayed": -4, "betrayal": -4, "revenge": -4,
	"threaten": -3, "threat": -3, "punish": -3, "punishment": -3,
	"manipulate": -3, "manipulative": -3, "exploit": -3,
	"cruel": -4, "malicious": -4, "vicious": -3, "hostile": -3,
	"scream": -3, "screaming": -3, "yell": -3, "yelling": -3,
	"shut up": -4, "get out": -3, "go away": -2,
	# --- Moderate Negative (-2 to -1) ---
	"angry": -2, "mad": -2, "frustrated": -2, "annoyed": -2, "irritated": -2,
	"upset": -2, "disappointed": -2, "hurt": -2, "sad": -2, "unhappy": -2,
	"worried": -2, "anxious": -2, "stressed": -2, "overwhelmed": -2,
	"confused": -1, "uncomfortable": -2, "uneasy": -1, "tense": -2,
	"lonely": -2, "isolated": -2, "exhausted": -2, "drained": -2, "tired": -1,
	"afraid": -2, "scared": -2, "fearful": -2, "nervous": -1,
	"resentful": -2, "bitter": -2, "jealous": -2, "envious": -2,
	"ashamed": -2, "guilty": -2, "embarrassed": -2, "humiliated": -3,
	"unfair": -2, "unjust": -2, "wrong": -1, "bad": -1, "worse": -2,
	"fault": -2, "blame": -2, "blamed": -2, "accuse": -2,
	"demand": -2, "insist": -1, "force": -2, "pressure": -2,
	"ignore": -2, "ignored": -2, "neglect": -2, "neglected": -2,
	"reject": -2, "rejected": -2, "abandon": -2, "abandoned": -2,
	"complain": -1, "complaint": -1, "problem": -1, "issue": -1,
	"disagree": -1, "conflict": -1, "argue": -2, "argument": -2,
	"rude": -2, "disrespectful": -2, "inconsiderate": -2, "selfish": -2,
	"lazy": -2, "careless": -2, "irresponsible": -2, "unreliable": -2,
	"annoying": -2, "obnoxious": -3, "insufferable": -3,
	"fail": -2, "failed": -2, "failure": -2, "mess": -1, "messy": -1,
	"pointless": -2, "useless": -2, "hopeless": -2, "helpless": -2,
	"never": -1, "can't": -1, "won't": -1, "don't": -1,
	"unfortunately": -1, "regret": -2, "sorry": -1, "apologies": -1,
	# --- Mild / Neutral-Leaning (-1 to 0) ---
	"fine": 0, "okay": 0, "whatever": -1, "guess": -1,
	"difficult": -1, "hard": -1, "tough": -1, "challenging": -1,
	"concern": -1, "concerned": -1, "bother": -1, "bothered": -1,
	# --- Mild Positive (1 to 2) ---
	"good": 1, "nice": 1, "well": 1, "better": 1, "improve": 1,
	"like": 1, "enjoy": 2, "pleasant": 2, "glad": 2, "pleased": 2,
	"comfortable": 1, "calm": 1, "relaxed": 2, "peaceful": 2,
	"patient": 2, "gentle": 2, "kind": 2, "warm": 1, "friendly": 2,
	"honest": 1, "sincere": 2, "genuine": 2, "authentic": 2,
	"fair": 1, "reasonable": 1, "open": 1, "willing": 2,
	"listen": 1, "hear": 1, "understand": 2, "understood": 2,
	"consider": 1, "thoughtful": 2, "mindful": 2, "aware": 1,
	"feel": 1, "feeling": 1, "feelings": 1,  # positive in NVC context
	"need": 1, "needs": 1,  # positive in NVC context
	"agree": 1, "accept": 1, "acknowledge": 2, "recognize": 1,
	"help": 1, "helpful": 2, "support": 2, "supportive": 2,
	"hope": 1, "hopeful": 2, "optimistic": 2, "possible": 1,
	"together": 2, "collaborate": 2, "cooperate": 2, "teamwork": 2,
	"resolve": 1, "solution": 1, "compromise": 1, "balance": 1,
	"safe": 1, "safety": 1, "secure": 1, "trust": 2, "trusting": 2,
	"respect": 2, "respectful": 2, "dignity": 2,
	"share": 1, "sharing": 1, "connect": 2, "connection": 2,
	# --- Strong Positive (3 to 5) ---
	"love": 3, "adore": 3, "cherish": 3, "treasure": 3,
	"grateful": 3, "thankful": 3, "appreciate": 3, "appreciation": 3,
	"wonderful": 3, "amazing": 3, "beautiful": 3, "excellent": 3,
	"compassion": 4, "compassionate": 4, "empathy": 4, "empathetic": 4,
	"forgive": 3, "forgiveness": 3, "mercy": 3, "grace": 3,
	"inspire": 3, "inspired": 3, "uplift": 3, "encourage": 3,
	"joyful": 3, "delighted": 3, "thrilled": 3, "overjoyed": 4,
	"harmony": 3, "unity": 3, "belonging": 3, "community": 2,
	"courage": 3, "courageous": 3, "brave": 3, "strength": 2,
	"growth": 2, "learn": 1, "learning": 1, "progress": 2,
	"heal": 3, "healing": 3, "nurture": 3, "nourish": 3,
}

# ─── Sentiment Modifiers ───
const NEGATION_WORDS := [
	"not", "no", "never", "neither", "nobody", "nothing", "nor",
	"hardly", "barely", "scarcely", "seldom", "without",
	"don't", "doesn't", "didn't", "won't", "wouldn't", "couldn't",
	"shouldn't", "can't", "cannot", "isn't", "aren't", "wasn't", "weren't",
]

const INTENSIFIERS := {
	"very": 1.5, "really": 1.5, "extremely": 2.0, "incredibly": 2.0,
	"so": 1.4, "absolutely": 2.0, "completely": 1.8, "totally": 1.8,
	"deeply": 1.6, "truly": 1.5, "terribly": 1.8, "awfully": 1.8,
	"immensely": 2.0, "profoundly": 2.0, "utterly": 2.0,
}

const DIMINISHERS := {
	"slightly": 0.5, "somewhat": 0.6, "a bit": 0.5, "a little": 0.5,
	"kind of": 0.6, "sort of": 0.6, "rather": 0.7, "fairly": 0.7,
	"marginally": 0.4, "partly": 0.6,
}

# ─── Communication Style Patterns ───
const EMPATHY_PATTERNS := [
	"i understand", "i hear you", "i can see how", "i can imagine",
	"that must be", "that sounds", "i appreciate", "i respect",
	"thank you for", "i'm grateful", "i care about", "i value our",
	"i want to understand", "help me understand", "tell me more",
	"how are you feeling", "what do you need", "what matters to you",
	"i acknowledge", "you matter", "your feelings matter",
	"i want us to", "let's work on this together", "we can figure this out",
]

const AGGRESSION_PATTERNS := [
	"or else", "you better", "you'd better", "i'm warning you",
	"i don't care what you", "deal with it", "too bad",
	"get over it", "grow up", "stop being", "knock it off",
	"i'm done with", "i'm sick of", "i've had enough",
	"that's your problem", "not my problem", "figure it out yourself",
]

const PASSIVE_AGGRESSIVE_PATTERNS := [
	"fine, whatever", "if that's what you want", "do whatever you want",
	"i guess that's fine", "sure, go ahead", "oh, that's nice",
	"no, it's fine", "don't worry about it", "it doesn't matter",
	"i'm not mad", "i'm not upset", "forget it", "never mind",
	"must be nice", "thanks a lot", "oh great", "how wonderful",
	"i just think it's funny how", "i mean, if you don't care",
	"but hey, what do i know", "clearly i'm the problem",
]

const DEFENSIVENESS_PATTERNS := [
	"it's not my fault", "don't blame me", "i didn't do anything",
	"what about you", "well you", "yeah but you", "at least i",
	"i was only", "i was just", "it's not like i", "i can't help it",
	"that's not what i meant", "you're overreacting", "you're too sensitive",
	"calm down", "relax", "you're making a big deal",
]


# ─── Scenarios ───
var scenarios := [
	{
		"title": "The Unwashed Dishes",
		"difficulty": "Guided",
		"situation": "You come home after a long day to find your roommate has left a pile of dirty dishes in the sink — for the third day in a row. The kitchen smells, and you can't prepare your dinner.",
		"context": "Your roommate is generally considerate, but has been stressed with a work deadline.",
		"hint": "[color=#4ecdc4]NVC Tip:[/color] Try using this structure:\n• [color=#ffb74d]Observation:[/color] \"When I see [specific behavior]...\"\n• [color=#ffb74d]Feeling:[/color] \"I feel [emotion]...\"\n• [color=#ffb74d]Need:[/color] \"...because I need [value]...\"\n• [color=#ffb74d]Request:[/color] \"Would you be willing to [specific action]?\"",
		"example": "When I see dishes in the sink for three days, I feel frustrated because I need a clean space to prepare meals. Would you be willing to wash your dishes by the end of each day?",
	},
	{
		"title": "Credit Where It's Due",
		"difficulty": "Guided",
		"situation": "During a team meeting, your coworker presented your idea for the new project approach as their own. Your manager praised them for the 'innovative thinking.' You worked on this idea for weeks.",
		"context": "This coworker is someone you generally get along with. You'll need to continue working together.",
		"hint": "[color=#4ecdc4]NVC Tip:[/color] Stay with observations, not stories about intent.\n• What exactly happened? (not \"they stole my idea\")\n• How do you feel? (not \"they're dishonest\")\n• What do you need? (recognition? fairness?)\n• What specific action would help?",
		"example": "When I heard my project approach presented without mention of my contribution, I felt hurt and disappointed because I value recognition for my work. Could we talk about how to credit ideas going forward?",
	},
	{
		"title": "The Forgotten Anniversary",
		"difficulty": "Intermediate",
		"situation": "Your partner completely forgot your anniversary. No card, no mention of it, nothing. When you brought it up, they said, \"Oh, I've been so busy with work. It's just a date.\"",
		"context": "You've been together for several years. They've remembered in previous years.",
		"hint": "",
		"example": "",
	},
	{
		"title": "Cancelled Again",
		"difficulty": "Intermediate",
		"situation": "Your close friend has cancelled plans with you for the third time in two months — each time with a last-minute text. This time, you had already driven to the restaurant and were waiting.",
		"context": "This friendship matters to you, and your friend has been going through some personal changes.",
		"hint": "",
		"example": "",
	},
	{
		"title": "The Late-Night Neighbor",
		"difficulty": "Intermediate",
		"situation": "Your neighbor has been playing loud bass-heavy music past midnight on weeknights. You have to wake up at 6 AM for work, and you've been losing sleep for two weeks. You see them in the hallway.",
		"context": "You've never spoken to this neighbor before. They moved in recently.",
		"hint": "",
		"example": "",
	},
	{
		"title": "The Broken Promise",
		"difficulty": "Advanced",
		"situation": "Your teenage child promised to clean their room before having friends over. You come home to find their friends there, the room untouched, and food wrappers on the floor. They say, \"I was going to do it later, relax.\"",
		"context": "You want to maintain a trusting relationship with your teen while also upholding household agreements.",
		"hint": "",
		"example": "",
	},
	{
		"title": "The Missed Deadline",
		"difficulty": "Advanced",
		"situation": "A team member missed a critical deadline on a component you needed to complete your part of a client project. The client is now unhappy, and your manager has asked you what happened. The team member says they \"didn't realize it was urgent.\"",
		"context": "You sent two reminder emails. The team dynamic matters for future projects.",
		"hint": "",
		"example": "",
	},
	{
		"title": "The Line Cutter",
		"difficulty": "Advanced",
		"situation": "You've been waiting in a long checkout line for 20 minutes. Someone walks up and steps directly in front of you, pretending they don't see the line. Others behind you are looking at you expectantly.",
		"context": "This is a stranger. There's social pressure. You want to be both honest and respectful.",
		"hint": "",
		"example": "",
	},
]

# ─── State ───
var current_scenario: int = 0
var has_submitted: bool = false
var score_history: Array = []  # array of {obs, feel, need, req, blame} per scenario

# ─── UI Nodes ───
var header_label: Label
var progress_label: Label
var difficulty_label: Label
var scenario_title: RichTextLabel
var scenario_text: RichTextLabel
var hint_panel: PanelContainer
var hint_text: RichTextLabel
var feedback_scroll: ScrollContainer
var feedback_text: RichTextLabel
var input_label: Label
var input_field: TextEdit
var submit_btn: Button
var next_btn: Button
var example_btn: Button
var score_display: Label


func _ready():
	_build_ui()
	_show_scenario()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		current_scenario = 0
		has_submitted = false
		score_history.clear()
		_show_scenario()
	# Ctrl+Enter to submit
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if event.ctrl_pressed and not has_submitted:
			_on_submit()


# ─── UI Construction ───

func _build_ui():
	# Root setup
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Main layout
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# ── Header Row ──
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 15)
	vbox.add_child(header_row)

	header_label = Label.new()
	header_label.text = "NVC Practice"
	header_label.add_theme_font_size_override("font_size", 28)
	header_label.add_theme_color_override("font_color", ACCENT)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)

	difficulty_label = Label.new()
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", TEXT_DIM)
	header_row.add_child(difficulty_label)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_color_override("font_color", TEXT_DIM)
	header_row.add_child(progress_label)

	score_display = Label.new()
	score_display.add_theme_font_size_override("font_size", 18)
	score_display.add_theme_color_override("font_color", GOLD)
	header_row.add_child(score_display)

	# ── Separator ──
	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("separator_color", ACCENT_DIM)
	vbox.add_child(sep1)

	# ── Scenario Panel ──
	var scenario_panel := _make_panel(PANEL_COLOR)
	scenario_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scenario_panel.custom_minimum_size.y = 120
	vbox.add_child(scenario_panel)

	var scenario_vbox := VBoxContainer.new()
	scenario_vbox.add_theme_constant_override("separation", 8)
	scenario_panel.add_child(scenario_vbox)

	scenario_title = RichTextLabel.new()
	scenario_title.bbcode_enabled = true
	scenario_title.fit_content = true
	scenario_title.scroll_active = false
	scenario_title.add_theme_font_size_override("normal_font_size", 20)
	scenario_title.add_theme_color_override("default_color", TEXT_WARM)
	scenario_vbox.add_child(scenario_title)

	scenario_text = RichTextLabel.new()
	scenario_text.bbcode_enabled = true
	scenario_text.fit_content = true
	scenario_text.scroll_active = false
	scenario_text.add_theme_font_size_override("normal_font_size", 17)
	scenario_text.add_theme_color_override("default_color", TEXT_COLOR)
	scenario_vbox.add_child(scenario_text)

	# ── Hint Panel (shown for guided scenarios) ──
	hint_panel = _make_panel(PANEL_LIGHT)
	hint_panel.custom_minimum_size.y = 0
	vbox.add_child(hint_panel)

	hint_text = RichTextLabel.new()
	hint_text.bbcode_enabled = true
	hint_text.fit_content = true
	hint_text.scroll_active = false
	hint_text.add_theme_font_size_override("normal_font_size", 15)
	hint_text.add_theme_color_override("default_color", TEXT_DIM)
	hint_panel.add_child(hint_text)

	# ── Feedback Area ──
	feedback_scroll = ScrollContainer.new()
	feedback_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feedback_scroll.custom_minimum_size.y = 100
	feedback_scroll.visible = false
	vbox.add_child(feedback_scroll)

	var feedback_panel := _make_panel(PANEL_LIGHT)
	feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feedback_scroll.add_child(feedback_panel)

	feedback_text = RichTextLabel.new()
	feedback_text.bbcode_enabled = true
	feedback_text.fit_content = true
	feedback_text.scroll_active = false
	feedback_text.add_theme_font_size_override("normal_font_size", 16)
	feedback_text.add_theme_color_override("default_color", TEXT_COLOR)
	feedback_panel.add_child(feedback_text)

	# ── Separator ──
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator_color", Color(1, 1, 1, 0.1))
	vbox.add_child(sep2)

	# ── Input Area ──
	input_label = Label.new()
	input_label.text = "Your response:"
	input_label.add_theme_font_size_override("font_size", 16)
	input_label.add_theme_color_override("font_color", ACCENT)
	vbox.add_child(input_label)

	input_field = TextEdit.new()
	input_field.placeholder_text = "Type your NVC response here... (Ctrl+Enter to submit)"
	input_field.custom_minimum_size.y = 80
	input_field.size_flags_vertical = Control.SIZE_SHRINK_END
	input_field.add_theme_font_size_override("font_size", 16)
	input_field.add_theme_color_override("font_color", TEXT_COLOR)
	input_field.add_theme_color_override("background_color", PANEL_COLOR)
	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = PANEL_COLOR
	input_sb.border_color = ACCENT_DIM
	input_sb.set_border_width_all(2)
	input_sb.set_corner_radius_all(6)
	input_sb.set_content_margin_all(10)
	input_field.add_theme_stylebox_override("normal", input_sb)
	input_field.add_theme_stylebox_override("focus", input_sb)
	vbox.add_child(input_field)

	# ── Button Row ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	example_btn = _make_button("Show Example", HEADER_COLOR)
	example_btn.pressed.connect(_on_show_example)
	example_btn.visible = false
	btn_row.add_child(example_btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	submit_btn = _make_button("Submit Response", ACCENT_DIM)
	submit_btn.pressed.connect(_on_submit)
	btn_row.add_child(submit_btn)

	next_btn = _make_button("Next Scenario →", ACCENT_DIM)
	next_btn.pressed.connect(_on_next)
	next_btn.visible = false
	btn_row.add_child(next_btn)


func _make_panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(180, 40)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate()
	sb_pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	return btn


# ─── Game Logic ───

func _show_scenario():
	has_submitted = false
	var s: Dictionary = scenarios[current_scenario]

	progress_label.text = "Scenario %d / %d" % [current_scenario + 1, scenarios.size()]
	difficulty_label.text = "[%s]" % s["difficulty"]
	_update_score_display()

	scenario_title.text = "[b]%s[/b]" % s["title"]
	scenario_text.text = "%s\n\n[color=#8899aa][i]Context: %s[/i][/color]" % [s["situation"], s["context"]]

	if s["hint"] != "":
		hint_panel.visible = true
		hint_text.text = s["hint"]
	else:
		hint_panel.visible = false

	feedback_scroll.visible = false
	feedback_text.text = ""
	input_field.text = ""
	input_field.editable = true
	submit_btn.visible = true
	submit_btn.disabled = false
	next_btn.visible = false
	example_btn.visible = s["example"] != ""
	example_btn.disabled = false

	input_field.grab_focus()


func _on_submit():
	if input_field.text.strip_edges().length() < 10:
		feedback_scroll.visible = true
		feedback_text.text = "[color=#ef5350]Please write a longer response (at least a sentence or two).[/color]"
		return

	has_submitted = true
	input_field.editable = false
	submit_btn.visible = false
	next_btn.visible = true

	var result := _evaluate(input_field.text)
	score_history.append(result)
	_show_feedback(result)
	_update_score_display()

	if current_scenario < scenarios.size() - 1:
		next_btn.text = "Next Scenario →"
	else:
		next_btn.text = "View Final Summary"


func _on_next():
	current_scenario += 1
	if current_scenario >= scenarios.size():
		_show_summary()
	else:
		_show_scenario()


func _on_show_example():
	var s: Dictionary = scenarios[current_scenario]
	if s["example"] != "":
		hint_text.text += "\n\n[color=#66bb6a][b]Example response:[/b][/color]\n[i]\"%s\"[/i]" % s["example"]
		example_btn.disabled = true


# ─── NVC Evaluation Engine ───

func _evaluate(response: String) -> Dictionary:
	var lower := response.to_lower()
	var result := {
		"observation": false,
		"feeling": false,
		"need": false,
		"request": false,
		"blame_count": 0,
		"judgment_count": 0,
		"blame_examples": [],
		"observation_detail": "",
		"feeling_detail": "",
		"need_detail": "",
		"request_detail": "",
	}

	# Check for observation language
	for pat in OBSERVATION_PATTERNS:
		if lower.find(pat) != -1:
			result["observation"] = true
			result["observation_detail"] = pat
			break

	# Check for feeling language
	for pat in FEELING_PATTERNS:
		if lower.find(pat) != -1:
			result["feeling"] = true
			break
	if not result["feeling"]:
		for word in FEELING_WORDS:
			if _word_present(lower, word):
				result["feeling"] = true
				result["feeling_detail"] = word
				break

	# Check for need language
	for pat in NEED_PATTERNS:
		if lower.find(pat) != -1:
			result["need"] = true
			break
	if not result["need"]:
		for word in NEED_WORDS:
			if _word_present(lower, word):
				result["need"] = true
				result["need_detail"] = word
				break

	# Check for request language
	for pat in REQUEST_PATTERNS:
		if lower.find(pat) != -1:
			result["request"] = true
			result["request_detail"] = pat
			break

	# Check for blame patterns
	for pat in BLAME_PATTERNS:
		if lower.find(pat) != -1:
			result["blame_count"] += 1
			result["blame_examples"].append(pat)

	# Check for judgment patterns
	for pat in JUDGMENT_PATTERNS:
		if lower.find(pat) != -1:
			result["judgment_count"] += 1
			result["blame_examples"].append(pat)

	# Add sentiment analysis
	result["sentiment"] = _analyze_sentiment(response)

	return result


func _word_present(text: String, word: String) -> bool:
	# Check if word appears as a standalone word (not part of another word)
	var idx := text.find(word)
	if idx == -1:
		return false
	# Check boundaries
	if idx > 0 and text[idx - 1].is_valid_identifier():
		return false
	var end_idx := idx + word.length()
	if end_idx < text.length() and text[end_idx].is_valid_identifier():
		return false
	return true


# ─── Sentiment Analysis Engine ───

func _analyze_sentiment(response: String) -> Dictionary:
	var lower := response.to_lower()
	# Tokenize: split on whitespace and basic punctuation
	var raw_words := lower.split(" ", false)
	var words: Array[String] = []
	for w in raw_words:
		# Strip punctuation from edges but keep contractions
		var cleaned := w.strip_edges()
		while cleaned.length() > 0 and not cleaned[-1].is_valid_identifier() and cleaned[-1] != "'":
			cleaned = cleaned.left(cleaned.length() - 1)
		while cleaned.length() > 0 and not cleaned[0].is_valid_identifier():
			cleaned = cleaned.right(cleaned.length() - 1)
		if cleaned.length() > 0:
			words.append(cleaned)

	# Score each word with negation and intensifier handling
	var word_scores: Array[float] = []
	var negation_active := false
	var intensifier_mult := 1.0
	var positive_words_found: Array[String] = []
	var negative_words_found: Array[String] = []

	for i in words.size():
		var word: String = words[i]

		# Check negation
		if word in NEGATION_WORDS:
			negation_active = true
			continue

		# Check intensifiers
		if word in INTENSIFIERS:
			intensifier_mult = INTENSIFIERS[word]
			continue

		# Check diminishers
		if word in DIMINISHERS:
			intensifier_mult = DIMINISHERS[word]
			continue

		# Score the word
		if word in SENTIMENT_LEXICON:
			var base_score: float = SENTIMENT_LEXICON[word]
			var final_score: float = base_score * intensifier_mult
			if negation_active:
				final_score *= -0.75  # negation flips but slightly weaker
			word_scores.append(final_score)

			if final_score > 0.5:
				positive_words_found.append(word)
			elif final_score < -0.5:
				negative_words_found.append(word)

		# Reset modifiers after scoring a word
		negation_active = false
		intensifier_mult = 1.0

	# Compute aggregate scores
	var total_score := 0.0
	var abs_total := 0.0
	for s in word_scores:
		total_score += s
		abs_total += absf(s)

	var word_count := maxi(words.size(), 1)
	var scored_count := maxi(word_scores.size(), 1)

	# Normalized sentiment: -1.0 (very negative) to +1.0 (very positive)
	var normalized: float = clampf(total_score / (scored_count * 2.5), -1.0, 1.0)

	# Emotional intensity: 0.0 (flat) to 1.0 (very charged)
	var intensity: float = clampf(abs_total / (scored_count * 2.0), 0.0, 1.0)

	# Detect communication styles
	var style_empathetic := 0
	var style_aggressive := 0
	var style_passive_aggressive := 0
	var style_defensive := 0

	for pat in EMPATHY_PATTERNS:
		if lower.find(pat) != -1:
			style_empathetic += 1

	for pat in AGGRESSION_PATTERNS:
		if lower.find(pat) != -1:
			style_aggressive += 1

	for pat in PASSIVE_AGGRESSIVE_PATTERNS:
		if lower.find(pat) != -1:
			style_passive_aggressive += 1

	for pat in DEFENSIVENESS_PATTERNS:
		if lower.find(pat) != -1:
			style_defensive += 1

	# Check for ALL CAPS words (3+ chars, shouting)
	var caps_count := 0
	for w in raw_words:
		if w.length() >= 3 and w == w.to_upper() and w != w.to_lower():
			caps_count += 1

	# Check for excessive punctuation (!! or ??)
	var excl_count := response.count("!!")
	var quest_count := response.count("??")

	# Determine primary communication style
	var primary_style := "Neutral"
	var style_scores := {
		"Empathetic": style_empathetic * 3 + (1 if normalized > 0.2 else 0),
		"Assertive": (1 if normalized > -0.1 and normalized < 0.5 and intensity < 0.6 else 0) + (1 if style_aggressive == 0 and style_passive_aggressive == 0 else 0),
		"Aggressive": style_aggressive * 3 + caps_count * 2 + excl_count * 2 + (2 if normalized < -0.4 and intensity > 0.5 else 0),
		"Passive-Aggressive": style_passive_aggressive * 3 + (1 if style_defensive > 0 else 0),
		"Defensive": style_defensive * 3,
	}

	var max_style_score := 0
	for style_name in style_scores:
		if style_scores[style_name] > max_style_score:
			max_style_score = style_scores[style_name]
			primary_style = style_name

	if max_style_score <= 1:
		primary_style = "Neutral"

	# "I" vs "You" statement ratio
	var i_count := 0
	var you_count := 0
	for w in words:
		if w == "i" or w == "i'm" or w == "i've" or w == "i'd" or w == "my":
			i_count += 1
		elif w == "you" or w == "you're" or w == "you've" or w == "you'd" or w == "your":
			you_count += 1

	return {
		"sentiment_score": normalized,
		"intensity": intensity,
		"primary_style": primary_style,
		"positive_words": positive_words_found,
		"negative_words": negative_words_found,
		"i_statements": i_count,
		"you_statements": you_count,
		"empathy_count": style_empathetic,
		"aggression_count": style_aggressive,
		"passive_aggressive_count": style_passive_aggressive,
		"defensive_count": style_defensive,
		"caps_shouting": caps_count,
		"excessive_punctuation": excl_count + quest_count,
		"word_count": word_count,
	}


func _sentiment_label(score: float) -> String:
	if score > 0.4:
		return "Very Positive"
	elif score > 0.15:
		return "Positive"
	elif score > -0.15:
		return "Neutral"
	elif score > -0.4:
		return "Negative"
	else:
		return "Very Negative"


func _intensity_label(intensity: float) -> String:
	if intensity > 0.7:
		return "Very High"
	elif intensity > 0.45:
		return "High"
	elif intensity > 0.25:
		return "Moderate"
	else:
		return "Calm"


func _sentiment_bar(score: float) -> String:
	# Visual bar from -1 to +1
	var bar := ""
	var segments := 10
	var center := segments / 2
	var pos := int((score + 1.0) / 2.0 * segments)
	pos = clampi(pos, 0, segments)
	for i in range(segments + 1):
		if i == pos:
			bar += "◆"
		elif i == center:
			bar += "│"
		else:
			bar += "─"
	return "Negative " + bar + " Positive"


# ─── Feedback Display ───

func _show_feedback(r: Dictionary):
	feedback_scroll.visible = true

	var stars := 0
	var fb := ""

	# Overall tone
	var has_blame: bool = r["blame_count"] > 0 or r["judgment_count"] > 0
	if has_blame:
		fb += "[color=#ef5350]⚠ Blame/Judgment Detected[/color]\n"
		fb += "[color=#ef5350]Phrases like \"%s\" can make the other person defensive. " % r["blame_examples"][0]
		fb += "Try describing specific behaviors instead of generalizing.[/color]\n\n"
	else:
		fb += "[color=#66bb6a]✓ No blame or judgment language detected — great![/color]\n\n"
		stars += 1

	# Observation
	fb += "[b][color=#ffb74d]1. Observation[/color][/b] — "
	if r["observation"]:
		fb += "[color=#66bb6a]✓ Found![/color]\n"
		fb += "Good — you described what happened specifically rather than interpreting it.\n\n"
		stars += 1
	else:
		fb += "[color=#ef5350]Not clearly detected[/color]\n"
		fb += "Try starting with a concrete observation: [i]\"When I see/hear [specific thing]...\"[/i]\n"
		fb += "This separates facts from evaluations and makes your message easier to hear.\n\n"

	# Feeling
	fb += "[b][color=#ffb74d]2. Feeling[/color][/b] — "
	if r["feeling"]:
		fb += "[color=#66bb6a]✓ Found![/color]\n"
		fb += "You named your emotional experience, which builds connection and vulnerability.\n\n"
		stars += 1
	else:
		fb += "[color=#ef5350]Not clearly detected[/color]\n"
		fb += "Try naming how you feel: [i]\"I feel frustrated / hurt / disappointed / anxious...\"[/i]\n"
		fb += "Owning your feelings (\"I feel...\") is different from thoughts disguised as feelings (\"I feel that you...\").\n\n"

	# Need
	fb += "[b][color=#ffb74d]3. Need[/color][/b] — "
	if r["need"]:
		fb += "[color=#66bb6a]✓ Found![/color]\n"
		fb += "Connecting feelings to universal human needs helps the other person understand your motivation.\n\n"
		stars += 1
	else:
		fb += "[color=#ef5350]Not clearly detected[/color]\n"
		fb += "Try connecting to an underlying need: [i]\"...because I need/value respect / trust / cooperation / rest...\"[/i]\n"
		fb += "Needs are universal — naming them moves the conversation from blame to shared humanity.\n\n"

	# Request
	fb += "[b][color=#ffb74d]4. Request[/color][/b] — "
	if r["request"]:
		fb += "[color=#66bb6a]✓ Found![/color]\n"
		fb += "A clear, doable request gives the other person a way to respond constructively.\n\n"
		stars += 1
	else:
		fb += "[color=#ef5350]Not clearly detected[/color]\n"
		fb += "End with a specific, actionable request: [i]\"Would you be willing to...?\"[/i]\n"
		fb += "Requests (not demands) respect the other person's autonomy and invite collaboration.\n\n"

	# ── Sentiment & Tone Analysis ──
	var sent: Dictionary = r["sentiment"]
	fb += "[b][color=#4ecdc4]── Tone & Sentiment Analysis ──[/color][/b]\n\n"

	# Sentiment score with visual bar
	var sent_score: float = sent["sentiment_score"]
	var sent_label := _sentiment_label(sent_score)
	var sent_color := GREEN if sent_score > 0.15 else (AMBER if sent_score > -0.15 else RED)
	fb += "[color=#8899aa]%s[/color]\n" % _sentiment_bar(sent_score)
	fb += "Overall Tone: [color=#%s][b]%s[/b][/color]  " % [sent_color.to_html(false), sent_label]
	fb += "  |  Emotional Intensity: [b]%s[/b]\n\n" % _intensity_label(sent["intensity"])

	# Communication style
	var style: String = sent["primary_style"]
	var style_color := GREEN
	var style_icon := "💬"
	var style_tip := ""
	match style:
		"Empathetic":
			style_color = GREEN
			style_icon = "💚"
			style_tip = "Your response shows care for the other person's perspective — this is the heart of NVC."
		"Assertive":
			style_color = ACCENT
			style_icon = "✦"
			style_tip = "Clear and direct while remaining respectful — an ideal NVC communication style."
		"Aggressive":
			style_color = RED
			style_icon = "⚡"
			style_tip = "This tone may trigger defensiveness. Try softening with feelings and needs language."
		"Passive-Aggressive":
			style_color = AMBER
			style_icon = "🔶"
			style_tip = "Indirect negativity can erode trust. NVC encourages expressing feelings directly."
		"Defensive":
			style_color = AMBER
			style_icon = "🛡"
			style_tip = "Defensiveness often blocks connection. Try acknowledging the situation before explaining."
		"Neutral":
			style_color = TEXT_DIM
			style_icon = "○"
			style_tip = "A measured tone. Consider adding more feeling words to build emotional connection."

	fb += "%s Communication Style: [color=#%s][b]%s[/b][/color]\n" % [style_icon, style_color.to_html(false), style]
	fb += "[color=#8899aa]%s[/color]\n\n" % style_tip

	# I vs You statements
	var i_ct: int = sent["i_statements"]
	var you_ct: int = sent["you_statements"]
	if i_ct + you_ct > 0:
		fb += "\"I\" statements: [b]%d[/b]  |  \"You\" statements: [b]%d[/b]  — " % [i_ct, you_ct]
		if i_ct >= you_ct and i_ct > 0:
			fb += "[color=#66bb6a]Good balance! \"I\" language takes ownership of your experience.[/color]\n"
		elif you_ct > i_ct * 2:
			fb += "[color=#ffb74d]Heavy \"you\" focus. Try reframing with \"I feel...\" and \"I need...\" statements.[/color]\n"
		else:
			fb += "[color=#ffb74d]Consider shifting more toward \"I\" statements to own your feelings.[/color]\n"
		fb += "\n"

	# Detected tone words
	var pos_words: Array = sent["positive_words"]
	var neg_words: Array = sent["negative_words"]
	if pos_words.size() > 0:
		var unique_pos := []
		for w in pos_words:
			if w not in unique_pos and unique_pos.size() < 6:
				unique_pos.append(w)
		fb += "[color=#66bb6a]Positive language:[/color] %s\n" % ", ".join(unique_pos)
	if neg_words.size() > 0:
		var unique_neg := []
		for w in neg_words:
			if w not in unique_neg and unique_neg.size() < 6:
				unique_neg.append(w)
		fb += "[color=#ef5350]Charged language:[/color] %s\n" % ", ".join(unique_neg)
	if pos_words.size() > 0 or neg_words.size() > 0:
		fb += "\n"

	# Flags for shouting or excessive punctuation
	if sent["caps_shouting"] > 0:
		fb += "[color=#ef5350]⚠ ALL CAPS detected (%d words) — this reads as shouting. Lowercase conveys respect.[/color]\n" % sent["caps_shouting"]
	if sent["excessive_punctuation"] > 0:
		fb += "[color=#ffb74d]⚠ Excessive punctuation (!!/? ?) can convey aggression or sarcasm. Keep it simple.[/color]\n"
	if sent["caps_shouting"] > 0 or sent["excessive_punctuation"] > 0:
		fb += "\n"

	# Empathy bonus
	if sent["empathy_count"] > 0:
		fb += "[color=#66bb6a]✓ Empathy language detected — acknowledging the other person builds trust and safety.[/color]\n\n"

	fb += "[b][color=#4ecdc4]── NVC Score ──[/color][/b]\n\n"

	# Star rating (now includes sentiment bonus)
	# Bonus star for empathetic/assertive style with positive sentiment
	if style in ["Empathetic", "Assertive"] and sent_score > 0.0:
		stars += 1
	var max_possible := 6

	var star_str := ""
	for i in range(max_possible):
		if i < stars:
			star_str += "★ "
		else:
			star_str += "☆ "

	var rating_color := GREEN if stars >= 5 else (AMBER if stars >= 3 else RED)
	fb += "[b][color=#%s]Score: %s(%d/%d)[/color][/b]\n" % [rating_color.to_html(false), star_str, stars, max_possible]

	# Encouragement
	if stars >= 5:
		fb += "[color=#66bb6a]Excellent! Your response demonstrates strong NVC skills with empathetic tone.[/color]"
	elif stars >= 4:
		fb += "[color=#66bb6a]Great work! You're communicating with both structure and heart.[/color]"
	elif stars >= 3:
		fb += "[color=#ffb74d]Good effort! You're on the right track. Review the missing components above.[/color]"
	elif stars >= 1:
		fb += "[color=#ffb74d]A good start — keep practicing the NVC structure. It gets more natural over time.[/color]"
	else:
		fb += "[color=#ef5350]This is a learning process! Try restructuring your response using the four NVC steps.[/color]"

	feedback_text.text = fb


func _update_score_display():
	if score_history.is_empty():
		score_display.text = ""
		return
	var total_stars := 0
	var max_stars := score_history.size() * 6
	for r in score_history:
		if not (r["blame_count"] > 0 or r["judgment_count"] > 0):
			total_stars += 1
		if r["observation"]:
			total_stars += 1
		if r["feeling"]:
			total_stars += 1
		if r["need"]:
			total_stars += 1
		if r["request"]:
			total_stars += 1
		# Sentiment bonus star
		if r.has("sentiment"):
			var sent: Dictionary = r["sentiment"]
			var style: String = sent["primary_style"]
			if style in ["Empathetic", "Assertive"] and sent["sentiment_score"] > 0.0:
				total_stars += 1
	score_display.text = "Total: %d/%d ★" % [total_stars, max_stars]


# ─── Final Summary ───

func _show_summary():
	# Replace the whole UI with a summary screen
	var total := 0
	var component_totals := {"observation": 0, "feeling": 0, "need": 0, "request": 0, "no_blame": 0}

	for r in score_history:
		if not (r["blame_count"] > 0 or r["judgment_count"] > 0):
			component_totals["no_blame"] += 1
			total += 1
		for key in ["observation", "feeling", "need", "request"]:
			if r[key]:
				component_totals[key] += 1
				total += 1

	scenario_title.text = "[b]Practice Complete![/b]"
	hint_panel.visible = false
	input_field.visible = false
	input_label.visible = false
	submit_btn.visible = false
	next_btn.visible = false
	example_btn.visible = false

	var n: int = score_history.size()
	var max_stars := n * 6
	var pct: int = int(float(total) / float(max_stars) * 100.0) if max_stars > 0 else 0

	var summary := "[b]Your NVC Journey — %d Scenarios Completed[/b]\n\n" % n
	summary += "[color=#ffd54f]Overall Score: %d / %d  (%d%%)[/color]\n\n" % [total, max_stars, pct]

	summary += "[b]Component Breakdown:[/b]\n"
	summary += "  [color=#ffb74d]Observations:[/color]     %d / %d\n" % [component_totals["observation"], n]
	summary += "  [color=#ffb74d]Feelings:[/color]         %d / %d\n" % [component_totals["feeling"], n]
	summary += "  [color=#ffb74d]Needs:[/color]            %d / %d\n" % [component_totals["need"], n]
	summary += "  [color=#ffb74d]Requests:[/color]         %d / %d\n" % [component_totals["request"], n]
	summary += "  [color=#ffb74d]No Blame/Judgment:[/color] %d / %d\n" % [component_totals["no_blame"], n]

	# Sentiment summary across all scenarios
	var avg_sentiment := 0.0
	var style_counts := {}
	var total_empathy := 0
	for r in score_history:
		if r.has("sentiment"):
			var s: Dictionary = r["sentiment"]
			avg_sentiment += s["sentiment_score"]
			var st: String = s["primary_style"]
			style_counts[st] = style_counts.get(st, 0) + 1
			total_empathy += s["empathy_count"]
			# Bonus star
			if st in ["Empathetic", "Assertive"] and s["sentiment_score"] > 0.0:
				total += 1
	avg_sentiment /= maxf(n, 1)

	summary += "  [color=#ffb74d]Empathetic Tone:[/color]  %d / %d\n\n" % [style_counts.get("Empathetic", 0) + style_counts.get("Assertive", 0), n]

	summary += "[b]Tone Patterns:[/b]\n"
	summary += "  Average Sentiment: [b]%s[/b] (%.2f)\n" % [_sentiment_label(avg_sentiment), avg_sentiment]
	for st_name in style_counts:
		summary += "  %s: %d scenario(s)\n" % [st_name, style_counts[st_name]]
	summary += "\n"

	# Identify strengths and growth areas
	var best_score := 0
	var best_name := ""
	var worst_score := n
	var worst_name := ""
	var names := {"observation": "Observations", "feeling": "Feelings", "need": "Needs", "request": "Requests", "no_blame": "Non-judgmental language"}
	for key in component_totals:
		if component_totals[key] >= best_score:
			best_score = component_totals[key]
			best_name = names[key]
		if component_totals[key] <= worst_score:
			worst_score = component_totals[key]
			worst_name = names[key]

	summary += "[color=#66bb6a]★ Strength: %s[/color]\n" % best_name
	if worst_score < n:
		summary += "[color=#ffb74d]→ Growth area: %s[/color]\n\n" % worst_name

	if pct >= 80:
		summary += "[color=#66bb6a]Outstanding! You have a strong grasp of NVC principles.[/color]"
	elif pct >= 60:
		summary += "[color=#ffb74d]Great progress! Keep practicing, especially your growth areas.[/color]"
	else:
		summary += "[color=#ffb74d]NVC is a skill that deepens with practice. You've taken a wonderful first step.[/color]"

	summary += "\n\n[color=#8899aa]Press R to start over with new responses.[/color]"

	scenario_text.text = ""
	feedback_scroll.visible = true
	feedback_text.text = summary
	progress_label.text = "Complete!"
