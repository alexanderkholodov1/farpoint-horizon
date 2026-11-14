extends "res://scripts/screens/screen.gd"
## From Earth orbit to an orbit around the Moon (issue #8), as a map at true scale, in real time with a time warp.
## The physics is scripts/flight/transfer.gd: the Earth's and the Moon's pull, the Moon where JPL Horizons puts it.
## What the player does, as a real crew and its mission control do:
##   1. Plan: mission control finds where on the parking orbit to fire the burn so the craft meets the Moon three or
##      four days later, where the Moon will be then (phasing). The plan is drawn: the path, and the Moon at arrival.
##      ↑ ↓ change the size of the burn (a bigger one is a faster trip); ← → move the burn to see how the path then
##      misses the Moon. R gives the planners' choice back.
##   2. Wait in orbit (speed up time with . and ,) for the countdown; at zero, BURN; CUT when the speed is added.
##   3. Coast. Six hours out, the mid-course correction mission control computes; CORRECT fires it.
##   4. At the Moon, BRAKE slows the craft into orbit around it. Then the landing (screen "landing").
## Generous: a pilot who lets go gets the flight computer, a missed window comes back on the next lap, a burn that is
## off is fixed by the correction, which spends some of the lander's fuel. Never a failure screen.
## Drawing: true proportions (the Earth 10 units across its radius); the craft and the burn point are markers of
## constant size on screen, never scaled-up models. Paths near the Moon are drawn as the Moon sees them.

const Space := preload("res://scripts/space_builder.gd")
const FlightHud := preload("res://scripts/flight/flight_hud.gd")
const FlightData := preload("res://scripts/flight/flight_data.gd")
const Sound := preload("res://scripts/flight/sound.gd")
const Transfer := preload("res://scripts/flight/transfer.gd")

const EARTH_U := 10.0               ## The Earth's radius in scene units.
const ORBIT_UTC := 13.0 * 3600.0    ## The craft reaches orbit at 13:00 UTC on 15 November 2026 (a game choice).
const DV_DEFAULT := 3150.0          ## m/s: a trip of about three and a half days, close to Apollo 11's 76 h [S-apollo11].
const DV_MIN := 3100.0
const DV_MAX := 3300.0
const CORRECT_AFTER := 6.0 * 3600.0 ## The mid-course correction, six hours after the burn.
const WINDOW_EARLY := 20.0          ## Seconds before the planned start the BURN button already works,
const WINDOW_LATE := 45.0           ## and after it.
const HANDS_OFF := 5.0              ## Real seconds without a touch before the flight computer acts.
const UNIX_DAY0 := 1794700800       ## 15 November 2026 00:00 UTC, the first row of the Moon's ephemeris.
const LUNAR_ORBIT_HIGH := 160000.0  ## The capture burn ends when the orbit's high point is below this height (m).

var m                                ## scripts/flight/transfer.gd
var hud
var r_park := 6.55e6
var n_park := 0.00119
var t_launch := 0.0
var u := 6.371e5                     ## metres per scene unit
var dv_plan := DV_DEFAULT
var shift_deg := 0.0                 ## The pilot's move of the burn point away from the plan.
var job := {}                        ## The planners at work (Transfer.plan_start), {} when idle.
var plan := {}                       ## {angle, time, pass}
var shown := {}                      ## The path drawn for the plan as shifted: a predict() result.
var burn_start := 0.0                ## When the burn should start (half of it before the planned point).
var phase := "plan"                  ## plan, burn, coast, capture, lunar
var phase_t := 0.0
var throttle := 1.0
var idle := 0.0
var missed := 0
var pred := {}                       ## Where the craft goes now (predict()), refreshed now and then.
var pred_age := 99.0
var correction := {}
var correction_state := ""           ## "", offered, done
var capture_at := 0.0
var braking := false
var leaving := false
var view := "trip"
var view_auto := true
var zoom := 1.0
var cam_center := Vector3.ZERO
var cam_dist := 60.0
var told := {}
var sfx := {}
var rumble: AudioStreamPlayer
var steer_was := Vector2.ZERO
var old_far := 2000.0

var earth: Node3D
var moon: Node3D
var ghost: MeshInstance3D
var ghost_lbl: Label3D
var craft: MeshInstance3D
var craft_lbl: Label3D
var mark: MeshInstance3D
var mark_lbl: Label3D
var plan_line: MeshInstance3D
var pred_line: MeshInstance3D
var trail_line: MeshInstance3D
var trail := PackedVector3Array()
var trail_t := 0.0
var moon_lbl: Label3D
var moon_dot: MeshInstance3D
var moon_track: MeshInstance3D
var earth_lbl: Label3D


