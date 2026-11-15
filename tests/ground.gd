extends SceneTree
## Ground control (issue #9): the Deep Space Network's numbers and both mini-games, played through their own steps.
## Run: tools/godot.sh --headless --path . -s res://tests/ground.gd
## check: ^ok ground

const Dsn := preload("res://scripts/minigames/dsn.gd")
const Carrier := preload("res://scripts/minigames/carrier.gd")
const Triage := preload("res://scripts/minigames/triage.gd")

var fails := 0


func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		print("FAIL ", what)


func _initialize() -> void:
	# GMST at 2000 January 1, 12h UT is 18.697374558 h = 280.46 degrees [S-usno-gast]
	_ok(absf(Dsn.gmst_deg(946728000.0) - 280.4606) < 0.01, "gmst at J2000: %f" % Dsn.gmst_deg(946728000.0))
	# a sidereal day later the sky is back where it was (23 h 56 m 4 s)
	_ok(absf(Dsn.gmst_deg(946728000.0 + 86164.0905) - 280.4606) < 0.01, "gmst after a sidereal day")
	# the vernal equinox direction has ra 0, dec 0; 90 degrees of ecliptic longitude has dec +23.44
	_ok(Dsn.equatorial(0.0).length() < 0.001, "equinox")
	_ok(absf(Dsn.equatorial(90.0).y - 23.44) < 0.01, "solstice")
	# at every hour of a day some complex sees a far craft (the 120 degree rule) [S-dsn-facts]
	var seen := 0
	for h in 24:
		var b: Dictionary = Dsn.best_station(1794700800.0 + h * 3600.0, 3.0e8, 1.0e8)
		if b.up:
			seen += 1
	_ok(seen == 24, "one complex always up: %d of 24 hours" % seen)
	# the three take turns over a day
	var names := {}
	for h in 24:
		names[Dsn.best_station(1794700800.0 + h * 3600.0, 3.0e8, 1.0e8).id] = true
	_ok(names.size() == 3, "all three complexes take turns")
	# the Moon is about 1.28 s away [S-jpl-lighttime]; going away lowers the tone
	_ok(absf(Dsn.light_s(3.844e8) - 1.282) < 0.01, "light time to the Moon")
	_ok(Dsn.doppler_hz(5000.0) < 0.0 and absf(Dsn.doppler_hz(5000.0) + 140096.0) < 10.0, "doppler at 5 km/s away")

	# Find the carrier: click the line at each filter, narrow down, hold
	var f0 := -123456.0
	var c = Carrier.new()
	c.setup({"name": "Madrid", "place": "Spain", "elev": 40.0}, func() -> float: return f0, 0.2, 4400.0)
	for i in 3:
		c.set_band(i)
		c.tune(f0 + 100.0)
		c.step(0.1)
	_ok(c.inside(), "tuned inside the narrowest filter")
	var got := {}
	c.done.connect(func(r): got.merge(r))
	for i in 20:
		c.step(0.1)
	_ok(got.get("by", "") == "player" and int(got.get("bonus", 0)) >= Carrier.BONUS_MIN, "carrier locked by the player: %s" % str(got))
	# far off, it never locks
	var c2 = Carrier.new()
	c2.setup({"name": "Goldstone", "place": "California", "elev": 20.0}, func() -> float: return f0, 0.2, 4400.0)
	c2.set_band(2)
	c2.tune(0.0)
	for i in 30:
		c2.step(0.1)
	_ok(not c2.locked, "no lock when tuned off the tone")
	c.free()
	c2.free()

	# The 1202: shed the radar's jobs, keep the landing's, call go
	var g = Triage.new()
	g.setup({"code": "1202"})
	var res := {}
	g.done.connect(func(r): res.merge(r))
	g.add_job("guide")
	g.click(0)
	_ok(g.tray.size() == 1 and g.slips == 1, "a landing job is kept")
	g.tray = ["guide"]
	g.ages = [0.0]
	for i in Triage.SHED_FOR_GO:
		g.add_job("radar")
		g.click(g.tray.size() - 1)
	_ok(g.shed == Triage.SHED_FOR_GO, "radar jobs shed")
	g.call_go()
	_ok(res.get("go", false) and res.get("by", "") == "player" and int(res.bonus) == 90, "go called by the player: %s" % str(res))
	# a full tray restarts and keeps only the landing's jobs
	var g2 = Triage.new()
	g2.setup({"code": "1202"})
	for k in ["radar", "guide", "radar", "radar", "throttle"]:
		g2.add_job(k)
	_ok(g2.restarts == 1 and g2.tray == ["guide", "throttle"], "restart keeps the landing: %s" % str(g2.tray))
	# left alone, ground still calls go in time
	var g3 = Triage.new()
	g3.setup({"code": "1202"})
	var r3 := {}
	g3.done.connect(func(r): r3.merge(r))
	for i in 220:
		g3.step(0.1)
	_ok(r3.get("go", false), "go called in time when nobody plays")
	for n in [g, g2, g3]:
		n.free()

	print("ok ground" if fails == 0 else "ground: %d failed" % fails)
	quit(0 if fails == 0 else 1)
