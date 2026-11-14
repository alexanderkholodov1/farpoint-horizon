extends Node3D
## SK Horizon - Mission Architect
## Flujo: Menú → Equipo → Objetivo (CML 1) → Diseño (CML 2-4) → Lanzamiento → Operación → Informe

const Mission := preload("res://scripts/mission.gd")
const Ship := preload("res://scripts/ship_builder.gd")
const Space := preload("res://scripts/space_builder.gd")
const FONT_R := preload("res://fonts/Inter-Regular.otf")
const FONT_B := preload("res://fonts/Inter-SemiBold.otf")
const FONT_T := preload("res://fonts/InterDisplay-Bold.otf")

const C_BG := Color(0.03, 0.055, 0.1, 0.9)
const C_CARD := Color(0.06, 0.1, 0.17, 0.92)
const C_ACCENT := Color(0.35, 0.72, 1.0)
const C_OK := Color(0.35, 0.95, 0.55)
const C_WARN := Color(1.0, 0.78, 0.25)
const C_BAD := Color(1.0, 0.38, 0.38)
const C_DIM := Color(0.62, 0.7, 0.82)
const C_TEXT := Color(0.93, 0.96, 1.0)

const ROLE_SPLIT := {
	1: [["director", "cientifico", "ingeniero", "operaciones"]],
	2: [["director", "cientifico"], ["ingeniero", "operaciones"]],
	3: [["director", "operaciones"], ["cientifico"], ["ingeniero"]],
	4: [["director"], ["cientifico"], ["ingeniero"], ["operaciones"]],
}
const RANKING_PATH := "user://ranking.json"

var mission = Mission.new()
var players: Array = []
var team_mode := false
var state := ""
var step_idx := 0
var approvals := {}
var last_sim := {}
var last_report := {}
var ranking: Array = []
var saved_to_ranking := false

# ---- 3D
var world_env: WorldEnvironment
var sun: DirectionalLight3D
var cam: Camera3D
var cam_yaw := 0.6
var cam_pitch := -0.25
var cam_dist := 4.0
var cam_dist_goal := 4.0
var cam_target := Vector3.ZERO
var cam_auto := true
var cam_auto_timer := 0.0
var dragging := false
var stage: Node3D
var ship: Node3D
var planet: Node3D
var orbit_ship: Node3D
var orbit_center := Vector3.ZERO
var orbit_radius := 1.3
var orbit_basis := Basis.IDENTITY
var orbit_angle := 0.0
var orbit_speed := 1.0
var ship_lost := false
var ship_label: Label3D

# ---- lanzamiento
var rocket: Node3D
var launch_t := 0.0
var exploded := false
var launch_done := false

# ---- simulación
var sim_speed := 1.0
var sim_month_f := 0.0
var shown_month := -1
var shown_events := 0
var sim_end_t := -1.0

# ---- UI
var ui: CanvasLayer
var root_ui: Control
var fade_rect: ColorRect
var info_title: Label
var info_text: Label
var dash_box: VBoxContainer
var step_box: VBoxContainer
var step_scroll: ScrollContainer
var hud: Dictionary = {}


# =====================================================================================
func trace(msg: String) -> void:
	print("[SKH] ", msg)


func _ready() -> void:
	randomize()
	trace("inicio")
	_setup_world()
	trace("mundo listo")
	_setup_ui()
	trace("interfaz lista")
	_load_ranking()
	show_menu()
	trace("menu listo")


func _setup_world() -> void:
	trace("creando cielo")
	world_env = Space.make_environment()
	add_child(world_env)
	trace("cielo listo")
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, -60, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 120, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.6, 0.75, 1.0)
	add_child(fill)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.far = 2000.0
	add_child(cam)
	cam.make_current()


func _setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = _build_theme()
	ui.add_child(root_ui)
	var top := CanvasLayer.new()
	top.layer = 10
	add_child(top)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fade_rect)


