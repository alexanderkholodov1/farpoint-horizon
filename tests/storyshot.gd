extends Node
## A look at the story scenes (issue #66; development only, needs a window): a scene over the crew, over the design
## and over the flight, a line with a NASA fact and a line still being written. Saves to shots/story_*.png.
## Run: tools/godot.sh --path . --resolution 1600x900 res://tests/storyshot.tscn
const Dialogue := preload("res://scripts/story/dialogue.gd")
var g

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/story_%s.png" % [dir, name])
	print("shot ", name)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func enter(d) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = KEY_ENTER
	d._input(e)

func _ready() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.0)
	g.go("crew_gallery")
	await wait(1.0)
	var d = Dialogue.play(g, "apollo13", "briefing")
	await wait(0.35)
	await shot("1_crew_writing")
	await wait(1.6)
	await shot("2_crew_fact")
	d._end(true)
	GameState.start_solo()
	GameState.start_mission("volcanes")
	GameState.mission.from_dict({"bus": "small", "instruments": ["ir_adv", "gas_adv", "cam_ms"], "panels": "dep_m", "battery": "b1k", "comms": "xband", "adcs": "rw", "propulsion": "cold", "launcher": "ride", "orbit": "sso", "years": 3})
	g.world.rebuild_ship()
	g.go("design", {"step": 0})
	await wait(1.0)
	d = Dialogue.play(g, "apollo13", "problem")
	for i in 7:
		enter(d)
		await wait(0.05)
	await wait(1.5)
	await shot("3_design_problem")
	for i in 4:
		enter(d)
		await wait(0.05)
	await wait(1.5)
	await shot("4_design_later")
	d._end(true)
	g.go("design", {"step": 6})
	await wait(0.5)
	g.launch()
	await wait(4.0)
	g.go("flight")
	await wait(5.0)
	d = Dialogue.play(g, "apollo13", "home", Callable(), true)
	await wait(2.0)
	await shot("5_flight_home")
	enter(d)
	enter(d)
	enter(d)
	await wait(2.0)
	await shot("6_flight_last")
	get_tree().quit()
