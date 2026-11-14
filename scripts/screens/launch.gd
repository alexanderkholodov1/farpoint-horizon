extends "res://scripts/screens/screen.gd"
## Launch: the countdown, liftoff from the pad among the Andes, the ascent (or the launcher's failure), then the fade
## to the operation (or to the report after a failure). The outcome was decided at launch (GameState.last_sim).

const Space := preload("res://scripts/space_builder.gd")
const RocketDesign := preload("res://scripts/craft/rocket_design.gd")

var rocket: Node3D
var launch_t := 0.0
var exploded := false
var launch_done := false
var dropped: Array = []     ## Stages and boosters falling away: [node, velocity, spin, age].
var sep_at := -1.0          ## Time after liftoff of the last stage separation, for its caption.
var telemetry: Label
var big: Label
var smoke: CPUParticles3D


func enter(_args: Dictionary) -> void:
	world.cam_free = false
	world.clear_stage()
	var env: Environment = world.world_env.environment
	Space.apply_day(env)
	env.ambient_light_energy = 0.55
	world.cam.far = 6000.0
	world.sun.rotation_degrees = Vector3(-50, -30, 0)
	world.stage.add_child(Space.make_pad())
	rocket = Space.make_rocket(mission.launcher)
	rocket.position = Vector3(0, Space.PAD_TOP, 0)
	world.stage.add_child(rocket)
	launch_t = 0.0
	exploded = false
	launch_done = false
	world.cam.position = Vector3(7, 2.5, 9)
	world.cam.look_at(Vector3(0, 3, 0), Vector3.UP)
	var p := Kit.panel_box(14)
	Kit.place(p, 0, 0, 0, 0, 20, 20, 460, 140)
	add_child(p)
	var v := Kit.vbox(4)
	p.add_child(v)
	v.add_child(Kit.lbl(tr("LAUNCH") + " · " + tr(RocketDesign.launcher(mission.launcher).name), 15, Kit.C_ACCENT, Kit.FONT_B))
	telemetry = Kit.lbl("T-00:03", 26, Color.WHITE, Kit.FONT_T)
	v.add_child(telemetry)
	v.add_child(Kit.lbl(tr("Destination") + " · " + GameData.ORBITS[mission.orbit].name, 14, Kit.C_DIM))
	# the countdown and the call-outs sit in the lower third, as on a launch broadcast, so they never cover the rocket
	big = Kit.lbl("3", 64, Color.WHITE, Kit.FONT_T)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 3)
	big.add_theme_constant_override("shadow_outline_size", 8)
	Kit.place(big, 0.5, 0.82, 0.5, 0.82, -360, -50, 360, 50)
	add_child(big)
	# the cloud of steam and smoke the deluge water and the exhaust throw sideways at ignition
	smoke = Space.make_pad_smoke()
	smoke.position = Vector3(1.0, 0.5, 0)
	world.stage.add_child(smoke)
	var skip := Kit.btn(tr("Skip ▶▶"), func(): launch_t = max(launch_t, 9.0), 14)
	Kit.place(skip, 1, 1, 1, 1, -150, -60, -20, -20)
	add_child(skip)


