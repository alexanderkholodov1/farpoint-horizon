extends "res://scripts/screens/screen.gd"
## The rocket builder (issue #6): assemble a launcher from real parts and see at once what it can do for this mission.
## Left: the parts, by kind, and ready rockets to start from. Centre: the rocket in 3D, at real proportions, on the pad
## in daylight; a new part drops onto the stack and snaps. Right: the stack by stage, the gauges (mass, thrust to weight,
## delta-v, payload to the mission's orbit against the craft's mass, cost) and what still stops it from flying.
## "Fly this rocket" makes it the mission's launcher (RocketDesign.CUSTOM) and goes back to the launcher step.
## args: {"back_step": index of GameData.STEPS to return to}.

const Space := preload("res://scripts/space_builder.gd")
const RocketDesign := preload("res://scripts/craft/rocket_design.gd")

const SCALE := 0.088          ## Metres to world units, as the launch screen draws its rockets.
const KINDS := [["engine", "Engines"], ["tank", "Fuel tanks"], ["decoupler", "Stage separators"],
	["fairing", "Fairings"], ["booster", "Side boosters"]]

var design                    ## The rocket being built (RocketDesign).
var back_step := 0
var model: Node3D
var snap_node: Node3D         ## The part that just snapped, animated in process().
var snap_t := 1.0
var right_box: VBoxContainer


func enter(args: Dictionary) -> void:
	back_step = args.get("back_step", 0)
	design = RocketDesign.current.copy() if RocketDesign.current != null else RocketDesign.from_preset("medium")
	world.clear_stage()
	var env: Environment = world.world_env.environment
	env.sky = Space.make_day_sky()
	env.ambient_light_energy = 0.9
	world.sun.rotation_degrees = Vector3(-42, -35, 0)
	world.stage.add_child(Space.make_pad())
	world.cam_free = true
	world.cam_auto = false
	world.cam_yaw = 0.7
	world.cam_pitch = -0.12
	_build_ui()
	_rebuild(false)


# ===================================================================================== UI
func _build_ui() -> void:
	clear()
	# ---------- left: parts and ready rockets
	var lp := Kit.panel_box(14)
	Kit.place(lp, 0, 0, 0, 1, 16, 16, 376, -16)
	add_child(lp)
	var lv := Kit.vbox(6)
	lp.add_child(lv)
	lv.add_child(Kit.lbl("Build your rocket", 22, Kit.C_TEXT, Kit.FONT_T))
	lv.add_child(Kit.lbl("Click a part to put it on top. Stages separate at each separator.", 13, Kit.C_DIM, Kit.FONT_R, true))
	var presets := Kit.hbox(6)
	lv.add_child(presets)
	for pid in ["light", "medium", "heavy"]:
		var p: Dictionary = RocketDesign.data().presets[pid]
		presets.add_child(Kit.btn(p.name, func(): design = RocketDesign.from_preset(pid); _rebuild(false), 13))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(scroll)
	var pb := Kit.vbox(6)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pb)
	var parts: Dictionary = RocketDesign.data().parts
	for kind in KINDS:
		pb.add_child(Kit.spacer(4))
		pb.add_child(Kit.lbl(kind[1], 15, Kit.C_ACCENT, Kit.FONT_B))
		for id in parts:
			var P: Dictionary = parts[id]
			if P.category != kind[0]:
				continue
			pb.add_child(Kit.card(P.name, _part_line(P), kind[0] == "booster" and design.boosters == id,
				func(): _add(id), P.desc + "\n\n" + _sources_line(P), "%.1f m" % P.family, Kit.C_DIM))
	# ---------- right: stack, gauges, problems, actions
	var rp := Kit.panel_box(14)
	Kit.place(rp, 1, 0, 1, 1, -396, 16, -16, -16)
	add_child(rp)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(rs)
	right_box = Kit.vbox(6)
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right_box)
	# ---------- bottom centre: actions
	var bar := Kit.hbox(10)
	Kit.place(bar, 0.5, 1, 0.5, 1, -250, -70, 250, -20)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bar)
	bar.add_child(Kit.btn("◀ Back", func(): go("design", {"step": back_step}), 15))
	var fly := Kit.accent_btn(Kit.btn("Fly this rocket ▶", _use), Kit.C_OK)
	bar.add_child(fly)


