extends "res://scripts/screens/screen.gd"
## Report: the grade and score of the last flight (GameState.last_sim and last_report), what happened and why, real
## missions like it, and the ways on: redesign, fly again, a new mission, save to the ranking.


func enter(_args: Dictionary) -> void:
	var last_sim: Dictionary = GameState.last_sim
	var team_mode: bool = GameState.team_mode
	if last_sim.launch_failed:
		world.stage_earth()
	elif world.stage == null or world.orbit_ship == null:
		world.stage_orbit()
	var s: Dictionary = last_sim.score
	var r: Dictionary = GameState.last_report
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var p := Kit.panel_box(22)
	Kit.place(p, 0.5, 0, 0.5, 1, -640, 16, 640, -16)
	add_child(p)
	var outer := Kit.vbox(10)
	p.add_child(outer)
	# header
	var head := Kit.hbox(20)
	outer.add_child(head)
	var gcol: Color = {"S": Color(1.0, 0.85, 0.3), "A": Kit.C_OK, "B": Kit.C_ACCENT, "C": Kit.C_WARN, "D": Kit.C_BAD}[s.grade]
	var gl := Kit.lbl(s.grade, 88, gcol, Kit.FONT_T)
	gl.custom_minimum_size.x = 90
	head.add_child(gl)
	var hv := Kit.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(Kit.lbl("INFORME DE MISIÓN · " + S.name.to_upper(), 14, Kit.C_ACCENT, Kit.FONT_B))
	hv.add_child(Kit.lbl(s.label, 34, Color.WHITE, Kit.FONT_T))
	hv.add_child(Kit.lbl("%d / 1000 puntos   ·   Costo final %s de %s   ·   %d de %d meses en operación" % [s.total, Kit.money(s.final_cost), Kit.money(r.budget), last_sim.months, mission.years * 12], 15, Kit.C_DIM))
	var cols := Kit.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)
	# column 1: score
	var c1 := Kit.vbox(8)
	c1.custom_minimum_size.x = 360
	cols.add_child(c1)
	c1.add_child(Kit.lbl("Puntaje", 18, Color.WHITE, Kit.FONT_B))
	_score_row(c1, "Objetivos cumplidos", s.objectives, 400, "Objetivos científicos cubiertos y tiempo en operación.")
	_score_row(c1, "Ciencia obtenida", s.science, 300, "%d de %d puntos de ciencia." % [int(last_sim.science), int(S.science_target)])
	_score_row(c1, "Uso eficiente de recursos", s.efficiency, 200, "Reserva de presupuesto y márgenes de masa y energía.")
	_score_row(c1, "Trabajo en equipo", s.team, 100, "Metas de cada rol cumplidas.")
	c1.add_child(Kit.spacer(6))
	c1.add_child(Kit.lbl("Metas por rol", 16, Color.WHITE, Kit.FONT_B))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		var who := (GameState.player_for_role(role) + " · ") if team_mode else ""
		c1.add_child(Kit.lbl(("✓ " if ok else "✗ ") + who + R.name, 14, Kit.C_OK if ok else Kit.C_BAD, Kit.FONT_B, true))
		c1.add_child(Kit.lbl(R.why, 12, Kit.C_DIM, Kit.FONT_R, true))
	# column 2: what happened and why
	var c2sc := ScrollContainer.new()
	c2sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c2sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(c2sc)
	var c2 := Kit.vbox(6)
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c2sc.add_child(c2)
	c2.add_child(Kit.lbl("¿Por qué pasó lo que pasó?", 18, Color.WHITE, Kit.FONT_B))
	var lessons := 0
	for c in r.checks:
		if c.level == "warn":
			c2.add_child(Kit.lbl("⚠ " + c.title, 14, Kit.C_WARN, Kit.FONT_B, true))
			c2.add_child(Kit.lbl(c.detail, 13, Kit.C_DIM, Kit.FONT_R, true))
			lessons += 1
	for e in last_sim.events:
		if e.kind == "bad" and e.month > 1:
			c2.add_child(Kit.lbl("✗ Mes %d: %s" % [e.month, e.title], 14, Kit.C_BAD, Kit.FONT_B, true))
			c2.add_child(Kit.lbl(e.text, 13, Kit.C_DIM, Kit.FONT_R, true))
			lessons += 1
	if lessons == 0:
		c2.add_child(Kit.lbl("✓ El diseño estaba equilibrado: energía, datos, masa y combustible con margen. ¡Así se diseña una misión!", 14, Kit.C_OK, Kit.FONT_B, true))
	c2.add_child(Kit.spacer(6))
	c2.add_child(Kit.lbl("Lo que salió bien", 18, Color.WHITE, Kit.FONT_B))
	for e in last_sim.events:
		if e.kind == "good":
			c2.add_child(Kit.lbl("✓ Mes %d: %s" % [e.month, e.title], 14, Kit.C_OK, Kit.FONT_B, true))
	c2.add_child(Kit.spacer(6))
	c2.add_child(Kit.lbl("Misiones reales parecidas", 18, Color.WHITE, Kit.FONT_B))
	for t in mission.real_missions():
		c2.add_child(Kit.lbl("• " + t, 14, Kit.C_DIM, Kit.FONT_R, true))
	c2.add_child(Kit.spacer(6))
	c2.add_child(Kit.lbl("No existe un diseño perfecto: otra combinación de plataforma, órbita e instrumentos podría cumplir el mismo objetivo. ¡Prueba otra!", 14, Kit.C_ACCENT, Kit.FONT_R, true))
	# buttons
	var bh := Kit.hbox(10)
	outer.add_child(bh)
	bh.add_child(Kit.accent_btn(Kit.btn("Rediseñar misión", func(): _back_to_design(), 16), Kit.C_ACCENT))
	bh.add_child(Kit.btn("↻ Volver a volar (otra suerte)", func(): _fly_again(), 16))
	bh.add_child(Kit.btn("Nueva misión", func(): go("missions"), 16))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sp)
	var name_e := LineEdit.new()
	name_e.custom_minimum_size.x = 220
	name_e.text = "SK Horizon" if not team_mode else " / ".join(PackedStringArray(GameState.players.map(func(pp): return pp.name)))
	bh.add_child(name_e)
	var save := Button.new()
	save.text = "Guardar en ranking"
	save.add_theme_font_size_override("font_size", 16)
	save.pressed.connect(func():
		if GameState.saved_to_ranking:
			return
		GameState.saved_to_ranking = true
		GameState.add_ranking(name_e.text, s.total, s.grade)
		save.text = "Guardado ✓"
		save.disabled = true)
	save.disabled = GameState.saved_to_ranking
	bh.add_child(save)
	bh.add_child(Kit.btn("Ranking", func(): main.overlay("ranking"), 16))


func _score_row(parent: VBoxContainer, nm: String, val: int, mx: int, sub: String) -> void:
	var h := Kit.hbox(6)
	parent.add_child(h)
	var n := Kit.lbl(nm, 15, Kit.C_TEXT, Kit.FONT_B)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(Kit.lbl("%d / %d" % [val, mx], 15, Color.WHITE, Kit.FONT_B))
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.max_value = mx
	pb.value = val
	var f: float = float(val) / mx
	pb.add_theme_stylebox_override("fill", Kit.flat(Kit.C_OK if f >= 0.75 else (Kit.C_WARN if f >= 0.4 else Kit.C_BAD), Color(0, 0, 0, 0), 4, 0, 0, 0))
	parent.add_child(pb)
	parent.add_child(Kit.lbl(sub, 12, Kit.C_DIM, Kit.FONT_R, true))


func _back_to_design() -> void:
	GameState.approvals = {}
	world.clear_stage()
	world.stage_design()
	go("design", {"step": GameData.STEPS.size() - 1})


## The same design flies again, with new luck: every role approves and it launches.
func _fly_again() -> void:
	GameState.approve_all()
	main.launch()
