extends "res://scripts/screens/screen.gd"
## From Earth orbit to the Moon (issue #8): the burn that leaves Earth orbit, flown by the pilot, then the coast.
## The burn adds the speed the scenario asks for (`flight.tli_dv`, about 3.2 km/s from low Earth orbit [S-delta-v]);
## the pilot fires it with BURN and cuts it with CUT when the gauge reaches the mark, easing the throttle near the
## end for a precise cut. A miss is never a failure: a correction on the way spends some of the lander's fuel.
## A pilot who lets go gets the flight computer, which cuts a little late on purpose (it plays safe).
## The coast is the real trip time (`flight.trip_hours`, 76 h for Apollo 11 [S-apollo11]) sped up to a few seconds.
## The scene is not to scale: the Moon is drawn far closer than it is, so both bodies fit on screen.
## Then the landing (screen "landing").

const Space := preload("res://scripts/space_builder.gd")
const Ship := preload("res://scripts/ship_builder.gd")
const FlightHud := preload("res://scripts/flight/flight_hud.gd")
const FlightData := preload("res://scripts/flight/flight_data.gd")
const Scene3D := preload("res://scripts/flight/flight_scene.gd")
const Sound := preload("res://scripts/flight/sound.gd")

const EARTH_R := 20.0           ## Scene units.
const MOON_R := 5.45            ## The Moon's size to the Earth's, 1737 / 6371 [S-nssdc-planets].
const MOON_D := 260.0           ## Scene units to the Moon (not to scale: really about 60 Earth radii).
const ORBIT_R := 23.0
const BURN_RATE := 280.0        ## m/s gained per second at full throttle (the burn sped up, a game value).
const COMPUTER_LATE := 1.02     ## The flight computer cuts at 102 % of the burn.
const OVERRUN := 1.3            ## Past this share the computer cuts whatever happens.
const COAST_S := 9.0            ## Real seconds the coast takes on screen.
const HANDS_OFF := 4.0
const CRAFT_SIZE := 0.45        ## The craft's size in scene units: small beside a 20-unit Earth, as in the other views
                                ## (look, #12: at 0.9 with the camera close it looked as big as the Moon).

var info: Dictionary
var target := 3200.0
var hours := 76.0
var hud
var craft: Node3D
var flame: CPUParticles3D
var moon: Node3D
var phase := "orbit"            ## orbit, burn, coast
var phase_t := 0.0
var ang := 0.0                  ## The craft's angle along its parking orbit.
var cam_off := Vector3.INF      ## The camera's place from the craft, damped (INF until the first frame).
var dv := 0.0
var throttle := 1.0
var idle := 0.0
var computer := false
var leaving := false
var told := {}
var sfx := {}
var rumble: AudioStreamPlayer
var start_pos := Vector3.ZERO
var start_vel := Vector3.ZERO
var old_far := 2000.0


func enter(_args: Dictionary) -> void:
	info = FlightData.scenario_flight(mission.scenario)
	target = float(info.get("tli_dv", 3200.0))
	hours = float(info.get("trip_hours", 76.0))
	world.cam_free = false
	world.clear_stage()
	old_far = world.cam.far
	world.cam.far = 4000.0
	world.world_env.environment.ambient_light_energy = 0.25
	var earth := Space.make_earth(EARTH_R, false)
	world.stage.add_child(earth)
	moon = Space.make_moon(MOON_R)
	moon.position = Vector3(-MOON_D * 0.85, MOON_D * 0.08, -MOON_D * 0.52)
	world.stage.add_child(moon)
	world.sun.rotation_degrees = Vector3(-20, 60, 0)
	craft = Ship.build(mission)
	var r: float = craft.get_meta("radius", 1.0)
	craft.scale = Vector3.ONE * (CRAFT_SIZE / maxf(r, 0.01))
	world.stage.add_child(craft)
	flame = Space.make_flame(0.25 * CRAFT_SIZE / 0.9)
	world.stage.add_child(flame)
	ang = 0.3
	_place_orbit()
	world.cam.position = craft.position + Vector3(3.4, 1.6, 4.4)
	world.cam.look_at(craft.position, Vector3.UP)
	_build_hud()
	for id in ["beep", "clunk", "chime"]:
		sfx[id] = Sound.player(self, id)
	rumble = Sound.player(self, "rumble", -40.0)


func exit() -> void:
	world.cam.far = old_far


