extends "res://scripts/screens/screen.gd"
## Design (CML 2-4), guided as the rocket builder is: the craft is designed one question at a time. Each question
## shows only the options that make sense here, as tiles with a drawing, a name and two facts; the rest is told when
## a tile is pointed at. The best fit carries a star, so a player who is lost can follow the stars.
##   Orbit: where it flies · Craft: its body, its instruments · Power: panels, battery · Systems: antenna, pointing,
##   engine · Rocket: the launcher (or build your own) · Launch: the review, years, extras, LAUNCH!
## Top: the six stages, the current one lit; a stage already reached can be clicked. Centre: the craft in 3D.
## Right: the mission board as seven short answers (budget, mass, power, battery, data, fuel, science).
## The questions map onto the eight steps of GameData.STEPS (who decides each, what the crew's bots choose), which
## stay as they were: args {"step": index of GameData.STEPS} opens that step's first question, as show_step(i) does.

const RocketDesign := preload("res://scripts/craft/rocket_design.gd")
const Bots := preload("res://scripts/crew/bots.gd")
const PartIcon := preload("res://scripts/ui/part_icon.gd")
const Progress := preload("res://scripts/progress.gd")

const STAGES := ["Orbit", "Craft", "Power", "Systems", "Rocket", "Launch"]
## The questions in order: [id, the GameData.STEPS id it belongs to, stage, the question, what it is about].
const QUESTIONS := [
	["orbit", "orbita", 0, "Where will it fly?", "The orbit decides what your craft sees, how long it talks to Earth and how hard it is to get there."],
	["bus", "plataforma", 1, "How big is your craft?", "The body holds everything. Bigger carries more instruments, and costs and weighs more."],
	["instruments", "instrumentos", 1, "What will it carry?", "The instruments do the science. Pick the ones that meet the goals, then continue."],
	["panels", "energia", 2, "Pick the solar panels", "They make the power for everything on board."],
	["battery", "energia", 2, "Pick the battery", "It keeps the craft alive in the shadow, where the panels make nothing."],
	["comms", "comunicaciones", 3, "Pick the antenna", "Every picture has to come home. A faster antenna sends more data each day."],
	["adcs", "control", 3, "How will it point?", "Sharp pictures need a steady aim."],
	["propulsion", "control", 3, "Pick its engine", "It moves the craft to its orbit and holds it there."],
	["launcher", "lanzador", 4, "Pick the rocket", "The farther the destination, the less a rocket can carry."],
	["review", "revision", 5, "Ready to launch?", "Fix what is red. Amber costs science but still flies."],
]
const YEARS := [1, 2, 3, 5, 7, 10]

static var _mission_id := 0     ## The mission the progress below belongs to.
static var _reached := 0        ## The furthest question reached in it.

var q := 0                      ## Index in QUESTIONS of the question shown.
var step_idx := 0               ## Index in GameData.STEPS of that question's step (the coach reads it).
var show_all := false           ## Instruments: also the ones of little use here.
var left_box: VBoxContainer
var board: VBoxContainer
var stages_row: HBoxContainer
var info_body: Label
var main_btn: Button


func enter(args: Dictionary) -> void:
	GameState.room.changed.connect(_on_room_changed)
	if mission.get_instance_id() != _mission_id:
		_mission_id = mission.get_instance_id()
		_reached = 0
	show_step(args.get("step", 0))


func exit() -> void:
	if GameState.room.changed.is_connected(_on_room_changed):
		GameState.room.changed.disconnect(_on_room_changed)


## Somebody else changed the room (a teammate online, or the host's bots): draw the question again.
func _on_room_changed(by_me: bool) -> void:
	if not by_me and is_inside_tree():
		_show.call_deferred(q)


## Opens the first question of step `idx` of GameData.STEPS.
func show_step(idx: int) -> void:
	var id: String = GameData.STEPS[clampi(idx, 0, GameData.STEPS.size() - 1)].id
	for i in QUESTIONS.size():
		if QUESTIONS[i][1] == id:
			_show(i)
			return
	_show(0)


