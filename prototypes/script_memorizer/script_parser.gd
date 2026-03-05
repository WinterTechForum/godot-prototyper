class_name ScriptParser
## Parses a standard play/screenplay text file into structured data.
##
## Expected format:
##   - Character names: ALL CAPS on their own line (e.g., "THESEUS")
##   - Dialogue: lines following a character name
##   - Stage directions: lines in parentheses, typically indented
##   - Act/Scene headings: lines starting with "Act" or "Scene"
##
## Also encodes lines for memorization (first-letter abbreviation).

# ─── Data Structures ───

class CharacterLine:
	var character: String  ## "DIRECTION" for stage directions, character name otherwise
	var lines: String      ## Full dialogue text
	var encoded: String    ## First-letter encoded version
	var is_direction: bool ## True if this is a stage direction

	func _init(char_name: String, text: String, direction: bool = false):
		character = char_name
		lines = text
		is_direction = direction
		encoded = ScriptParser.encode_for_memorization(text) if not direction else text


class ParsedScript:
	var title: String = "Untitled Script"
	var character_lines: Array = []  ## Array of CharacterLine
	var character_names: Array = []  ## Sorted unique character names (excluding DIRECTION)
	var acts_scenes: Array = []      ## Array of {label, line_index} for navigation

	func get_lines_for_character(char_name: String) -> Array:
		## Returns character's lines with their preceding cue lines
		var result: Array = []
		for i in character_lines.size():
			var cl: CharacterLine = character_lines[i]
			if cl.character == char_name:
				# Include preceding cue line if from a different character
				if i > 0:
					var prev: CharacterLine = character_lines[i - 1]
					if prev.character != char_name:
						result.append({"type": "cue", "line": prev})
				result.append({"type": "line", "line": cl})
		return result

	func get_line_count_for(char_name: String) -> int:
		var count := 0
		for cl in character_lines:
			if cl.character == char_name:
				count += 1
		return count


# ─── Typographic Replacements ───

const REPLACEMENTS := {
	"\u2018": "'", "\u2019": "'",   # Smart single quotes
	"\u201c": "\"", "\u201d": "\"", # Smart double quotes
	"\u2014": "--",                   # Em dash
	"\u2013": "-",                    # En dash
}

const PUNCTUATION_CHARS := [".", ",", ";", "!", "?", ":"]


# ─── Encoding (matches original Midsummer-Memorizer logic) ───

static func encode_word(word: String) -> String:
	if word.is_empty():
		return ""
	if word[0].to_upper() != word[0].to_lower():  # is alphabetic
		return word[0]
	return word  # non-alpha words kept as-is


static func process_segment(segment: String) -> String:
	# Remove quotes
	segment = segment.replace("\"", "")
	# Split on spaces and hyphens
	var parts: PackedStringArray = segment.split(" ", false)
	var encoded_words: Array = []

	for part in parts:
		# Handle hyphenated words
		var sub_parts := part.split("-", false)
		var encoded_subs: Array = []
		for sub in sub_parts:
			if sub.is_empty():
				continue
			# Check if last char is punctuation
			var last_char := sub[sub.length() - 1]
			if last_char in PUNCTUATION_CHARS and sub.length() > 1:
				encoded_subs.append(encode_word(sub.left(sub.length() - 1)) + last_char)
			else:
				encoded_subs.append(encode_word(sub))
		encoded_words.append(" ".join(encoded_subs))

	return " ".join(encoded_words)


