extends "res://scripts/screens/screen.gd"
## The main menu: play alone or as a team, the difficulty, how to play and the ranking. The Earth turns behind it.


func enter(_args: Dictionary) -> void:
	world.stage_menu()
	var box := Kit.vbox(14)
	Kit.place(box, 0, 0, 0, 1, 70, 90, 620, -40)
	add_child(box)
	box.add_child(Kit.lbl("NASA SPACE APPS CHALLENGE 2026", 15, Kit.C_ACCENT, Kit.FONT_B))
	box.add_child(Kit.lbl("Farpoint HORIZON", 66, Color.WHITE, Kit.FONT_T))
	box.add_child(Kit.lbl(tr("Design, launch and operate your own space mission. Every decision has consequences, in mass, power, data, budget and time."), 18, Kit.C_DIM, Kit.FONT_R, true))
	box.add_child(Kit.spacer(14))
	box.add_child(Kit.accent_btn(Kit.btn(tr("▶  One player"), func(): _start_solo(), 20, 340), Kit.C_ACCENT))
	box.add_child(Kit.accent_btn(Kit.btn(tr("Team (2 to 4 players)"), func(): go("team"), 20, 340), Color(0.5, 1.0, 0.6)))
	box.add_child(Kit.spacer(4))
	box.add_child(Kit.lbl(tr("Difficulty"), 14, Kit.C_DIM, Kit.FONT_B))
	var dh := Kit.hbox(8)
	box.add_child(dh)
	for d in ["facil", "normal", "dificil"]:
		var b := Kit.btn(GameData.DIFFICULTY[d].name, func(): GameState.difficulty = d; go("menu"), 16, 110)
		if GameState.difficulty == d:
			Kit.accent_btn(b, Kit.C_WARN)
		dh.add_child(b)
	box.add_child(Kit.lbl(GameData.DIFFICULTY[GameState.difficulty].desc, 14, Kit.C_DIM))
	box.add_child(Kit.spacer(6))
	var hh := Kit.hbox(8)
	box.add_child(hh)
	hh.add_child(Kit.btn(tr("How to play"), func(): main.overlay("howto"), 16, 166))
	hh.add_child(Kit.btn("Ranking", func(): main.overlay("ranking"), 16, 166))
	var foot := Kit.lbl(tr("Space Mission Design Game challenge · Team SK Horizon · Quito, Ecuador"), 13, Kit.C_DIM)
	Kit.place(foot, 0, 1, 0, 1, 70, -40, 900, -14)
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
	Kit.place(tag, 1, 1, 1, 1, -150, -40, -20, -14)
	add_child(tag)


## Switches the language (the choice is remembered) and draws the menu again in it.
func _set_language(code: String) -> void:
	GameData.set_language(code)
	go("menu")


func _start_solo() -> void:
	GameState.start_solo()
	go("missions")
