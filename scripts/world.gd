extends Node3D
## The 3D world every screen shares: sky, lights, the orbital camera, and the stage (Earth, Moon, orbit, the craft).
## main.gd creates it once and calls update() every frame. A screen picks a ready stage (stage_menu, stage_design,
## stage_orbit, stage_earth) or builds its own on `stage` after clear_stage(), as the launch screen does.
## Builders of the pieces: scripts/space_builder.gd (places, rocket) and scripts/ship_builder.gd (the craft).

const Mission := preload("res://scripts/mission.gd")
const Ship := preload("res://scripts/ship_builder.gd")
const Space := preload("res://scripts/space_builder.gd")

var world_env: WorldEnvironment
var sun: DirectionalLight3D
var cam: Camera3D

# ---- orbital camera: it circles cam_target at cam_dist; the mouse drags it and the wheel zooms
## False while a screen drives the camera itself (launch): no orbit, no mouse. main.gd resets it on every screen change.
var cam_free := true
var cam_yaw := 0.6
var cam_pitch := -0.25
var cam_dist := 4.0
var cam_dist_goal := 4.0
var cam_target := Vector3.ZERO
var cam_auto := true
var cam_auto_timer := 0.0
var dragging := false

# ---- stage: what is shown now; clear_stage() replaces it
var stage: Node3D
var ship: Node3D            ## The craft being designed (stage_design).
var planet: Node3D
var orbit_ship: Node3D      ## The craft circling its orbit (stage_menu, stage_orbit).
var orbit_center := Vector3.ZERO
var orbit_radius := 1.3
var orbit_basis := Basis.IDENTITY
var orbit_angle := 0.0
var orbit_speed := 1.0
var ship_lost := false
var ship_label: Label3D
var cloud_shift := 0.0     ## Drift of the Earth's cloud layer (U of its texture).


func setup() -> void:
	GameState.trace("creando cielo")
	world_env = Space.make_environment()
	add_child(world_env)
	GameState.trace("cielo listo")
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


## Called by main.gd every frame, before the screen's process().
func update(delta: float) -> void:
	_update_camera(delta)
	_animate_world(delta)