# ===================================================================================== THE SCREEN
## Draws the screen at question i.
func _show(i: int) -> void:
	q = clampi(i, 0, QUESTIONS.size() - 1)
	_reached = maxi(_reached, q)
	var Q: Array = QUESTIONS[q]
	for k in GameData.STEPS.size():
		if GameData.STEPS[k].id == Q[1]:
			step_idx = k
	GameState.room.enter_step(Q[1])   # the bot that holds this step's station decides now
	clear()
	if not world.stage or world.ship == null:
		world.stage_design()
	var r: Dictionary = mission.compute()
	var STEP: Dictionary = GameData.STEPS[step_idx]
	var room = GameState.room
	# ---------- top: the stages
	var sp := Kit.panel_box(8)
	Kit.place(sp, 0.5, 0, 0.5, 0, 0, 14, 0, 14)
	sp.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(sp)
	stages_row = Kit.hbox(6)
	sp.add_child(stages_row)
	for s in STAGES.size():
		var first := _first_of(s)
		var b := Kit.choice(("✓ " if first < _reached and s != Q[2] else "%d  " % (s + 1)) + tr(STAGES[s]), s == Q[2], func(): _show(first))
		b.disabled = first > _reached
		if s == Q[2]:
			Kit.accent_btn(b, Kit.C_GOLD)
		stages_row.add_child(b)
	# ---------- left: the question and its options
	var lp := Kit.panel_box(Kit.PAD)
	Kit.place(lp, 0, 0, 0, 1, Kit.MARGIN, 84, 476, -Kit.MARGIN)
	add_child(lp)
	var lv := Kit.vbox(Kit.GAP)
	lp.add_child(lv)
	lv.add_child(Kit.caps(GameData.SCENARIOS[mission.scenario].name + "  ·  " + Kit.kg(r.mass_total)))
	lv.add_child(Kit.lbl(tr(Q[3]), Kit.T_STAT, Kit.C_GOLD, Kit.FONT_T, true))
	lv.add_child(Kit.lbl(tr(Q[4]), Kit.T_BODY, Kit.C_DIM, Kit.FONT_R, true))
	var said: Dictionary = room.state.bot_lines.get(STEP.id, {})
	if room.is_bot(STEP.role) and STEP.id != "revision":
		if said.has("line"):
			lv.add_child(Kit.lbl(room.holder_name(STEP.role) + ": " + Bots.say(said.line), Kit.T_SMALL, Kit.C_TEXT, Kit.FONT_R, true))
	elif not room.can_edit(STEP.role):
		lv.add_child(Kit.lbl(tr("This is %s's station. You can watch their choices here.") % room.holder_name(STEP.role), Kit.T_SMALL, Kit.C_WARN, Kit.FONT_B, true))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(sc)
	left_box = Kit.vbox(8)
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(left_box)
	# ---------- right: the mission board
	var rp := Kit.panel_box(Kit.PAD)
	Kit.place(rp, 1, 0, 1, 0, -364, 84, -Kit.MARGIN, 84)   # grows to its content
	add_child(rp)
	board = Kit.vbox(6)
	rp.add_child(board)
	# ---------- bottom centre: what the pointed thing is, and the actions
	var hb: Array = Kit.hint_box()
	var ip: Control = hb[0]
	Kit.place(ip, 0, 1, 1, 1, 496, -214, -388, -110)
	add_child(ip)
	info_body = hb[1]
	info_body.add_theme_font_size_override("font_size", Kit.T_BODY)
	_say("", tr("Point at an option to know more. Drag to turn the craft, scroll to zoom."))
	var bp := Kit.panel_box(10)
	Kit.place(bp, 0, 1, 1, 1, 496, -96, -388, -Kit.MARGIN)
	add_child(bp)
	var bar := Kit.hbox(10)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bp.add_child(bar)
	var menu := Kit.btn(tr("Menu"), func(): go("menu"), Kit.T_BODY, 100)
	menu.custom_minimum_size.y = Kit.BTN_H + 8
	bar.add_child(menu)
	var back := Kit.btn(tr("◀ Back"), func(): _show(q - 1), Kit.T_BODY, 130)
	back.custom_minimum_size.y = Kit.BTN_H + 8
	back.disabled = q == 0
	bar.add_child(back)
	if Q[0] == "review":
		main_btn = Kit.accent_btn(Kit.btn(tr("LAUNCH!"), func(): main.launch(), Kit.T_ACTION, 260), Kit.C_GOLD)
		main_btn.disabled = not GameState.can_launch(r)
		if main_btn.disabled:
			main_btn.modulate.a = 0.45
	else:
		main_btn = Kit.accent_btn(Kit.btn(tr("Continue ▶"), func(): _show(q + 1), Kit.T_ACTION, 260), Kit.C_GOLD)
	main_btn.custom_minimum_size.y = Kit.BTN_H + 8
	bar.add_child(main_btn)
	_fill_question(Q[0], r)
	_fill_board(r)
	if not room.can_edit(STEP.role):
		left_box.modulate.a = 0.6
		for c in left_box.find_children("*", "Control", true, false):
			if c is Button:
				c.disabled = true
			elif c is PanelContainer:
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _first_of(stage: int) -> int:
	for i in QUESTIONS.size():
		if QUESTIONS[i][2] == stage:
			return i
	return 0


