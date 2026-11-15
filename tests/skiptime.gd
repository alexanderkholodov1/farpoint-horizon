extends Node
## How long Skip takes from the launch to the operation, flown twice in a row as "Fly again" does (development only).
var g


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(150.0).timeout.connect(func(): print("skiptime: timed out"); get_tree().quit())
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await get_tree().create_timer(1.5).timeout
	GameState.start_solo()
	GameState.start_mission("volcanes")
	GameState.mission.from_dict({"bus": "small", "instruments": ["ir_adv", "gas_adv"], "panels": "dep_m", "battery": "b1k", "comms": "xband", "adcs": "rw", "propulsion": "cold", "launcher": "ride", "orbit": "sso", "years": 2})
	for run in 2:
		g.launch()
		await get_tree().create_timer(5.0).timeout
		var t0 := Time.get_ticks_msec()
		g.screen._skip()
		var orbit_at := -1.0
		while g.screen_id != "operation" and Time.get_ticks_msec() - t0 < 60000:
			if orbit_at < 0.0 and g.screen_id == "launch" and g.screen.phase == "orbit":
				orbit_at = (Time.get_ticks_msec() - t0) / 1000.0
			await get_tree().process_frame
		print("run %d: orbit after %.1f s, operation after %.1f s (%s)" % [run, orbit_at, (Time.get_ticks_msec() - t0) / 1000.0, g.screen_id])
		await get_tree().create_timer(1.0).timeout
	get_tree().quit()
