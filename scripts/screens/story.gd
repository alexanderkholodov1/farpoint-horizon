extends "res://scripts/screens/screen.gd"
## The story stage (issue #66): a chapter's scenes played as a short film. The four cuyes stand on a platform in
## space, the Earth behind them; black bars close in as in a cinema; a title card gives the date and the place; the
## camera cuts to whoever speaks (a close-up that slowly pushes in, alternating sides as in a conversation), the others
## turn their heads toward them, and every face takes the line's mood (scripts/story/cuy_actor.gd). A line may ask for
## a shot ("wide", "close", "two", "low") and an effect ("shake": the bang, "alarm": a red light that pulses until
## "calm", "dim": the power goes down, "calm": lights back), and may set everyone's mood at once ("all").
## Enter or a click goes on, Esc skips to the end. args: {"chapter": "apollo13", "scenes": [...], "back": screen id}.

const CuyActor := preload("res://scripts/story/cuy_actor.gd")
const Dialogue := preload("res://scripts/story/dialogue.gd")
const Space := preload("res://scripts/space_builder.gd")

## Where each cuy stands: a shallow arc facing the camera.
const MARKS := {"rumi": Vector3(-1.05, 0, -0.2), "killa": Vector3(-0.35, 0, 0.05), "inti": Vector3(0.35, 0, 0.05),
	"wayra": Vector3(1.05, 0, -0.2)}
const BAR := 0.11            ## The black bars, as a fraction of the window's height.

var chapter := "apollo13"
var scenes: Array = []
var back := "crew_gallery"
var actors := {}
var dialogue: Node
var scene_at := -1
var bars: Array = []
var flash: ColorRect
var vignette: ColorRect
var alarm_light: OmniLight3D
var key_light: DirectionalLight3D
var shot := {"from": Vector3(0, 0.9, 4.2), "to": Vector3(0, 0.6, 0), "push": Vector3.ZERO}
var shot_t := 0.0
var shake := 0.0
var alarm := false
var dim := 0.0
var dim_goal := 0.0
var side := 1.0
var last_speaker := ""
var _t := 0.0


func enter(args: Dictionary) -> void:
	chapter = args.get("chapter", "apollo13")
	back = args.get("back", "crew_gallery")
	scenes = args.get("scenes", [])
	if scenes.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/%s.json" % chapter))
		scenes = data.get("order", data.scenes.keys()) if data is Dictionary else []
	_build_set()
	_build_ui()
	_next_scene()


func _build_set() -> void:
	world.clear_stage()
	world.cam_free = false
	world.cam.fov = 38.0
	world.cam.far = 400.0
	world.sun.light_energy = 0.0
	var env: Environment = world.world_env.environment
	env.ambient_light_energy = 0.25
	env.glow_enabled = true
	# the Earth, big and behind, lit from the side; the Moon small and far
	var earth: Node3D = Space.make_earth(9.0, false)
	earth.position = Vector3(-12, -4.0, -30)
	world.stage.add_child(earth)
	world.planet = earth
	var moon: Node3D = Space.make_moon(1.2)
	moon.position = Vector3(16, 6, -60)
	world.stage.add_child(moon)
	world.sun.rotation_degrees = Vector3(-15, 70, 0)
	# lights of the set: a warm key from the Sun's side, a cool rim from behind, a soft fill
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-28, 55, 0)
	key_light.light_energy = 1.35
	key_light.light_color = Color(1.0, 0.92, 0.82)
	key_light.shadow_enabled = true
	world.stage.add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 200, 0)
	rim.light_energy = 0.9
	rim.light_color = Color(0.55, 0.72, 1.0)
	world.stage.add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 1.4, 2.5)
	fill.omni_range = 6.0
	fill.light_energy = 0.5
	world.stage.add_child(fill)
	alarm_light = OmniLight3D.new()
	alarm_light.position = Vector3(0, 2.2, 0.6)
	alarm_light.omni_range = 6.0
	alarm_light.light_color = Color(1.0, 0.18, 0.12)
	alarm_light.light_energy = 0.0
	world.stage.add_child(alarm_light)
	# the platform: a round deck with a lit edge
	var deck := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.9
	cyl.bottom_radius = 1.7
	cyl.height = 0.12
	cyl.radial_segments = 64
	deck.mesh = cyl
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.16, 0.18, 0.23)
	dm.metallic = 0.4
	dm.roughness = 0.55
	deck.material_override = dm
	deck.position = Vector3(0, -0.06, 0)
	world.stage.add_child(deck)
	var edge := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.88
	tor.outer_radius = 1.93
	tor.rings = 96
	edge.mesh = tor
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color(1.0, 0.66, 0.26)
	edge.material_override = em
	world.stage.add_child(edge)
	for id in MARKS:
		var a = CuyActor.new()
		a.id = id
		a.position = MARKS[id]
		a.rotation.y = -MARKS[id].x * 0.25
		world.stage.add_child(a)
		actors[id] = a


