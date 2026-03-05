extends Control

## Script Memorizer — A tool for actors to practice memorizing lines.
##
## Parses any standard play script, lets you pick your character,
## and rehearse with cue-and-respond flow + first-letter encoding.

## --- Tuning ---
@export var base_font_size: int = 18
@export var cue_font_size: int = 16
@export var heading_font_size: int = 28
## --- End Tuning ---

# ─── Theme Colors ───
const BG := Color("#1a1a2e")
const PANEL := Color("#16213e")
const PANEL_ALT := Color("#1c2a4a")
const HEADER := Color("#0f3460")
const ACCENT := Color("#4ecdc4")
const ACCENT2 := Color("#45b7aa")
const TEXT := Color("#e8e8e8")
const TEXT_DIM := Color("#8899aa")
const TEXT_WARM := Color("#f0d9b5")
const CUE_BG := Color("#1e3a5f")
const CUE_TEXT := Color("#8cb4d5")
const LINE_BG := Color("#2a2a1e")
const LINE_HIGHLIGHT := Color("#4a4a2e")
const ENCODED_COLOR := Color("#ffd54f")
const DIRECTION_COLOR := Color("#7c8ea0")
const GREEN := Color("#66bb6a")
const AMBER := Color("#ffb74d")
const RED := Color("#ef5350")
const GOLD := Color("#ffd54f")

# ─── State ───
enum Screen { TITLE, CHARACTER_SELECT, REHEARSAL }
var current_screen: Screen = Screen.TITLE
var parsed_script: ScriptParser.ParsedScript = null
var selected_character: String = ""
var character_lines: Array = []  # filtered lines for selected character
var current_line_index: int = 0
var line_revealed: Array = []    # bool per line — is the actor's line revealed?
var line_confidence: Array = []  # 0-3 per actor line (unknown, shaky, good, solid)
var self_test_mode: bool = true  # hide actor lines until revealed
var show_encoded: bool = true    # show encoded vs full text for actor lines

# ─── UI Node References ───
var screen_container: Control
var title_screen: Control
var select_screen: Control
var rehearsal_screen: Control

# Title screen
var title_label: Label
var subtitle_label: Label
var load_default_btn: Button
var load_custom_btn: Button
var file_dialog: FileDialog

# Character select
var char_grid: GridContainer
var back_to_title_btn: Button
var script_info_label: Label

# Rehearsal
var char_name_label: Label
var progress_label: Label
var mode_label: Label
var lines_container: VBoxContainer
var lines_scroll: ScrollContainer
var prev_btn: Button
var next_btn: Button
var reveal_btn: Button
var toggle_encode_btn: Button
var toggle_mode_btn: Button
var back_to_chars_btn: Button
var scene_nav_btn: OptionButton
var confidence_btns: Array = []
var font_size_slider: HSlider


func _ready():
	_build_ui()
	_show_screen(Screen.TITLE)


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		match current_screen:
			Screen.REHEARSAL:
				_show_screen(Screen.CHARACTER_SELECT)
			Screen.CHARACTER_SELECT:
				_show_screen(Screen.TITLE)
			Screen.TITLE:
				get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if current_screen == Screen.TITLE:
			get_tree().reload_current_scene()

	# Rehearsal keyboard shortcuts
	if current_screen == Screen.REHEARSAL and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_DOWN, KEY_N:
				_on_next()
			KEY_LEFT, KEY_UP, KEY_P:
				_on_prev()
			KEY_SPACE, KEY_ENTER:
				_on_reveal()
			KEY_T:
				_on_toggle_encode()
			KEY_M:
				_on_toggle_mode()
			KEY_1:
				_set_confidence(0)
			KEY_2:
				_set_confidence(1)
			KEY_3:
				_set_confidence(2)
			KEY_4:
				_set_confidence(3)


# ═══════════════════════════════════════
# UI CONSTRUCTION
# ═══════════════════════════════════════