func enter(_args: Dictionary) -> void:
	m = Transfer.new()
	m.setup()
	u = m.r_e / EARTH_U
	var climb: Dictionary = GameState.flight.get("ascent", {})
	r_park = m.r_e + float(climb.get("height_km", 166.0)) * 1000.0
	n_park = sqrt(m.mu_e / pow(r_park, 3.0))
	t_launch = ORBIT_UTC - float(climb.get("time_s", 480.0))
	m.place_circular(r_park, 0.0, ORBIT_UTC)
	world.cam_free = false
	world.clear_stage()
	old_far = world.cam.far
	world.cam.far = 30000.0
	world.cam.near = 0.05
	world.world_env.environment.ambient_light_energy = 0.25
	world.sun.rotation_degrees = Vector3(-25, 30, 0)
	_build_scene()
	_build_hud()
	for id in ["beep", "clunk", "chime", "alarm"]:
		sfx[id] = Sound.player(self, id)
	rumble = Sound.player(self, "rumble", -40.0)
	_replan()
	_camera(1.0, true)


func exit() -> void:
	world.cam.far = old_far


# ===================================================================================== SCENE
func _build_scene() -> void:
	earth = Space.make_earth(EARTH_U, false)
	world.stage.add_child(earth)
	earth_lbl = _label(tr("Earth"), Vector3(0, EARTH_U * 1.25, 0), Color(0.7, 0.85, 1.0))
	world.stage.add_child(earth_lbl)
	moon = Space.make_moon(m.r_m / u)
	world.stage.add_child(moon)
	moon_dot = _dot(Color(0.78, 0.78, 0.8))      # the Moon as a marker when it is too small to see
	world.stage.add_child(moon_dot)
	moon_lbl = _label(tr("Moon"), Vector3.ZERO, Color(0.9, 0.9, 0.92))
	world.stage.add_child(moon_lbl)
	# the Moon's real track over the month, from the ephemeris, dashed
	var track := PackedVector3Array()
	var k := 0
	var tt := 0.0
	while tt < 29.0 * Transfer.DAY:
		if k % 2 == 0:
			track.append(_v3(m.moon(tt)))
			track.append(_v3(m.moon(tt + 3.0 * 3600.0)))
		tt += 3.0 * 3600.0
		k += 1
	moon_track = _line_node(Color(0.75, 0.78, 0.85, 0.45))
	_set_line(moon_track, track, false)
	world.stage.add_child(moon_track)
	# the parking orbit
	var ring := PackedVector3Array()
	for i in 181:
		var a := TAU * i / 180.0
		ring.append(_v3([r_park * cos(a), r_park * sin(a)]))
	var rl := _line_node(Color(0.45, 0.8, 1.0, 0.85))
	_set_line(rl, ring)
	world.stage.add_child(rl)
	plan_line = _line_node(Color(0.4, 1.0, 0.6, 0.95))
	world.stage.add_child(plan_line)
	pred_line = _line_node(Color(0.45, 0.85, 1.0))
	world.stage.add_child(pred_line)
	trail_line = _line_node(Color(1.0, 0.72, 0.3, 0.9))
	world.stage.add_child(trail_line)
	ghost = _dot(Color(0.85, 0.87, 0.92, 0.35))
	world.stage.add_child(ghost)
	ghost_lbl = _label("", Vector3.ZERO, Color(0.85, 0.87, 0.92))
	world.stage.add_child(ghost_lbl)
	mark = _dot(Kit.C_OK)
	world.stage.add_child(mark)
	mark_lbl = _label(tr("Burn here"), Vector3.ZERO, Kit.C_OK)
	world.stage.add_child(mark_lbl)
	craft = _dot(Color.WHITE)
	world.stage.add_child(craft)
	craft_lbl = _label(tr("Your craft"), Vector3.ZERO, Color.WHITE)
	world.stage.add_child(craft_lbl)


func _build_hud() -> void:
	hud = FlightHud.new()
	add_child(hud)
	hud.build(tr("TO THE MOON"), tr("BURN"), tr("Space: act · W S throttle · , . time · V view · ← → ↑ ↓ plan · R reset"), true, false)
	hud.add_time_warp(1000.0)
	hud.add_readout("utc", tr("Date (UTC)"))
	hud.add_readout("next", tr("Next"))
	hud.add_readout("dv", tr("Burn"))
	hud.add_readout("trip", tr("Trip"))
	hud.add_readout("pass", tr("Pass over the Moon"))
	hud.add_readout("speed", tr("Speed"))
	hud.add_gauge("burn", tr("Speed added"), 1.02, 1.08, Color(0.45, 1.0, 0.7))
	hud.show_gauge("burn", false)
	hud.lever.value = 1.0
	hud.action.lit = false
	hud.throttle_changed.connect(_on_lever)
	hud.action_pressed.connect(_on_action)
	hud.autopilot_toggled.connect(_on_autopilot)
	hud.skip_pressed.connect(_skip)
	hud.set_autopilot(GameState.pilot_bot)
	hud.hint(tr("You are in orbit around the Earth. Mission control is working out when to leave so that you meet the Moon where it will be in three or four days."))