func _build_hud() -> void:
	hud = FlightHud.new()
	add_child(hud)
	hud.build(tr("TO THE MOON"), tr("BURN"), tr("Space burn and cut · W S throttle"), false, false)
	hud.add_readout("dv", tr("Speed added"))
	hud.add_readout("goal", tr("The burn needs"))
	hud.add_gauge("burn", tr("Burn toward the Moon"), 1.0 / OVERRUN, 1.1 / OVERRUN, Color(0.45, 0.85, 1.0))
	hud.value("dv", "0 m/s")
	hud.value("goal", "%d m/s" % roundi(target))
	hud.gauge("burn", 0.0, "0 %")
	hud.lever.value = 1.0
	hud.action.lit = true
	hud.throttle_changed.connect(_on_lever)
	hud.action_pressed.connect(_on_action)
	hud.autopilot_toggled.connect(func(on): computer = on)
	hud.skip_pressed.connect(_skip)
	hud.set_autopilot(GameState.pilot_bot)
	computer = GameState.pilot_bot
	hud.clock.text = tr("Earth orbit")
	hud.hint(tr("You are circling the Earth. Press BURN to fire the engine and head for the Moon; press CUT when the gauge reaches %d m/s.") % roundi(target))


func _on_lever(v: float) -> void:
	throttle = v
	idle = 0.0


func _on_action() -> void:
	idle = 0.0
	if phase == "orbit":
		_start_burn()
	elif phase == "burn":
		_cut(false)


func process(delta: float) -> void:
	phase_t += delta
	match phase:
		"orbit":
			ang += delta * 0.35
			_place_orbit()
			if (computer or phase_t > 8.0) and phase_t > 2.0:
				if not computer and not told.has("auto"):
					hud.hint(tr("The flight computer starts the burn for you."))
				_start_burn()
		"burn":
			_burn(delta)
		"coast":
			_coast(delta)
	_camera(delta)
	flame.emitting = phase == "burn" and throttle > 0.02
	# the flame (it blows along its own -Y) trails behind the craft, out of its engine side (-Z)
	var back: Vector3 = -craft.basis.z.normalized()
	var fy := -back
	var fx := fy.cross(Vector3.UP).normalized() if absf(fy.y) < 0.99 else Vector3.RIGHT
	flame.basis = Basis(fx, fy, fx.cross(fy))
	flame.position = craft.position + back * CRAFT_SIZE * 0.67
	var loud: bool = flame.emitting
	if loud and not rumble.playing:
		rumble.play()
	rumble.volume_db = lerpf(rumble.volume_db, lerpf(-34.0, -16.0, throttle) if loud else -60.0, clampf(delta * 5.0, 0.0, 1.0))
	if rumble.volume_db < -55.0 and rumble.playing:
		rumble.stop()


func _place_orbit() -> void:
	craft.position = Vector3(cos(ang), 0.0, -sin(ang)) * ORBIT_R
	var ahead := Vector3(-sin(ang), 0.0, -cos(ang))
	craft.basis = Basis.looking_at(-ahead, Vector3.UP)     # its engine (-Z back) trails, its nose leads


func _start_burn() -> void:
	phase = "burn"
	phase_t = 0.0
	told["auto"] = true
	hud.action.label = "CUT"
	sfx.beep.play()
	hud.message(tr("BURN"), tr("Engine on. Watch the gauge."), Kit.C_ACCENT, 1.5)
	if not computer:
		hud.hint(tr("Ease the throttle down (S) as you near the mark, then press CUT (Space). Within 1 % is a perfect burn."))
	GameState.flight_moment("tli_start", {})


func _burn(delta: float) -> void:
	if hud.pilot_input():
		idle = 0.0
		if hud.autopilot:
			hud.set_autopilot(false)
			computer = false
	else:
		idle += delta
	if idle > HANDS_OFF and not computer:
		computer = true
		hud.hint(tr("Hands off: the flight computer will cut the engine. It cuts a little late, to be safe."))
	if computer:
		throttle = 1.0 if dv < target * 0.95 else 0.3
		hud.lever.value = throttle
	else:
		throttle = hud.throttle_keys(throttle, delta, 0.9)
	dv += BURN_RATE * throttle * delta
	ang += delta * 0.35
	_place_orbit()
	var share := dv / target
	hud.value("dv", "%d m/s" % roundi(dv), Kit.C_OK if absf(share - 1.0) <= 0.01 else Color.WHITE)
	hud.gauge("burn", dv / (target * OVERRUN), "%d %%" % roundi(share * 100.0))
	if computer and dv >= target * COMPUTER_LATE:
		_cut(true)
	elif dv >= target * OVERRUN:
		_cut(true)