# ===================================================================================== CAMERA AND INPUT
func _update_camera(delta: float) -> void:
	if not dragging:
		cam_auto_timer -= delta
		if cam_auto and cam_auto_timer <= 0.0:
			cam_yaw += delta * 0.12
	cam_dist = lerp(cam_dist, cam_dist_goal, clamp(delta * 3.0, 0.0, 1.0))
	if not cam_free:
		return
	var off := Vector3(cos(cam_pitch) * sin(cam_yaw), -sin(cam_pitch), cos(cam_pitch) * cos(cam_yaw)) * cam_dist
	cam.position = cam_target + off
	cam.look_at(cam_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not cam_free:
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


## Points the camera's yaw from the sun's side, plus `extra` radians.
func face_sun(extra := 0.8) -> void:
	var sd: Vector3 = sun.global_transform.basis.z
	cam_yaw = atan2(sd.x, sd.z) + extra


func _animate_world(delta: float) -> void:
	# the Sun's direction for the night side of the Earth, and the slow drift of its clouds
	cloud_shift = fmod(cloud_shift + delta * 0.0012, 1.0)
	var sd: Vector3 = sun.global_transform.basis.z
	for m in get_tree().get_nodes_in_group(Space.SUN_LIT):
		var mat := (m as MeshInstance3D).material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("sun_dir", sd)
			mat.set_shader_parameter("cloud_shift", cloud_shift)
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
	if orbit_ship and is_instance_valid(orbit_ship) and not ship_lost:
		orbit_angle += delta * orbit_speed
		var p := orbit_basis * Vector3(cos(orbit_angle), 0, sin(orbit_angle)) * orbit_radius
		var tangent := orbit_basis * Vector3(-sin(orbit_angle), 0, cos(orbit_angle))
		orbit_ship.position = orbit_center + p
		orbit_ship.look_at(orbit_ship.position + tangent, (orbit_basis * Vector3.UP))
		if ship_label and is_instance_valid(ship_label):
			ship_label.position = orbit_ship.position + Vector3(0, 0.12, 0)


# ===================================================================================== STAGES
## Empties the stage and restores the space sky and light.
func clear_stage() -> void:
	if stage and is_instance_valid(stage):
		stage.queue_free()
	stage = Node3D.new()
	add_child(stage)
	ship = null
	planet = null
	orbit_ship = null
	ship_label = null
	ship_lost = false
	world_env.environment.sky = Space.make_space_sky()
	world_env.environment.ambient_light_energy = 0.35
	world_env.environment.fog_enabled = false
	world_env.environment.tonemap_exposure = 1.0
	cam.far = 2000.0
	sun.rotation_degrees = Vector3(-30, -60, 0)


## The menu: the Earth on the right with a demo craft circling it.
func stage_menu() -> void:
	clear_stage()
	GameState.trace("creando Tierra")
	planet = Space.make_earth(1.0)
	stage.add_child(planet)
	GameState.trace("Tierra lista")
	var demo = Mission.new()
	demo.from_dict({"bus": "small", "instruments": ["cam_ms", "ir_adv"], "panels": "dep_m", "comms": "xband", "adcs": "rw", "propulsion": "cold"})
	setup_orbit_ship(demo, Vector3.ZERO, 1.35, 98.0, 0.1)
	ship_label.visible = false
	cam_auto = false
	cam_yaw = 0.0
	cam_pitch = -0.12
	cam_dist_goal = 3.6
	cam_dist = 3.6
	cam_target = Vector3(-1.25, 0.05, 0)


## Puts the craft of mission m on a circular orbit (ring, craft, tr("YOUR CRAFT") label); _animate_world moves it.
func setup_orbit_ship(m, center: Vector3, radius: float, incl: float, ship_size: float) -> void:
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
	ship_label = Space.make_label(tr("YOUR CRAFT"), Color(0.55, 0.9, 1.0))
	stage.add_child(ship_label)
	orbit_speed = 0.35


## The design: GameState's craft up close, above the Earth or the Moon.
func stage_design() -> void:
	clear_stage()
	var mission = GameState.mission
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
	face_sun(0.5)
	rebuild_ship()


## Rebuilds the designed craft from GameState's mission (after a part changes).
func rebuild_ship() -> void:
	if ship and is_instance_valid(ship):
		ship.queue_free()
	ship = Ship.build(GameState.mission)
	stage.add_child(ship)
	var r: float = ship.get_meta("radius")
	cam_dist_goal = r * 2.6 + 0.9


## The operation: GameState's craft on its orbit around the Earth, the Moon, or at L2.
func stage_orbit() -> void:
	clear_stage()
	var mission = GameState.mission
	var O: Dictionary = GameData.ORBITS[mission.orbit]
	var ship_size := 0.11
	if mission.orbit == "lunar":
		planet = Space.make_moon(1.0)
		stage.add_child(planet)
		var earth := Space.make_earth(1.4, false)
		earth.position = Vector3(-30, 6, -40)
		stage.add_child(earth)
		setup_orbit_ship(mission, Vector3.ZERO, O.radius, O.incl, ship_size)
		cam_target = Vector3.ZERO
		cam_dist_goal = 3.6
	elif mission.orbit == "l2":
		planet = Space.make_earth(1.0)
		stage.add_child(planet)
		var sun_dir := sun.global_transform.basis.z
		var l2: Vector3 = -sun_dir * O.radius
		setup_orbit_ship(mission, l2, 0.7, 90.0, 0.35)
		cam_target = l2 * 0.5
		cam_dist_goal = 11.0
		var l2l := Space.make_label(tr("L2 point · 1.5 million km"), Color(0.85, 0.75, 1.0))
		l2l.position = l2 + Vector3(0, -0.95, 0)
		stage.add_child(l2l)
		var line := Space.make_orbit_ring(O.radius, 0.0, Color(1, 1, 1, 0.08))
		stage.add_child(line)
	else:
		planet = Space.make_earth(1.0)
		stage.add_child(planet)
		if mission.orbit == "geo":
			ship_size = 0.2
		setup_orbit_ship(mission, Vector3.ZERO, O.radius, O.incl, ship_size)
		cam_target = Vector3.ZERO
		cam_dist_goal = 3.4 if O.radius < 2.0 else 8.5
	orbit_speed = {"leo": 0.5, "sso": 0.45, "geo": 0.12, "lunar": 0.45, "l2": 0.6}.get(mission.orbit, 0.4)
	cam_dist = cam_dist_goal
	cam_auto = true
	cam_pitch = -0.3
	face_sun()
	if mission.orbit == "l2":
		cam_auto = false
		cam_pitch = -0.15
		face_sun(PI / 2.0)


## The Earth alone (the report after a launch failure).
func stage_earth() -> void:
	clear_stage()
	planet = Space.make_earth(1.0)
	stage.add_child(planet)
	cam_target = Vector3.ZERO
	cam_dist_goal = 3.4
	cam_auto = true
	face_sun()


## The orbiting craft is lost: it falls (low orbits) and vanishes.
func lose_ship() -> void:
	if orbit_ship == null or ship_lost:
		return
	ship_lost = true
	var tw := create_tween()
	if GameState.mission.orbit == "leo" or GameState.mission.orbit == "sso":
		tw.tween_property(orbit_ship, "position", orbit_ship.position * 0.98, 1.5)
	tw.tween_property(orbit_ship, "scale", Vector3.ONE * 0.0001, 0.6)