func _build_ui():
	set_anchors_preset(PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	screen_container = Control.new()
	screen_container.set_anchors_preset(PRESET_FULL_RECT)
	add_child(screen_container)

	_build_title_screen()
	_build_select_screen()
	_build_rehearsal_screen()


func _build_title_screen():
	title_screen = MarginContainer.new()
	title_screen.set_anchors_preset(PRESET_FULL_RECT)
	title_screen.add_theme_constant_override("margin_left", 100)
	title_screen.add_theme_constant_override("margin_right", 100)
	title_screen.add_theme_constant_override("margin_top", 80)
	title_screen.add_theme_constant_override("margin_bottom", 80)
	screen_container.add_child(title_screen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_screen.add_child(vbox)

	# Icon / Title
	title_label = Label.new()
	title_label.text = "🎭  Script Memorizer"
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", ACCENT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Load any play script and practice your lines"
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", TEXT_DIM)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 40
	vbox.add_child(spacer)

	# Buttons
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 15)
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)

	load_default_btn = _make_button("📖  Load Built-in: A Midsummer Night's Dream", ACCENT2, 400)
	load_default_btn.pressed.connect(_on_load_default)
	btn_box.add_child(load_default_btn)

	# Center the button
	load_default_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	load_custom_btn = _make_button("📂  Load Custom Script (.txt)", HEADER, 400)
	load_custom_btn.pressed.connect(_on_load_custom)
	btn_box.add_child(load_custom_btn)
	load_custom_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Help text
	var help := Label.new()
	help.text = "Scripts should have character names in ALL CAPS, dialogue below.\nStage directions in (parentheses). Esc to go back, R to restart."
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", TEXT_DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(help)

	# File dialog
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.txt ; Text Files"])
	file_dialog.size = Vector2i(800, 500)
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)