func _cut(by_computer: bool) -> void:
	var error := (dv - target) / target
	var fuel_used := clampf(absf(error) * 1.5, 0.0, 0.45) if absf(error) > 0.01 else 0.0
	GameState.flight["tli"] = {"dv": roundi(dv), "target": roundi(target), "error": snappedf(error, 0.0001),
		"by": "computer" if by_computer else "pilot", "lander_fuel_used": snappedf(fuel_used, 0.001)}
	GameState.flight_moment("tli", GameState.flight.tli)
	phase = "coast"
	phase_t = 0.0
	hud.action.lit = false
	sfx.clunk.play()
	var pct := absf(error) * 100.0
	if absf(error) <= 0.01:
		sfx.chime.play()
		hud.message(tr("PERFECT BURN"), tr("Off by %.1f %%. Straight to the Moon.") % pct, Kit.C_OK, 3.0)
	elif error < 0.0:
		hud.message(tr("A LITTLE SHORT"), tr("Off by %.1f %%. A correction on the way spends some of the lander's fuel.") % pct, Kit.C_WARN, 3.0)
	else:
		hud.message(tr("A LITTLE LONG"), tr("Off by %.1f %%. A correction on the way spends some of the lander's fuel.") % pct, Kit.C_WARN, 3.0)
	hud.hint(tr("Now the long coast: no engine, just falling toward the Moon. Apollo 11 took about %d hours.") % roundi(hours))
	start_pos = craft.position
	start_vel = Vector3(-sin(ang), 0.0, -cos(ang))


func _coast(_delta: float) -> void:
	var k := clampf(phase_t / COAST_S, 0.0, 1.0)
	# a gentle curve from the parking orbit out to the Moon (a drawing of the path, not a trajectory)
	var end: Vector3 = moon.position + (Vector3.ZERO - moon.position).normalized() * (MOON_R * 1.6)
	var ctrl: Vector3 = start_pos + start_vel * MOON_D * 0.45
	var e := smoothstep(0.0, 1.0, k)
	var p := start_pos.lerp(ctrl, e).lerp(ctrl.lerp(end, e), e)
	if p.distance_to(craft.position) > 0.0001:
		craft.basis = Basis.looking_at(craft.position - p, Vector3.UP)
	craft.position = p
	# out in deep space the craft (a few metres) shrinks to a small bright point beside a Moon 3,474 km across (look, #12)
	var r: float = craft.get_meta("radius", 1.0)
	craft.scale = Vector3.ONE * (CRAFT_SIZE / maxf(r, 0.01)) * lerpf(1.0, 0.45, smoothstep(0.0, 0.25, k))
	hud.clock.text = tr("%d h of %d") % [roundi(hours * k), roundi(hours)]
	if k > 0.45 and not told.has("half"):
		told["half"] = true
		hud.hint(tr("Halfway there. The Earth's pull has been slowing you down; soon the Moon's pull takes over."))
	if k > 0.85 and not told.has("near"):
		told["near"] = true
		hud.message(tr("ARRIVING"), tr("A short burn behind the Moon slows you into orbit. Get ready to land."), Kit.C_ACCENT, 2.5)
	if k >= 1.0 and not leaving:
		leaving = true
		main.go_faded("landing", 1.0, 1.0)


## Skip: the computer flies the burn and the coast at once.
func _skip() -> void:
	if phase == "orbit":
		computer = true
		_start_burn()
	if phase == "burn":
		dv = target * COMPUTER_LATE
		_cut(true)
	phase_t = maxf(phase_t, COAST_S * 0.9)


func _camera(delta: float) -> void:
	var cam: Camera3D = world.cam
	var want: Vector3
	var look: Vector3 = craft.position
	if phase == "coast":
		# behind the craft, the Moon ahead growing
		var to_moon: Vector3 = (moon.position - craft.position).normalized()
		# far enough back that the craft is a small thing in space and the Moon grows ahead of it
		# from behind and a little to the side: the craft small in the foreground, the Moon ahead beside it
		var side: Vector3 = to_moon.cross(Vector3.UP).normalized()
		want = craft.position - to_moon * 7.0 + side * 2.2 + Vector3(0, 1.4, 0)
		look = craft.position.lerp(moon.position, 0.12)
	else:
		var out := craft.position.normalized()
		want = craft.position + out * 5.0 + Vector3(0, 2.2, 0) + craft.basis.z.normalized() * 3.4
	# smoothed relative to the craft, not in the world: in the coast the craft crosses 260 units in seconds and a
	# world-space lag left the camera far behind it (look, #12)
	var off_goal: Vector3 = want - craft.position
	cam_off = off_goal if cam_off == Vector3.INF else cam_off.lerp(off_goal, clampf(delta * 1.5, 0.0, 1.0))
	cam.position = craft.position + cam_off
	cam.look_at(look, Vector3.UP)
