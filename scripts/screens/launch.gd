extends "res://scripts/screens/screen.gd"
## Launch: the countdown, liftoff from the pad among the Andes, the ascent (or the launcher's failure), then the fade
## to the operation (or to the report after a failure). The outcome was decided at launch (GameState.last_sim).

const Space := preload("res://scripts/space_builder.gd")

var rocket: Node3D
var launch_t := 0.0
var exploded := false
var launch_done := false
var telemetry: Label
var big: Label


func enter(_args: Dictionary) -> void:
	world.cam_free = false
	world.clear_stage()
	var env: Environment = world.world_env.environment
	env.sky = Space.make_day_sky()
	env.ambient_light_energy = 0.8
	world.sun.rotation_degrees = Vector3(-50, -30, 0)
	world.stage.add_child(Space.make_pad())
	rocket = Space.make_rocket(mission.launcher)
	rocket.position = Vector3(0, 0.2, 0)
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
	v.add_child(Kit.lbl(tr("LAUNCH") + " · " + GameData.LAUNCHERS[mission.launcher].name, 15, Kit.C_ACCENT, Kit.FONT_B))
	telemetry = Kit.lbl("T-00:03", 26, Color.WHITE, Kit.FONT_T)
	v.add_child(telemetry)
	v.add_child(Kit.lbl(tr("Destination") + " · " + GameData.ORBITS[mission.orbit].name, 14, Kit.C_DIM))
	big = Kit.lbl("3", 120, Color.WHITE, Kit.FONT_T)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Kit.place(big, 0.5, 0.35, 0.5, 0.35, -300, -80, 300, 80)
	add_child(big)
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
		return
	var tt := launch_t - 3.0
	big.text = tr("LIFTOFF!") if tt < 1.5 else ""
	var alt := 0.6 * tt * tt * 2.2
	if not exploded:
		rocket.position.y = 0.2 + alt
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
	world.world_env.environment.ambient_light_energy = lerp(0.8, 0.3, k)
	# chase camera
	var cam: Camera3D = world.cam
	var rp := rocket.position
	if not exploded:
		var follow := rp + Vector3(6.0 + tt * 0.6, 1.5 - min(tt, 4.0) * 0.6, 8.0 + tt * 0.5)
		cam.position = cam.position.lerp(follow, clamp(delta * 2.0, 0.0, 1.0))
		cam.look_at(rp + Vector3(0, 2.5, 0), Vector3.UP)
	if GameState.last_sim.launch_failed and tt > 3.2 and not exploded:
		_explode()
	if exploded and tt > 7.0 and not launch_done:
		launch_done = true
		main.go_faded("report", 0.8, 0.6)
	elif not exploded and tt > 6.5 and not launch_done:
		launch_done = true
		main.go_faded("operation", 0.6, 0.8)


func _explode() -> void:
	exploded = true
	big.text = tr("LAUNCHER FAILURE!")
	big.add_theme_font_size_override("font_size", 56)
	big.add_theme_color_override("font_color", Kit.C_BAD)
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
	world.stage.add_child(boom)
	boom.emitting = true
	var flash := OmniLight3D.new()
	flash.position = pos
	flash.light_energy = 16.0
	flash.omni_range = 60.0
	flash.light_color = Color(1, 0.6, 0.3)
	world.stage.add_child(flash)
	flash.create_tween().tween_property(flash, "light_energy", 0.0, 1.5)