func _on_lever(v: float) -> void:
	throttle = v
	idle = 0.0


func _on_autopilot(on: bool) -> void:
	if on:
		hud.hint(tr("Autopilot on: the flight computer flies every step. Touch a control to take over."))


# ===================================================================================== EACH FRAME
func process(delta: float) -> void:
	phase_t += delta
	_input_plan()
	if hud.pilot_input():
		idle = 0.0
	else:
		idle += delta
	var dt: float = delta * hud.warp
	match phase:
		"plan":
			_plan_phase(dt)
		"burn":
			_burn_phase(dt)
		"coast":
			_coast_phase(dt)
		"capture":
			_capture_phase(dt)
		"lunar":
			_lunar_phase(dt)
	_draw()
	_camera(delta)
	_readouts()
	var loud: bool = (phase == "burn" or braking) and throttle > 0.02
	if loud and not rumble.playing:
		rumble.play()
	rumble.volume_db = lerpf(rumble.volume_db, lerpf(-34.0, -16.0, throttle) if loud else -60.0, clampf(delta * 5.0, 0.0, 1.0))
	if rumble.volume_db < -55.0 and rumble.playing:
		rumble.stop()


func _computer() -> bool:
	return hud.autopilot or idle > HANDS_OFF


# ===================================================================================== 1. PLAN AND WAIT
## Starts the planners again from where the craft is now (they take a second or two, spread over frames).
func _replan() -> void:
	var a_now := atan2(m.y, m.x)
	job = m.plan_start(r_park, a_now, m.t, dv_plan, 3.0, dv_plan / Transfer.BURN_ACCEL * 0.5 + 240.0)
	plan = {}
	shown = {}
	shift_deg = 0.0
	hud.message(tr("PLANNING"), tr("Mission control is computing your departure..."), Kit.C_ACCENT, 0.0)


func _plan_phase(dt: float) -> void:
	if not job.is_empty():
		if m.plan_work(job, 8.0):
			plan = job.result
			job = {}
			hud.message("", "", Color.WHITE, 0.01)
			if plan.is_empty():
				hud.hint(tr("No departure on this lap meets the Moon with this burn; try another burn size (↑ ↓)."))
			else:
				_show_plan()
				if not told.has("plan"):
					told["plan"] = true
					hud.hint(tr("The plan: burn at the green mark, on the far side of the Earth from where the Moon will be. Your path (green) swings out and meets the Moon three or four days later. Speed up time (.) to wait; it slows by itself before the burn."))
		_advance_orbit(dt)
		return
	if plan.is_empty():
		_advance_orbit(dt)
		return
	# the warp eases off as the burn nears, so the countdown is never skipped
	var left: float = burn_start - m.t
	if left > 900.0:
		hud.cap_warp(1000.0)
	elif left > 120.0:
		hud.cap_warp(10.0, tr("burn soon"))
	else:
		hud.cap_warp(1.0, tr("burn soon"))
	if dt > left and left > 0.0:
		dt = left      # stop exactly at the start of the burn
	_advance_orbit(dt)
	hud.action.label = "BURN"
	hud.action.lit = m.t >= burn_start - WINDOW_EARLY and m.t <= burn_start + WINDOW_LATE
	if m.t >= burn_start and (_computer() or missed > 0):
		if not hud.autopilot:
			hud.hint(tr("The flight computer starts the burn."))
		_start_burn()
	elif m.t > burn_start + WINDOW_LATE:
		missed += 1
		hud.message(tr("WINDOW MISSED"), tr("No harm: the planners move the burn to the next lap."), Kit.C_WARN, 2.5)
		_replan()


func _advance_orbit(dt: float) -> void:
	m.advance(dt)


## The plan as the pilot shifted it: the path from the moved burn point and where it passes the Moon.
func _show_plan() -> void:
	var a: float = plan.angle + deg_to_rad(shift_deg)
	var dep: Array = m.departure(r_park, atan2(m.y, m.x), a, m.t, dv_plan, dv_plan / Transfer.BURN_ACCEL * 0.5 + 60.0)
	if shift_deg == 0.0:
		shown = plan.pass
		dep[1] = plan.time
	else:
		shown = m.predict(dep[0], dep[1])
	burn_start = float(dep[1]) - dv_plan / Transfer.BURN_ACCEL * 0.5
	mark.position = _v3([r_park * cos(a), r_park * sin(a)])
	_draw_path(plan_line, shown)