func _fill_right() -> void:
	for c in right_box.get_children():
		c.queue_free()
	var r: Dictionary = mission.compute()
	var craft_kg: float = r.mass_total
	var O: Dictionary = GameData.ORBITS[mission.orbit]
	var cap: float = design.capacity_kg(mission.orbit)
	var perf: Dictionary = design.performance(craft_kg)
	var twr: float = design.liftoff_twr(craft_kg)
	var target: float = RocketDesign.data().targets[mission.orbit]
	right_box.add_child(Kit.lbl("Your rocket", 18, Kit.C_TEXT, Kit.FONT_B))
	# the gauges that matter, large
	var fits := cap >= craft_kg and cap > 0.0
	right_box.add_child(_gauge("Carries to %s" % O.short, Kit.kg(cap), "Your craft weighs %s" % Kit.kg(craft_kg), Kit.C_OK if fits else Kit.C_BAD))
	right_box.add_child(_gauge("Speed it can gain (Δv)", "%.1f km/s" % (perf.dv / 1000.0),
		"%.1f km/s needed to reach %s with your craft" % [target / 1000.0, O.short], Kit.C_OK if perf.dv >= target else Kit.C_WARN))
	right_box.add_child(_gauge("Thrust to weight at liftoff", "%.2f" % twr,
		"Above 1 it rises; real rockets leave at 1.2 to 1.5", Kit.C_OK if twr >= 1.15 else (Kit.C_WARN if twr >= 1.0 else Kit.C_BAD)))
	right_box.add_child(Kit.lbl("Mass %s · height %.0f m · cost %s" % [Kit.kg(design.mass_kg(craft_kg)), design.height_m(), Kit.money(design.total_cost())], 13, Kit.C_DIM, Kit.FONT_R, true))
	for p in design.problems():
		right_box.add_child(Kit.lbl("✗ " + p, 14, Kit.C_BAD, Kit.FONT_B, true))
	# the stack, top to bottom, by stage
	right_box.add_child(Kit.spacer(6))
	right_box.add_child(Kit.lbl("Stack, top to bottom", 15, Kit.C_ACCENT, Kit.FONT_B))
	var st: Array = design.stages()
	var idx: int = design.stack.size() - 1
	for si in range(st.size() - 1, -1, -1):
		var dv: float = perf.stages[si] if si < perf.stages.size() else 0.0
		right_box.add_child(Kit.lbl("Stage %d · Δv %.1f km/s" % [si + 1, dv / 1000.0], 13, Kit.C_WARN, Kit.FONT_B))
		for j in range(st[si].size() - 1, -1, -1):
			var id: String = st[si][j]
			var at := idx
			var row := Kit.hbox(6)
			var nl := Kit.lbl(RocketDesign.part(id).name, 14)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nl)
			row.add_child(Kit.btn("✕", func(): design.stack.remove_at(at); _rebuild(false), 12))
			right_box.add_child(row)
			idx -= 1
		if si == 0 and design.boosters != "":
			var row := Kit.hbox(6)
			var nl := Kit.lbl("+ " + RocketDesign.part(design.boosters).name, 14)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nl)
			row.add_child(Kit.btn("✕", func(): design.boosters = ""; _rebuild(false), 12))
			right_box.add_child(row)


func _gauge(title: String, value: String, note: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Kit.flat(Kit.C_CARD, col.darkened(0.3), 8, 2))
	var v := Kit.vbox(2)
	p.add_child(v)
	v.add_child(Kit.lbl(title, 13, Kit.C_DIM, Kit.FONT_B))
	v.add_child(Kit.lbl(value, 26, col, Kit.FONT_T))
	v.add_child(Kit.lbl(note, 12, Kit.C_DIM, Kit.FONT_R, true))
	return p


func _part_line(P: Dictionary) -> String:
	var each := " each" if P.category == "booster" else ""
	var bits: Array = [Kit.kg(P.dry_kg + P.get("propellant_kg", 0.0)) + each]
	if P.has("thrust_sl_kn"):
		bits.append("%s kN%s" % [_num(P.thrust_sl_kn), each])
	elif P.has("thrust_vac_kn"):
		bits.append("%s kN in vacuum" % _num(P.thrust_vac_kn))
	if P.has("isp_vac_s"):
		bits.append("Isp %d s" % int(P.isp_vac_s))
	bits.append(Kit.money(P.cost_musd))
	return " · ".join(bits)


func _sources_line(P: Dictionary) -> String:
	var s := "Sources: " + ", ".join(P.sources)
	if not P.get("estimate", []).is_empty():
		s += ". Our estimate: " + ", ".join(P.estimate).replace("_musd", "").replace("_kg", "").replace("_", " ")
	return s


static func _num(x: float) -> String:
	var s := str(int(round(x)))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += " "
		out += s[i]
	return out


# ===================================================================================== ACTIONS
func _add(id: String) -> void:
	if RocketDesign.part(id).category == "booster":
		design.boosters = "" if design.boosters == id else id
		_rebuild(false)
		return
	design.stack.append(id)
	_rebuild(true)


func _use() -> void:
	var probs: Array = design.problems()
	if not probs.is_empty():
		toast(probs[0], Kit.C_BAD)
		return
	RocketDesign.current = design.copy()
	mission.launcher = RocketDesign.CUSTOM
	go("design", {"step": back_step})


# ===================================================================================== 3D
func _rebuild(snap: bool) -> void:
	if model and is_instance_valid(model):
		model.queue_free()
	model = Node3D.new()
	model.position = Vector3(0, 0.2, 0)
	world.stage.add_child(model)
	var assembled: Node3D = design.build_model()
	assembled.scale = Vector3.ONE * SCALE
	model.add_child(assembled)
	var h: float = maxf(design.height_m() * SCALE, 1.0)
	world.cam_target = Vector3(0, 0.2 + h * 0.5, 0)
	world.cam_dist_goal = clampf(h * 1.25, 2.5, 12.0)
	snap_node = null
	if snap and not design.stack.is_empty():
		var top_stage: Node3D = assembled.get_child(design.stages().size() - 1)
		if top_stage.get_child_count() > 0:
			snap_node = top_stage.get_child(top_stage.get_child_count() - 1)
			snap_t = 0.0
	_fill_right()


func process(delta: float) -> void:
	if snap_node and is_instance_valid(snap_node) and snap_t < 1.0:
		# the new part drops from above and settles with a small spring (about 0.45 s)
		snap_t = minf(1.0, snap_t + delta / 0.45)
		var e := 1.0 - pow(1.0 - snap_t, 3.0)
		var bounce := sin(snap_t * PI * 2.5) * (1.0 - snap_t) * 0.12
		snap_node.set_meta("rest_y", snap_node.get_meta("rest_y", snap_node.position.y))
		var rest: float = snap_node.get_meta("rest_y")
		snap_node.position.y = rest + (1.0 - e) * 25.0 + bounce * 10.0
