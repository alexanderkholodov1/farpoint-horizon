extends "res://scripts/screens/screen.gd"

const RocketDesign := preload("res://scripts/craft/rocket_design.gd")
const Bots := preload("res://scripts/crew/bots.gd")
## Design (CML 2-4): the eight steps of GameData.STEPS (orbit, platform, instruments, energy, communications, control
## and propulsion, launcher and lifetime, review), the mission dashboard on the right, and the "why it matters" box.
## args: {"step": index of GameData.STEPS} (default 0). Every change redraws the screen and refreshes the 3D craft.

var step_idx := 0
var info_title: Label
var info_text: Label
var dash_box: VBoxContainer
var step_box: VBoxContainer
var step_scroll: ScrollContainer


static var _arc_last := 0.0   ## Where the progress arc stood on the last step shown.

func enter(args: Dictionary) -> void:
	GameState.room.changed.connect(_on_room_changed)
	show_step(args.get("step", 0))


func exit() -> void:
	if GameState.room.changed.is_connected(_on_room_changed):
		GameState.room.changed.disconnect(_on_room_changed)


## Somebody else changed the room (a teammate online, or the host's bots): draw the step again.
func _on_room_changed(by_me: bool) -> void:
	if not by_me and is_inside_tree():
		show_step.call_deferred(step_idx)