func _build_select_screen():
	select_screen = MarginContainer.new()
	select_screen.set_anchors_preset(PRESET_FULL_RECT)
	select_screen.add_theme_constant_override("margin_left", 40)
	select_screen.add_theme_constant_override("margin_right", 40)
	select_screen.add_theme_constant_override("margin_top", 20)
	select_screen.add_theme_constant_override("margin_bottom", 20)
	screen_container.add_child(select_screen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	select_screen.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	vbox.add_child(header)

	var sel_title := Label.new()
	sel_title.text = "🎭  Choose Your Character"
	sel_title.add_theme_font_size_override("font_size", 28)
	sel_title.add_theme_color_override("font_color", ACCENT)
	sel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sel_title)

	back_to_title_btn = _make_button("← Back", HEADER, 120)
	back_to_title_btn.pressed.connect(func(): _show_screen(Screen.TITLE))
	header.add_child(back_to_title_btn)

	# Script info
	script_info_label = Label.new()
	script_info_label.add_theme_font_size_override("font_size", 16)
	script_info_label.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(script_info_label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", ACCENT2)
	vbox.add_child(sep)

	# Character grid (in a scroll container)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	char_grid = GridContainer.new()
	char_grid.columns = 4
	char_grid.add_theme_constant_override("h_separation", 10)
	char_grid.add_theme_constant_override("v_separation", 10)
	char_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(char_grid)


func _build_rehearsal_screen():
	rehearsal_screen = MarginContainer.new()
	rehearsal_screen.set_anchors_preset(PRESET_FULL_RECT)
	rehearsal_screen.add_theme_constant_override("margin_left", 30)
	rehearsal_screen.add_theme_constant_override("margin_right", 30)
	rehearsal_screen.add_theme_constant_override("margin_top", 10)
	rehearsal_screen.add_theme_constant_override("margin_bottom", 10)
	screen_container.add_child(rehearsal_screen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	rehearsal_screen.add_child(vbox)

	# ── Top bar ──
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	vbox.add_child(top_bar)

	char_name_label = Label.new()
	char_name_label.add_theme_font_size_override("font_size", 24)
	char_name_label.add_theme_color_override("font_color", ACCENT)
	char_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(char_name_label)

	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.add_theme_color_override("font_color", AMBER)
	top_bar.add_child(mode_label)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", TEXT_DIM)
	top_bar.add_child(progress_label)

	back_to_chars_btn = _make_button("← Characters", HEADER, 140)
	back_to_chars_btn.pressed.connect(func(): _show_screen(Screen.CHARACTER_SELECT))
	top_bar.add_child(back_to_chars_btn)

	# ── Scene navigation + controls row ──
	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 8)
	vbox.add_child(ctrl_row)

	var scene_label := Label.new()
	scene_label.text = "Jump to:"
	scene_label.add_theme_font_size_override("font_size", 14)
	scene_label.add_theme_color_override("font_color", TEXT_DIM)
	ctrl_row.add_child(scene_label)

	scene_nav_btn = OptionButton.new()
	scene_nav_btn.add_theme_font_size_override("font_size", 14)
	scene_nav_btn.custom_minimum_size.x = 200
	scene_nav_btn.item_selected.connect(_on_scene_selected)
	ctrl_row.add_child(scene_nav_btn)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl_row.add_child(spacer2)

	toggle_mode_btn = _make_button("Mode: Self-Test", PANEL_ALT, 160)
	toggle_mode_btn.pressed.connect(_on_toggle_mode)
	ctrl_row.add_child(toggle_mode_btn)

	toggle_encode_btn = _make_button("Show: Encoded", PANEL_ALT, 160)
	toggle_encode_btn.pressed.connect(_on_toggle_encode)
	ctrl_row.add_child(toggle_encode_btn)

	# Font size
	var font_label := Label.new()
	font_label.text = "  Text:"
	font_label.add_theme_font_size_override("font_size", 14)
	font_label.add_theme_color_override("font_color", TEXT_DIM)
	ctrl_row.add_child(font_label)

	font_size_slider = HSlider.new()
	font_size_slider.min_value = 12
	font_size_slider.max_value = 32
	font_size_slider.value = base_font_size
	font_size_slider.custom_minimum_size.x = 80
	font_size_slider.value_changed.connect(func(v: float): base_font_size = int(v); _render_lines())
	ctrl_row.add_child(font_size_slider)

	# ── Separator ──
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(1, 1, 1, 0.1))
	vbox.add_child(sep)

	# ── Lines display ──
	lines_scroll = ScrollContainer.new()
	lines_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lines_scroll)

	lines_container = VBoxContainer.new()
	lines_container.add_theme_constant_override("separation", 4)
	lines_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_scroll.add_child(lines_container)

	# ── Bottom bar ──
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator_color", Color(1, 1, 1, 0.1))
	vbox.add_child(sep2)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom)

	prev_btn = _make_button("← Prev (←)", HEADER, 140)
	prev_btn.pressed.connect(_on_prev)
	bottom.add_child(prev_btn)

	reveal_btn = _make_button("Reveal (Space)", ACCENT2, 160)
	reveal_btn.pressed.connect(_on_reveal)
	bottom.add_child(reveal_btn)

	next_btn = _make_button("Next → (→)", HEADER, 140)
	next_btn.pressed.connect(_on_next)
	bottom.add_child(next_btn)

	# Spacer
	var spacer3 := Control.new()
	spacer3.custom_minimum_size.x = 30
	bottom.add_child(spacer3)

	# Confidence buttons
	var conf_label := Label.new()
	conf_label.text = "Confidence:"
	conf_label.add_theme_font_size_override("font_size", 14)
	conf_label.add_theme_color_override("font_color", TEXT_DIM)
	bottom.add_child(conf_label)

	var conf_names := ["? (1)", "Shaky (2)", "Good (3)", "Solid (4)"]
	var conf_colors := [TEXT_DIM, RED, AMBER, GREEN]
	for i in 4:
		var btn := _make_button(conf_names[i], PANEL_ALT, 90)
		btn.add_theme_color_override("font_color", conf_colors[i])
		btn.pressed.connect(_set_confidence.bind(i))
		bottom.add_child(btn)
		confidence_btns.append(btn)


# ═══════════════════════════════════════
# SCREEN MANAGEMENT
# ═══════════════════════════════════════

func _show_screen(screen: Screen):
	current_screen = screen
	title_screen.visible = screen == Screen.TITLE
	select_screen.visible = screen == Screen.CHARACTER_SELECT
	rehearsal_screen.visible = screen == Screen.REHEARSAL

	if screen == Screen.CHARACTER_SELECT and parsed_script:
		_populate_character_grid()
	elif screen == Screen.REHEARSAL:
		_start_rehearsal()


# ═══════════════════════════════════════
# TITLE SCREEN ACTIONS
# ═══════════════════════════════════════

