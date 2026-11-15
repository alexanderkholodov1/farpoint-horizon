extends "res://scripts/screens/screen.gd"
## Report, as a celebration (issue #11): the grade and score of the last flight (GameState.last_sim, last_report),
## the photos the mission sent home (real NASA images, scripts/flight/photos.gd; an extra objective's photo only when it
## was met, the others locked with what to do to bring them home), the extra objectives met and their bonus (it adds
## to the score; missing one never takes anything away), what happened and why, the real missions like it, and the
## ways on: redesign, fly again, a new mission, save to the ranking. Behind it, the craft where it is: the lander on
## the ground after a landing (scripts/flight/surface.gd), the orbit otherwise, the Earth after a lost launch.

const Photos := preload("res://scripts/flight/photos.gd")
const Objectives := preload("res://scripts/flight/objectives.gd")
const Surface := preload("res://scripts/flight/surface.gd")
const FlightData := preload("res://scripts/flight/flight_data.gd")
const Horizon := preload("res://scripts/ui/horizon.gd")

var surface                    ## scripts/flight/surface.gd behind a landed mission's report
var bonus := 0


func enter(_args: Dictionary) -> void:
	var last_sim: Dictionary = GameState.last_sim
	var flight: Dictionary = GameState.flight
	var landing: Dictionary = flight.get("landing", {})
	if last_sim.launch_failed:
		world.stage_earth()
	elif bool(landing.get("landed", false)) and FlightData.has_landing(mission.scenario):
		Surface.note_landing(mission, landing)
		surface = Surface.new()
		surface.build(world, mission, landing)
		surface.cam_dist = 11.0
	elif world.stage == null or world.orbit_ship == null:
		world.stage_orbit()
	bonus = int(flight.get("bonus", 0))
	var s: Dictionary = last_sim.score
	var r: Dictionary = GameState.last_report
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var p := Kit.panel_box(Kit.PAD)
	Kit.place(p, 0.5, 0, 0.5, 1, -660, Kit.MARGIN, 660, -Kit.MARGIN)
	add_child(p)
	var outer := Kit.vbox(Kit.GAP)
	p.add_child(outer)
	_header(outer, s, r, S, last_sim)
	var cols := Kit.hbox(26)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)
	_score_column(cols, s, r, S, last_sim)
	_photo_column(cols, flight, last_sim)
	_story_column(cols, last_sim)
	outer.add_child(Kit.rule())
	_actions(outer, s)


func exit() -> void:
	if surface:
		surface.restore()


func process(delta: float) -> void:
	if surface:
		surface.camera(delta)


