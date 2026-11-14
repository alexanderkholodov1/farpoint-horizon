extends Node
## Scripted walkthrough: plays through the game and saves screenshots to the project's shots/ folder (development only; needs a window).
## It drives the game as the buttons do: GameState for the choices, g.go(screen id) and g.overlay(id) for the flow.
var g

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
	print("shot ", name)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.5)
	await shot("01_menu")
	GameState.start_solo()
	g.go("missions")
	await wait(0.5)
	await shot("02_scenarios")
	GameState.start_mission("volcanes")
	g.go("design", {"step": 0})
	GameState.mission.from_dict({"bus": "small", "instruments": ["ir_adv", "gas_adv", "cam_ms"], "panels": "dep_m", "battery": "b1k", "comms": "xband", "adcs": "rw", "propulsion": "cold", "launcher": "ride", "orbit": "sso", "years": 3})
	g.world.rebuild_ship()
	g.go("design", {"step": 2})
	await wait(1.5)
	await shot("03_instruments")
	g.go("design", {"step": 7})
	await wait(0.5)
	await shot("04_review")
	g.launch()
	await wait(4.6)
	await shot("05_launch")
	await wait(4.0)
	await shot("06_launch_high")
	while g.screen_id != "operation":
		await wait(0.2)
	await wait(5.0)
	await shot("07_sim")
	g.screen.month_f = 9999.0
	while g.screen_id != "report":
		await wait(0.2)
	await wait(1.0)
	await shot("08_report")
	# Moon
	GameState.start_mission("luna")
	g.go("design", {"step": 0})
	GameState.mission.from_dict({"bus": "medium", "instruments": ["cam_ms", "gamma"], "panels": "dep_m", "battery": "b1k", "comms": "ka", "adcs": "st", "propulsion": "chem", "launcher": "medium", "orbit": "lunar", "years": 1, "redundancy": true, "shielding": true})
	g.world.stage_design()
	g.go("design", {"step": 5})
	await wait(1.5)
	await shot("09_luna_design")
	GameState.last_sim = GameState.mission.simulate(5)
	GameState.last_report = GameState.mission.compute()
	g.go("operation")
	await wait(3.0)
	await shot("10_luna_orbit")
	# Telescope at L2
	GameState.start_mission("telescopio")
	g.go("design", {"step": 0})
	GameState.mission.from_dict({"bus": "large", "instruments": ["tel_ir"], "panels": "wing_l", "battery": "b6k", "comms": "ka", "adcs": "st", "propulsion": "cold", "launcher": "heavy", "orbit": "l2", "years": 5})
	g.world.stage_design()
	g.go("design", {"step": 2})
	await wait(1.5)
	await shot("11_tel_design")
	GameState.last_sim = GameState.mission.simulate(2)
	GameState.last_report = GameState.mission.compute()
	g.go("operation")
	await wait(3.0)
	await shot("12_l2_orbit")
	# Forced launch failure
	GameState.last_report = GameState.mission.compute()
	var s = GameState.mission.simulate(2)
	s.launch_failed = true
	s.months = 0
	s.status = "lost"
	s.score = GameState.mission.score(GameState.last_report, s)
	GameState.last_sim = s
	g.go("launch")
	await wait(7.0)
	await shot("13_explosion")
	while g.screen_id != "report":
		await wait(0.2)
	await wait(1.0)
	await shot("14_fail_report")
	# Team mode
	g.go("team", {"players": 3})
	await wait(0.5)
	await shot("15_team")
	g.overlay("howto")
	await wait(0.5)
	await shot("16_howto")
	get_tree().quit()