func _say(title: String, text: String) -> void:
	if info_body and is_instance_valid(info_body):
		info_body.text = (title + "\n" if title != "" else "") + text


## After a choice: approvals are void, the craft is rebuilt (unless rebuild_3d is false), and the screen goes on to
## the next question (advance) or stays on this one.
func on_change(rebuild_3d := true, advance := false) -> void:
	GameState.room.design_edited(QUESTIONS[q][1])
	if rebuild_3d:
		world.rebuild_ship()
	GameState.changed.emit()
	_show(q + 1 if advance else q)


# ===================================================================================== TILES
## One option: its drawing, its name, two facts and a mark (the best fit, enough, too little). Pointing at it tells
## the rest. dim: it cannot be chosen here.
func _tile(kind: String, title: String, facts: Array, chosen: bool, on_click: Callable, more: String, mark := "", mark_col := Kit.C_DIM, dim := false) -> Control:
	var pc := PanelContainer.new()
	var sb := Kit.flat(Kit.C_CARD_SEL if chosen else Kit.C_CARD, Kit.C_GOLD if chosen else Kit.C_LINE, 12, 2 if chosen else 1, 12, 9)
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var h := Kit.hbox(12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(h)
	var icon := PartIcon.new()
	icon.kind = kind
	icon.k = 0.75
	h.add_child(icon)
	var v := Kit.vbox(5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(Kit.lbl(("● " if chosen else "") + title, Kit.T_BODY + 1, Kit.C_TEXT, Kit.FONT_B, true))
	var chips := HFlowContainer.new()
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	v.add_child(chips)
	for i in facts.size():
		chips.add_child(Kit.chip(str(facts[i]), Kit.C_GOLD if i == 0 else Kit.C_ACCENT))
	if mark != "":
		chips.add_child(Kit.chip(mark, mark_col))
	if dim:
		pc.modulate.a = 0.5
	pc.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Kit.UiSound.play("click")
			on_click.call())
	pc.mouse_entered.connect(func():
		sb.border_color = Kit.C_GOLD
		_say(title, more))
	pc.mouse_exited.connect(func(): sb.border_color = Kit.C_GOLD if chosen else Kit.C_LINE)
	return pc


## The mark of an option that is enough or not; `best` is the cheapest one that is enough.
func _fit(ok: bool, best: bool, short_word: String) -> Array:
	if not _guided():   # past the first mission the choice is the player's: only what falls short is said
		return ["", Kit.C_DIM] if ok else [short_word, Kit.C_WARN]
	if best:
		return ["★ " + tr("Best fit"), Kit.C_OK]
	return [tr("Enough"), Kit.C_DIM] if ok else [short_word, Kit.C_WARN]


## The first mission (and the guided one) point at the best fit; from the second on the player decides alone.
func _guided() -> bool:
	return mission.scenario == Progress.ORDER[0] or main.has_node("Coach")


## The id of the cheapest option of `table` for which enough.call(entry) is true ("" if none); cost by `cost_key`.
func _best(table: Dictionary, enough: Callable, cost_key: String) -> String:
	var best := ""
	for id in table:
		if enough.call(table[id]) and (best == "" or float(table[id][cost_key]) < float(table[best][cost_key])):
			best = id
	return best


# ===================================================================================== QUESTIONS
func _fill_question(id: String, r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var O: Dictionary = GameData.ORBITS[mission.orbit]
	match id:
		"orbit":
			var top := 0.0
			for o in GameData.ORBITS:
				top = maxf(top, S.orbit_mult.get(o, 0.0))
			for o in GameData.ORBITS:
				var OO: Dictionary = GameData.ORBITS[o]
				var m: float = S.orbit_mult.get(o, 0.0)
				if m <= 0.0 and mission.orbit != o:
					continue   # an orbit that cannot serve this goal is not offered
				left_box.add_child(_tile("orbit", OO.name, [tr("science ×%.1f") % m, tr("%d m/s to get there") % int(OO.insert_dv)], mission.orbit == o, func():
					mission.orbit = o
					world.stage_design()
					on_change(false, true), OO.desc + "\n" + tr("Shadow %s per lap · Contact %s per day · Δv to get there %d m/s") % [Kit.mins(OO.eclipse_min), Kit.mins(OO.contact_min), int(OO.insert_dv)],
					"★ " + tr("Best fit") if m >= top and _guided() else "", Kit.C_OK))
		"bus":
			for b in GameData.BUSES:
				var B: Dictionary = GameData.BUSES[b]
				left_box.add_child(_tile("bus", B.name, [Kit.money(B.cost), tr("%d instrument(s)") % B.slots], mission.bus == b, func(): mission.bus = b; on_change(true, true),
					B.desc + "\n" + tr("Max load %s · %d slot(s) · instruments up to “%s” · %s") % [Kit.kg(B.max), B.slots, GameData.SIZE_NAMES[B.max_size], Kit.money(B.cost)]))
		"instruments":
			var B: Dictionary = GameData.BUSES[mission.bus]
			var over: bool = mission.instruments.size() > B.slots
			left_box.add_child(Kit.lbl(tr("%d of %d places used") % [mission.instruments.size(), B.slots], Kit.T_BODY, Kit.C_BAD if over else Kit.C_TEXT, Kit.FONT_B))
			for n in r.needs:
				left_box.add_child(Kit.lbl(("✓ " if n.ok else "○ ") + n.label, Kit.T_SMALL + 1, Kit.C_OK if n.ok else Kit.C_WARN, Kit.FONT_B, true))
			var default_rel: float = S.get("default_relevance", 0.1)
			var hidden := 0
			for i in GameData.INSTRUMENTS:
				var I: Dictionary = GameData.INSTRUMENTS[i]
				var rel := 0.0
				for t in I.tags:
					rel = max(rel, S.relevance.get(t, default_rel))
				if S.relevance.is_empty():
					rel = default_rel
				var fits: bool = I.size <= B.max_size
				var has: bool = mission.instruments.has(i)
				# only what helps here and fits this body, unless the player asks for all of them
				# (a key instrument that needs a bigger body stays in view, dimmed, so the player learns why)
				if not has and not show_all and not S.relevance.is_empty() and (rel < 0.5 or (not fits and rel < 0.95)):
					hidden += 1
					continue
				var mark := "★ " + tr("Key") if rel >= 0.95 else (tr("Useful") if rel >= 0.5 else tr("Minor use"))
				if not fits:
					mark = tr("Needs a bigger body")
				left_box.add_child(_tile("camera", I.name, [Kit.money(I.cost), Kit.kg(I.mass)], has, func():
					if not has and not fits:
						toast(tr("%s doesn't fit on %s") % [I.name, B.name], Kit.C_BAD)
						return
					mission.toggle_instrument(i)
					on_change(), I.desc + "\n" + tr("%s · %s · %s per day · %s · %s pointing") % [Kit.kg(I.mass), Kit.watts(I.power), Kit.gb(I.data), Kit.money(I.cost), [tr("free"), tr("coarse"), tr("fine"), tr("precise")][I.pointing]],
					mark, Kit.C_OK if rel >= 0.95 and fits else (Kit.C_WARN if not fits else Kit.C_DIM), not fits))
			if hidden > 0 or show_all:
				var more := Kit.btn(tr("Show the useful ones only") if show_all else tr("Show all %d instruments") % GameData.INSTRUMENTS.size(), func():
					show_all = not show_all
					_show(q), Kit.T_SMALL)
				more.flat = true
				left_box.add_child(more)
		"panels":
			var need: float = r.power_load * 1.15 / maxf(0.01, 1.0 - O.eclipse_frac)
			left_box.add_child(Kit.lbl(tr("Your craft needs %s of panels.") % Kit.watts(need), Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B, true))
			var best := _best(GameData.PANELS, func(P): return P.power >= need, "cost")
			for p in GameData.PANELS:
				var P: Dictionary = GameData.PANELS[p]
				var f: Array = _fit(P.power >= need, p == best, tr("Too little"))
				left_box.add_child(_tile("panel", P.name, [Kit.money(P.cost), Kit.watts(P.power)], mission.panels == p, func(): mission.panels = p; on_change(true, true),
					P.desc + "\n" + tr("%s in sunlight · %s · %s") % [Kit.watts(P.power), Kit.kg(P.mass), Kit.money(P.cost)], f[0], f[1]))
		"battery":
			left_box.add_child(Kit.lbl(tr("In the shadow it needs %.0f Wh.") % r.battery_need, Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B, true))
			var best := _best(GameData.BATTERIES, func(BT): return BT.wh * 0.6 >= r.battery_need, "cost")
			for b in GameData.BATTERIES:
				var BT: Dictionary = GameData.BATTERIES[b]
				var ok: bool = BT.wh * 0.6 >= r.battery_need
				var f: Array = _fit(ok, b == best, tr("Falls short"))
				left_box.add_child(_tile("battery", BT.name, [Kit.money(BT.cost), "%d Wh" % int(BT.wh)], mission.battery == b, func(): mission.battery = b; on_change(true, true),
					BT.desc + "\n" + "%s · %s" % [Kit.kg(BT.mass), Kit.money(BT.cost)] + " · " + tr("Only 60 % of a battery is used, so it lasts many cycles."), f[0], f[1]))
		"comms":
			left_box.add_child(Kit.lbl(tr("Your instruments make %s per day.") % Kit.gb(r.data_gen), Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B, true))
			var down := func(C: Dictionary) -> float: return C.rate * O.comm_factor * O.contact_min * 60.0 / 8.0 / 1000.0
			var best := _best(GameData.COMMS, func(C): return down.call(C) >= r.data_gen, "cost")
			for c in GameData.COMMS:
				var C: Dictionary = GameData.COMMS[c]
				var d: float = down.call(C)
				var f: Array = _fit(d >= r.data_gen, c == best, tr("Too slow"))
				left_box.add_child(_tile("antenna", C.name, [Kit.money(C.cost), tr("sends %s a day") % Kit.gb(d)], mission.comms == c, func(): mission.comms = c; on_change(true, true),
					C.desc + "\n" + tr("Sends %s per day · %s · %s · %s") % [Kit.gb(d), Kit.kg(C.mass), Kit.watts(C.power), Kit.money(C.cost)], f[0], f[1]))
		"adcs":
			var best := _best(GameData.ADCS, func(A): return A.level >= r.pointing_need, "cost_pct")
			for a in GameData.ADCS:
				var A: Dictionary = GameData.ADCS[a]
				var f: Array = _fit(A.level >= r.pointing_need, a == best, tr("Too coarse"))
				left_box.add_child(_tile("wheel", A.name, [tr("+%s cost") % Kit.pct(A.cost_pct), [tr("coarse"), tr("coarse"), tr("fine"), tr("precise")][clampi(A.level, 0, 3)]], mission.adcs == a, func(): mission.adcs = a; on_change(true, true),
					A.desc + "\n" + tr("Your instruments need pointing level %d.") % r.pointing_need + " " + tr("Level %d · %s of the platform's cost") % [A.level, Kit.pct(A.cost_pct)], f[0], f[1]))
		"propulsion":
			left_box.add_child(Kit.lbl(tr("It needs %d m/s for this orbit and %d years.") % [int(r.dv_need), mission.years], Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B, true))
			var best := _best(GameData.PROPULSION, func(PR): return PR.dv >= r.dv_need, "mass_pct")
			for p in GameData.PROPULSION:
				var PR: Dictionary = GameData.PROPULSION[p]
				var f: Array = _fit(PR.dv >= r.dv_need, p == best, tr("Too little"))
				left_box.add_child(_tile("none" if PR.dv <= 0.0 else "thruster", PR.name, [tr("+%s mass") % Kit.pct(PR.mass_pct), "%d m/s" % int(PR.dv)], mission.propulsion == p, func(): mission.propulsion = p; on_change(true, true),
					PR.desc + "\n" + tr("Δv %d m/s · fuel ≈ %s of the mass") % [int(PR.dv), Kit.pct(PR.mass_pct)], f[0], f[1]))
		"launcher":
			left_box.add_child(Kit.lbl(tr("Your craft weighs %s and goes to %s.") % [Kit.kg(r.mass_total), O.short], Kit.T_BODY, Kit.C_TEXT, Kit.FONT_B, true))
			left_box.add_child(_tile("rocket", tr("Build your own rocket"), [tr("part by part")], false, func(): go("builder", {"back_step": step_idx}),
				tr("Put a rocket together from real parts, from the engines up, and see if it can lift your craft.")))
			if RocketDesign.current != null:
				var CL: Dictionary = RocketDesign.current.launcher_info()
				var ccap: float = CL.cap[mission.orbit]
				var cok: bool = ccap >= r.mass_total and ccap > 0.0
				left_box.add_child(_tile("rocket", tr(CL.name), [Kit.money(CL.cost), tr("lifts %s") % Kit.kg(ccap)], mission.launcher == RocketDesign.CUSTOM, func(): mission.launcher = RocketDesign.CUSTOM; on_change(false, true),
					tr(CL.desc), tr("Fits") if cok else (tr("Can't reach") if ccap <= 0.0 else tr("Too heavy")), Kit.C_OK if cok else Kit.C_WARN, ccap <= 0.0))
			var cost_of := func(L: Dictionary) -> float: return max(L.min_cost, L.cost + L.cost_per_kg * r.mass_total)
			var best := ""
			for l in GameData.LAUNCHERS:
				var L: Dictionary = GameData.LAUNCHERS[l]
				if L.cap[mission.orbit] >= r.mass_total and (best == "" or cost_of.call(L) < cost_of.call(GameData.LAUNCHERS[best])):
					best = l
			for l in GameData.LAUNCHERS:
				var L: Dictionary = GameData.LAUNCHERS[l]
				var cap: float = L.cap[mission.orbit]
				if cap <= 0.0 and mission.launcher != l:
					continue   # a rocket that cannot reach this orbit is not offered
				var f: Array = _fit(cap >= r.mass_total, l == best, tr("Too heavy"))
				left_box.add_child(_tile("rocket", L.name, [Kit.money(cost_of.call(L)), tr("lifts %s") % Kit.kg(cap)], mission.launcher == l, func(): mission.launcher = l; on_change(false, true),
					L.desc + "\n" + tr("Up to %s to %s · %s · reliability %s") % [Kit.kg(cap), O.short, Kit.money(cost_of.call(L)), Kit.pct(1.0 - L.fail)], f[0], f[1]))
		"review":
			_fill_review(r)


func _fill_review(r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var O: Dictionary = GameData.ORBITS[mission.orbit]
	var order := {"fatal": 0, "warn": 1, "ok": 2}
	var checks: Array = r.checks.duplicate()
	checks.sort_custom(func(a, b): return order[a.level] < order[b.level])
	var fine := 0
	for c in checks:
		if c.level == "ok":
			fine += 1
			continue
		var col: Color = Kit.C_BAD if c.level == "fatal" else Kit.C_WARN
		var pc := Kit.tile(col, 12, 8)
		pc.mouse_filter = Control.MOUSE_FILTER_STOP
		pc.add_child(Kit.lbl(("✗ " if c.level == "fatal" else "! ") + c.title, Kit.T_BODY, col, Kit.FONT_B, true))
		pc.mouse_entered.connect(func(): _say(c.title, c.detail))
		left_box.add_child(pc)
	if fine == checks.size():
		left_box.add_child(Kit.lbl("✓ " + tr("All systems go"), Kit.T_VALUE, Kit.C_OK, Kit.FONT_T))
	elif fine > 0:
		left_box.add_child(Kit.lbl("✓ " + tr("%d other things are fine") % fine, Kit.T_SMALL + 1, Kit.C_OK, Kit.FONT_B))
	# how long it works, and what protects it
	left_box.add_child(Kit.spacer(2))
	left_box.add_child(Kit.caps(tr("Years of work · at least %d") % S.min_years))
	var yh := Kit.segmented()
	left_box.add_child(yh)
	for y in YEARS:
		var b := Kit.choice(str(y), mission.years == y, func(): mission.years = y; on_change(false))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		yh.add_child(b)
	left_box.add_child(Kit.caps(tr("Extras")))
	left_box.add_child(_tile("spare", tr("Backup parts"), [tr("+20 % cost"), tr("+10 % mass")], mission.redundancy, func(): mission.redundancy = not mission.redundancy; on_change(),
		tr("Doubles critical components (computer, wheels). If something fails, the backup takes over.")))
	left_box.add_child(_tile("shield", tr("Radiation shielding"), [tr("+5 % cost"), tr("+4 % mass")], mission.shielding, func(): mission.shielding = not mission.shielding; on_change(),
		tr("Plates that shield the electronics from particles from the Sun and the radiation belts. Key far from Earth.")))
	_say("", tr("More years means more science, and more cost (%s per year) and fuel.") % Kit.money(O.ops * GameData.BUSES[mission.bus].ops_mult))
	# the crew's sign-off, when friends hold stations
	var room = GameState.room
	if GameState.team_mode:
		left_box.add_child(Kit.caps(tr("Crew sign-off")))
		for role in GameData.ROLE_ORDER:
			var R: Dictionary = GameData.ROLES[role]
			var ok: bool = r.goals[role]
			var pc := Kit.tile(R.color, 10.0, 8.0)
			var h := Kit.hbox(8)
			pc.add_child(h)
			var v := Kit.vbox(1)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(v)
			v.add_child(Kit.lbl(room.holder_name(role) + " · " + R.name, Kit.T_SMALL + 1, R.color, Kit.FONT_B, true))
			v.add_child(Kit.lbl(("✓ " if ok else "✗ ") + R.goal, Kit.T_SMALL, Kit.C_OK if ok else Kit.C_WARN, Kit.FONT_R, true))
			var approved: bool = GameState.approvals.get(role, false)
			var b := Kit.btn(tr("Approved ✓") if approved else (tr("Approve") if ok else tr("Approve anyway")), func():
				room.sign(role, not GameState.approvals.get(role, false))
				_show(q), Kit.T_SMALL)
			b.disabled = not room.can_edit(role) or room.is_bot(role)
			if approved:
				Kit.accent_btn(b, Kit.C_OK)
			h.add_child(b)
			left_box.add_child(pc)
		if not r.fatal and not GameState.crew_ready():
			left_box.add_child(Kit.lbl(tr("The whole crew still has to sign off."), Kit.T_SMALL + 1, Kit.C_WARN, Kit.FONT_B, true))


# ===================================================================================== THE MISSION BOARD
## Seven short answers: what the craft uses against what it has. Pointing at one tells the numbers behind it.
func _fill_board(r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	board.add_child(Kit.caps(tr("Mission board")))
	_row(tr("Budget"), tr("costs %s · you have %s") % [Kit.money(r.cost_total), Kit.money(r.budget)], r.cost_total / r.budget, 0.9,
		tr("Covers building, launch (%s) and operations for %d years (%s).") % [Kit.money(r.cost.launch), mission.years, Kit.money(r.cost.ops)] + " " + (tr("Reserve %s") % Kit.pct(r.reserve) if r.reserve >= 0.0 else tr("Over budget!")))
	_row(tr("Mass"), tr("weighs %s · limit %s") % [Kit.kg(r.mass_total), Kit.kg(r.mass_limit)], r.mass_total / max(0.001, r.mass_limit), 0.9,
		tr("Limit") + " · " + tr("platform %s · rocket %s") % [Kit.kg(r.mass_bus_max), Kit.kg(r.launch_cap) if r.launch_cap > 0.0 else tr("can't reach")] + ". " + tr("Instruments %s · power %s · fuel %s · platform %s.") % [Kit.kg(r.mass.instruments), Kit.kg(r.mass.power), Kit.kg(r.mass.propellant), Kit.kg(r.mass.bus)])
	_row(tr("Power"), tr("uses %s · makes %s") % [Kit.watts(r.power_load), Kit.watts(r.power_gen)], r.power_load / max(0.001, r.power_gen), 0.87,
		tr("Draw against the panels' average generation (counting shadow).") + " " + tr("Margin %s") % Kit.pct(r.power_margin), false, 3)
	_row(tr("Battery"), tr("needs %d Wh · holds %d Wh") % [int(r.battery_need), int(r.battery_wh)], r.battery_need / max(0.001, r.battery_wh), 0.85, tr("Energy needed to cross the shadow."), false, 4)
	_row(tr("Data"), tr("makes %s · sends %s a day") % [Kit.gb(r.data_gen), Kit.gb(r.data_down)], r.data_gen / max(0.0001, r.data_down), 0.9, tr("Data made against what the antenna can send down."), false, 5)
	_row(tr("Fuel"), tr("needs %d m/s · has %d m/s") % [int(r.dv_need), int(r.dv_have)], r.dv_need / max(0.001, r.dv_have) if r.dv_have > 0.0 else (0.0 if r.dv_need <= 0.0 else 2.0), 0.9, tr("Change of speed needed to get there and hold the orbit."), false, 7)
	var sf: float = r.expected_science / S.science_target
	_row(tr("Science"), tr("%d points · goal %d") % [int(r.expected_science), int(S.science_target)], sf, 0.0, tr("An estimate with no surprises."), true, 2)
	var nf := 0
	var nw := 0
	for c in r.checks:
		if c.level == "fatal":
			nf += 1
		elif c.level == "warn":
			nw += 1
	var facts := Kit.hbox(6)
	board.add_child(facts)
	if nf > 0:
		facts.add_child(Kit.chip("✗ " + tr("%d to fix") % nf, Kit.C_BAD))
	if nw > 0:
		facts.add_child(Kit.chip("! " + tr("%d warning(s)") % nw, Kit.C_WARN))
	if nf == 0 and nw == 0:
		facts.add_child(Kit.chip("✓ " + tr("Ready to fly"), Kit.C_OK))


## One answer of the board. frac = use / what there is; above 1 is red (too much: it cannot fly like this), above
## warn amber; more_is_better flips it. A row whose question (index from_q in QUESTIONS) has not been reached yet, or
## that nothing provides yet, is grey: not chosen, which is not a fault.
func _row(label: String, value: String, frac: float, warn: float, explain: String, more_is_better := false, from_q := -1) -> void:
	var state := 1
	if more_is_better:
		state = 1 if frac >= 0.8 else (0 if frac >= 0.4 else -1)
	elif frac > 1.0:
		state = -1
	elif frac > warn:
		state = 0
	var pending: bool = (from_q >= 0 and _reached < from_q) or (not more_is_better and frac >= 1.99) or (more_is_better and frac <= 0.0)
	var col: Color = Kit.C_OK if state > 0 else (Kit.C_WARN if state == 0 else Kit.C_BAD)
	var why := explain
	if pending:
		col = Kit.C_DIM
		value = tr("not chosen yet")
		why = tr("You have not chosen this yet: it comes in a later step.") + " " + explain
	elif state < 0 and not more_is_better:
		why = tr("Too much: %s over what you have") % Kit.pct(frac - 1.0) + ". " + explain
	var flagged: bool = state <= 0 and not pending
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.add_theme_stylebox_override("panel", Kit.flat(Color(col, 0.1) if state < 0 and not pending else Kit.C_CARD, Color(col, 0.45 if flagged else 0.0), 8, 1, 10, 5))
	var v := Kit.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var h := Kit.hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	h.add_child(Kit.lbl("○" if pending else ("✓" if state > 0 else ("!" if state == 0 else "✗")), Kit.T_LEAD, col, Kit.FONT_T))
	h.add_child(Kit.lbl(label, Kit.T_BODY, Kit.C_DIM if pending else Kit.C_TEXT, Kit.FONT_B))
	var val := Kit.lbl(value, Kit.T_SMALL, col if flagged else Kit.C_DIM)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(val)
	pc.mouse_entered.connect(func(): _say(label, why))
	board.add_child(pc)
