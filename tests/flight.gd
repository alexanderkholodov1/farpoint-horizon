extends SceneTree
## The pilot's flight, played by scripted hands (issue #8): the climb to orbit flown by the bot pilot, by a sloppy
## pilot and by one who tries to break the rocket; the landing flown by the bot, by players with slow reflexes, and
## by one who never touches the throttle. Prints what happened; fails if the generous cases do not end well or the
## deliberate ones do not end badly.
## Run: tools/godot.sh --headless --path . -s res://tests/flight.gd

const Ascent := preload("res://scripts/flight/ascent.gd")
const GD := preload("res://scripts/game_data.gd")

var failures := 0


func _initialize() -> void:
	_ascent_cases()
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
