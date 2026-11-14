extends Node
## Prueba automática: recorre el juego y guarda capturas en /tmp/shots (solo para desarrollo).
var g

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % name)
	print("shot ", name)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.5)
	await shot("01_menu")
	g._start_solo()
	await wait(0.5)
	await shot("02_scenarios")
	g._choose_scenario("volcanes")
	g.mission.from_dict({"bus": "small", "instruments": ["ir_adv", "gas_adv", "cam_ms"], "panels": "dep_m", "battery": "b1k", "comms": "xband", "adcs": "rw", "propulsion": "cold", "launcher": "ride", "orbit": "sso", "years": 3})
	g.rebuild_ship()
	g.show_design(2)
	await wait(1.5)
	await shot("03_instruments")
	g.show_design(7)
	await wait(0.5)
	await shot("04_review")
	g._try_launch()
	await wait(4.6)
	await shot("05_launch")
	await wait(4.0)
	await shot("06_launch_high")
	while g.state != "sim":
		await wait(0.2)
	await wait(5.0)
	await shot("07_sim")
	g.sim_month_f = 9999.0
	while g.state != "report":
		await wait(0.2)
	await wait(1.0)
	await shot("08_report")
	# Luna
	g._choose_scenario("luna")
	g.mission.from_dict({"bus": "medium", "instruments": ["cam_ms", "gamma"], "panels": "dep_m", "battery": "b1k", "comms": "ka", "adcs": "st", "propulsion": "chem", "launcher": "medium", "orbit": "lunar", "years": 1, "redundancy": true, "shielding": true})
	g.stage_design()
	g.show_design(5)
	await wait(1.5)
	await shot("09_luna_design")
	g.last_sim = g.mission.simulate(5)
	g.last_report = g.mission.compute()
	g.show_sim()
	await wait(3.0)
	await shot("10_luna_orbit")
	# Telescopio en L2
	g._choose_scenario("telescopio")
	g.mission.from_dict({"bus": "large", "instruments": ["tel_ir"], "panels": "wing_l", "battery": "b6k", "comms": "ka", "adcs": "st", "propulsion": "cold", "launcher": "heavy", "orbit": "l2", "years": 5})
	g.stage_design()
	g.show_design(2)
	await wait(1.5)
	await shot("11_tel_design")
	g.last_sim = g.mission.simulate(2)
	g.last_report = g.mission.compute()
	g.show_sim()
	await wait(3.0)
	await shot("12_l2_orbit")
	# Falla de lanzamiento forzada
	g.last_report = g.mission.compute()
	var s = g.mission.simulate(2)
	s.launch_failed = true
	s.months = 0
	s.status = "lost"
	s.score = g.mission.score(g.last_report, s)
	g.last_sim = s
	g.show_launch()
	await wait(7.0)
	await shot("13_explosion")
	while g.state != "report":
		await wait(0.2)
	await wait(1.0)
	await shot("14_fail_report")
	# Modo equipo
	g.show_team(3)
	await wait(0.5)
	await shot("15_team")
	g.show_howto()
	await wait(0.5)
	await shot("16_howto")
	get_tree().quit()
