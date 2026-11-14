extends SceneTree
## The pilot's flight, played by scripted hands (issue #8): the climb to orbit flown by the bot pilot, by a sloppy
## pilot and by one who tries to break the rocket; the landing flown by the bot, by players with slow reflexes, and
## by one who never touches the throttle. Prints what happened; fails if the generous cases do not end well or the
## deliberate ones do not end badly.
## Run: tools/godot.sh --headless --path . -s res://tests/flight.gd

const Ascent := preload("res://scripts/flight/ascent.gd")
const GD := preload("res://scripts/game_data.gd")
const Terrain := preload("res://scripts/flight/terrain.gd")
const Descent := preload("res://scripts/flight/descent.gd")
const FlightData := preload("res://scripts/flight/flight_data.gd")

var failures := 0


func _initialize() -> void:
	_ascent_cases()
	_landing_cases()
	print("flight test: ", failures, " failure(s)")
	quit(1 if failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1


## Flies a climb with a pilot function f(a) -> steer, staging when asked. Returns the summary.
func _fly(launcher: String, pilot: Callable, stage_delay := 0.5) -> Dictionary:
	var a = Ascent.new()
	a.setup(launcher, 2000.0, "lunar")
	var dt := 1.0 / 60.0
	var wait := 0.0
	for _i in 60 * 120:
		a.step(dt, pilot.call(a))
		if a.wants_stage():
			wait += dt
			if wait > stage_delay:
				a.stage()
				wait = 0.0
		if a.orbit or a.broken or a.crashed:
			break
	var s: Dictionary = a.summary()
	s.game_s = a.t / Ascent.TIME_SCALE
	return s


func _ascent_cases() -> void:
	var bot := func(a): return clampf((a.marker - a.pitch) * 0.5, -1.0, 1.0)
	for l in ["light", "medium", "heavy"]:
		var s := _fly(l, bot)
		print("bot ", l, " ", s)
		_check(s.orbit and not s.broken, "the bot pilot reaches orbit on the %s launcher" % l)
	# a lazy pilot who only steers every few seconds, late
	var lazy := func(a): return clampf(a.marker - a.pitch - 8.0, -1.0, 1.0) if int(a.t) % 40 < 8 else 0.0
	var s2 := _fly("medium", lazy, 3.0)
	print("lazy ", s2)
	_check(s2.orbit and not s2.broken, "a lazy pilot still reaches orbit")
	# a pilot who does nothing at all
	var idle := func(_a): return 0.0
	var s3 := _fly("medium", idle, 3.0)
	print("idle ", s3)
	# someone who holds the stick hard over at max-Q on purpose
	var wild := func(a): return 1.0 if a.h > 6000.0 else 0.0
	var s4 := _fly("medium", wild)
	print("wild ", s4)
	_check(s4.broken or s4.crashed, "holding the stick hard over at max-Q breaks the rocket")


## Flies the landing with a pilot function f(d) -> [throttle, steer]; a pilot who lets go for HANDS_OFF seconds gets
## the flight computer, as on the landing screen. Returns the touchdown result.
func _land(pilot: Callable, terrain, help := true) -> Dictionary:
	var d = Descent.new()
	d.setup(FlightData.scenario_flight("moon_south_pole").landing, terrain)
	var dt := 1.0 / 30.0
	var idle := 0.0
	for _i in 30 * 400:
		var a: Array = pilot.call(d)
		if a.is_empty():
			idle += dt
		else:
			idle = 0.0
		if a.is_empty() or (help and idle > 2.5):
			a = d.bot() if (help or not a.is_empty()) else [0.0, Vector2.ZERO]
		d.step(dt, a[0], a[1])
		if d.done:
			break
	return d.result


func _landing_cases() -> void:
	var t0 := Time.get_ticks_msec()
	var terrain = Terrain.new()
	terrain.setup(FlightData.scenario_flight("moon_south_pole").landing)
	print("terrain ready in ", Time.get_ticks_msec() - t0, " ms; shadow cells near the target ", terrain.shadow_pts.size(),
		"; target slope ", snappedf(terrain.slope_deg(0, 0), 0.1), " deg; earth in view at the target ", terrain.sees_earth(Vector3(0, 2, 0)))
	_check(terrain.slope_deg(0, 0) < 8.0, "the landing target is flat enough to land on")
	var bot := func(d): return d.bot()
	var r1 := _land(bot, terrain)
	print("bot lander ", r1)
	_check(r1.get("landed", false) and r1.grade in ["soft", "good"], "the bot lander sets down softly")
	_check(float(r1.get("target_m", 999.0)) < 60.0, "the bot lander lands near the target")
	# a slow pilot: only touches the throttle every few seconds, late, and never steers
	var slow := func(d):
		if int(d.t) % 6 < 2:
			return [0.9 if d.vel.y < -4.0 else 0.2, Vector2.ZERO]
		return []
	var r2 := _land(slow, terrain)
	print("slow pilot ", r2)
	_check(r2.get("landed", false), "a slow pilot still lands")
	# someone who never touches anything at all: the flight computer lands
	var idle := func(_d): return []
	var r3 := _land(idle, terrain)
	print("idle pilot ", r3)
	_check(r3.get("landed", false), "a pilot who never touches anything still lands")
	# someone who holds the engine off on purpose all the way down
	var off := func(_d): return [0.0, Vector2.ZERO]
	var r4 := _land(off, terrain)
	print("engine off ", r4)
	_check(r4.get("grade", "") == "crater", "holding the engine off all the way down makes a crater")