func process(delta: float) -> void:
	if rocket == null or not is_instance_valid(rocket):
		return
	launch_t += delta
	var flames: Node3D = rocket.get_node("Flames")
	if launch_t < 3.0:
		big.text = str(3 - int(launch_t))
		telemetry.text = "T-00:0%d" % (3 - int(launch_t))
		flames.visible = launch_t > 2.4
		for f in flames.get_children():
			if f is CPUParticles3D:
				f.emitting = launch_t > 2.4
		smoke.emitting = launch_t > 2.5
		return
	smoke.emitting = launch_t < 6.0
	var tt := launch_t - 3.0
	if not exploded:   # the failure call-out stays up once it is shown
		big.text = tr("LIFTOFF!") if tt < 1.5 else (tr("STAGE SEPARATION") if sep_at >= 0.0 and tt - sep_at < 1.6 else "")
	var alt := 0.6 * tt * tt * 2.2
	if not exploded:
		rocket.position.y = Space.PAD_TOP + alt
		rocket.rotation_degrees.z = -clamp(tt - 2.0, 0.0, 6.0) * 3.0
		rocket.position.x = -pow(max(tt - 2.0, 0.0), 2.0) * 0.25
		var km := alt * 0.8
		var vel := tt * 0.45
		telemetry.text = "T+00:%02d · %.0f km · %.1f km/s" % [int(tt * 8.0), km, vel]
	# the sky darkens on the way up
	var k: float = clamp((tt - 1.0) / 5.0, 0.0, 1.0)
	var sky_m = world.world_env.environment.sky.sky_material
	if sky_m is ProceduralSkyMaterial:
		sky_m.sky_top_color = Color(0.18, 0.4, 0.78).lerp(Color(0, 0, 0.02), k)
		sky_m.sky_horizon_color = Color(0.62, 0.74, 0.88).lerp(Color(0.05, 0.08, 0.15), k)
	world.world_env.environment.ambient_light_energy = lerp(0.55, 0.3, k)
	# chase camera
	var cam: Camera3D = world.cam
	var rp := rocket.position
	if not exploded:
		var follow := rp + Vector3(6.0 + tt * 0.6, 1.5 - min(tt, 4.0) * 0.6, 8.0 + tt * 0.5)
		cam.position = cam.position.lerp(follow, clamp(delta * 2.0, 0.0, 1.0))
		cam.look_at(rp + Vector3(0, 2.5, 0), Vector3.UP)
	if not exploded:
		_staging(tt)
	_fall(delta)
	if GameState.last_sim.launch_failed and tt > 3.2 and not exploded:
		_explode()
	if exploded and tt > 7.0 and not launch_done:
		launch_done = true
		main.go_faded("report", 0.8, 0.6)
	elif not exploded and tt > 6.5 and not launch_done:
		launch_done = true
		main.go_faded("operation", 0.6, 0.8)


## The player's rocket sheds what it built to shed: the boosters, then each lower stage at its separator.
func _staging(tt: float) -> void:
	var asm := rocket.find_child("Assembled", true, false) as Node3D
	if asm == null:
		return
	var b := asm.get_node_or_null("Boosters") as Node3D
	if b and tt > 2.6:
		_drop(b, Vector3(0, -0.4, 0))
		for f in rocket.get_node("Flames").get_children():
			if f.has_meta("booster"):
				f.queue_free()
	var s0 := asm.get_node_or_null("Stage0") as Node3D
	if s0 and asm.get_child_count() > 1 and tt > 4.2:
		_drop(s0, Vector3(0, -0.8, 0))
		var flames := rocket.get_node("Flames") as Node3D
		flames.position.y = rocket.get_meta("stage1_y", 0.0)
		sep_at = tt
		big.add_theme_font_size_override("font_size", 64)


func _drop(n: Node3D, vel: Vector3) -> void:
	var xf := n.global_transform
	n.get_parent().remove_child(n)
	world.stage.add_child(n)
	n.global_transform = xf
	dropped.append([n, vel, randf_range(-0.6, 0.6), 0.0])


func _fall(delta: float) -> void:
	for d in dropped.duplicate():
		var n: Node3D = d[0]
		if not is_instance_valid(n):
			dropped.erase(d)
			continue
		d[3] += delta
		d[1] += Vector3(0, -3.0, 0) * delta
		n.global_position += d[1] * delta
		n.rotate_z(d[2] * delta)
		if d[3] > 5.0:
			n.queue_free()
			dropped.erase(d)


func _explode() -> void:
	exploded = true
	big.text = tr("LAUNCHER FAILURE!")
	big.add_theme_font_size_override("font_size", 56)
	big.add_theme_color_override("font_color", Kit.C_BAD)
	var pos := rocket.position + Vector3(0, 2.0, 0)
	rocket.visible = false
	var boom := Space.make_explosion()
	boom.position = pos
	world.stage.add_child(boom)
	for e in boom.get_children():
		(e as CPUParticles3D).emitting = true
	var flash := OmniLight3D.new()
	flash.position = pos
	flash.light_energy = 16.0
	flash.omni_range = 60.0
	flash.light_color = Color(1, 0.6, 0.3)
	world.stage.add_child(flash)
	flash.create_tween().tween_property(flash, "light_energy", 0.0, 1.5)