# ===================================================================================== HEADER
func _header(outer: VBoxContainer, s: Dictionary, r: Dictionary, S: Dictionary, last_sim: Dictionary) -> void:
	var head := Kit.hbox(22)
	outer.add_child(head)
	var gcol: Color = {"S": Color(1.0, 0.85, 0.3), "A": Kit.C_OK, "B": Kit.C_ACCENT, "C": Kit.C_WARN, "D": Kit.C_BAD}[s.grade]
	var gl := Kit.lbl(s.grade, 88, Kit.ink(gcol), Kit.FONT_T)
	gl.custom_minimum_size.x = 92
	head.add_child(gl)
	var hv := Kit.vbox(4)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(Kit.caps(tr("Mission report") + " · " + S.name))
	hv.add_child(Kit.lbl(s.label, 34, Kit.C_TEXT, Kit.FONT_T))
	var pts := tr("%d / 1000 points") % s.total
	if bonus > 0:
		pts += "  " + tr("+ %d bonus") % bonus
	hv.add_child(Kit.lbl(pts + "   ·   " + tr("Final cost %s of %s") % [Kit.money(s.final_cost), Kit.money(r.budget)] + "   ·   " \
		+ tr("%d of %d months in operation") % [last_sim.months, mission.years * 12], Kit.T_BODY, Kit.C_DIM))
	var good: bool = s.grade in ["S", "A", "B"] and not last_sim.launch_failed and last_sim.status != "lost"
	if good:
		Kit.UiSound.play("success", 0.0)
		# the brand's horizon arc draws itself under the header: the moment of the mission done
		var arc := Horizon.new()
		arc.custom_minimum_size = Vector2(0, 10)
		arc.thickness = 2.5
		arc.progress = 0.0
		outer.add_child(arc)
		arc.create_tween().tween_property(arc, "progress", 1.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		outer.add_child(Kit.rule())


# ===================================================================================== SCORE
func _score_column(cols: HBoxContainer, s: Dictionary, r: Dictionary, S: Dictionary, last_sim: Dictionary) -> void:
	var c1 := Kit.vbox(8)
	c1.custom_minimum_size.x = 340
	cols.add_child(c1)
	c1.add_child(Kit.caps(tr("Score")))
	_score_row(c1, tr("Goals met"), s.objectives, 400, tr("Science goals covered and time in operation."))
	_score_row(c1, tr("Science gathered"), s.science, 300, tr("%d of %d science points.") % [int(last_sim.science), int(S.science_target)])
	_score_row(c1, tr("Efficient use of resources"), s.efficiency, 200, tr("Budget reserve and mass and power margins."))
	_score_row(c1, tr("Teamwork"), s.team, 100, tr("Each role's goals met."))
	c1.add_child(Kit.spacer(4))
	c1.add_child(Kit.caps(tr("Goals by role")))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		var who := (GameState.player_for_role(role) + " · ") if GameState.team_mode else ""
		c1.add_child(Kit.lbl(("✓ " if ok else "✗ ") + who + R.name, Kit.T_BODY, Kit.ink(Kit.C_OK if ok else Kit.C_BAD), Kit.FONT_B, true))
		c1.add_child(Kit.lbl(R.why, Kit.T_SMALL - 1, Kit.C_DIM, Kit.FONT_R, true))


func _score_row(parent: VBoxContainer, nm: String, val: int, mx: int, sub: String) -> void:
	var h := Kit.hbox(6)
	parent.add_child(h)
	var n := Kit.lbl(nm, Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(Kit.lbl("%d / %d" % [val, mx], Kit.T_BODY, Kit.C_TEXT, Kit.font_num()))
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.max_value = mx
	pb.value = val
	var f: float = float(val) / mx
	pb.add_theme_stylebox_override("fill", Kit.flat(Kit.C_OK if f >= 0.75 else (Kit.C_WARN if f >= 0.4 else Kit.C_BAD), Color(0, 0, 0, 0), 4, 0, 0, 0))
	parent.add_child(pb)
	parent.add_child(Kit.lbl(sub, Kit.T_SMALL - 1, Kit.C_DIM, Kit.FONT_R, true))


# ===================================================================================== PHOTOS AND BONUSES
func _photo_column(cols: HBoxContainer, flight: Dictionary, last_sim: Dictionary) -> void:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.x = 420
	cols.add_child(sc)
	var c := Kit.vbox(Kit.GAP)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(c)
	var photos: Array = Photos.of(mission.scenario)
	var got := 0
	for ph in photos:
		if Photos.earned(ph, flight, last_sim):
			got += 1
	c.add_child(Kit.caps(tr("Photos your mission sent home")))
	if photos.is_empty():
		c.add_child(Kit.lbl(tr("This mission's pictures are not in the game yet."), Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true))
	else:
		c.add_child(Kit.lbl(tr("%d of %d, real NASA images of your target. Click one to see it large.") % [got, photos.size()], Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		c.add_child(grid)
		for ph in photos:
			grid.add_child(_photo_tile(ph, Photos.earned(ph, flight, last_sim)))
	# the extra objectives drawn for this mission
	var offered: Array = mission.extras_offered
	if not offered.is_empty():
		c.add_child(Kit.spacer(4))
		c.add_child(Kit.caps(tr("Extra objectives")))
		var all: Dictionary = Objectives.all()
		var met: Dictionary = flight.get("extras", {})
		for id in offered:
			if not all.has(id):
				continue
			var ok: bool = met.get(id, false)
			var row := Kit.hbox(8)
			c.add_child(row)
			var nm := Kit.lbl(("✓ " if ok else "○ ") + str(all[id].name), Kit.T_BODY, Kit.ink(Kit.C_OK) if ok else Kit.C_DIM, Kit.FONT_B, true)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nm)
			row.add_child(Kit.lbl(("+%d" % int(all[id].points)) if ok else tr("not this time"), Kit.T_BODY, Kit.ink(Kit.C_OK) if ok else Kit.C_DIM, Kit.font_num()))
			c.add_child(Kit.lbl(str(all[id].desc), Kit.T_SMALL - 1, Kit.C_DIM, Kit.FONT_R, true))
		if bonus > 0:
			c.add_child(Kit.lbl(tr("Bonus: +%d points on top of your score.") % bonus, Kit.T_BODY, Kit.ink(Kit.C_OK), Kit.FONT_B, true))


## A photo's tile: the picture (click to see it large) or, when it did not come home, what would bring it.
func _photo_tile(ph: Dictionary, earned: bool) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(200, 132)
	tile.add_theme_stylebox_override("panel", Kit.flat(Kit.C_CARD, Kit.C_LINE, 8, 1, 0, 0))
	if earned:
		var tr_ := TextureRect.new()
		tr_.texture = load(ph.path)
		tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr_.clip_contents = true
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(tr_)
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tile.tooltip_text = tr(str(ph.caption))
		tile.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_show_photo(ph))
	else:
		var v := Kit.vbox(4)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		tile.add_child(v)
		var all: Dictionary = Objectives.all()
		var what: String = tr("Meet “%s” to bring this one home.") % str(all[ph.objective].name) if ph.objective != "" and all.has(ph.objective) \
			else tr("It comes home when the mission works.")
		var l := Kit.lbl("🔒  " + what, Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.x = 180
		v.add_child(l)
	return tile


## A photo large, with what it shows and whose it is.
func _show_photo(ph: Dictionary) -> void:
	Kit.UiSound.play("select")
	var box := Kit.overlay(self, tr("A photo your mission sent home"), 980.0, 760.0)
	var tex := TextureRect.new()
	tex.texture = load(ph.path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tex)
	box.add_child(Kit.lbl(tr(str(ph.caption)), Kit.T_LEAD, Kit.C_TEXT, Kit.FONT_R, true))
	box.add_child(Kit.lbl(tr("Credit: %s") % ph.credit, Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true))


# ===================================================================================== THE STORY
func _story_column(cols: HBoxContainer, last_sim: Dictionary) -> void:
	var c2sc := ScrollContainer.new()
	c2sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c2sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(c2sc)
	var c2 := Kit.vbox(6)
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c2sc.add_child(c2)
	c2.add_child(Kit.caps(tr("Why it went the way it did")))
	var any_bad := false
	var r: Dictionary = GameState.last_report
	for c in r.checks:
		if c.level == "warn":
			any_bad = true
			c2.add_child(Kit.lbl("⚠ " + c.title, Kit.T_BODY, Kit.ink(Kit.C_WARN), Kit.FONT_B, true))
			c2.add_child(Kit.lbl(c.detail, Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true))
	for e in last_sim.events:
		if e.kind == "bad" and e.month > 1:
			any_bad = true
			c2.add_child(Kit.lbl(tr("✗ Month %d · %s") % [e.month, e.title], Kit.T_BODY, Kit.ink(Kit.C_BAD), Kit.FONT_B, true))
			c2.add_child(Kit.lbl(e.text, Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true))
	if not any_bad:
		c2.add_child(Kit.lbl(tr("✓ The design was balanced, with margin in power, data, mass and fuel. That's how a mission gets designed!"), Kit.T_BODY, Kit.ink(Kit.C_OK), Kit.FONT_B, true))
	c2.add_child(Kit.spacer(4))
	c2.add_child(Kit.caps(tr("What went well")))
	for e in last_sim.events:
		if e.kind == "good":
			c2.add_child(Kit.lbl(tr("✓ Month %d · %s") % [e.month, e.title], Kit.T_BODY, Kit.ink(Kit.C_OK), Kit.FONT_B, true))
	c2.add_child(Kit.spacer(4))
	c2.add_child(Kit.caps(tr("Similar real missions")))
	for t in mission.real_missions():
		c2.add_child(Kit.lbl("• " + t, Kit.T_SMALL + 1, Kit.C_DIM, Kit.FONT_R, true))
	c2.add_child(Kit.spacer(4))
	c2.add_child(Kit.lbl(tr("There is no perfect design. Another mix of platform, orbit and instruments could meet the same goal. Try another!"), Kit.T_BODY, Kit.ink(Kit.C_ACCENT), Kit.FONT_R, true))


# ===================================================================================== WAYS ON
func _actions(outer: VBoxContainer, s: Dictionary) -> void:
	var bh := Kit.hbox(10)
	outer.add_child(bh)
	var redo := Kit.accent_btn(Kit.btn(tr("Redesign mission"), func(): _back_to_design(), Kit.T_BODY), Kit.C_ACCENT)
	redo.custom_minimum_size.y = Kit.BTN_H
	bh.add_child(redo)
	for b in [Kit.btn(tr("↻ Fly again (new luck)"), func(): _fly_again(), Kit.T_BODY), Kit.btn(tr("New mission"), func(): go("missions"), Kit.T_BODY)]:
		b.custom_minimum_size.y = Kit.BTN_H
		bh.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sp)
	var name_e := LineEdit.new()
	name_e.custom_minimum_size = Vector2(220, Kit.BTN_H)
	name_e.text = "SK Horizon" if not GameState.team_mode else " / ".join(PackedStringArray(GameState.players.map(func(pp): return pp.name)))
	bh.add_child(name_e)
	var save := Kit.btn(tr("Save to ranking"), func(): pass, Kit.T_BODY)
	save.custom_minimum_size.y = Kit.BTN_H
	save.pressed.connect(func():
		if GameState.saved_to_ranking:
			return
		GameState.saved_to_ranking = true
		GameState.add_ranking(name_e.text, s.total + bonus, s.grade)     # achieving more is rewarded
		save.text = tr("Saved ✓")
		save.disabled = true)
	save.disabled = GameState.saved_to_ranking
	bh.add_child(save)
	var rk := Kit.btn("Ranking", func(): main.overlay("ranking"), Kit.T_BODY)
	rk.custom_minimum_size.y = Kit.BTN_H
	bh.add_child(rk)


func _back_to_design() -> void:
	GameState.approvals = {}
	world.clear_stage()
	world.stage_design()
	go("design", {"step": GameData.STEPS.size() - 1})


## The same design flies again, with new luck: every role approves and it launches.
func _fly_again() -> void:
	GameState.approve_all()
	main.launch()