## ↑ ↓ change the burn, ← → move it (each press), R resets; only while planning.
func _input_plan() -> void:
	if phase != "plan" or plan.is_empty() or not job.is_empty():
		steer_was = Vector2.ZERO
		return
	var s: Vector2 = hud.steer()
	var pressed := Vector2(s.x if s.x != steer_was.x else 0.0, s.y if s.y != steer_was.y else 0.0)
	steer_was = s
	if Input.is_physical_key_pressed(KEY_R) and shift_deg != 0.0:
		shift_deg = 0.0
		_show_plan()
		hud.hint(tr("Back to the planners' choice."))
	if pressed.x != 0.0:
		shift_deg += pressed.x * 1.0
		_show_plan()
		if not told.has("shift"):
			told["shift"] = true
			hud.hint(tr("Moving the burn by one degree moves your pass over the Moon by thousands of kilometres: that is why real missions plan the departure so carefully, and correct on the way. R gives the plan back."))
	elif pressed.y != 0.0:
		var nd := clampf(dv_plan + pressed.y * 25.0, DV_MIN, DV_MAX)
		if nd != dv_plan:
			dv_plan = nd
			_replan()
			if not told.has("dv"):
				told["dv"] = true
				hud.hint(tr("A bigger burn is a faster trip, but you arrive faster too, and need a bigger burn to stop at the Moon."))


func _on_action() -> void:
	idle = 0.0
	match phase:
		"plan":
			if plan.is_empty():
				return
			if hud.action.lit:
				_start_burn()
			else:
				hud.message(tr("NOT YET"), tr("Wait for the countdown: the burn starts in %s.") % _span(burn_start - m.t), Kit.C_WARN, 2.0)
		"burn":
			_cut(false)
		"coast":
			if correction_state == "offered":
				_correct(false)
		"capture":
			if not braking and m.t >= capture_at - WINDOW_EARLY:
				_brake()
			elif braking:
				_end_capture(false)


# ===================================================================================== 2. THE BURN
func _start_burn() -> void:
	phase = "burn"
	phase_t = 0.0
	m.dv_used = 0.0
	throttle = 1.0
	hud.lever.value = 1.0
	hud.cap_warp(10.0, tr("engine on"))
	hud.set_warp(1.0)
	hud.action.label = "CUT"
	hud.action.lit = true
	hud.show_gauge("burn", true)
	plan_line.visible = true
	mark.visible = false
	mark_lbl.visible = false
	sfx.beep.play()
	hud.message(tr("BURN"), tr("Engine on. About %s of burning.") % _span(dv_plan / Transfer.BURN_ACCEL), Kit.C_ACCENT, 2.0)
	if not _computer():
		hud.hint(tr("Hold the throttle and watch the speed you add. Press CUT (Space) when it reaches %d m/s; ease the throttle (S) near the end for a precise cut.") % roundi(dv_plan))
	GameState.flight_moment("tli_start", {"dv_plan": roundi(dv_plan)})


func _burn_phase(dt: float) -> void:
	if _computer():
		var left: float = dv_plan - m.dv_used
		throttle = clampf(left / 40.0, 0.15, 1.0)
		hud.lever.value = throttle
	else:
		throttle = hud.throttle_keys(throttle, get_process_delta_time(), 0.9)
	# never past the planned speed in one step when the computer flies
	var max_dt: float = dt
	if _computer() and throttle > 0.0:
		max_dt = minf(dt, (dv_plan - m.dv_used) / (Transfer.BURN_ACCEL * throttle))
	m.advance(maxf(max_dt, 0.0), throttle, 1.0)
	_refresh_pred(0.3)
	hud.gauge("burn", m.dv_used / dv_plan / 1.1, "%d / %d m/s" % [roundi(m.dv_used), roundi(dv_plan)])
	if _computer() and m.dv_used >= dv_plan - 0.05:
		_cut(true)
	elif m.dv_used >= dv_plan * 1.08:
		_cut(true)


func _cut(by_computer: bool) -> void:
	var error: float = (float(m.dv_used) - dv_plan) / dv_plan
	GameState.flight["tli"] = {"dv": roundi(m.dv_used), "target": roundi(dv_plan), "error": snappedf(error, 0.0001),
		"by": "computer" if by_computer else "pilot", "shift_deg": shift_deg, "burn_s": roundi(phase_t)}
	GameState.flight_moment("tli", GameState.flight.tli)
	phase = "coast"
	phase_t = 0.0
	throttle = 0.0
	hud.lever.value = 0.0
	hud.action.lit = false
	hud.show_gauge("burn", false)
	hud.cap_warp(100000.0)
	sfx.clunk.play()
	pred_age = 99.0
	_refresh_pred(0.0)
	var pct := absf(error) * 100.0
	if pct <= 1.0:
		sfx.chime.play()
		hud.message(tr("ON YOUR WAY"), tr("Off by %.1f %%. Next stop, the Moon.") % pct, Kit.C_OK, 3.0)
	else:
		hud.message(tr("ON YOUR WAY"), tr("Off by %.1f %%: the mid-course correction will fix it.") % pct, Kit.C_WARN, 3.0)
	hud.hint(tr("Engine off. Now you coast: the Earth's pull slows you as you climb. Speed up time (.) to cross the days; the trip takes about %s.") % _span(float(pred.get("t_closest", m.t)) - m.t))