## Draws the screen at step idx.
func show_step(idx: int) -> void:
	step_idx = idx
	GameState.room.enter_step(GameData.STEPS[idx].id)   # the bot that holds this step's station decides now
	clear()
	info_title = null
	info_text = null
	dash_box = null
	step_box = null
	if not world.stage or world.ship == null:
		world.stage_design()
	var r: Dictionary = mission.compute()
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var STEP: Dictionary = GameData.STEPS[idx]

	# ---------- top bar
	var top := Kit.panel_box(10)
	Kit.place(top, 0, 0, 1, 0, 12, 10, -12, 70)
	add_child(top)
	var th := Kit.hbox(6)
	top.add_child(th)
	var tl := Kit.vbox(0)
	tl.custom_minimum_size.x = 300
	th.add_child(tl)
	tl.add_child(Kit.lbl(S.name, 17, S.color, Kit.FONT_B))
	tl.add_child(Kit.lbl(GameData.CML_NAMES[STEP.cml], 13, Kit.C_DIM))
	var tabs := Kit.hbox(4)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	th.add_child(tabs)
	for i in GameData.STEPS.size():
		var st: Dictionary = GameData.STEPS[i]
		var b := Kit.btn("%d. %s" % [i + 1, st.title], func(): show_step(i), 14)
		if i == idx:
			Kit.accent_btn(b, GameData.ROLES[st.role].color)
		tabs.add_child(b)
	th.add_child(Kit.btn(tr("Menu"), func(): go("menu"), 14))
	# the brand's horizon arc as the progress line: it lights up step by step toward launch
	var arc := preload("res://scripts/ui/horizon.gd").new()
	arc.track = true
	arc.bulge = 0.0
	arc.thickness = 2.0
	arc.sun_at = 0.98
	Kit.place(arc, 0, 0, 1, 0, 26, 66, -26, 74)
	add_child(arc)
	var goal := float(idx + 1) / GameData.STEPS.size()
	arc.progress = _arc_last
	arc.create_tween().tween_property(arc, "progress", goal, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_arc_last = goal

	# ---------- left panel: the step's options
	var left := Kit.panel_box(14)
	Kit.place(left, 0, 0, 0, 1, 12, 80, 492, -12)
	add_child(left)
	var lv := Kit.vbox(8)
	left.add_child(lv)
	var R: Dictionary = GameData.ROLES[STEP.role]
	lv.add_child(Kit.lbl(STEP.title, 26, Kit.C_TEXT, Kit.FONT_T))
	var room = GameState.room
	var turn: String = (tr("%s (bot) · %s") if room.is_bot(STEP.role) else tr("%s decides · %s")) % [room.holder_name(STEP.role), R.name]
	lv.add_child(Kit.lbl(turn, 14, R.color, Kit.FONT_B))
	var said: Dictionary = room.state.bot_lines.get(STEP.id, {})
	if room.is_bot(STEP.role) and STEP.id != "revision":
		if said.has("line"):
			lv.add_child(Kit.lbl(room.holder_name(STEP.role) + ": " + Bots.say(said.line), 14, Kit.C_TEXT, Kit.FONT_R, true))
		lv.add_child(Kit.lbl(tr("A bot holds this station. Change anything you like, it will not mind."), 12, Kit.C_DIM, Kit.FONT_R, true))
	elif not room.can_edit(STEP.role):
		lv.add_child(Kit.lbl(tr("This is %s's station. You can watch their choices here.") % room.holder_name(STEP.role), 13, Kit.C_WARN, Kit.FONT_B, true))
	step_scroll = ScrollContainer.new()
	step_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	step_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(step_scroll)
	step_box = Kit.vbox(8)
	step_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_scroll.add_child(step_box)
	_fill_step(STEP.id, r)
	if not room.can_edit(STEP.role):
		step_box.modulate.a = 0.6
		for c in step_box.find_children("*", "Control", true, false):
			if c is Button:
				c.disabled = true
			elif c is PanelContainer:
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nav := Kit.hbox(8)
	lv.add_child(nav)
	var prev := Kit.btn(tr("◀ Previous"), func(): show_step(max(0, idx - 1)))
	prev.disabled = idx == 0
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(prev)
	if STEP.id == "revision":
		var go_btn := Kit.accent_btn(Kit.btn(tr("LAUNCH!"), func(): main.launch(), 18), Kit.C_OK)
		go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go_btn.disabled = not GameState.can_launch(r)
		nav.add_child(go_btn)
	else:
		var nx := Kit.accent_btn(Kit.btn(tr("Next ▶"), func(): show_step(idx + 1)), Kit.C_ACCENT)
		nx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(nx)

	# ---------- right panel: the mission dashboard
	var right := Kit.panel_box(14)
	Kit.place(right, 1, 0, 1, 1, -402, 80, -12, -12)
	add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	dash_box = Kit.vbox(7)
	dash_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(dash_box)
	_fill_dashboard(r)

	# ---------- bottom box: "why it matters"
	var info := Kit.panel_box(14)
	Kit.place(info, 0, 1, 1, 1, 504, -150, -414, -12)
	add_child(info)
	var iv := Kit.vbox(4)
	info.add_child(iv)
	info_title = Kit.lbl(tr("Why it matters"), 17, Kit.C_ACCENT, Kit.FONT_B, true)
	iv.add_child(info_title)
	info_text = Kit.lbl(tr("Hover an option to see what it is and how it affects the mission. Drag to turn the craft, scroll to zoom."), 14, Kit.C_DIM, Kit.FONT_R, true)
	iv.add_child(info_text)
	var dims_lbl := Kit.lbl(tr("Platform") + " · " + GameData.BUSES[mission.bus].name + "  ·  " + Kit.kg(r.mass_total), 14, Color(Kit.C_ON_DARK, 0.8), Kit.FONT_B)
	Kit.place(dims_lbl, 0, 0, 1, 0, 510, 84, -420, 110)
	dims_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(dims_lbl)


## After a choice: approvals are void, the craft is rebuilt (unless rebuild_3d is false), the screen redrawn.
func on_change(rebuild_3d := true) -> void:
	GameState.room.design_edited(GameData.STEPS[step_idx].id)
	if rebuild_3d:
		world.rebuild_ship()
	GameState.changed.emit()
	var scroll_v := step_scroll.scroll_vertical if step_scroll else 0
	show_step(step_idx)
	await get_tree().process_frame
	if step_scroll:
		step_scroll.scroll_vertical = scroll_v


func set_info(title: String, text: String) -> void:
	if info_title and is_instance_valid(info_title):
		info_title.text = title
		info_text.text = text


## A step option: Kit.card that shows its explanation in the "why it matters" box on hover.
func card(title: String, body: String, selected: bool, on_click: Callable, info_body := "", badge := "", badge_col := Kit.C_DIM, dimmed := false) -> PanelContainer:
	return Kit.card(title, body, selected, on_click, info_body, badge, badge_col, dimmed, set_info)


func section(text: String, hint := "") -> void:
	step_box.add_child(Kit.spacer(4))
	step_box.add_child(Kit.lbl(text, 15, Kit.C_ACCENT, Kit.FONT_B))
	if hint != "":
		step_box.add_child(Kit.lbl(hint, 13, Kit.C_DIM, Kit.FONT_R, true))


# ===================================================================================== STEPS
func _fill_step(id: String, r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	match id:
		"orbita":
			step_box.add_child(Kit.lbl(tr("The orbit decides what you see, how long you talk to Earth, how much shadow you get and how much energy it takes to get there."), 14, Kit.C_DIM, Kit.FONT_R, true))
			for o in GameData.ORBITS:
				var O: Dictionary = GameData.ORBITS[o]
				var m: float = S.orbit_mult.get(o, 0.0)
				var badge := tr("×%.1f science") % m
				var bc := Kit.C_OK if m >= 1.1 else (Kit.C_WARN if m >= 0.7 else Kit.C_BAD)
				if m <= 0.0:
					badge = tr("Not for this goal")
				var body := tr("Shadow %s per lap · Contact %s per day · Δv to get there %d m/s") % [Kit.mins(O.eclipse_min), Kit.mins(O.contact_min), int(O.insert_dv)]
				step_box.add_child(card(O.name, body, mission.orbit == o, func():
					mission.orbit = o
					world.stage_design()
					on_change(false), O.desc + "\n\n" + (tr("This orbit can't serve your goal.") if m <= 0.0 else tr("For your goal, science ×%.1f.") % m), badge, bc, m <= 0.0))
		"plataforma":
			step_box.add_child(Kit.lbl(tr("The platform (bus) is the chassis, with the structure, computer and room for instruments. Bigger means more capacity, but also pricier and heavier."), 14, Kit.C_DIM, Kit.FONT_R, true))
			for b in GameData.BUSES:
				var B: Dictionary = GameData.BUSES[b]
				var body := tr("Max load %s · %d slot(s) · instruments up to “%s” · %s") % [Kit.kg(B.max), B.slots, GameData.SIZE_NAMES[B.max_size], Kit.money(B.cost)]
				step_box.add_child(card(B.name, body, mission.bus == b, func(): mission.bus = b; on_change(), B.desc + tr("\n\nEmpty mass %s · base power draw %s.") % [Kit.kg(B.dry), Kit.watts(B.base_power)]))
		"instrumentos":
			var B: Dictionary = GameData.BUSES[mission.bus]
			step_box.add_child(Kit.lbl(tr("Slots used %d of %d on %s") % [mission.instruments.size(), B.slots, B.name], 15, Kit.C_WARN if mission.instruments.size() <= B.slots else Kit.C_BAD, Kit.FONT_B))
			for n in r.needs:
				step_box.add_child(Kit.lbl(("✓ " if n.ok else "✗ ") + n.label, 14, Kit.C_OK if n.ok else Kit.C_BAD, Kit.FONT_B, true))
			var default_rel: float = S.get("default_relevance", 0.1)
			for i in GameData.INSTRUMENTS:
				var I: Dictionary = GameData.INSTRUMENTS[i]
				var rel := 0.0
				for t in I.tags:
					rel = max(rel, S.relevance.get(t, default_rel))
				if S.relevance.is_empty():
					rel = default_rel
				var badge := tr("★ Key") if rel >= 0.95 else (tr("Useful") if rel >= 0.5 else tr("Minor use"))
				var bc := Kit.C_OK if rel >= 0.95 else (Kit.C_WARN if rel >= 0.5 else Kit.C_DIM)
				var fits: bool = I.size <= B.max_size
				var body := tr("%s · %s · %s per day · %s · %s pointing") % [Kit.kg(I.mass), Kit.watts(I.power), Kit.gb(I.data), Kit.money(I.cost), [tr("free"), tr("coarse"), tr("fine"), tr("precise")][I.pointing]]
				if not fits:
					body = tr("Needs a “%s” platform\n") % GameData.SIZE_NAMES[I.size] + body
				step_box.add_child(card(I.name, body, mission.instruments.has(i), func():
					if not mission.instruments.has(i) and not fits:
						toast(tr("%s doesn't fit on %s") % [I.name, B.name], Kit.C_BAD)
						return
					mission.toggle_instrument(i)
					on_change(), I.desc + tr("\n\nBase science %d points per month · Relevance for your goal %d %%.") % [int(I.sci), int(rel * 100)], badge, bc, not fits))
		"energia":
			step_box.add_child(Kit.lbl(tr("Total draw %s · Average generation %s (panels make nothing in shadow, %d %% of the time).") % [Kit.watts(r.power_load), Kit.watts(r.power_gen), int(GameData.ORBITS[mission.orbit].eclipse_frac * 100)], 14, Kit.C_DIM, Kit.FONT_R, true))
			section(tr("Solar panels"), tr("You need at least %s of panels (with a 15 %% margin).") % Kit.watts(r.power_load * 1.15 / max(0.01, 1.0 - GameData.ORBITS[mission.orbit].eclipse_frac)))
			for p in GameData.PANELS:
				var P: Dictionary = GameData.PANELS[p]
				step_box.add_child(card(P.name, tr("%s in sunlight · %s · %s") % [Kit.watts(P.power), Kit.kg(P.mass), Kit.money(P.cost)], mission.panels == p, func(): mission.panels = p; on_change(), P.desc))
			section(tr("Battery"), tr("In shadow you need ~%.0f Wh (using only 60 %% of the battery so it lasts many cycles).") % r.battery_need)
			for b in GameData.BATTERIES:
				var BT: Dictionary = GameData.BATTERIES[b]
				var ok: bool = BT.wh >= r.battery_need
				step_box.add_child(card(BT.name, "%s · %s" % [Kit.kg(BT.mass), Kit.money(BT.cost)], mission.battery == b, func(): mission.battery = b; on_change(), BT.desc, tr("Covers it") if ok else tr("Falls short"), Kit.C_OK if ok else Kit.C_WARN))
		"comunicaciones":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			step_box.add_child(Kit.lbl(tr("Your instruments make %s per day. From %s there is %s of contact per day, and distance cuts the signal to %s of the nominal rate.") % [Kit.gb(r.data_gen), O.short, Kit.mins(O.contact_min), Kit.pct(O.comm_factor)], 14, Kit.C_DIM, Kit.FONT_R, true))
			for c in GameData.COMMS:
				var C: Dictionary = GameData.COMMS[c]
				var down: float = C.rate * O.comm_factor * O.contact_min * 60.0 / 8.0 / 1000.0
				var ok: bool = down >= r.data_gen
				step_box.add_child(card(C.name, tr("Sends %s per day · %s · %s · %s") % [Kit.gb(down), Kit.kg(C.mass), Kit.watts(C.power), Kit.money(C.cost)], mission.comms == c, func(): mission.comms = c; on_change(), C.desc, tr("Enough") if ok else tr("Too slow"), Kit.C_OK if ok else Kit.C_WARN))
		"control":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			section(tr("Attitude control (pointing)"), tr("Your instruments need pointing level %d.") % r.pointing_need)
			for a in GameData.ADCS:
				var A: Dictionary = GameData.ADCS[a]
				var ok: bool = A.level >= r.pointing_need
				step_box.add_child(card(A.name, tr("Level %d · %s of the platform's cost") % [A.level, Kit.pct(A.cost_pct)], mission.adcs == a, func(): mission.adcs = a; on_change(), A.desc, tr("Enough") if ok else tr("Too coarse"), Kit.C_OK if ok else Kit.C_WARN))
			section(tr("Propulsion"), tr("For %s you need %d m/s to get there plus %d m/s per year to hold the orbit (%d years = %d m/s).") % [O.short, int(O.insert_dv), int(O.maint_dv), mission.years, int(r.dv_need)])
			for p in GameData.PROPULSION:
				var PR: Dictionary = GameData.PROPULSION[p]
				var ok: bool = PR.dv >= r.dv_need
				step_box.add_child(card(PR.name, tr("Δv %d m/s · fuel ≈ %s of the mass") % [int(PR.dv), Kit.pct(PR.mass_pct)], mission.propulsion == p, func(): mission.propulsion = p; on_change(), PR.desc, tr("Enough") if ok else tr("Too little"), Kit.C_OK if ok else Kit.C_WARN))
			section(tr("Protection"), tr("They cost mass and money, but cut the risks during operations."))
			step_box.add_child(card(tr("Redundancy (backup parts)"), tr("+10 % mass · +20 % hardware cost"), mission.redundancy, func(): mission.redundancy = not mission.redundancy; on_change(), tr("Doubles critical components (computer, wheels). If something fails, the backup takes over.")))
			step_box.add_child(card(tr("Radiation shielding"), tr("+4 % mass · +5 % hardware cost"), mission.shielding, func(): mission.shielding = not mission.shielding; on_change(), tr("Plates that shield the electronics from particles from the Sun and the radiation belts. Key far from Earth.")))
		"lanzador":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			step_box.add_child(Kit.lbl(tr("Your craft weighs %s and is headed to %s. The farther the destination, the less a rocket can carry.") % [Kit.kg(r.mass_total), O.short], 14, Kit.C_DIM, Kit.FONT_R, true))
			var build_btn := Kit.accent_btn(Kit.btn(tr("Build your own rocket, part by part ▶"), func(): go("builder", {"back_step": step_idx}), 15), Kit.C_WARN)
			step_box.add_child(build_btn)
			if RocketDesign.current != null:
				var CL: Dictionary = RocketDesign.current.launcher_info()
				var ccap: float = CL.cap[mission.orbit]
				var cok: bool = ccap >= r.mass_total and ccap > 0.0
				var cbadge := tr("Can't reach") if ccap <= 0.0 else (tr("Fits") if cok else tr("Too heavy"))
				step_box.add_child(card(tr(CL.name), tr("Up to %s to %s · %s · reliability %s") % [Kit.kg(ccap), O.short, Kit.money(CL.cost), Kit.pct(1.0 - CL.fail)], mission.launcher == RocketDesign.CUSTOM, func(): mission.launcher = RocketDesign.CUSTOM; on_change(), tr(CL.desc), cbadge, Kit.C_OK if cok else Kit.C_BAD, ccap <= 0.0))
			for l in GameData.LAUNCHERS:
				var L: Dictionary = GameData.LAUNCHERS[l]
				var cap: float = L.cap[mission.orbit]
				var cost: float = max(L.min_cost, L.cost + L.cost_per_kg * r.mass_total)
				var ok: bool = cap >= r.mass_total
				var badge := tr("Can't reach") if cap <= 0.0 else (tr("Fits") if ok else tr("Too heavy"))
				step_box.add_child(card(L.name, tr("Up to %s to %s · %s · reliability %s") % [Kit.kg(cap), O.short, Kit.money(cost), Kit.pct(1.0 - L.fail)], mission.launcher == l, func(): mission.launcher = l; on_change(), L.desc, badge, Kit.C_OK if ok else Kit.C_BAD, cap <= 0.0))
			section(tr("Design life"), tr("More years means more science, but also more operating cost (%s per year) and more fuel.") % Kit.money(O.ops * GameData.BUSES[mission.bus].ops_mult))
			var yh := HFlowContainer.new()
			yh.add_theme_constant_override("h_separation", 6)
			yh.add_theme_constant_override("v_separation", 6)
			step_box.add_child(yh)
			for y in [1, 2, 3, 4, 5, 7, 10]:
				var b := Kit.btn((tr("%d year") if y == 1 else tr("%d years")) % y, func(): mission.years = y; on_change(false), 14)
				if mission.years == y:
					Kit.accent_btn(b, Kit.C_WARN)
				yh.add_child(b)
			step_box.add_child(Kit.lbl(tr("The goal asks for at least %d year(s) of operation.") % S.min_years, 13, Kit.C_DIM))
		"revision":
			_fill_review(r)


func _fill_review(r: Dictionary) -> void:
	var team_mode: bool = GameState.team_mode
	step_box.add_child(Kit.lbl(tr("Design review (CML 4) is how NASA engineers check that a mission is ready. Red blocks the launch, yellow will have consequences."), 14, Kit.C_DIM, Kit.FONT_R, true))
	var order := {"fatal": 0, "warn": 1, "ok": 2}
	var checks: Array = r.checks.duplicate()
	checks.sort_custom(func(a, b): return order[a.level] < order[b.level])
	for c in checks:
		var col: Color = Kit.C_BAD if c.level == "fatal" else (Kit.C_WARN if c.level == "warn" else Kit.C_OK)
		var icon: String = "✗ " if c.level == "fatal" else ("⚠ " if c.level == "warn" else "✓ ")
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Kit.flat(Color(col.r, col.g, col.b, 0.08), Color(col.r, col.g, col.b, 0.5), 6, 1, 10, 7))
		var v := Kit.vbox(2)
		pc.add_child(v)
		v.add_child(Kit.lbl(icon + c.title, 15, col, Kit.FONT_B, true))
		v.add_child(Kit.lbl(c.detail, 13, Kit.C_DIM, Kit.FONT_R, true))
		step_box.add_child(pc)
	var room = GameState.room
	section(tr("Crew sign-off"), tr("Every station checks its goal and signs off. If anyone changes the design, the sign-offs start over.") if team_mode else tr("The bots sign off by themselves. Your own sign-off is the launch button."))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		var pc := Kit.tile(R.color, 10.0, 8.0)
		var h := Kit.hbox(8)
		pc.add_child(h)
		var v := Kit.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(Kit.lbl(room.holder_name(role) + " · " + R.name, 14, R.color, Kit.FONT_B, true))
		v.add_child(Kit.lbl(("✓ " if ok else "✗ ") + R.goal, 13, Kit.C_OK if ok else Kit.C_WARN, Kit.FONT_R, true))
		var approved: bool = GameState.approvals.get(role, false)
		var said: Dictionary = room.state.bot_lines.get("revision_" + role, {})
		if room.is_bot(role) and said.has("line"):
			v.add_child(Kit.lbl(Bots.say(said.line), 13, Kit.C_TEXT, Kit.FONT_R, true))
		var b := Kit.btn(tr("Approved ✓") if approved else (tr("Approve") if ok else tr("Approve anyway")), func():
			room.sign(role, not GameState.approvals.get(role, false))
			show_step(step_idx), 13)
		b.disabled = not room.can_edit(role) or room.is_bot(role)
		if approved:
			Kit.accent_btn(b, Kit.C_OK)
		h.add_child(b)
		step_box.add_child(pc)
	if r.fatal:
		step_box.add_child(Kit.lbl(tr("Fix the red items to launch."), 14, Kit.C_BAD, Kit.FONT_B, true))
	elif not GameState.crew_ready():
		step_box.add_child(Kit.lbl(tr("The whole crew still has to sign off."), 14, Kit.C_WARN, Kit.FONT_B, true))


# ===================================================================================== DASHBOARD
func _fill_dashboard(r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	dash_box.add_child(Kit.lbl(tr("Mission board"), 20, Kit.C_TEXT, Kit.FONT_T))
	_bar(tr("Budget"), tr("%s of %s") % [Kit.money(r.cost_total), Kit.money(r.budget)], r.cost_total / r.budget, 0.9, 1.0,
		tr("Reserve %s") % Kit.pct(r.reserve) if r.reserve >= 0.0 else tr("Over budget!"), tr("Covers building, launch (%s) and operations for %d years (%s).") % [Kit.money(r.cost.launch), mission.years, Kit.money(r.cost.ops)])
	var lim_txt := tr("platform %s · rocket %s") % [Kit.kg(r.mass_bus_max), Kit.kg(r.launch_cap) if r.launch_cap > 0.0 else tr("can't reach")]
	_bar(tr("Mass"), tr("%s of %s") % [Kit.kg(r.mass_total), Kit.kg(r.mass_limit)], r.mass_total / max(0.001, r.mass_limit), 0.9, 1.0, tr("Limit") + " · " + lim_txt,
		tr("Instruments %s · power %s · fuel %s · platform %s.") % [Kit.kg(r.mass.instruments), Kit.kg(r.mass.power), Kit.kg(r.mass.propellant), Kit.kg(r.mass.bus)])
	_bar(tr("Power"), tr("%s of %s") % [Kit.watts(r.power_load), Kit.watts(r.power_gen)], r.power_load / max(0.001, r.power_gen), 0.87, 1.0,
		tr("Margin %s") % Kit.pct(r.power_margin), tr("Draw against the panels' average generation (counting shadow)."))
	_bar(tr("Battery (eclipse)"), tr("%.0f of %.0f Wh") % [r.battery_need, r.battery_wh], r.battery_need / max(0.001, r.battery_wh), 0.85, 1.0,
		"", tr("Energy needed to cross the shadow."))
	_bar(tr("Data"), tr("%s of %s per day") % [Kit.gb(r.data_gen), Kit.gb(r.data_down)], r.data_gen / max(0.0001, r.data_down), 0.9, 1.0,
		"", tr("Data made against what the antenna can send down."))
	_bar(tr("Delta-v (propulsion)"), tr("%d of %d m/s") % [int(r.dv_need), int(r.dv_have)], r.dv_need / max(0.001, r.dv_have) if r.dv_have > 0.0 else (0.0 if r.dv_need <= 0.0 else 2.0), 0.9, 1.0,
		"", tr("Change of speed needed to get there and hold the orbit."))
	var life_txt := tr("%.1f years") % r.life_years if r.life_years < 100.0 else tr("> 100 years")
	_bar(tr("Lifetime"), tr("%s (design %d)") % [life_txt, mission.years], float(mission.years) / max(0.001, r.life_years), 0.95, 1.0, "", tr("How long it can last with this orbit and fuel."))
	var sf: float = r.expected_science / S.science_target
	_bar(tr("Expected science"), tr("%d of %d pts") % [int(r.expected_science), int(S.science_target)], sf, 0.0, 0.0, "", tr("An estimate with no surprises."), true)
	dash_box.add_child(Kit.spacer(4))
	dash_box.add_child(Kit.lbl(tr("Science goals"), 15, Kit.C_ACCENT, Kit.FONT_B))
	if r.needs.is_empty():
		dash_box.add_child(Kit.lbl(tr("Free mode, with no required goals."), 13, Kit.C_DIM, Kit.FONT_R, true))
	for n in r.needs:
		dash_box.add_child(Kit.lbl(("✓ " if n.ok else "✗ ") + n.label, 13, Kit.C_OK if n.ok else Kit.C_BAD, Kit.FONT_R, true))
	dash_box.add_child(Kit.spacer(4))
	dash_box.add_child(Kit.lbl(tr("Team goals"), 15, Kit.C_ACCENT, Kit.FONT_B))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		dash_box.add_child(Kit.lbl(("✓ " if ok else "○ ") + R.name, 13, Kit.C_OK if ok else Kit.C_DIM, Kit.FONT_R, true))
	var nf := 0
	var nw := 0
	for c in r.checks:
		if c.level == "fatal":
			nf += 1
		elif c.level == "warn":
			nw += 1
	dash_box.add_child(Kit.spacer(4))
	if nf > 0:
		dash_box.add_child(Kit.lbl(tr("✗ %d problem(s) block the launch") % nf, 14, Kit.C_BAD, Kit.FONT_B, true))
	if nw > 0:
		dash_box.add_child(Kit.lbl(tr("⚠ %d warning(s)") % nw, 14, Kit.C_WARN, Kit.FONT_B, true))


## A dashboard row. frac = use/limit. Green < warn <= yellow < bad <= red. higher_better inverts the colors.
func _bar(nm: String, value: String, frac: float, warn: float, bad: float, sub: String, info: String, higher_better := false) -> void:
	var v := Kit.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	var h := Kit.hbox(4)
	v.add_child(h)
	var n := Kit.lbl(nm, 14, Kit.C_TEXT, Kit.FONT_B)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(Kit.lbl(value, 13, Kit.C_DIM))
	var col := Kit.C_OK
	if higher_better:
		col = Kit.C_OK if frac >= 0.8 else (Kit.C_WARN if frac >= 0.4 else Kit.C_BAD)
	else:
		if frac > bad:
			col = Kit.C_BAD
		elif frac > warn:
			col = Kit.C_WARN
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.max_value = 1.0
	pb.value = clamp(frac, 0.0, 1.0)
	pb.add_theme_stylebox_override("fill", Kit.flat(col, Color(0, 0, 0, 0), 4, 0, 0, 0))
	v.add_child(pb)
	if sub != "":
		v.add_child(Kit.lbl(sub, 12, col))
	v.mouse_entered.connect(func(): set_info(nm, info))
	dash_box.add_child(v)
