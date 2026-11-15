extends "res://scripts/screens/screen.gd"
## The crew (issue #44): the four cuy astronauts of the v0.3.0 story side by side on a turntable, each with their name,
## station and one line about them. Drag to turn them, the wheel to come closer; 1-4 (or a click on a name) brings one
## to the front. The models are assets/models/crew/crew_<name>_meshy.glb (assets/source/crew_*.py; docs/design/crew.md).
## Names and lines are proposals for the team to confirm (story: docs/design/story-v0.3.0.md).

const Space := preload("res://scripts/space_builder.gd")

## [file id, name, station, one line]
const CREW := [
	["rumi", "Rumi", "Engineer", "Fixes anything with what is at hand. Unimpressed by everything."],
	["killa", "Killa", "Scientist", "Wants the data, even if it means crashing into the Moon."],
	["inti", "Inti", "Pilot", "Calm at the stick. Less calm inside an airbag."],
	["wayra", "Wayra", "Ground control", "The voice on the radio. Half asleep, never misses a word."],
]
const SPACING := 1.25
const CuyActor := preload("res://scripts/story/cuy_actor.gd")

var root: Node3D
var focus := -1             ## The cuy brought to the front (-1: the whole crew).
var spin := 0.0
var name_btns: Array = []


func enter(_args: Dictionary) -> void:
	world.clear_stage()
	var env: Environment = world.world_env.environment
	Space.apply_day(env)
	env.ambient_light_energy = 0.55
	world.sun.light_energy = 1.0
	world.sun.rotation_degrees = Vector3(-40, -30, 0)
	world.cam.far = 200.0
	# a plain studio floor
	var floor_mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 4.0
	disc.bottom_radius = 4.0
	disc.height = 0.04
	floor_mi.mesh = disc
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.2, 0.22, 0.27)
	fm.roughness = 0.9
	floor_mi.material_override = fm
	floor_mi.position = Vector3(0, -0.02, 0)
	world.stage.add_child(floor_mi)
	root = Node3D.new()
	world.stage.add_child(root)
	for i in CREW.size():
		var path := "res://assets/models/crew/crew_%s_meshy.glb" % CREW[i][0]
		var holder := Node3D.new()
		holder.position = Vector3((i - 1.5) * SPACING, 0, 0)
		root.add_child(holder)
		if ResourceLoader.exists(path):
			# alive: they blink, breathe and keep their personality (scripts/story/cuy_actor.gd); glTF's forward is +Z
			# in Godot, so they face the camera
			var actor = CuyActor.new()
			actor.id = CREW[i][0]
			holder.add_child(actor)
	world.cam_free = true
	world.cam_auto = false
	world.cam_target = Vector3(-0.75, 0.55, 0)
	world.cam_dist_goal = 5.2
	world.cam_dist = 5.2
	world.cam_yaw = 0.0
	world.cam_pitch = -0.08
	_build_ui()


## The fur and the coat's lining are painted on the meshes' vertices (assets/source/crew_*.py): the imported materials
## need to be told to show them.
func _use_vertex_colours(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var src: Mesh = mi.mesh
		var painted := false
		for k in src.get_surface_count():
			var cols = src.surface_get_arrays(k)[Mesh.ARRAY_COLOR]
			painted = painted or (cols != null and cols.size() > 0)
		if painted:
			# glTF keeps vertex colours linear; this renderer shows them as they are, so they are brought back to sRGB
			var out := ArrayMesh.new()
			for k in src.get_surface_count():
				var arrays: Array = src.surface_get_arrays(k)
				var mat := mi.get_active_material(k)
				var cols = arrays[Mesh.ARRAY_COLOR]
				if cols != null and cols.size() > 0:
					var c2 := PackedColorArray()
					c2.resize(cols.size())
					for i in cols.size():
						c2[i] = cols[i].linear_to_srgb()
					arrays[Mesh.ARRAY_COLOR] = c2
					if mat is StandardMaterial3D:
						mat = mat.duplicate()
						mat.vertex_color_use_as_albedo = true
						mat.albedo_color = Color.WHITE
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				out.surface_set_material(out.get_surface_count() - 1, mat)
			mi.mesh = out
	for c in n.get_children():
		_use_vertex_colours(c)


func _build_ui() -> void:
	var p := Kit.panel_box(Kit.PAD)
	Kit.place(p, 0, 0, 0, 0, Kit.MARGIN, Kit.MARGIN, 460, Kit.MARGIN)
	add_child(p)
	var v := Kit.vbox(Kit.GAP)
	p.add_child(v)
	v.add_child(Kit.caps(tr("The crew") + "  ·  v0.3.0"))
	v.add_child(Kit.lbl(tr("The cuyes who were there"), Kit.T_STAT, Kit.C_GOLD, Kit.FONT_T, true))
	v.add_child(Kit.lbl(tr("Four cuy astronauts who slip into six real NASA missions. Drag to turn them; 1 to 4 brings one forward."), Kit.T_BODY, Kit.C_DIM, Kit.FONT_R, true))
	for i in CREW.size():
		var c: Array = CREW[i]
		var b := Kit.btn("%d  %s  ·  %s" % [i + 1, c[1], tr(c[2])], func(): _focus(i), Kit.T_BODY)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
		name_btns.append(b)
	var line := Kit.lbl("", Kit.T_SMALL + 1, Kit.C_TEXT, Kit.FONT_R, true)
	line.name = "Line"
	v.add_child(line)
	var row := Kit.hbox(Kit.GAP)
	v.add_child(row)
	row.add_child(Kit.btn(tr("All four"), func(): _focus(-1), Kit.T_BODY))
	v.add_child(Kit.btn(tr("Play the story"), func(): _play_story(), Kit.T_BODY))
	row.add_child(Kit.btn(tr("◀ Menu"), func(): go("menu"), Kit.T_BODY))


## The story from the start: the prologue, then mission 1 (issue #66).
func _play_story() -> void:
	go("story", {"scenes": load("res://scripts/screens/story.gd").story(), "back": "crew_gallery"})


func _focus(i: int) -> void:
	focus = i
	for k in name_btns.size():
		var b: Button = name_btns[k]
		for st in ["normal", "hover", "pressed"]:
			b.remove_theme_stylebox_override(st)
		for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.remove_theme_color_override(cn)
		if k == i:
			Kit.accent_btn(b, Kit.C_GOLD)
	var line: Label = find_child("Line", true, false)
	line.text = "" if i < 0 else tr(CREW[i][3])
	if i < 0:
		world.cam_target = Vector3(-0.75, 0.55, 0)
		world.cam_dist_goal = 5.2
	else:
		world.cam_target = Vector3((i - 1.5) * SPACING - 0.45, 0.55, 0)
		world.cam_dist_goal = 2.1


func process(delta: float) -> void:
	# each cuy turns slowly on its spot, the focused one faces the camera
	spin += delta * 0.5
	for i in root.get_child_count():
		var h: Node3D = root.get_child(i)
		var goal := 0.0 if i == focus else sin(spin + i * 1.3) * 0.6
		h.rotation.y = lerp_angle(h.rotation.y, goal, clampf(delta * 3.0, 0.0, 1.0))


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k: int = e.physical_keycode
	if k >= KEY_1 and k <= KEY_4:
		_focus(k - KEY_1)
	elif k == KEY_0 or k == KEY_ENTER:
		_focus(-1)
	elif k == KEY_BACKSPACE or k == KEY_ESCAPE:
		go("menu")
	else:
		return
	get_viewport().set_input_as_handled()