# ===================================================================================== 3. THE COAST
func _coast_phase(dt: float) -> void:
	var t_cut: float = GameState.flight.tli.get("t_cut", 0.0)
	if t_cut == 0.0:
		GameState.flight.tli["t_cut"] = m.t
		t_cut = m.t
	# the correction: six hours out, mission control computes it, the crew fires it
	if correction_state == "" and m.t >= t_cut + CORRECT_AFTER:
		hud.set_warp(1.0)
		correction = m.plan_correction()
		correction_state = "offered"
		if correction.is_empty() or absf(float(correction.dv)) < 0.5:
			correction_state = "done"
			GameState.flight["correction"] = {"dv": 0.0}
			hud.message(tr("ON COURSE"), tr("No correction needed: you will pass %d km over the Moon.") % roundi(m.pass_height(pred) / 1000.0), Kit.C_OK, 3.0)
		else:
			hud.action.label = "CORRECT"
			hud.action.lit = true
			sfx.beep.play()
			hud.message(tr("MID-COURSE CORRECTION"), tr("Mission control: a %.1f m/s burn brings your pass to %d km over the Moon. Press CORRECT.") % [absf(float(correction.dv)), roundi(m.pass_height(correction.pass) / 1000.0)], Kit.C_ACCENT, 0.0)
			hud.hint(tr("Real crews made small corrections on the way: a tiny error at the start grows over 380,000 km."))
	if correction_state == "offered":
		if _computer() and idle > HANDS_OFF:
			_correct(true)
		return
	# the warp eases off near the Moon so the arrival is seen
	var cap_s: float = m.capture_dv(pred) / Transfer.BURN_ACCEL if not pred.is_empty() else 100.0
	capture_at = float(pred.get("t_closest", m.t + 1e9)) - cap_s * 0.5
	var left: float = capture_at - m.t
	if left > 6.0 * 3600.0:
		hud.cap_warp(100000.0)
	elif left > 3600.0:
		hud.cap_warp(1000.0, tr("near the Moon"))
	elif left > 300.0:
		hud.cap_warp(100.0, tr("near the Moon"))
	else:
		hud.cap_warp(1.0, tr("brake soon"))
	if dt > left and left > 0.0:
		dt = left
	m.advance(dt)
	_refresh_pred(0.5)
	if not told.has("half") and m.about_moon().r < Transfer.SOI:
		told["half"] = true
		hud.hint(tr("You are inside the Moon's sphere of influence: from here its pull is stronger than the Earth's, and it bends your path."))
	if m.t >= capture_at - WINDOW_EARLY - 10.0:
		phase = "capture"
		phase_t = 0.0
		hud.action.label = "BRAKE"
		hud.action.lit = true
		sfx.beep.play()
		hud.message(tr("BRAKE"), tr("You are falling past the Moon at %.1f km/s. Burn against your motion to stay in orbit around it.") % (m.about_moon().v / 1000.0), Kit.C_ACCENT, 3.0)


func _correct(by_computer: bool) -> void:
	m.kick(float(correction.dv))
	correction_state = "done"
	var dv := absf(float(correction.dv))
	# the correction comes out of the lander's tanks: 1000 m/s would be all of them (a game value)
	GameState.flight["correction"] = {"dv": snappedf(dv, 0.1), "by": "computer" if by_computer else "pilot"}
	GameState.flight.tli["lander_fuel_used"] = snappedf(clampf(dv / 1000.0, 0.0, 0.4), 0.001)
	hud.action.lit = false
	hud.message(tr("CORRECTED"), tr("%.1f m/s burned. You will pass %d km over the Moon.") % [dv, roundi(m.pass_height(correction.pass) / 1000.0)], Kit.C_OK, 3.0)
	sfx.clunk.play()
	pred_age = 99.0
	_refresh_pred(0.0)


# ===================================================================================== 4. CAPTURE
func _capture_phase(dt: float) -> void:
	hud.cap_warp(10.0 if braking else 1.0, tr("engine on") if braking else tr("brake soon"))
	if not braking and m.t >= capture_at and _computer():
		_brake()
	if braking:
		throttle = 1.0 if _computer() else hud.throttle_keys(throttle, get_process_delta_time(), 0.9)
		hud.lever.value = throttle
		m.advance(dt, throttle, -1.0, true)
		var o: Dictionary = m.moon_orbit()
		if o.high < LUNAR_ORBIT_HIGH and (_computer() or o.high < 120000.0):
			_end_capture(true)
	else:
		m.advance(dt)
		if m.t > capture_at + 120.0:
			_brake()       # the computer does not let the Moon go by
	_refresh_pred(0.4)


