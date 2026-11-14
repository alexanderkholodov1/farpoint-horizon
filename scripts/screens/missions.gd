extends "res://scripts/screens/screen.gd"
## Missions (CML 1): choose the mission's scientific objective among the scenarios of GameData.SCENARIOS.


func enter(_args: Dictionary) -> void:
	var head := Kit.vbox(4)
	Kit.place(head, 0, 0, 1, 0, 50, 30, -50, 130)
	add_child(head)
	head.add_child(Kit.lbl(GameData.CML_NAMES[1] + "  —  " + tr("Every mission starts with a science question"), 15, Kit.C_ACCENT, Kit.FONT_B))
	head.add_child(Kit.lbl(tr("Choose your mission's goal"), 36, Color.WHITE, Kit.FONT_T))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Kit.place(sc, 0, 0, 1, 1, 50, 140, -50, -80)
	add_child(sc)
	sc.add_child(grid)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mult: float = GameData.DIFFICULTY[GameState.difficulty].budget
	for id in GameData.SCENARIOS:
		var S: Dictionary = GameData.SCENARIOS[id]
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := Kit.flat(Kit.C_BG, S.color.darkened(0.2), 12, 2, 18, 16)
		pc.add_theme_stylebox_override("panel", sb)
		pc.custom_minimum_size = Vector2(0, 250)
		pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var v := Kit.vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pc.add_child(v)
		v.add_child(Kit.lbl(S.type.to_upper(), 13, S.color, Kit.FONT_B))
		v.add_child(Kit.lbl(S.name, 22, Color.WHITE, Kit.FONT_T, true))
		v.add_child(Kit.lbl(S.desc, 14, Kit.C_DIM, Kit.FONT_R, true))
		var facts := tr("Budget %s   ·   Operate at least %d yr") % [Kit.money(S.budget * mult), S.min_years]
		v.add_child(Kit.lbl(facts, 14, Kit.C_WARN, Kit.FONT_B, true))
		pc.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_choose(id))
		pc.mouse_entered.connect(func(): sb.bg_color = Color(0.07, 0.13, 0.22, 0.95))
		pc.mouse_exited.connect(func(): sb.bg_color = Kit.C_BG)
		grid.add_child(pc)
	var back := Kit.btn(tr("◀ Menu"), func(): go("menu"))
	Kit.place(back, 0, 1, 0, 1, 50, -62, 180, -20)
	add_child(back)


func _choose(id: String) -> void:
	GameState.start_mission(id)
	go("design", {"step": 0})
