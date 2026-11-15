extends "res://scripts/screens/screen.gd"
## Overlay: the credits (issue #14). Who made the game, what it is built with, which AI agents helped, and every outside
## source the game uses, from data/credits.json (made by tools/credits.py from docs/sources.md and the README, so it
## never drifts; tests/credits.gd checks it). Links open in the browser. Opened with main.overlay("credits").

const CREDITS_PATH := "res://data/credits.json"


func enter(_args: Dictionary) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CREDITS_PATH))
	var v := Kit.overlay(self, tr("Credits"), 1040, 740, queue_free)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var box := Kit.vbox(Kit.GAP)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)

	box.add_child(_text(tr("Farpoint HORIZON was made by %s for the 2026 NASA Space Apps Challenge, challenge “Space Mission Design Game”. It uses NASA's open data; NASA does not endorse it.") % _team(data), Kit.T_LEAD, Kit.C_TEXT))

	box.add_child(Kit.spacer(Kit.GAP))
	box.add_child(Kit.caps(tr("Built with")))
	box.add_child(Kit.rule())
	for line in data.get("built_with", []):
		box.add_child(_text("•  " + line))

	box.add_child(Kit.spacer(Kit.GAP))
	box.add_child(Kit.caps(tr("Use of AI")))
	box.add_child(Kit.rule())
	var notes: Array = data.get("ai_note", [])
	if notes.size() > 0:
		box.add_child(_text(notes[0]))
	for line in data.get("ai", []):
		box.add_child(_text("•  " + line))
	for i in range(1, notes.size()):
		box.add_child(_text(notes[i]))

	box.add_child(Kit.spacer(Kit.GAP))
	box.add_child(Kit.caps(tr("Sources") + " · " + str(int(data.get("count", 0)))))
	box.add_child(Kit.rule())
	box.add_child(_text(tr("Every number, dataset, image and model from outside the team, as cited in the game's code and data."), Kit.T_SMALL, Kit.C_DIM))
	for sec in data.get("sections", []):
		box.add_child(Kit.spacer(Kit.GAP * 0.5))
		box.add_child(Kit.lbl(sec.title, Kit.T_BODY, Kit.C_ACCENT, Kit.FONT_B, true))
		for e in sec.entries:
			box.add_child(_text("[b]%s[/b]  %s" % [e.id, _links(_esc(e.text))], Kit.T_SMALL, Kit.C_TEXT, false))


func _team(data: Dictionary) -> String:
	# "Team SK Horizon, Quito, Ecuador." reads as "Team SK Horizon (Quito, Ecuador)" inside a sentence
	var t: String = String(data.get("team", "Team SK Horizon")).trim_suffix(".")
	var i := t.find(", ")
	return t if i < 0 else "%s (%s)" % [t.substr(0, i), t.substr(i + 2)]


## A wrapped rich-text paragraph whose links open in the browser.
func _text(t: String, size := Kit.T_BODY, col := Kit.C_TEXT, escape := true) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.selection_enabled = true
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", size)
	rt.add_theme_font_size_override("bold_font_size", size)
	rt.add_theme_color_override("default_color", col)
	rt.text = _links(_esc(t)) if escape else t
	rt.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	return rt


## BBCode-safe: a literal "[" in a source would start a tag.
static func _esc(t: String) -> String:
	return t.replace("[", "[lb]")


## Every http(s) address becomes a link in the accent colour.
static func _links(t: String) -> String:
	var rx := RegEx.new()
	rx.compile(r"https?://[^\s)\]]+[^\s)\].,;]")
	var out := ""
	var at := 0
	var col := Kit.C_ACCENT.to_html(false)
	for m in rx.search_all(t):
		out += t.substr(at, m.get_start() - at)
		out += "[url=%s][color=#%s]%s[/color][/url]" % [m.get_string(), col, m.get_string()]
		at = m.get_end()
	return out + t.substr(at)
