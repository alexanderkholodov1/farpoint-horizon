extends SceneTree
## Prueba de robustez: diseños aleatorios en todos los escenarios.
func _initialize():
	var M = load("res://scripts/mission.gd")
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var n = 0
	var grades = {}
	for i in 600:
		var m = M.new()
		m.scenario = GameData.SCENARIOS.keys()[rng.randi() % 5]
		m.difficulty = GameData.DIFFICULTY.keys()[rng.randi() % 3]
		m.orbit = GameData.ORBITS.keys()[rng.randi() % 5]
		m.bus = GameData.BUSES.keys()[rng.randi() % 6]
		m.instruments = []
		for k in rng.randi() % 4:
			var id = GameData.INSTRUMENTS.keys()[rng.randi() % GameData.INSTRUMENTS.size()]
			if not m.instruments.has(id): m.instruments.append(id)
		m.panels = GameData.PANELS.keys()[rng.randi() % 5]
		m.battery = GameData.BATTERIES.keys()[rng.randi() % 5]
		m.comms = GameData.COMMS.keys()[rng.randi() % 4]
		m.adcs = GameData.ADCS.keys()[rng.randi() % 3]
		m.propulsion = GameData.PROPULSION.keys()[rng.randi() % 4]
		m.launcher = GameData.LAUNCHERS.keys()[rng.randi() % 4]
		m.years = [1,2,3,4,5,7,10][rng.randi() % 7]
		m.redundancy = rng.randf() < 0.5
		m.shielding = rng.randf() < 0.5
		var r = m.compute()
		var s = m.simulate(i)
		n += 1
		if not r.fatal:
			grades[s.score.grade] = grades.get(s.score.grade, 0) + 1
	print("ok ", n, " launchable grades ", grades)
	quit()