# ===================================================================================== TEMA
func flat(bg: Color, border := Color(0, 0, 0, 0), radius := 8, bw := 0, mx := 12.0, my := 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.anti_aliasing = true
	return s


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_R
	t.default_font_size = 16
	var panel := flat(C_BG, Color(0.35, 0.6, 1.0, 0.28), 12, 1, 16, 14)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", flat(Color(0.1, 0.19, 0.32, 0.95), Color(0.4, 0.65, 1.0, 0.45), 8, 1, 16, 8))
	t.set_stylebox("hover", "Button", flat(Color(0.15, 0.3, 0.5, 1.0), Color(0.5, 0.78, 1.0, 0.9), 8, 1, 16, 8))
	t.set_stylebox("pressed", "Button", flat(Color(0.2, 0.45, 0.75, 1.0), Color(0.6, 0.85, 1.0, 1.0), 8, 1, 16, 8))
	t.set_stylebox("disabled", "Button", flat(Color(0.12, 0.13, 0.16, 0.8), Color(0.3, 0.3, 0.35, 0.5), 8, 1, 16, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", FONT_B)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.55))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("normal", "LineEdit", flat(Color(0.05, 0.09, 0.15, 1.0), Color(0.4, 0.65, 1.0, 0.5), 6, 1, 10, 8))
	t.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0), Color(0.5, 0.8, 1.0, 1.0), 6, 2, 10, 8))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_stylebox("background", "ProgressBar", flat(Color(0.1, 0.13, 0.2, 1.0), Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", flat(C_ACCENT, Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_font("normal_font", "RichTextLabel", FONT_R)
	t.set_font("bold_font", "RichTextLabel", FONT_B)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_font_size("bold_font_size", "RichTextLabel", 16)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	return t


# ===================================================================================== HELPERS UI
func clear_ui() -> void:
	for c in root_ui.get_children():
		c.queue_free()
	hud = {}
	info_title = null
	info_text = null
	dash_box = null
	step_box = null


func place(c: Control, al: float, at: float, ar: float, ab: float, ol: float, ot: float, orr: float, ob: float) -> Control:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob
	return c


func lbl(text: String, size := 16, color := C_TEXT, font: Font = FONT_R, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func btn(text: String, cb: Callable, size := 16, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if min_w > 0.0:
		b.custom_minimum_size.x = min_w
	return b


func accent_btn(b: Button, col: Color) -> Button:
	b.add_theme_stylebox_override("normal", flat(col.darkened(0.45), col, 8, 2, 18, 10))
	b.add_theme_stylebox_override("hover", flat(col.darkened(0.25), col.lightened(0.3), 8, 2, 18, 10))
	b.add_theme_stylebox_override("pressed", flat(col.darkened(0.1), Color.WHITE, 8, 2, 18, 10))
	return b


func panel_box(pad := 16.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if pad != 16.0:
		p.add_theme_stylebox_override("panel", flat(C_BG, Color(0.35, 0.6, 1.0, 0.28), 12, 1, pad, pad))
	return p


func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


func spacer(h := 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func card(title: String, body: String, selected: bool, on_click: Callable, info_body := "", badge := "", badge_col := C_DIM, dimmed := false) -> PanelContainer:
	var pc := PanelContainer.new()
	var base_bg := Color(0.09, 0.22, 0.38, 0.96) if selected else C_CARD
	var border := C_ACCENT if selected else Color(1, 1, 1, 0.08)
	var sb := flat(base_bg, border, 8, 2 if selected else 1, 12, 9)
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var v := vbox(3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var t := lbl(("● " if selected else "○ ") + title, 16, Color.WHITE if selected else C_TEXT, FONT_B, true)
	h.add_child(t)
	if badge != "":
		var b := lbl(badge, 12, badge_col, FONT_B)
		h.add_child(b)
	if body != "":
		v.add_child(lbl(body, 13, C_DIM, FONT_R, true))
	if dimmed:
		pc.modulate = Color(1, 1, 1, 0.55)
	pc.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on_click.call())
	pc.mouse_entered.connect(func():
		sb.bg_color = base_bg.lightened(0.08)
		set_info(title, info_body if info_body != "" else body))
	pc.mouse_exited.connect(func(): sb.bg_color = base_bg)
	return pc


func set_info(title: String, text: String) -> void:
	if info_title and is_instance_valid(info_title):
		info_title.text = title
		info_text.text = text


func fade(to: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", to, time)
	return tw


func pct(x: float) -> String:
	return "%d %%" % int(round(x * 100.0))


func money(x: float) -> String:
	if x >= 100.0:
		return "%.0f M$" % x
	if x >= 1.0:
		return "%.1f M$" % x
	return "%.2f M$" % x


func kg(x: float) -> String:
	if x >= 1000.0:
		return "%.2f t" % (x / 1000.0)
	if x >= 10.0:
		return "%.0f kg" % x
	return "%.1f kg" % x


func watts(x: float) -> String:
	if x >= 1000.0:
		return "%.1f kW" % (x / 1000.0)
	return "%.0f W" % x


func gb(x: float) -> String:
	if x >= 10.0:
		return "%.0f GB" % x
	if x >= 0.1:
		return "%.1f GB" % x
	return "%.3f GB" % x


func player_for_role(role: String) -> String:
	for p in players:
		if p.roles.has(role):
			return p.name
	return "Jugador"


# ===================================================================================== CÁMARA E INPUT
func _process(delta: float) -> void:
	_update_camera(delta)
	_animate_world(delta)
	match state:
		"launch":
			_process_launch(delta)
		"sim":
			_process_sim(delta)


func _update_camera(delta: float) -> void:
	if not dragging:
		cam_auto_timer -= delta
		if cam_auto and cam_auto_timer <= 0.0:
			cam_yaw += delta * 0.12
	cam_dist = lerp(cam_dist, cam_dist_goal, clamp(delta * 3.0, 0.0, 1.0))
	if state == "launch":
		return
	var off := Vector3(cos(cam_pitch) * sin(cam_yaw), -sin(cam_pitch), cos(cam_pitch) * cos(cam_yaw)) * cam_dist
	cam.position = cam_target + off
	cam.look_at(cam_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if state == "launch":
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			cam_auto_timer = 4.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_dist_goal = max(0.6, cam_dist_goal * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_dist_goal = min(300.0, cam_dist_goal * 1.1)
	elif event is InputEventMouseMotion and dragging:
		cam_yaw -= event.relative.x * 0.006
		cam_pitch = clamp(cam_pitch + event.relative.y * 0.005, -1.4, 1.4)


func _animate_world(delta: float) -> void:
	if planet and is_instance_valid(planet):
		var surf: Node3D = planet.get_node_or_null("Surface")
		if surf:
			surf.rotate_y(delta * 0.03)
		var mk: Node3D = planet.get_node_or_null("Surface/Ecuador")
		if mk:
			var outward: Vector3 = mk.global_position - planet.global_position
			mk.get_node("Label").visible = outward.dot(cam.global_position - mk.global_position) > 0.0
		var pulse: Node3D = planet.get_node_or_null("Surface/Ecuador/Pulse")
		if pulse:
			var k := 1.0 + 0.6 * fmod(Time.get_ticks_msec() / 1000.0, 1.5)
			pulse.scale = Vector3.ONE * k
	if orbit_ship and is_instance_valid(orbit_ship) and not ship_lost and state != "design":
		orbit_angle += delta * orbit_speed
		var p := orbit_basis * Vector3(cos(orbit_angle), 0, sin(orbit_angle)) * orbit_radius
		var tangent := orbit_basis * Vector3(-sin(orbit_angle), 0, cos(orbit_angle))
		orbit_ship.position = orbit_center + p
		orbit_ship.look_at(orbit_ship.position + tangent, (orbit_basis * Vector3.UP))
		if ship_label and is_instance_valid(ship_label):
			ship_label.position = orbit_ship.position + Vector3(0, 0.12, 0)


# ===================================================================================== ESCENARIOS 3D
func clear_stage() -> void:
	if stage and is_instance_valid(stage):
		stage.queue_free()
	stage = Node3D.new()
	add_child(stage)
	ship = null
	planet = null
	orbit_ship = null
	ship_label = null
	rocket = null
	ship_lost = false
	world_env.environment.sky = Space.make_space_sky()
	world_env.environment.ambient_light_energy = 0.35
	sun.rotation_degrees = Vector3(-30, -60, 0)


func stage_menu() -> void:
	clear_stage()
	trace("creando Tierra")
	planet = Space.make_earth(1.0)
	stage.add_child(planet)
	trace("Tierra lista")
	var demo = Mission.new()
	demo.from_dict({"bus": "small", "instruments": ["cam_ms", "ir_adv"], "panels": "dep_m", "comms": "xband", "adcs": "rw", "propulsion": "cold"})
	_setup_orbit_ship(demo, Vector3.ZERO, 1.35, 98.0, 0.1)
	ship_label.visible = false
	cam_auto = false
	cam_yaw = 0.0
	cam_pitch = -0.12
	cam_dist_goal = 3.6
	cam_dist = 3.6
	cam_target = Vector3(-1.25, 0.05, 0)


func _setup_orbit_ship(m, center: Vector3, radius: float, incl: float, ship_size: float) -> void:
	orbit_center = center
	orbit_radius = radius
	var ring := Space.make_orbit_ring(radius, incl, Color(0.4, 0.8, 1.0, 0.45))
	ring.position = center
	stage.add_child(ring)
	orbit_basis = ring.basis
	orbit_ship = Ship.build(m)
	var r: float = orbit_ship.get_meta("radius")
	orbit_ship.scale = Vector3.ONE * (ship_size / r)
	stage.add_child(orbit_ship)
	ship_label = Space.make_label("TU NAVE", Color(0.55, 0.9, 1.0))
	stage.add_child(ship_label)
	orbit_speed = 0.35


func stage_design() -> void:
	clear_stage()
	var body: String = GameData.SCENARIOS[mission.scenario].body
	if mission.orbit == "lunar":
		body = "luna"
	if body == "luna":
		planet = Space.make_moon(30.0)
	else:
		planet = Space.make_earth(30.0, false)
	planet.position = Vector3(0, -38, -14)
	stage.add_child(planet)
	cam_auto = true
	cam_pitch = -0.22
	cam_target = Vector3(0, 0, 0)
	_face_sun(0.5)
	rebuild_ship()


func rebuild_ship() -> void:
	if ship and is_instance_valid(ship):
		ship.queue_free()
	ship = Ship.build(mission)
	stage.add_child(ship)
	var r: float = ship.get_meta("radius")
	cam_dist_goal = r * 2.6 + 0.9


# ===================================================================================== MENÚ
func show_menu() -> void:
	state = "menu"
	clear_ui()
	stage_menu()
	var box := vbox(14)
	place(box, 0, 0, 0, 1, 70, 90, 620, -40)
	root_ui.add_child(box)
	box.add_child(lbl("NASA SPACE APPS CHALLENGE 2026", 15, C_ACCENT, FONT_B))
	box.add_child(lbl("SK HORIZON", 76, Color.WHITE, FONT_T))
	box.add_child(lbl("MISSION ARCHITECT", 26, Color(0.75, 0.85, 1.0), FONT_B))
	box.add_child(lbl("Diseña, lanza y opera tu propia misión espacial. Cada decisión tiene consecuencias: masa, energía, datos, presupuesto y tiempo.", 18, C_DIM, FONT_R, true))
	box.add_child(spacer(14))
	box.add_child(accent_btn(btn("▶  Un jugador", func(): _start_solo(), 20, 340), C_ACCENT))
	box.add_child(accent_btn(btn("Equipo (2 a 4 jugadores)", func(): show_team_count(), 20, 340), Color(0.5, 1.0, 0.6)))
	box.add_child(spacer(4))
	box.add_child(lbl("Dificultad", 14, C_DIM, FONT_B))
	var dh := hbox(8)
	box.add_child(dh)
	for d in ["facil", "normal", "dificil"]:
		var b := btn(GameData.DIFFICULTY[d].name, func(): mission.difficulty = d; show_menu(), 16, 110)
		if mission.difficulty == d:
			accent_btn(b, C_WARN)
		dh.add_child(b)
	box.add_child(lbl(GameData.DIFFICULTY[mission.difficulty].desc, 14, C_DIM))
	box.add_child(spacer(6))
	var hh := hbox(8)
	box.add_child(hh)
	hh.add_child(btn("Cómo se juega", func(): show_howto(), 16, 166))
	hh.add_child(btn("Ranking", func(): show_ranking_overlay(), 16, 166))
	var foot := lbl("Reto: Space Mission Design Game · Equipo SK Horizon · Quito, Ecuador", 13, C_DIM)
	place(foot, 0, 1, 0, 1, 70, -40, 900, -14)
	root_ui.add_child(foot)
	var tag := lbl("● Ecuador", 14, Color(1, 0.8, 0.3), FONT_B)
	place(tag, 1, 1, 1, 1, -150, -40, -20, -14)
	root_ui.add_child(tag)


func _start_solo() -> void:
	team_mode = false
	players = [{"name": "Jugador", "roles": GameData.ROLE_ORDER.duplicate()}]
	show_scenarios()


func show_team_count() -> void:
	clear_ui()
	var p := panel_box(26)
	place(p, 0.5, 0.5, 0.5, 0.5, -330, -260, 330, 260)
	root_ui.add_child(p)
	var v := vbox(12)
	p.add_child(v)
	v.add_child(lbl("Modo equipo", 30, Color.WHITE, FONT_T))
	v.add_child(lbl("Como en el Mission Design Lab de la NASA, cada integrante es responsable de una parte de la misión. Tendrán que negociar: lo que uno gana, otro lo pierde.", 15, C_DIM, FONT_R, true))
	v.add_child(lbl("¿Cuántos jugadores?", 16, C_TEXT, FONT_B))
	var h := hbox(10)
	v.add_child(h)
	for n in [2, 3, 4]:
		h.add_child(accent_btn(btn("%d jugadores" % n, func(): show_team(n), 18, 180), Color(0.5, 1.0, 0.6)))
	v.add_child(spacer(10))
	v.add_child(btn("◀ Volver", func(): show_menu()))


func show_team(n: int) -> void:
	clear_ui()
	var p := panel_box(26)
	place(p, 0.5, 0.5, 0.5, 0.5, -480, -330, 480, 330)
	root_ui.add_child(p)
	var v := vbox(10)
	p.add_child(v)
	v.add_child(lbl("Su equipo de misión", 30, Color.WHITE, FONT_T))
	v.add_child(lbl("Escriban sus nombres. Cada rol tiene una meta propia: si todos la cumplen, el equipo gana puntos extra.", 15, C_DIM, FONT_R, true))
	var split: Array = ROLE_SPLIT[n]
	var edits: Array = []
	for i in n:
		var row := hbox(12)
		v.add_child(row)
		var e := LineEdit.new()
		e.placeholder_text = "Jugador %d" % (i + 1)
		e.text = "Jugador %d" % (i + 1)
		e.custom_minimum_size = Vector2(220, 0)
		row.add_child(e)
		edits.append(e)
		var rv := vbox(2)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rv)
		for role in split[i]:
			var R: Dictionary = GameData.ROLES[role]
			rv.add_child(lbl(R.name, 16, R.color, FONT_B))
			rv.add_child(lbl("Meta: " + R.goal, 13, C_DIM, FONT_R, true))
		v.add_child(HSeparator.new())
	var h := hbox(10)
	v.add_child(h)
	h.add_child(btn("◀ Volver", func(): show_team_count()))
	h.add_child(accent_btn(btn("Continuar ▶", func():
		team_mode = true
		players = []
		for i in n:
			var nm: String = edits[i].text.strip_edges()
			players.append({"name": nm if nm != "" else "Jugador %d" % (i + 1), "roles": split[i].duplicate()})
		show_scenarios(), 18), C_ACCENT))


# ===================================================================================== OBJETIVO (CML 1)
func show_scenarios() -> void:
	state = "scenario"
	clear_ui()
	var head := vbox(4)
	place(head, 0, 0, 1, 0, 50, 30, -50, 130)
	root_ui.add_child(head)
	head.add_child(lbl(GameData.CML_NAMES[1] + "  —  Toda misión empieza con una pregunta científica", 15, C_ACCENT, FONT_B))
	head.add_child(lbl("Elige el objetivo de tu misión", 36, Color.WHITE, FONT_T))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	place(sc, 0, 0, 1, 1, 50, 140, -50, -80)
	root_ui.add_child(sc)
	sc.add_child(grid)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mult: float = GameData.DIFFICULTY[mission.difficulty].budget
	for id in GameData.SCENARIOS:
		var S: Dictionary = GameData.SCENARIOS[id]
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := flat(C_BG, S.color.darkened(0.2), 12, 2, 18, 16)
		pc.add_theme_stylebox_override("panel", sb)
		pc.custom_minimum_size = Vector2(0, 250)
		pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var v := vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pc.add_child(v)
		v.add_child(lbl(S.type.to_upper(), 13, S.color, FONT_B))
		v.add_child(lbl(S.name, 22, Color.WHITE, FONT_T, true))
		v.add_child(lbl(S.desc, 14, C_DIM, FONT_R, true))
		var facts := "Presupuesto: %s   ·   Operar ≥ %d año(s)" % [money(S.budget * mult), S.min_years]
		v.add_child(lbl(facts, 14, C_WARN, FONT_B, true))
		pc.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_choose_scenario(id))
		pc.mouse_entered.connect(func(): sb.bg_color = Color(0.07, 0.13, 0.22, 0.95))
		pc.mouse_exited.connect(func(): sb.bg_color = C_BG)
		grid.add_child(pc)
	var back := btn("◀ Menú", func(): show_menu())
	place(back, 0, 1, 0, 1, 50, -62, 180, -20)
	root_ui.add_child(back)


func _choose_scenario(id: String) -> void:
	var diff: String = mission.difficulty
	mission = Mission.new()
	mission.difficulty = diff
	mission.scenario = id
	mission.bus = "cube6"
	mission.panels = "body"
	mission.battery = "b20"
	mission.comms = "uhf"
	mission.adcs = "mag"
	mission.propulsion = "none"
	mission.launcher = "ride"
	mission.orbit = "lunar" if id == "luna" else ("l2" if id == "telescopio" else "sso")
	if id == "telescopio":
		mission.orbit = "leo"
	mission.years = GameData.SCENARIOS[id].min_years
	approvals = {}
	show_design(0)


# ===================================================================================== DISEÑO
func show_design(idx: int) -> void:
	state = "design"
	step_idx = idx
	clear_ui()
	if not stage or ship == null:
		stage_design()
	var r: Dictionary = mission.compute()
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var STEP: Dictionary = GameData.STEPS[idx]

	# ---------- barra superior
	var top := panel_box(10)
	place(top, 0, 0, 1, 0, 12, 10, -12, 70)
	root_ui.add_child(top)
	var th := hbox(6)
	top.add_child(th)
	var tl := vbox(0)
	tl.custom_minimum_size.x = 300
	th.add_child(tl)
	tl.add_child(lbl(S.name, 17, S.color, FONT_B))
	tl.add_child(lbl(GameData.CML_NAMES[STEP.cml], 13, C_DIM))
	var tabs := hbox(4)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	th.add_child(tabs)
	for i in GameData.STEPS.size():
		var st: Dictionary = GameData.STEPS[i]
		var b := btn("%d. %s" % [i + 1, st.title], func(): show_design(i), 14)
		if i == idx:
			accent_btn(b, GameData.ROLES[st.role].color)
		tabs.add_child(b)
	th.add_child(btn("Menú", func(): show_menu(), 14))

	# ---------- panel izquierdo: opciones del paso
	var left := panel_box(14)
	place(left, 0, 0, 0, 1, 12, 80, 492, -12)
	root_ui.add_child(left)
	var lv := vbox(8)
	left.add_child(lv)
	var R: Dictionary = GameData.ROLES[STEP.role]
	lv.add_child(lbl(STEP.title, 26, Color.WHITE, FONT_T))
	var turn: String = "Decide: %s · %s" % [player_for_role(STEP.role), R.name] if team_mode else "Rol: " + R.name
	lv.add_child(lbl(turn, 14, R.color, FONT_B))
	step_scroll = ScrollContainer.new()
	step_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	step_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(step_scroll)
	step_box = vbox(8)
	step_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_scroll.add_child(step_box)
	_fill_step(STEP.id, r)
	var nav := hbox(8)
	lv.add_child(nav)
	var prev := btn("◀ Anterior", func(): show_design(max(0, idx - 1)))
	prev.disabled = idx == 0
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(prev)
	if STEP.id == "revision":
		var go := accent_btn(btn("¡LANZAR!", func(): _try_launch(), 18), C_OK)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.disabled = not _can_launch(r)
		nav.add_child(go)
	else:
		var nx := accent_btn(btn("Siguiente ▶", func(): show_design(idx + 1)), C_ACCENT)
		nx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(nx)

	# ---------- panel derecho: tablero de recursos
	var right := panel_box(14)
	place(right, 1, 0, 1, 1, -402, 80, -12, -12)
	root_ui.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	dash_box = vbox(7)
	dash_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(dash_box)
	_fill_dashboard(r)

	# ---------- caja inferior: "¿Por qué importa?"
	var info := panel_box(14)
	place(info, 0, 1, 1, 1, 504, -150, -414, -12)
	root_ui.add_child(info)
	var iv := vbox(4)
	info.add_child(iv)
	info_title = lbl("¿Por qué importa?", 17, C_ACCENT, FONT_B, true)
	iv.add_child(info_title)
	info_text = lbl("Pasa el mouse sobre una opción para ver qué es y cómo afecta a la misión. Arrastra para girar la nave, rueda para acercar.", 14, C_DIM, FONT_R, true)
	iv.add_child(info_text)
	var dims_lbl := lbl("Plataforma: " + GameData.BUSES[mission.bus].name + "  ·  " + kg(r.mass_total), 14, C_DIM, FONT_B)
	place(dims_lbl, 0, 0, 1, 0, 510, 84, -420, 110)
	dims_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_ui.add_child(dims_lbl)


func on_change(rebuild_3d := true) -> void:
	if not approvals.is_empty():
		approvals = {}
	if rebuild_3d:
		rebuild_ship()
	var scroll_v := step_scroll.scroll_vertical if step_scroll else 0
	show_design(step_idx)
	await get_tree().process_frame
	if step_scroll:
		step_scroll.scroll_vertical = scroll_v


func section(text: String, hint := "") -> void:
	step_box.add_child(spacer(4))
	step_box.add_child(lbl(text, 15, C_ACCENT, FONT_B))
	if hint != "":
		step_box.add_child(lbl(hint, 13, C_DIM, FONT_R, true))


func _fill_step(id: String, r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	match id:
		"orbita":
			step_box.add_child(lbl("La órbita decide qué ves, cuánto tiempo hablas con la Tierra, cuánta sombra hay y cuánta energía necesitas para llegar.", 14, C_DIM, FONT_R, true))
			for o in GameData.ORBITS:
				var O: Dictionary = GameData.ORBITS[o]
				var m: float = S.orbit_mult.get(o, 0.0)
				var badge := "×%.1f ciencia" % m
				var bc := C_OK if m >= 1.1 else (C_WARN if m >= 0.7 else C_BAD)
				if m <= 0.0:
					badge = "No sirve"
				var body := "Sombra %s/vuelta · Contacto %s/día · Δv para llegar: %d m/s" % [_mins(O.eclipse_min), _mins(O.contact_min), int(O.insert_dv)]
				step_box.add_child(card(O.name, body, mission.orbit == o, func():
					mission.orbit = o
					stage_design()
					on_change(false), O.desc + "\n\nPara tu objetivo: " + ("no se puede cumplir desde aquí." if m <= 0.0 else "ciencia ×%.1f." % m), badge, bc, m <= 0.0))
		"plataforma":
			step_box.add_child(lbl("La plataforma (bus) es el «chasis»: estructura, computadora y espacio para instrumentos. Más grande = más capacidad, pero más caro y pesado.", 14, C_DIM, FONT_R, true))
			for b in GameData.BUSES:
				var B: Dictionary = GameData.BUSES[b]
				var body := "Carga máx. %s · %d espacio(s) · instrumentos hasta «%s» · %s" % [kg(B.max), B.slots, GameData.SIZE_NAMES[B.max_size], money(B.cost)]
				step_box.add_child(card(B.name, body, mission.bus == b, func(): mission.bus = b; on_change(), B.desc + "\n\nMasa vacía: %s · consumo base: %s." % [kg(B.dry), watts(B.base_power)]))
		"instrumentos":
			var B: Dictionary = GameData.BUSES[mission.bus]
			step_box.add_child(lbl("Espacios usados: %d de %d en %s" % [mission.instruments.size(), B.slots, B.name], 15, C_WARN if mission.instruments.size() <= B.slots else C_BAD, FONT_B))
			for n in r.needs:
				step_box.add_child(lbl(("✓ " if n.ok else "✗ ") + n.label, 14, C_OK if n.ok else C_BAD, FONT_B, true))
			var default_rel: float = S.get("default_relevance", 0.1)
			for i in GameData.INSTRUMENTS:
				var I: Dictionary = GameData.INSTRUMENTS[i]
				var rel := 0.0
				for t in I.tags:
					rel = max(rel, S.relevance.get(t, default_rel))
				if S.relevance.is_empty():
					rel = default_rel
				var badge := "★ Clave" if rel >= 0.95 else ("Útil" if rel >= 0.5 else "Poco útil")
				var bc := C_OK if rel >= 0.95 else (C_WARN if rel >= 0.5 else C_DIM)
				var fits: bool = I.size <= B.max_size
				var body := "%s · %s · %s/día · %s · apuntado %s" % [kg(I.mass), watts(I.power), gb(I.data), money(I.cost), ["libre", "grueso", "fino", "preciso"][I.pointing]]
				if not fits:
					body = "No cabe: requiere plataforma «%s»\n" % GameData.SIZE_NAMES[I.size] + body
				step_box.add_child(card(I.name, body, mission.instruments.has(i), func():
					if not mission.instruments.has(i) and not fits:
						toast("%s no cabe en %s" % [I.name, B.name], C_BAD)
						return
					mission.toggle_instrument(i)
					on_change(), I.desc + "\n\nCiencia base: %d puntos/mes · Relevancia para tu objetivo: %d %%." % [int(I.sci), int(rel * 100)], badge, bc, not fits))
		"energia":
			step_box.add_child(lbl("Consumo total: %s · Generación promedio: %s (los paneles no producen en la sombra: %d %% del tiempo)." % [watts(r.power_load), watts(r.power_gen), int(GameData.ORBITS[mission.orbit].eclipse_frac * 100)], 14, C_DIM, FONT_R, true))
			section("Paneles solares", "Necesitas al menos %s de paneles (con margen de 15 %%)." % watts(r.power_load * 1.15 / max(0.01, 1.0 - GameData.ORBITS[mission.orbit].eclipse_frac)))
			for p in GameData.PANELS:
				var P: Dictionary = GameData.PANELS[p]
				step_box.add_child(card(P.name, "%s en sol · %s · %s" % [watts(P.power), kg(P.mass), money(P.cost)], mission.panels == p, func(): mission.panels = p; on_change(), P.desc))
			section("Batería", "En la sombra necesitas ~%.0f Wh (usando solo el 60 %% de la batería para que dure muchos ciclos)." % r.battery_need)
			for b in GameData.BATTERIES:
				var BT: Dictionary = GameData.BATTERIES[b]
				var ok: bool = BT.wh >= r.battery_need
				step_box.add_child(card(BT.name, "%s · %s" % [kg(BT.mass), money(BT.cost)], mission.battery == b, func(): mission.battery = b; on_change(), BT.desc, "Alcanza" if ok else "Corta", C_OK if ok else C_WARN))
		"comunicaciones":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			step_box.add_child(lbl("Tus instrumentos generan %s/día. Desde %s hay %s de contacto al día y la distancia reduce la señal a %s de la velocidad nominal." % [gb(r.data_gen), O.short, _mins(O.contact_min), pct(O.comm_factor)], 14, C_DIM, FONT_R, true))
			for c in GameData.COMMS:
				var C: Dictionary = GameData.COMMS[c]
				var down: float = C.rate * O.comm_factor * O.contact_min * 60.0 / 8.0 / 1000.0
				var ok: bool = down >= r.data_gen
				step_box.add_child(card(C.name, "Bajarías %s/día · %s · %s · %s" % [gb(down), kg(C.mass), watts(C.power), money(C.cost)], mission.comms == c, func(): mission.comms = c; on_change(), C.desc, "Suficiente" if ok else "Insuficiente", C_OK if ok else C_WARN))
		"control":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			section("Control de actitud (apuntado)", "Tus instrumentos necesitan apuntado nivel %d." % r.pointing_need)
			for a in GameData.ADCS:
				var A: Dictionary = GameData.ADCS[a]
				var ok: bool = A.level >= r.pointing_need
				step_box.add_child(card(A.name, "Nivel %d · %s de la plataforma en costo" % [A.level, pct(A.cost_pct)], mission.adcs == a, func(): mission.adcs = a; on_change(), A.desc, "Suficiente" if ok else "Impreciso", C_OK if ok else C_WARN))
			section("Propulsión", "Para %s necesitas %d m/s para llegar + %d m/s por año para mantener la órbita (%d años = %d m/s)." % [O.short, int(O.insert_dv), int(O.maint_dv), mission.years, int(r.dv_need)])
			for p in GameData.PROPULSION:
				var PR: Dictionary = GameData.PROPULSION[p]
				var ok: bool = PR.dv >= r.dv_need
				step_box.add_child(card(PR.name, "Δv %d m/s · combustible ≈ %s de la masa" % [int(PR.dv), pct(PR.mass_pct)], mission.propulsion == p, func(): mission.propulsion = p; on_change(), PR.desc, "Suficiente" if ok else "Corto", C_OK if ok else C_WARN))
			section("Protección", "Cuestan masa y dinero, pero reducen los riesgos durante la operación.")
			step_box.add_child(card("Redundancia (piezas de respaldo)", "+10 % masa · +20 % costo de hardware", mission.redundancy, func(): mission.redundancy = not mission.redundancy; on_change(), "Duplica componentes críticos (computadora, ruedas). Si algo falla, el respaldo toma el control."))
			step_box.add_child(card("Blindaje contra radiación", "+4 % masa · +5 % costo de hardware", mission.shielding, func(): mission.shielding = not mission.shielding; on_change(), "Placas que protegen la electrónica de partículas del Sol y de los cinturones de radiación. Clave lejos de la Tierra."))
		"lanzador":
			var O: Dictionary = GameData.ORBITS[mission.orbit]
			step_box.add_child(lbl("Tu nave pesa %s y va a %s. Cuanto más lejos el destino, menos carga puede llevar un cohete." % [kg(r.mass_total), O.short], 14, C_DIM, FONT_R, true))
			for l in GameData.LAUNCHERS:
				var L: Dictionary = GameData.LAUNCHERS[l]
				var cap: float = L.cap[mission.orbit]
				var cost: float = max(L.min_cost, L.cost + L.cost_per_kg * r.mass_total)
				var ok: bool = cap >= r.mass_total
				var badge := "No llega" if cap <= 0.0 else ("Cabe" if ok else "Muy pesada")
				step_box.add_child(card(L.name, "Hasta %s a %s · %s · confiabilidad %s" % [kg(cap), O.short, money(cost), pct(1.0 - L.fail)], mission.launcher == l, func(): mission.launcher = l; on_change(), L.desc, badge, C_OK if ok else C_BAD, cap <= 0.0))
			section("Vida útil de diseño", "Más años = más ciencia, pero más costo de operación (%s por año) y más combustible." % money(O.ops * GameData.BUSES[mission.bus].ops_mult))
			var yh := HFlowContainer.new()
			yh.add_theme_constant_override("h_separation", 6)
			yh.add_theme_constant_override("v_separation", 6)
			step_box.add_child(yh)
			for y in [1, 2, 3, 4, 5, 7, 10]:
				var b := btn("%d año%s" % [y, "" if y == 1 else "s"], func(): mission.years = y; on_change(false), 14)
				if mission.years == y:
					accent_btn(b, C_WARN)
				yh.add_child(b)
			step_box.add_child(lbl("El objetivo pide operar al menos %d año(s)." % S.min_years, 13, C_DIM))
		"revision":
			_fill_review(r)


func _mins(m: float) -> String:
	if m >= 1440.0:
		return "24 h"
	if m >= 60.0:
		return "%.1f h" % (m / 60.0)
	if m <= 0.0:
		return "0 min"
	return "%d min" % int(m)


func _fill_review(r: Dictionary) -> void:
	step_box.add_child(lbl("Revisión de diseño (CML 4): así revisan los ingenieros de la NASA si una misión está lista. Lo rojo impide lanzar; lo amarillo tendrá consecuencias.", 14, C_DIM, FONT_R, true))
	var order := {"fatal": 0, "warn": 1, "ok": 2}
	var checks: Array = r.checks.duplicate()
	checks.sort_custom(func(a, b): return order[a.level] < order[b.level])
	for c in checks:
		var col: Color = C_BAD if c.level == "fatal" else (C_WARN if c.level == "warn" else C_OK)
		var icon: String = "✗ " if c.level == "fatal" else ("⚠ " if c.level == "warn" else "✓ ")
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", flat(Color(col.r, col.g, col.b, 0.08), Color(col.r, col.g, col.b, 0.5), 6, 1, 10, 7))
		var v := vbox(2)
		pc.add_child(v)
		v.add_child(lbl(icon + c.title, 15, col, FONT_B, true))
		v.add_child(lbl(c.detail, 13, C_DIM, FONT_R, true))
		step_box.add_child(pc)
	section("Aprobación del equipo", "Cada rol revisa su meta y aprueba. Si alguien cambia el diseño, hay que volver a aprobar." if team_mode else "Revisa las metas de cada rol: cumplirlas suma puntos de equipo.")
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", flat(C_CARD, R.color.darkened(0.3), 8, 1, 10, 8))
		var h := hbox(8)
		pc.add_child(h)
		var v := vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var who := (player_for_role(role) + " · ") if team_mode else ""
		v.add_child(lbl(who + R.name, 14, R.color, FONT_B, true))
		v.add_child(lbl(("✓ " if ok else "✗ ") + R.goal, 13, C_OK if ok else C_WARN, FONT_R, true))
		if team_mode:
			var approved: bool = approvals.get(role, false)
			var b := btn("Aprobado ✓" if approved else ("Aprobar" if ok else "Aprobar con riesgo"), func():
				approvals[role] = not approvals.get(role, false)
				show_design(step_idx), 13)
			if approved:
				accent_btn(b, C_OK)
			h.add_child(b)
		step_box.add_child(pc)
	if r.fatal:
		step_box.add_child(lbl("Corrige los puntos en rojo para poder lanzar.", 14, C_BAD, FONT_B, true))
	elif team_mode and not _all_approved():
		step_box.add_child(lbl("Falta la aprobación de todo el equipo.", 14, C_WARN, FONT_B, true))


func _all_approved() -> bool:
	for role in GameData.ROLE_ORDER:
		if not approvals.get(role, false):
			return false
	return true


func _can_launch(r: Dictionary) -> bool:
	return not r.fatal and (not team_mode or _all_approved())


func _fill_dashboard(r: Dictionary) -> void:
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	dash_box.add_child(lbl("Tablero de la misión", 20, Color.WHITE, FONT_T))
	_bar("Presupuesto", "%s de %s" % [money(r.cost_total), money(r.budget)], r.cost_total / r.budget, 0.9, 1.0,
		"Reserva: %s" % pct(r.reserve) if r.reserve >= 0.0 else "¡Excedido!", "Incluye fabricación, lanzamiento (%s) y operación por %d años (%s)." % [money(r.cost.launch), mission.years, money(r.cost.ops)])
	var lim_txt := "plataforma %s · cohete %s" % [kg(r.mass_bus_max), kg(r.launch_cap) if r.launch_cap > 0.0 else "no llega"]
	_bar("Masa", "%s de %s" % [kg(r.mass_total), kg(r.mass_limit)], r.mass_total / max(0.001, r.mass_limit), 0.9, 1.0, "Límite: " + lim_txt,
		"Instrumentos %s · energía %s · combustible %s · plataforma %s." % [kg(r.mass.instruments), kg(r.mass.power), kg(r.mass.propellant), kg(r.mass.bus)])
	_bar("Energía", "%s de %s" % [watts(r.power_load), watts(r.power_gen)], r.power_load / max(0.001, r.power_gen), 0.87, 1.0,
		"Margen: %s" % pct(r.power_margin), "Consumo vs. generación promedio de los paneles (contando la sombra).")
	_bar("Batería (eclipse)", "%.0f de %.0f Wh" % [r.battery_need, r.battery_wh], r.battery_need / max(0.001, r.battery_wh), 0.85, 1.0,
		"", "Energía necesaria para cruzar la sombra.")
	_bar("Datos", "%s de %s por día" % [gb(r.data_gen), gb(r.data_down)], r.data_gen / max(0.0001, r.data_down), 0.9, 1.0,
		"", "Datos generados vs. lo que la antena puede bajar.")
	_bar("Delta-v (propulsión)", "%d de %d m/s" % [int(r.dv_need), int(r.dv_have)], r.dv_need / max(0.001, r.dv_have) if r.dv_have > 0.0 else (0.0 if r.dv_need <= 0.0 else 2.0), 0.9, 1.0,
		"", "Cambio de velocidad necesario para llegar y mantener la órbita.")
	var life_txt := "%.1f años" % r.life_years if r.life_years < 100.0 else "> 100 años"
	_bar("Vida útil", "%s (diseño: %d)" % [life_txt, mission.years], float(mission.years) / max(0.001, r.life_years), 0.95, 1.0, "", "Cuánto puede durar con esta órbita y combustible.")
	var sf: float = r.expected_science / S.science_target
	_bar("Ciencia esperada", "%d de %d pts" % [int(r.expected_science), int(S.science_target)], sf, 0.0, 0.0, "", "Estimación sin imprevistos.", true)
	dash_box.add_child(spacer(4))
	dash_box.add_child(lbl("Objetivos científicos", 15, C_ACCENT, FONT_B))
	if r.needs.is_empty():
		dash_box.add_child(lbl("Modo libre: sin objetivos obligatorios.", 13, C_DIM, FONT_R, true))
	for n in r.needs:
		dash_box.add_child(lbl(("✓ " if n.ok else "✗ ") + n.label, 13, C_OK if n.ok else C_BAD, FONT_R, true))
	dash_box.add_child(spacer(4))
	dash_box.add_child(lbl("Metas del equipo", 15, C_ACCENT, FONT_B))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		dash_box.add_child(lbl(("✓ " if ok else "○ ") + R.name, 13, C_OK if ok else C_DIM, FONT_R, true))
	var nf := 0
	var nw := 0
	for c in r.checks:
		if c.level == "fatal":
			nf += 1
		elif c.level == "warn":
			nw += 1
	dash_box.add_child(spacer(4))
	if nf > 0:
		dash_box.add_child(lbl("✗ %d problema(s) impiden lanzar" % nf, 14, C_BAD, FONT_B, true))
	if nw > 0:
		dash_box.add_child(lbl("⚠ %d advertencia(s)" % nw, 14, C_WARN, FONT_B, true))


## Fila del tablero. frac = uso/límite. Verde < warn ≤ amarillo < bad ≤ rojo. higher_better invierte colores.
func _bar(nm: String, value: String, frac: float, warn: float, bad: float, sub: String, info: String, higher_better := false) -> void:
	var v := vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	var h := hbox(4)
	v.add_child(h)
	var n := lbl(nm, 14, C_TEXT, FONT_B)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(lbl(value, 13, C_DIM))
	var col := C_OK
	if higher_better:
		col = C_OK if frac >= 0.8 else (C_WARN if frac >= 0.4 else C_BAD)
	else:
		if frac > bad:
			col = C_BAD
		elif frac > warn:
			col = C_WARN
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.max_value = 1.0
	pb.value = clamp(frac, 0.0, 1.0)
	pb.add_theme_stylebox_override("fill", flat(col, Color(0, 0, 0, 0), 4, 0, 0, 0))
	v.add_child(pb)
	if sub != "":
		v.add_child(lbl(sub, 12, col))
	v.mouse_entered.connect(func(): set_info(nm, info))
	dash_box.add_child(v)


func toast(text: String, col := C_ACCENT, time := 2.5) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(Color(0.03, 0.05, 0.09, 0.95), col, 10, 2, 18, 12))
	p.add_child(lbl(text, 16, col, FONT_B))
	place(p, 0.5, 0, 0.5, 0, -300, 122, 300, 176)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(p)
	var tw := create_tween()
	tw.tween_interval(time)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


# ===================================================================================== LANZAMIENTO
func _try_launch() -> void:
	var r: Dictionary = mission.compute()
	if not _can_launch(r):
		toast("Todavía no se puede lanzar", C_BAD)
		return
	last_report = r
	last_sim = mission.simulate()
	saved_to_ranking = false
	await fade(1.0, 0.5).finished
	show_launch()
	fade(0.0, 0.6)


func show_launch() -> void:
	state = "launch"
	clear_ui()
	clear_stage()
	var env: Environment = world_env.environment
	env.sky = Space.make_day_sky()
	env.ambient_light_energy = 0.8
	sun.rotation_degrees = Vector3(-50, -30, 0)
	stage.add_child(Space.make_pad())
	rocket = Space.make_rocket(mission.launcher)
	rocket.position = Vector3(0, 0.2, 0)
	stage.add_child(rocket)
	launch_t = 0.0
	exploded = false
	launch_done = false
	cam.position = Vector3(7, 2.5, 9)
	cam.look_at(Vector3(0, 3, 0), Vector3.UP)
	var p := panel_box(14)
	place(p, 0, 0, 0, 0, 20, 20, 460, 140)
	root_ui.add_child(p)
	var v := vbox(4)
	p.add_child(v)
	v.add_child(lbl("LANZAMIENTO · " + GameData.LAUNCHERS[mission.launcher].name, 15, C_ACCENT, FONT_B))
	hud.telemetry = lbl("T-00:03", 26, Color.WHITE, FONT_T)
	v.add_child(hud.telemetry)
	hud.sub = lbl("Destino: " + GameData.ORBITS[mission.orbit].name, 14, C_DIM)
	v.add_child(hud.sub)
	hud.big = lbl("3", 120, Color.WHITE, FONT_T)
	hud.big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hud.big, 0.5, 0.35, 0.5, 0.35, -300, -80, 300, 80)
	root_ui.add_child(hud.big)
	var skip := btn("Saltar ▶▶", func(): launch_t = max(launch_t, 9.0), 14)
	place(skip, 1, 1, 1, 1, -150, -60, -20, -20)
	root_ui.add_child(skip)


func _process_launch(delta: float) -> void:
	if rocket == null or not is_instance_valid(rocket):
		return
	launch_t += delta
	var flames: Node3D = rocket.get_node("Flames")
	if launch_t < 3.0:
		hud.big.text = str(3 - int(launch_t))
		hud.telemetry.text = "T-00:0%d" % (3 - int(launch_t))
		flames.visible = launch_t > 2.4
		for f in flames.get_children():
			if f is CPUParticles3D:
				f.emitting = launch_t > 2.4
		return
	var tt := launch_t - 3.0
	hud.big.text = "¡DESPEGUE!" if tt < 1.5 else ""
	var alt := 0.6 * tt * tt * 2.2
	if not exploded:
		rocket.position.y = 0.2 + alt
		rocket.rotation_degrees.z = -clamp(tt - 2.0, 0.0, 6.0) * 3.0
		rocket.position.x = -pow(max(tt - 2.0, 0.0), 2.0) * 0.25
		var km := alt * 0.8
		var vel := tt * 0.45
		hud.telemetry.text = "T+00:%02d · %.0f km · %.1f km/s" % [int(tt * 8.0), km, vel]
	# el cielo se oscurece al subir
	var k: float = clamp((tt - 1.0) / 5.0, 0.0, 1.0)
	var sky_m = world_env.environment.sky.sky_material
	if sky_m is ProceduralSkyMaterial:
		sky_m.sky_top_color = Color(0.18, 0.4, 0.78).lerp(Color(0, 0, 0.02), k)
		sky_m.sky_horizon_color = Color(0.62, 0.74, 0.88).lerp(Color(0.05, 0.08, 0.15), k)
	world_env.environment.ambient_light_energy = lerp(0.8, 0.3, k)
	# cámara de seguimiento
	var rp := rocket.position
	if not exploded:
		var follow := rp + Vector3(6.0 + tt * 0.6, 1.5 - min(tt, 4.0) * 0.6, 8.0 + tt * 0.5)
		cam.position = cam.position.lerp(follow, clamp(delta * 2.0, 0.0, 1.0))
		cam.look_at(rp + Vector3(0, 2.5, 0), Vector3.UP)
	if last_sim.launch_failed and tt > 3.2 and not exploded:
		_explode()
	if exploded and tt > 7.0 and not launch_done:
		launch_done = true
		_go_report()
	elif not exploded and tt > 6.5 and not launch_done:
		launch_done = true
		_go_orbit()


func _explode() -> void:
	exploded = true
	hud.big.text = "¡FALLA DEL LANZADOR!"
	hud.big.add_theme_font_size_override("font_size", 56)
	hud.big.add_theme_color_override("font_color", C_BAD)
	var pos := rocket.position + Vector3(0, 2.0, 0)
	rocket.visible = false
	var boom := Space.make_flame(1.2)
	boom.position = pos
	boom.direction = Vector3.UP
	boom.spread = 180.0
	boom.one_shot = true
	boom.explosiveness = 0.9
	boom.amount = 220
	boom.lifetime = 2.0
	boom.initial_velocity_min = 2.0
	boom.initial_velocity_max = 7.0
	stage.add_child(boom)
	boom.emitting = true
	var flash := OmniLight3D.new()
	flash.position = pos
	flash.light_energy = 16.0
	flash.omni_range = 60.0
	flash.light_color = Color(1, 0.6, 0.3)
	stage.add_child(flash)
	create_tween().tween_property(flash, "light_energy", 0.0, 1.5)


func _go_orbit() -> void:
	await fade(1.0, 0.6).finished
	show_sim()
	fade(0.0, 0.8)


func _go_report() -> void:
	await fade(1.0, 0.8).finished
	show_report()
	fade(0.0, 0.6)


# ===================================================================================== OPERACIÓN (simulación)
func stage_orbit() -> void:
	clear_stage()
	var O: Dictionary = GameData.ORBITS[mission.orbit]
	var ship_size := 0.11
	if mission.orbit == "lunar":
		planet = Space.make_moon(1.0)
		stage.add_child(planet)
		var earth := Space.make_earth(1.4)
		earth.position = Vector3(-30, 6, -40)
		stage.add_child(earth)
		_setup_orbit_ship(mission, Vector3.ZERO, O.radius, O.incl, ship_size)
		cam_target = Vector3.ZERO
		cam_dist_goal = 3.6
	elif mission.orbit == "l2":
		planet = Space.make_earth(1.0)
		stage.add_child(planet)
		var sun_dir := sun.global_transform.basis.z
		var l2: Vector3 = -sun_dir * O.radius
		_setup_orbit_ship(mission, l2, 0.7, 90.0, 0.35)
		cam_target = l2 * 0.5
		cam_dist_goal = 11.0
		var l2l := Space.make_label("Punto L2 · 1,5 millones de km", Color(0.85, 0.75, 1.0))
		l2l.position = l2 + Vector3(0, -0.95, 0)
		stage.add_child(l2l)
		var line := Space.make_orbit_ring(O.radius, 0.0, Color(1, 1, 1, 0.08))
		stage.add_child(line)
	else:
		planet = Space.make_earth(1.0)
		stage.add_child(planet)
		if mission.orbit == "geo":
			ship_size = 0.2
		_setup_orbit_ship(mission, Vector3.ZERO, O.radius, O.incl, ship_size)
		cam_target = Vector3.ZERO
		cam_dist_goal = 3.4 if O.radius < 2.0 else 8.5
	orbit_speed = {"leo": 0.5, "sso": 0.45, "geo": 0.12, "lunar": 0.45, "l2": 0.6}.get(mission.orbit, 0.4)
	cam_dist = cam_dist_goal
	cam_auto = true
	cam_pitch = -0.3
	_face_sun()
	if mission.orbit == "l2":
		cam_auto = false
		cam_pitch = -0.15
		_face_sun(PI / 2.0)


func _face_sun(extra := 0.8) -> void:
	var sd: Vector3 = sun.global_transform.basis.z
	cam_yaw = atan2(sd.x, sd.z) + extra


func show_sim() -> void:
	state = "sim"
	clear_ui()
	stage_orbit()
	var months_total: int = mission.years * 12
	sim_speed = max(1.0, months_total / 36.0)
	sim_month_f = 0.0
	shown_month = -1
	shown_events = 0
	sim_end_t = -1.0
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	# barra superior
	var top := panel_box(12)
	place(top, 0, 0, 1, 0, 468, 12, -16, 112)
	root_ui.add_child(top)
	var tv := vbox(4)
	top.add_child(tv)
	var th := hbox(10)
	tv.add_child(th)
	var tt := lbl("OPERACIÓN · " + GameData.ORBITS[mission.orbit].name, 15, C_ACCENT, FONT_B)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tt)
	hud.month = lbl("Mes 0 de %d" % months_total, 15, Color.WHITE, FONT_B)
	th.add_child(hud.month)
	hud.time = ProgressBar.new()
	hud.time.show_percentage = false
	hud.time.custom_minimum_size = Vector2(0, 8)
	hud.time.max_value = months_total
	tv.add_child(hud.time)
	var sh := hbox(10)
	tv.add_child(sh)
	var sl := lbl("Ciencia", 14, C_TEXT, FONT_B)
	sh.add_child(sl)
	hud.sci = ProgressBar.new()
	hud.sci.show_percentage = false
	hud.sci.custom_minimum_size = Vector2(0, 12)
	hud.sci.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.sci.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud.sci.max_value = S.science_target
	hud.sci.add_theme_stylebox_override("fill", flat(C_OK, Color(0, 0, 0, 0), 4, 0, 0, 0))
	sh.add_child(hud.sci)
	hud.sci_lbl = lbl("0 / %d" % int(S.science_target), 13, C_DIM)
	sh.add_child(hud.sci_lbl)
	# bitácora de eventos
	var log_p := panel_box(12)
	place(log_p, 0, 0, 0, 1, 12, 12, 452, -12)
	root_ui.add_child(log_p)
	var lv := vbox(6)
	log_p.add_child(lv)
	lv.add_child(lbl("Bitácora de la misión", 20, Color.WHITE, FONT_T))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(sc)
	hud.log_scroll = sc
	hud.log = vbox(6)
	hud.log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(hud.log)
	# controles de velocidad
	var ctl := hbox(6)
	place(ctl, 1, 1, 1, 1, -420, -60, -16, -16)
	ctl.alignment = BoxContainer.ALIGNMENT_END
	root_ui.add_child(ctl)
	for sp in [1.0, 3.0, 10.0]:
		ctl.add_child(btn("×%d" % int(sp), func(): sim_speed = sp * max(1.0, months_total / 36.0), 14))
	ctl.add_child(accent_btn(btn("Ver informe ▶▶", func(): sim_month_f = 9999.0, 14), C_WARN))


func _process_sim(delta: float) -> void:
	if last_sim.is_empty():
		return
	sim_month_f += delta * sim_speed / 0.7
	var target := int(floor(sim_month_f))
	var months: int = last_sim.months
	var events: Array = last_sim.events
	while shown_month < min(target, months):
		shown_month += 1
		while shown_events < events.size() and events[shown_events].month <= shown_month:
			_log_event(events[shown_events])
			shown_events += 1
		if shown_month > 0 and shown_month <= last_sim.timeline.size():
			var s: float = last_sim.timeline[shown_month - 1]
			hud.sci.value = s
			hud.sci_lbl.text = "%d / %d" % [int(s), int(GameData.SCENARIOS[mission.scenario].science_target)]
		hud.month.text = "Mes %d de %d" % [shown_month, mission.years * 12]
		hud.time.value = shown_month
	if shown_month >= months and sim_end_t < 0.0:
		while shown_events < events.size():
			_log_event(events[shown_events])
			shown_events += 1
		sim_end_t = 0.0
		if last_sim.status == "lost" or months < mission.years * 12:
			_lose_ship()
	if sim_end_t >= 0.0:
		sim_end_t += delta
		if sim_end_t > (2.5 if sim_month_f < 9000.0 else 0.3) and state == "sim":
			state = "to_report"
			_go_report()


func _lose_ship() -> void:
	if orbit_ship == null or ship_lost:
		return
	ship_lost = true
	var tw := create_tween()
	if mission.orbit == "leo" or mission.orbit == "sso":
		tw.tween_property(orbit_ship, "position", orbit_ship.position * 0.98, 1.5)
	tw.tween_property(orbit_ship, "scale", Vector3.ONE * 0.0001, 0.6)


func _log_event(e: Dictionary) -> void:
	var col: Color = C_OK if e.kind == "good" else (C_BAD if e.kind == "bad" else C_ACCENT)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", flat(Color(col.r, col.g, col.b, 0.08), Color(col.r, col.g, col.b, 0.55), 6, 1, 10, 7))
	var v := vbox(2)
	pc.add_child(v)
	v.add_child(lbl("Mes %d · %s" % [e.month, e.title], 14, col, FONT_B, true))
	v.add_child(lbl(e.text, 13, C_DIM, FONT_R, true))
	hud.log.add_child(pc)
	pc.modulate.a = 0.0
	create_tween().tween_property(pc, "modulate:a", 1.0, 0.4)
	if e.kind != "info" and sim_month_f < 9000.0:
		toast(e.title, col, 1.8)
	await get_tree().process_frame
	if hud.has("log_scroll") and is_instance_valid(hud.log_scroll):
		hud.log_scroll.scroll_vertical = int(hud.log_scroll.get_v_scroll_bar().max_value)


# ===================================================================================== INFORME FINAL
func show_report() -> void:
	state = "report"
	clear_ui()
	if last_sim.launch_failed:
		clear_stage()
		planet = Space.make_earth(1.0)
		stage.add_child(planet)
		cam_target = Vector3.ZERO
		cam_dist_goal = 3.4
		cam_auto = true
		_face_sun()
	elif stage == null or orbit_ship == null:
		stage_orbit()
	var s: Dictionary = last_sim.score
	var r: Dictionary = last_report
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	var p := panel_box(22)
	place(p, 0.5, 0, 0.5, 1, -640, 16, 640, -16)
	root_ui.add_child(p)
	var outer := vbox(10)
	p.add_child(outer)
	# encabezado
	var head := hbox(20)
	outer.add_child(head)
	var gcol: Color = {"S": Color(1.0, 0.85, 0.3), "A": C_OK, "B": C_ACCENT, "C": C_WARN, "D": C_BAD}[s.grade]
	var gl := lbl(s.grade, 88, gcol, FONT_T)
	gl.custom_minimum_size.x = 90
	head.add_child(gl)
	var hv := vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(lbl("INFORME DE MISIÓN · " + S.name.to_upper(), 14, C_ACCENT, FONT_B))
	hv.add_child(lbl(s.label, 34, Color.WHITE, FONT_T))
	hv.add_child(lbl("%d / 1000 puntos   ·   Costo final %s de %s   ·   %d de %d meses en operación" % [s.total, money(s.final_cost), money(r.budget), last_sim.months, mission.years * 12], 15, C_DIM))
	var cols := hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)
	# columna 1: puntaje
	var c1 := vbox(8)
	c1.custom_minimum_size.x = 360
	cols.add_child(c1)
	c1.add_child(lbl("Puntaje", 18, Color.WHITE, FONT_B))
	_score_row(c1, "Objetivos cumplidos", s.objectives, 400, "Objetivos científicos cubiertos y tiempo en operación.")
	_score_row(c1, "Ciencia obtenida", s.science, 300, "%d de %d puntos de ciencia." % [int(last_sim.science), int(S.science_target)])
	_score_row(c1, "Uso eficiente de recursos", s.efficiency, 200, "Reserva de presupuesto y márgenes de masa y energía.")
	_score_row(c1, "Trabajo en equipo", s.team, 100, "Metas de cada rol cumplidas.")
	c1.add_child(spacer(6))
	c1.add_child(lbl("Metas por rol", 16, Color.WHITE, FONT_B))
	for role in GameData.ROLE_ORDER:
		var R: Dictionary = GameData.ROLES[role]
		var ok: bool = r.goals[role]
		var who := (player_for_role(role) + " · ") if team_mode else ""
		c1.add_child(lbl(("✓ " if ok else "✗ ") + who + R.name, 14, C_OK if ok else C_BAD, FONT_B, true))
		c1.add_child(lbl(R.why, 12, C_DIM, FONT_R, true))
	# columna 2: qué pasó y por qué
	var c2sc := ScrollContainer.new()
	c2sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c2sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(c2sc)
	var c2 := vbox(6)
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c2sc.add_child(c2)
	c2.add_child(lbl("¿Por qué pasó lo que pasó?", 18, Color.WHITE, FONT_B))
	var lessons := 0
	for c in r.checks:
		if c.level == "warn":
			c2.add_child(lbl("⚠ " + c.title, 14, C_WARN, FONT_B, true))
			c2.add_child(lbl(c.detail, 13, C_DIM, FONT_R, true))
			lessons += 1
	for e in last_sim.events:
		if e.kind == "bad" and e.month > 1:
			c2.add_child(lbl("✗ Mes %d: %s" % [e.month, e.title], 14, C_BAD, FONT_B, true))
			c2.add_child(lbl(e.text, 13, C_DIM, FONT_R, true))
			lessons += 1
	if lessons == 0:
		c2.add_child(lbl("✓ El diseño estaba equilibrado: energía, datos, masa y combustible con margen. ¡Así se diseña una misión!", 14, C_OK, FONT_B, true))
	c2.add_child(spacer(6))
	c2.add_child(lbl("Lo que salió bien", 18, Color.WHITE, FONT_B))
	for e in last_sim.events:
		if e.kind == "good":
			c2.add_child(lbl("✓ Mes %d: %s" % [e.month, e.title], 14, C_OK, FONT_B, true))
	c2.add_child(spacer(6))
	c2.add_child(lbl("Misiones reales parecidas", 18, Color.WHITE, FONT_B))
	for t in mission.real_missions():
		c2.add_child(lbl("• " + t, 14, C_DIM, FONT_R, true))
	c2.add_child(spacer(6))
	c2.add_child(lbl("No existe un diseño perfecto: otra combinación de plataforma, órbita e instrumentos podría cumplir el mismo objetivo. ¡Prueba otra!", 14, C_ACCENT, FONT_R, true))
	# botones
	var bh := hbox(10)
	outer.add_child(bh)
	bh.add_child(accent_btn(btn("Rediseñar misión", func(): _back_to_design(), 16), C_ACCENT))
	bh.add_child(btn("↻ Volver a volar (otra suerte)", func(): _try_launch_again(), 16))
	bh.add_child(btn("Nueva misión", func(): show_scenarios(), 16))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sp)
	var name_e := LineEdit.new()
	name_e.custom_minimum_size.x = 220
	name_e.text = "SK Horizon" if not team_mode else " / ".join(PackedStringArray(players.map(func(pp): return pp.name)))
	bh.add_child(name_e)
	var save := Button.new()
	save.text = "Guardar en ranking"
	save.add_theme_font_size_override("font_size", 16)
	save.pressed.connect(func():
		if saved_to_ranking:
			return
		saved_to_ranking = true
		_add_ranking(name_e.text, s.total, s.grade)
		save.text = "Guardado ✓"
		save.disabled = true)
	save.disabled = saved_to_ranking
	bh.add_child(save)
	bh.add_child(btn("Ranking", func(): show_ranking_overlay(), 16))


func _score_row(parent: VBoxContainer, nm: String, val: int, mx: int, sub: String) -> void:
	var h := hbox(6)
	parent.add_child(h)
	var n := lbl(nm, 15, C_TEXT, FONT_B)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(lbl("%d / %d" % [val, mx], 15, Color.WHITE, FONT_B))
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.max_value = mx
	pb.value = val
	var f: float = float(val) / mx
	pb.add_theme_stylebox_override("fill", flat(C_OK if f >= 0.75 else (C_WARN if f >= 0.4 else C_BAD), Color(0, 0, 0, 0), 4, 0, 0, 0))
	parent.add_child(pb)
	parent.add_child(lbl(sub, 12, C_DIM, FONT_R, true))


func _back_to_design() -> void:
	approvals = {}
	clear_stage()
	stage_design()
	show_design(GameData.STEPS.size() - 1)


func _try_launch_again() -> void:
	approvals = {}
	for role in GameData.ROLE_ORDER:
		approvals[role] = true
	_try_launch()


# ===================================================================================== RANKING Y AYUDA
func _load_ranking() -> void:
	ranking = []
	if FileAccess.file_exists(RANKING_PATH):
		var f := FileAccess.open(RANKING_PATH, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Array:
				ranking = data


func _add_ranking(team: String, score: int, grade: String) -> void:
	ranking.append({"team": team.strip_edges(), "score": score, "grade": grade, "scenario": GameData.SCENARIOS[mission.scenario].name,
		"difficulty": GameData.DIFFICULTY[mission.difficulty].name, "date": Time.get_date_string_from_system()})
	ranking.sort_custom(func(a, b): return a.score > b.score)
	if ranking.size() > 20:
		ranking.resize(20)
	var f := FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ranking))


func _overlay(title: String, w := 900.0, h := 640.0) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ui.add_child(shade)
	var p := panel_box(24)
	place(p, 0.5, 0.5, 0.5, 0.5, -w / 2.0, -h / 2.0, w / 2.0, h / 2.0)
	shade.add_child(p)
	var v := vbox(10)
	p.add_child(v)
	var hh := hbox(8)
	v.add_child(hh)
	var t := lbl(title, 28, Color.WHITE, FONT_T)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(t)
	hh.add_child(btn("Cerrar ×", func(): shade.queue_free(), 14))
	return v


func show_ranking_overlay() -> void:
	var v := _overlay("Ranking de misiones", 760, 560)
	if ranking.is_empty():
		v.add_child(lbl("Todavía no hay misiones guardadas. ¡Sé el primero!", 16, C_DIM))
		return
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 22)
	sc.add_child(g)
	for hdr in ["#", "Equipo", "Puntos", "Misión", "Dificultad"]:
		g.add_child(lbl(hdr, 14, C_ACCENT, FONT_B))
	for i in ranking.size():
		var e: Dictionary = ranking[i]
		g.add_child(lbl(str(i + 1), 15, C_DIM))
		g.add_child(lbl(str(e.team), 15, Color.WHITE, FONT_B))
		g.add_child(lbl("%d (%s)" % [int(e.score), e.grade], 15, C_WARN, FONT_B))
		g.add_child(lbl(str(e.scenario), 14, C_DIM))
		g.add_child(lbl(str(e.difficulty), 14, C_DIM))


func show_howto() -> void:
	var v := _overlay("Cómo se juega", 960, 680)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = false
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.text = """[b]1. Elige un objetivo[/b] (CML 1). Cada misión nace de una pregunta científica: ¿cuándo va a erupcionar un volcán? ¿Llega El Niño?

[b]2. Diseña la misión paso a paso[/b] (CML 2 a 4), como en el Mission Design Lab de la NASA: órbita, plataforma, instrumentos, energía, comunicaciones, control, propulsión y lanzador. Cada decisión cambia las demás: el tablero de la derecha lo muestra en vivo.

[b]3. Revisa y lanza.[/b] Lo rojo impide lanzar (no cabe, no alcanza el dinero). Lo amarillo se puede lanzar… pero tendrá consecuencias en la operación.

[b]4. Opera la misión.[/b] Mira los meses pasar: tormentas solares, basura espacial, fallas… y descubrimientos. Un buen diseño resiste los imprevistos.

[b]5. Aprende del informe[/b] y rediseña. No hay una única respuesta correcta.

[b]Recursos clave[/b]
• [b]Masa:[/b] todo pesa. La plataforma y el cohete tienen un límite.
• [b]Energía:[/b] los paneles no producen en la sombra de la Tierra; la batería debe cubrir ese tiempo.
• [b]Datos:[/b] un instrumento que genera más datos de los que la antena puede enviar desperdicia ciencia.
• [b]Delta-v:[/b] el «cambio de velocidad» que da la propulsión. Ir a la Luna o a GEO exige mucho.
• [b]Presupuesto y tiempo:[/b] más años de operación = más ciencia y más costo.

[b]Modo equipo:[/b] hasta 4 jugadores con roles (Dirección, Ciencia, Ingeniería y Operaciones). Cada rol tiene su meta; todos deben aprobar el diseño antes de lanzar.

[b]Controles:[/b] arrastra con el mouse para girar la cámara, rueda para acercar.

Basado en recursos de la NASA: «Design and Develop Science Missions», «CubeSat 101» y los Concept Maturity Levels (CML) del JPL."""
	v.add_child(rt)


var _frames_traced := 0
func _physics_process(_d: float) -> void:
	if _frames_traced < 3:
		_frames_traced += 1
		trace("frame %d dibujado" % _frames_traced)