func _build_ui() -> void:
	for top in [true, false]:
		var r := ColorRect.new()
		r.color = Color.BLACK
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_right = 1.0
		r.anchor_top = 0.0 if top else 1.0
		r.anchor_bottom = 0.0 if top else 1.0
		add_child(r)
		bars.append(r)
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.9, 0.05, 0.03, 0.0)
	add_child(vignette)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1.0, 0.97, 0.9, 0.0)
	add_child(flash)
	var skip := Kit.lbl(tr("Esc skips"), Kit.T_CAPS, Color(1, 1, 1, 0.45), Kit.spaced(Kit.FONT_B, 2))
	Kit.place(skip, 1, 0, 1, 0, -200, 14, -Kit.MARGIN, 40)
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(skip)


func _next_scene() -> void:
	scene_at += 1
	if scene_at >= scenes.size():
		_leave()
		return
	dialogue = Dialogue.new()
	dialogue.lines = Dialogue.load_scene(chapter, scenes[scene_at])
	dialogue.live = false
	dialogue.show_portrait = false
	dialogue.line_started.connect(_on_line)
	dialogue.finished.connect(func(skipped: bool):
		if skipped:
			_leave()
		else:
			_next_scene())
	main.add_child(dialogue)


func _leave() -> void:
	world.cam.fov = 50.0
	world.world_env.environment.glow_enabled = false
	go(back)


## Each line: who is on screen, how they feel, where the camera goes, what happens.
func _on_line(_i: int, L: Dictionary) -> void:
	var who := str(L.get("who", ""))
	if L.has("all"):
		for k in actors:
			actors[k].set_mood(str(L.all))
	if actors.has(who):
		actors[who].set_mood(str(L.get("mood", "")))
	for k in actors:
		actors[k].talking = false
	match str(L.get("fx", "")):
		"shake":
			shake = 1.4
			flash.color.a = 0.9
			Kit.UiSound.play("snap", 0.0)
			Kit.UiSound.play("error", 0.0)
			for k in actors:
				actors[k].shake(1.4)
		"alarm":
			alarm = true
		"dim":
			dim_goal = 0.65
		"calm":
			alarm = false
			dim_goal = 0.0
	var kind := str(L.get("shot", "close" if actors.has(who) else "wide"))
	if not actors.has(who) and kind != "wide":
		kind = "wide"
	_frame(kind, who)
	last_speaker = who if actors.has(who) else last_speaker


## Sets the camera's shot. A close-up sits in front of the speaker, a little to one side, alternating as in a
## conversation; it pushes in slowly while the line plays.
func _frame(kind: String, who: String) -> void:
	shot_t = 0.0
	match kind:
		"wide":
			shot = {"from": Vector3(0.0, 1.05, 4.6), "to": Vector3(0, 0.55, 0), "push": Vector3(0, -0.05, -0.5)}
		"two":
			var a: Vector3 = actors[who].face_point()
			var b: Vector3 = actors[last_speaker].face_point() if actors.has(last_speaker) and last_speaker != who else Vector3(0, a.y, 0)
			var mid := (a + b) * 0.5
			shot = {"from": mid + Vector3(0.0, 0.08, 2.1), "to": mid + Vector3(0, -0.14, 0), "push": Vector3(0, 0, -0.18)}
		"low":
			var f: Vector3 = actors[who].face_point()
			shot = {"from": f + Vector3(0.2 * side, -0.3, 1.55), "to": f + Vector3(0, -0.1, 0), "push": Vector3(0, 0.04, -0.2)}
		_:
			side = -side if who != last_speaker else side
			var f2: Vector3 = actors[who].face_point()
			# the face in the upper half of the frame, above the line's card
			shot = {"from": f2 + Vector3(0.2 * side, 0.02, 1.5), "to": f2 + Vector3(0, -0.13, 0), "push": Vector3(-0.03 * side, 0, -0.22)}
	# the speaker looks toward the camera, the others at the speaker
	for k in actors:
		var a2 = actors[k]
		if k == who:
			a2.look_target = shot.from
		elif actors.has(who):
			a2.look_target = actors[who].face_point()
		else:
			a2.look_target = shot.from


func process(delta: float) -> void:
	_t += delta
	shot_t += delta
	# the bars close in at the start
	var h := get_viewport_rect().size.y * BAR * clampf(_t * 1.5, 0.0, 1.0)
	bars[0].offset_bottom = h
	bars[1].offset_top = -h
	# the camera: the shot, a slow push, a breath of handheld drift, and the shake of the bang
	var push := 1.0 - exp(-shot_t * 0.25)
	var from: Vector3 = shot.from + shot.push * push
	var drift := Vector3(sin(_t * 0.6), sin(_t * 0.83) * 0.6, 0) * 0.008
	shake = maxf(0.0, shake - delta)
	var jolt := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.05 * shake * shake
	world.cam.position = from + drift + jolt
	world.cam.look_at(shot.to + jolt * 0.5, Vector3.UP)
	# the mouth of whoever speaks
	if dialogue and is_instance_valid(dialogue) and actors.has(dialogue.speaker):
		actors[dialogue.speaker].talking = dialogue.writing()
	# light effects
	flash.color.a = maxf(0.0, flash.color.a - delta * 3.0)
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	alarm_light.light_energy = lerpf(alarm_light.light_energy, (2.2 * pulse) if alarm else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	vignette.color.a = lerpf(vignette.color.a, (0.12 * pulse) if alarm else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	dim = lerpf(dim, dim_goal, clampf(delta * 1.5, 0.0, 1.0))
	key_light.light_energy = 1.35 * (1.0 - dim)