func _brake() -> void:
	braking = true
	m.dv_used = 0.0
	throttle = 1.0
	hud.lever.value = 1.0
	hud.action.label = "CUT"
	sfx.beep.play()


func _end_capture(by_computer: bool) -> void:
	var o: Dictionary = m.moon_orbit()
	if o.high == INF:
		hud.message(tr("NOT YET"), tr("Still too fast to stay: keep braking."), Kit.C_WARN, 1.5)
		return
	braking = false
	throttle = 0.0
	hud.lever.value = 0.0
	phase = "lunar"
	phase_t = 0.0
	hud.action.lit = false
	sfx.chime.play()
	GameState.flight["capture"] = {"dv": roundi(m.dv_used), "low_km": roundi(o.low / 1000.0), "high_km": roundi(o.high / 1000.0),
		"by": "computer" if by_computer else "pilot", "met_s": roundi(m.t - t_launch)}
	GameState.flight_moment("lunar_orbit", GameState.flight.capture)
	hud.cap_warp(100.0)
	hud.message(tr("IN ORBIT AROUND THE MOON"), tr("%d × %d km over its surface. The lander gets ready to go down.") % [roundi(o.low / 1000.0), roundi(o.high / 1000.0)], Kit.C_OK, 0.0)
	hud.hint(tr("Each lap around the Moon takes about two hours. Next: the landing at Shackleton's rim."))


func _lunar_phase(dt: float) -> void:
	m.advance(dt)
	_refresh_pred(0.5)
	if phase_t > 7.0 and not leaving:
		leaving = true
		GameState.flight["arrival_met_s"] = roundi(m.t - t_launch)
		main.go_faded("landing", 1.0, 1.0)


# ===================================================================================== SKIP
## Skip: the flight computer flies to the next step at once.
func _skip() -> void:
	idle = HANDS_OFF + 1.0
	match phase:
		"plan":
			if plan.is_empty():
				while not m.plan_work(job, 1.0e9):
					pass
				plan = job.result
				job = {}
				_show_plan()
			m.advance(maxf(burn_start - m.t, 0.0))
			_start_burn()
		"burn":
			while m.dv_used < dv_plan - 0.05:
				m.advance(minf(1.0, (dv_plan - m.dv_used) / Transfer.BURN_ACCEL), 1.0, 1.0)
			_cut(true)
		"coast":
			if correction_state == "":
				m.advance(maxf(float(GameState.flight.tli.get("t_cut", m.t)) + CORRECT_AFTER - m.t, 0.0))
				_coast_phase(0.0)
			if correction_state == "offered":
				_correct(true)
			pred_age = 99.0
			_refresh_pred(0.0)
			capture_at = float(pred.t_closest) - m.capture_dv(pred) / Transfer.BURN_ACCEL * 0.5
			m.advance(maxf(capture_at - m.t, 0.0))
			_coast_phase(0.0)
		"capture":
			if not braking:
				m.advance(maxf(capture_at - m.t, 0.0))
				_brake()
			while m.moon_orbit().high >= LUNAR_ORBIT_HIGH:
				m.advance(0.5, 1.0, -1.0, true)
			_end_capture(true)
		"lunar":
			phase_t = 99.0


# ===================================================================================== DRAWING
func _v3(p: Array) -> Vector3:
	return Vector3(p[0], 0.0, -p[1]) / u


func _refresh_pred(every: float) -> void:
	pred_age += get_process_delta_time()
	if pred_age < every:
		return
	pred_age = 0.0
	# once bound to the Moon, one lap around it (about two hours) is the path to show
	pred = m.predict(m.state(), m.t, 2.2 * 3600.0 if phase == "lunar" or (phase == "capture" and m.moon_orbit().high < INF) else 7.0 * Transfer.DAY)
	_draw_path(pred_line, pred)


## A predicted path, where each point will be at its time (so it meets the Moon drawn where the Moon will be then).
## Once the craft is near the Moon, the points near the Moon are drawn as the Moon sees them (relative to the Moon,
## where it is now), so an orbit around it is a closed loop, not a smear left by the Moon's own motion.
func _draw_path(line: MeshInstance3D, p: Dictionary) -> void:
	var moon_frame: bool = phase in ["capture", "lunar"] or m.about_moon().r < Transfer.SOI
	var pts: PackedVector2Array = p.get("points", PackedVector2Array())
	var ts: PackedFloat64Array = p.get("times", PackedFloat64Array())
	var mn: Array = m.moon(m.t)
	var out := PackedVector3Array()
	var step := maxi(1, pts.size() / 600)
	for i in range(0, pts.size(), step):
		var q := [pts[i].x, pts[i].y]
		var mt: Array = m.moon(ts[i])
		var d := Vector2(q[0] - mt[0], q[1] - mt[1]).length()
		if moon_frame and d < Transfer.SOI:
			q = [q[0] - mt[0] + mn[0], q[1] - mt[1] + mn[1]]
		out.append(_v3(q))
	_set_line(line, out)