static func encode_for_memorization(text: String) -> String:
	## Encode text to first-letter abbreviation, preserving parenthesized content.
	var result_parts: Array = []
	var regex := RegEx.new()
	regex.compile("\\([^)]+\\)")

	# Split by parenthesized segments
	var last_end := 0
	var matches := regex.search_all(text)

	if matches.is_empty():
		return process_segment(text)

	for m in matches:
		# Process text before this parenthesized segment
		if m.get_start() > last_end:
			var before := text.substr(last_end, m.get_start() - last_end)
			result_parts.append(process_segment(before))
		# Keep parenthesized content as-is
		result_parts.append(m.get_string())
		last_end = m.get_end()

	# Process remaining text after last match
	if last_end < text.length():
		result_parts.append(process_segment(text.substr(last_end)))

	var result := " ".join(result_parts)
	# Clean up multiple spaces
	while result.find("  ") != -1:
		result = result.replace("  ", " ")
	return result.strip_edges()


# ─── Script Parsing ───

static func parse(source_text: String) -> ParsedScript:
	var parsed := ParsedScript.new()

	# Normalize typographic characters
	var text := source_text
	for key in REPLACEMENTS:
		text = text.replace(key, REPLACEMENTS[key])

	var lines := text.split("\n")
	var raw_entries: Array = []  # Array of CharacterLine
	var current_character: String = ""
	var current_lines: Array = []

	# Regex for character names: ALL CAPS, short, on own line
	var name_regex := RegEx.new()
	name_regex.compile("^[A-Z0-9 \\-\\']+$")

	var act_scene_regex := RegEx.new()
	act_scene_regex.compile("^(Act|Scene)\\b")

	for raw_line in lines:
		var stripped := raw_line.strip_edges()

		# Skip blank lines
		if stripped.is_empty():
			continue

		# Act/Scene headings → navigation markers
		if act_scene_regex.search(stripped):
			# Flush pending dialogue
			if not current_character.is_empty() and not current_lines.is_empty():
				raw_entries.append(CharacterLine.new(
					current_character, " ".join(current_lines)))
				current_character = ""
				current_lines = []
			parsed.acts_scenes.append({
				"label": stripped,
				"line_index": raw_entries.size(),
			})
			continue

		# Stage directions: indented + parenthesized
		if (raw_line.begins_with("        ") or raw_line.begins_with("\t\t")) \
				and stripped.begins_with("(") and stripped.ends_with(")"):
			if not current_character.is_empty() and not current_lines.is_empty():
				raw_entries.append(CharacterLine.new(
					current_character, " ".join(current_lines)))
				current_character = ""
				current_lines = []
			raw_entries.append(CharacterLine.new("DIRECTION", stripped, true))
			continue

		# Character name: ALL CAPS, reasonably short
		if name_regex.search(stripped) and stripped == stripped.to_upper() \
				and stripped.length() < 50 and stripped.length() > 1:
			# Flush previous character's lines
			if not current_character.is_empty() and not current_lines.is_empty():
				raw_entries.append(CharacterLine.new(
					current_character, " ".join(current_lines)))
			current_character = stripped
			current_lines = []
			continue

		# Dialogue continuation
		if not current_character.is_empty():
			current_lines.append(stripped)

	# Flush last speaker
	if not current_character.is_empty() and not current_lines.is_empty():
		raw_entries.append(CharacterLine.new(
			current_character, " ".join(current_lines)))

	# Combine adjacent lines from same character
	var combined: Array = []
	var prev: CharacterLine = null
	for cl in raw_entries:
		if prev != null and cl.character == prev.character and not cl.is_direction:
			prev.lines += " " + cl.lines
			prev.encoded = encode_for_memorization(prev.lines)
		else:
			if prev != null:
				combined.append(prev)
			prev = cl
	if prev != null:
		combined.append(prev)

	parsed.character_lines = combined

	# Extract unique character names (exclude DIRECTION)
	var name_set := {}
	for cl in combined:
		if cl.character != "DIRECTION":
			name_set[cl.character] = true
	var names: Array = name_set.keys()
	names.sort()
	parsed.character_names = names

	# Try to guess title from first act/scene heading
	if not parsed.acts_scenes.is_empty():
		parsed.title = "Script (%d characters, %d lines)" % [names.size(), combined.size()]
	else:
		parsed.title = "Script (%d characters)" % names.size()

	return parsed