func _on_load_default():
	var file := FileAccess.open("res://default_script.txt", FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		_load_script(content, "A Midsummer Night's Dream")
	else:
		subtitle_label.text = "Error: Could not load built-in script"


func _on_load_custom():
	file_dialog.popup_centered()


func _on_file_selected(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var fname := path.get_file().get_basename()
		_load_script(content, fname)
	else:
		subtitle_label.text = "Error: Could not open file"


func _load_script(content: String, name: String):
	parsed_script = ScriptParser.parse(content)
	parsed_script.title = name
	_show_screen(Screen.CHARACTER_SELECT)


# ═══════════════════════════════════════
# CHARACTER SELECT
# ═══════════════════════════════════════

func _populate_character_grid():
	# Clear existing buttons
	for child in char_grid.get_children():
		child.queue_free()

	script_info_label.text = "%s — %d characters, %d total lines" % [
		parsed_script.title, parsed_script.character_names.size(),
		parsed_script.character_lines.size()]

	for char_name in parsed_script.character_names:
		var line_count: int = parsed_script.get_line_count_for(char_name)
		var btn := _make_button("%s\n(%d lines)" % [char_name, line_count], PANEL_ALT, 280)
		btn.custom_minimum_size.y = 70
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_select_character.bind(char_name))
		char_grid.add_child(btn)


func _select_character(char_name: String):
	selected_character = char_name
	character_lines = parsed_script.get_lines_for_character(char_name)
	current_line_index = 0

	# Initialize tracking arrays (only for actor lines, not cues)
	line_revealed = []
	line_confidence = []
	for entry in character_lines:
		if entry["type"] == "line":
			line_revealed.append(false)
			line_confidence.append(0)

	_show_screen(Screen.REHEARSAL)


# ═══════════════════════════════════════
# REHEARSAL
# ═══════════════════════════════════════

func _start_rehearsal():
	char_name_label.text = "🎭 %s" % selected_character
	_update_mode_labels()

	# Populate scene navigation
	scene_nav_btn.clear()
	scene_nav_btn.add_item("(All)")
	for as_entry in parsed_script.acts_scenes:
		scene_nav_btn.add_item(as_entry["label"])

	_render_lines()


func _update_mode_labels():
	mode_label.text = "Self-Test" if self_test_mode else "Read-Through"
	toggle_mode_btn.text = "Mode: %s" % ("Self-Test" if self_test_mode else "Read")
	toggle_encode_btn.text = "Show: %s" % ("Encoded" if show_encoded else "Full Text")
	reveal_btn.disabled = not self_test_mode

	# Progress: count actor lines that are revealed
	var actor_idx := 0
	var revealed_count := 0
	var total_actor := 0
	for entry in character_lines:
		if entry["type"] == "line":
			total_actor += 1
			if actor_idx < line_revealed.size() and line_revealed[actor_idx]:
				revealed_count += 1
			actor_idx += 1

	progress_label.text = "%d / %d lines" % [revealed_count, total_actor]


func _get_current_actor_index() -> int:
	## Maps current_line_index to the actor line index (skipping cues)
	var actor_idx := 0
	for i in range(mini(current_line_index + 1, character_lines.size())):
		if character_lines[i]["type"] == "line":
			if i < current_line_index:
				actor_idx += 1
	return actor_idx


func _render_lines():
	# Clear
	for child in lines_container.get_children():
		child.queue_free()

	var actor_idx := 0
	for i in character_lines.size():
		var entry: Dictionary = character_lines[i]
		var cl: ScriptParser.CharacterLine = entry["line"]
		var is_current := (i == current_line_index)

		if entry["type"] == "cue":
			_add_cue_line(cl, is_current)
		else:
			_add_actor_line(cl, actor_idx, is_current)
			actor_idx += 1

	_update_mode_labels()
	# Scroll to current line (delayed to let layout settle)
	_scroll_to_current.call_deferred()


func _scroll_to_current():
	var idx := 0
	for child in lines_container.get_children():
		if idx == current_line_index or idx == current_line_index - 1:
			# Scroll so this child is visible
			var y_pos: float = child.position.y - 50
			lines_scroll.scroll_vertical = int(maxf(0, y_pos))
			return
		idx += 1


func _add_cue_line(cl: ScriptParser.CharacterLine, is_current: bool):
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CUE_BG if is_current else CUE_BG.darkened(0.3)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	sb.border_color = ACCENT if is_current else Color.TRANSPARENT
	sb.set_border_width_all(2 if is_current else 0)
	panel.add_theme_stylebox_override("panel", sb)
	lines_container.add_child(panel)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", cue_font_size)
	rtl.add_theme_color_override("default_color", CUE_TEXT)

	var char_label := cl.character
	if cl.is_direction:
		rtl.text = "[i][color=#7c8ea0]%s[/color][/i]" % cl.lines
	else:
		rtl.text = "[b][color=#6a9fc5]%s:[/color][/b] %s" % [char_label, cl.lines]
	panel.add_child(rtl)


func _add_actor_line(cl: ScriptParser.CharacterLine, actor_idx: int, is_current: bool):
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()

	# Color based on confidence
	var conf: int = line_confidence[actor_idx] if actor_idx < line_confidence.size() else 0
	var conf_colors := [LINE_BG, Color("#2e1a1a"), Color("#2a2a1e"), Color("#1a2e1a")]
	sb.bg_color = conf_colors[conf] if is_current else conf_colors[conf].darkened(0.2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	sb.border_color = GOLD if is_current else Color.TRANSPARENT
	sb.set_border_width_all(3 if is_current else 0)
	panel.add_theme_stylebox_override("panel", sb)
	lines_container.add_child(panel)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", base_font_size)

	var is_hidden: bool = self_test_mode and actor_idx < line_revealed.size() and not line_revealed[actor_idx]

	if is_hidden:
		rtl.add_theme_color_override("default_color", TEXT_DIM)
		rtl.text = "[b]%s:[/b] [i](tap Space or click to reveal your line)[/i]" % cl.character
	elif show_encoded:
		rtl.add_theme_color_override("default_color", ENCODED_COLOR)
		rtl.text = "[b]%s:[/b] %s" % [cl.character, cl.encoded]
	else:
		rtl.add_theme_color_override("default_color", TEXT)
		rtl.text = "[b]%s:[/b] %s" % [cl.character, cl.lines]

	panel.add_child(rtl)

	# Click to toggle individual line reveal
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if actor_idx < line_revealed.size():
				line_revealed[actor_idx] = not line_revealed[actor_idx]
				_render_lines()
	)


# ─── Navigation ───

func _on_next():
	if current_line_index < character_lines.size() - 1:
		current_line_index += 1
		# Skip cue lines — advance to next actor line
		while current_line_index < character_lines.size() - 1 and character_lines[current_line_index]["type"] == "cue":
			current_line_index += 1
		_render_lines()


func _on_prev():
	if current_line_index > 0:
		current_line_index -= 1
		# Skip cue lines going backward
		while current_line_index > 0 and character_lines[current_line_index]["type"] == "cue":
			current_line_index -= 1
		_render_lines()


func _on_reveal():
	if not self_test_mode:
		return
	# Find actor index for current line
	var actor_idx := 0
	for i in range(current_line_index + 1):
		if i < character_lines.size() and character_lines[i]["type"] == "line":
			if i == current_line_index:
				break
			actor_idx += 1

	if actor_idx < line_revealed.size():
		line_revealed[actor_idx] = true
		_render_lines()


func _on_toggle_encode():
	show_encoded = not show_encoded
	_render_lines()


func _on_toggle_mode():
	self_test_mode = not self_test_mode
	if not self_test_mode:
		# Reveal all lines in read-through mode
		for i in line_revealed.size():
			line_revealed[i] = true
	else:
		# Reset reveals
		for i in line_revealed.size():
			line_revealed[i] = false
	_render_lines()


func _set_confidence(level: int):
	var actor_idx := 0
	for i in range(current_line_index + 1):
		if i < character_lines.size() and character_lines[i]["type"] == "line":
			if i == current_line_index:
				break
			actor_idx += 1
	if actor_idx < line_confidence.size():
		line_confidence[actor_idx] = level
		_render_lines()


func _on_scene_selected(idx: int):
	if idx == 0:
		current_line_index = 0
		_render_lines()
		return

	# Find the first character line after this scene marker
	var scene_entry: Dictionary = parsed_script.acts_scenes[idx - 1]
	var target_global_idx: int = scene_entry["line_index"]

	# Map global index to our filtered character_lines index
	var global_idx := 0
	for i in character_lines.size():
		var cl: ScriptParser.CharacterLine = character_lines[i]["line"]
		# Find this entry in the global list
		for gi in range(global_idx, parsed_script.character_lines.size()):
			if parsed_script.character_lines[gi] == cl:
				global_idx = gi
				break
		if global_idx >= target_global_idx:
			current_line_index = i
			_render_lines()
			return
	# Fallback
	current_line_index = 0
	_render_lines()


# ═══════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════

func _make_button(text: String, color: Color, min_width: int = 180) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	btn.custom_minimum_size = Vector2(min_width, 36)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate()
	sb_h.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sb_h)
	var sb_p := sb.duplicate()
	sb_p.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	return btn