func _draw() -> void:
	var cam: Vector3 = world.cam.global_position
	var mp: Vector3 = _v3(m.moon(m.t))
	moon.position = mp
	moon.rotation.y = atan2(mp.x, mp.z) + PI      # the same face always toward the Earth
	earth.rotation.y = TAU * m.t / (FlightData.fact("earth", "sidereal_rotation_h", 23.9345) * 3600.0)
	moon_lbl.position = mp + Vector3(0, (m.r_m / u) * 1.6 + cam.distance_to(mp) * 0.03, 0)
	var cp: Vector3 = _v3([m.x, m.y])
	craft.position = cp
	var s := cam.distance_to(cp) * 0.009
	craft.scale = Vector3.ONE * s
	moon_dot.position = mp
	moon_dot.scale = Vector3.ONE * maxf(m.r_m / u * 1.02, cam.distance_to(mp) * 0.007)
	(craft.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.62, 0.22) if (phase == "burn" or braking) and throttle > 0.02 else Color.WHITE
	craft_lbl.position = cp + Vector3(0, s * 3.5, 0)
	mark.scale = Vector3.ONE * cam.distance_to(mark.position) * 0.008
	mark_lbl.position = mark.position + Vector3(0, mark.scale.x * 3.5, 0)
	var showing_plan: bool = phase == "plan" and not plan.is_empty()
	mark.visible = showing_plan
	# labels that would sit on top of each other at this scale stay hidden: near the Earth in the trip view, the Earth
	# itself in the Earth view
	mark_lbl.visible = showing_plan and view == "earth"
	craft_lbl.visible = view != "trip" or m.about_moon().r < Transfer.SOI or (phase == "coast" and m.x * m.x + m.y * m.y > 4.0e15)
	earth_lbl.visible = view == "trip"
	plan_line.visible = phase in ["plan", "burn"] and not plan.is_empty()
	pred_line.visible = phase != "plan"
	# where the Moon will be at the closest pass of the path drawn
	var p: Dictionary = shown if phase == "plan" else pred
	ghost.visible = not p.is_empty() and phase in ["plan", "burn", "coast"] and m.about_moon().r > Transfer.SOI
	moon_track.visible = view != "moon"
	ghost_lbl.visible = ghost.visible
	if ghost.visible:
		var gp := _v3(p.moon_at)
		ghost.position = gp
		ghost.scale = Vector3.ONE * maxf(m.r_m / u, cam.distance_to(gp) * 0.008)
		ghost_lbl.position = gp - Vector3(0, ghost.scale.x * 2.5, 0)
		ghost_lbl.text = tr("The Moon when you pass it (%s)") % _span(float(p.t_closest) - m.t)
	# the track flown so far
	trail_t += get_process_delta_time()
	# (inside the Moon's sphere the Moon moves under the craft, so there the predicted path shows the orbit instead)
	trail_line.visible = phase in ["burn", "coast"]
	if phase in ["burn", "coast"] and trail_t > 0.05 and m.about_moon().r > Transfer.SOI:
		trail_t = 0.0
		if trail.is_empty() or trail[trail.size() - 1].distance_to(cp) > s * 0.4:
			trail.append(cp)
			if trail.size() > 2000:
				trail.remove_at(0)
			_set_line(trail_line, trail)


