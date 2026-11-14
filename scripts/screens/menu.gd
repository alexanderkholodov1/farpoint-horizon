extends "res://scripts/screens/screen.gd"
## The main menu: play alone or as a team, the difficulty, how to play and the ranking. The Earth turns behind it.


func enter(_args: Dictionary) -> void:
	world.stage_menu()
	# a frosted panel on the left, the turning Earth on the right (clean room over space)
	var panel := Kit.panel_box(34)
	Kit.place(panel, 0, 0, 0, 0, 56, 72, 600, 72)   # grows to its content
	add_child(panel)
	var box := Kit.vbox(14)
	panel.add_child(box)
	box.add_child(Kit.lbl("NASA SPACE APPS CHALLENGE 2026", 13, Kit.C_DIM, Kit.FONT_B))
	box.add_child(logo(1.0))
	box.add_child(Kit.lbl(tr("Design, launch and operate your own space mission. Every decision has consequences, in mass, power, data, budget and time."), 18, Kit.C_DIM, Kit.FONT_R, true))
	box.add_child(Kit.spacer(14))
	box.add_child(Kit.accent_btn(Kit.btn(tr("▶  Play"), func(): go("team"), 20, 340), Kit.C_GOLD))
	box.add_child(Kit.spacer(4))
	box.add_child(Kit.lbl(tr("Difficulty"), 14, Kit.C_DIM, Kit.FONT_B))
	var dh := Kit.hbox(8)
	box.add_child(dh)
	for d in ["facil", "normal", "dificil"]:
		var b := Kit.btn(GameData.DIFFICULTY[d].name, func(): GameState.difficulty = d; go("menu"), 16, 110)
		if GameState.difficulty == d:
			Kit.accent_btn(b, Kit.C_ACCENT)
		dh.add_child(b)
	box.add_child(Kit.lbl(GameData.DIFFICULTY[GameState.difficulty].desc, 14, Kit.C_DIM))
	box.add_child(Kit.spacer(6))
	var hh := Kit.hbox(8)
	box.add_child(hh)
	hh.add_child(Kit.btn(tr("How to play"), func(): main.overlay("howto"), 16, 166))
	hh.add_child(Kit.btn("Ranking", func(): main.overlay("ranking"), 16, 166))
	var foot := Kit.lbl(tr("Space Mission Design Game challenge · Team SK Horizon · Quito, Ecuador"), 13, Color(Kit.C_ON_DARK, 0.6))
	Kit.place(foot, 0, 1, 0, 1, 60, -40, 900, -14)
	add_child(foot)
	var langs := Kit.hbox(6)
	Kit.place(langs, 1, 0, 1, 0, -270, 24, -30, 64)
	langs.alignment = BoxContainer.ALIGNMENT_END
	add_child(langs)
	for code in GameData.LANGUAGES:
		var lb := Kit.btn(GameData.LANGUAGES[code], func(): _set_language(code), 15, 110)
		if GameData.language == code:
			Kit.accent_btn(lb, Kit.C_ACCENT)
		langs.add_child(lb)
	var tag := Kit.lbl("● Ecuador", 14, Color(1, 0.8, 0.3), Kit.FONT_B)
	tag.add_theme_color_override("font_color", Color(1, 0.8, 0.3))   # on the dark scene: keep the light gold
	Kit.place(tag, 1, 1, 1, 1, -150, -40, -20, -14)
	add_child(tag)


## Switches the language (the choice is remembered) and draws the menu again in it.
func _set_language(code: String) -> void:
	GameData.set_language(code)
	go("menu")


## The game's logo: the horizon arc rising over the name, "HORIZON" spaced and in the deep blue of the arc's ends.
## `k` scales it (1 on the menu).
static func logo(k := 1.0) -> Control:
	var v := Kit.vbox(0)
	var arc := preload("res://scripts/ui/horizon.gd").new()
	arc.custom_minimum_size = Vector2(470 * k, 34 * k)
	arc.thickness = 2.5 * k
	arc.sun_at = 0.36
	v.add_child(arc)
	var h := Kit.hbox(int(14 * k))
	v.add_child(h)
	h.add_child(Kit.lbl("Farpoint", int(56 * k), Kit.C_TEXT, Kit.FONT_T))
	var hz := Kit.lbl("HORIZON", int(56 * k), Kit.C_ACCENT, _spaced(int(7 * k)))
	h.add_child(hz)
	return v


static func _spaced(px: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = Kit.FONT_B
	f.spacing_glyph = px
	return f