func _dot(col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.0
	sp.height = 2.0
	sp.radial_segments = 16
	sp.rings = 8
	mi.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _label(text: String, pos: Vector3, col: Color) -> Label3D:
	var l := Space.make_label(text, col)
	l.position = pos
	return l


func _line_node(col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _set_line(mi: MeshInstance3D, pts: PackedVector3Array, strip := true) -> void:
	var im := mi.mesh as ImmediateMesh
	im.clear_surfaces()
	if pts.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP if strip else Mesh.PRIMITIVE_LINES)
	for q in pts:
		im.surface_add_vertex(q)
	im.surface_end()


# ===================================================================================== READOUTS AND CAMERA
func _readouts() -> void:
	hud.clock.text = FlightHud.met_text(m.t - t_launch)
	var dt := Time.get_datetime_dict_from_unix_time(UNIX_DAY0 + int(m.t))
	hud.value("utc", "%d %s %02d:%02d" % [dt.day, ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][dt.month - 1], dt.hour, dt.minute])
	var next := ""
	match phase:
		"plan":
			next = tr("planning...") if plan.is_empty() else tr("burn in %s") % _span(burn_start - m.t)
		"burn":
			next = tr("cut at %d m/s") % roundi(dv_plan)
		"coast":
			next = tr("correction") if correction_state != "done" else tr("brake in %s") % _span(capture_at - m.t)
		"capture":
			next = tr("brake now") if braking or m.t >= capture_at - WINDOW_EARLY else tr("brake in %s") % _span(capture_at - m.t)
		"lunar":
			next = tr("landing")
	hud.value("next", next)
	hud.value("dv", "%d m/s" % roundi(dv_plan))
	var p: Dictionary = shown if phase == "plan" else pred
	if phase == "lunar":
		var o: Dictionary = m.moon_orbit()
		hud.value("trip", tr("arrived"))
		hud.value("pass", "%d × %d km" % [roundi(o.low / 1000.0), roundi(o.high / 1000.0)], Kit.C_OK)
	elif not p.is_empty():
		var reaches: bool = float(p.closest) < Transfer.SOI
		hud.value("trip", _span(float(p.t_closest) - (burn_start if phase == "plan" else m.t)) if reaches else "—")
		var hgt: float = m.pass_height(p)
		var col := Kit.C_OK if hgt > 30000.0 and hgt < 400000.0 else (Kit.C_BAD if p.impact or hgt < 0.0 else Kit.C_WARN)
		hud.value("pass", tr("hits the Moon") if p.impact or hgt < 0.0 else (tr("misses it") if float(p.closest) > Transfer.SOI else "%s km" % FlightHud._thousands(hgt / 1000.0)), col)
	if phase in ["capture", "lunar"] or m.about_moon().r < Transfer.SOI:
		var am: Dictionary = m.about_moon()
		hud.value("speed", tr("%.2f km/s past the Moon") % (am.v / 1000.0))
	else:
		hud.value("speed", "%.2f km/s" % (sqrt(m.vx * m.vx + m.vy * m.vy) / 1000.0))


## A span of time in words: "41 min", "3 d 10 h", "52 s".
func _span(s: float) -> String:
	s = maxf(s, 0.0)
	if s < 120.0:
		return tr("%d s") % roundi(s)
	if s < 3.0 * 3600.0:
		return tr("%d min") % roundi(s / 60.0)
	if s < 2.0 * Transfer.DAY:
		return tr("%d h") % roundi(s / 3600.0)
	var hours := roundi(s / 3600.0)
	return tr("%d d %d h") % [hours / 24, hours % 24]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_V:
		var order := ["earth", "trip", "moon"]
		view = order[(order.find(view) + 1) % order.size()]
		view_auto = false
		zoom = 1.0
		hud.message(tr("VIEW"), {"earth": tr("The Earth and your orbit"), "trip": tr("The whole trip"), "moon": tr("The Moon")}[view], Color.WHITE, 1.0)
	elif e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		zoom = clampf(zoom * (0.85 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.18), 0.15, 6.0)


func _camera(delta: float, snap := false) -> void:
	if view_auto:
		match phase:
			"plan":
				view = "earth" if not plan.is_empty() and burn_start - m.t < 600.0 else "trip"
			"burn":
				view = "earth"
			"coast":
				view = "moon" if m.about_moon().r < Transfer.SOI * 0.6 else "trip"
			_:
				view = "moon"
	var mp: Vector3 = _v3(m.moon(m.t))
	var want_c := Vector3.ZERO
	var want_d := 45.0
	match view:
		"earth":
			want_c = Vector3.ZERO
			want_d = 46.0
			if phase == "burn":
				want_d = 46.0 + clampf(m.dv_used / dv_plan, 0.0, 1.0) * 120.0
		"trip":
			# the Earth, the Moon now and the Moon at the pass all in view, a little above centre (the panels sit low)
			var pts: Array = [Vector3.ZERO, mp]
			var p: Dictionary = shown if phase == "plan" else pred
			if not p.is_empty() and phase != "lunar":
				pts.append(_v3(p.moon_at))
			var lo := Vector3(INF, 0, INF)
			var hi := Vector3(-INF, 0, -INF)
			for q in pts:
				lo = Vector3(minf(lo.x, q.x), 0, minf(lo.z, q.z))
				hi = Vector3(maxf(hi.x, q.x), 0, maxf(hi.z, q.z))
			want_c = (lo + hi) * 0.5 + Vector3(0, 0, (hi - lo).length() * 0.08)
			want_d = maxf(hi.x - lo.x, (hi.z - lo.z) * 1.6) * 0.95 + 60.0
		"moon":
			want_c = mp
			var r: float = m.about_moon().r / u
			want_d = clampf(r * 2.6, 34.0, 220.0)
	want_d *= zoom
	var k := 1.0 if snap else clampf(delta * 2.0, 0.0, 1.0)
	cam_center = cam_center.lerp(want_c, k)
	cam_dist = lerpf(cam_dist, want_d, k)
	world.cam.position = cam_center + Vector3(0.0, 0.97, 0.24).normalized() * cam_dist
	world.cam.look_at(cam_center, Vector3.UP)
