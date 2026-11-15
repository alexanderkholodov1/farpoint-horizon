extends Node
## A look at the story (issue #66; development only, needs a window): chapter 1 on the story stage (title card, the
## bang, close-ups, the alarm) and a scene over the design and the flight with the live portrait.
## Saves to shots/story_*.png. Run: tools/godot.sh --path . --resolution 1600x900 res://tests/storyshot.tscn
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

## Finishes the line on screen and shows the next one.
func step(d) -> void:
	enter(d)
	await wait(0.05)
	enter(d)

func _ready() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.0)
	g.go("crew_gallery")
	await wait(1.5)
	await shot("0_crew")
	g.go("story", {"chapter": "apollo13", "back": "crew_gallery"})
	await wait(1.4)
	await shot("1_title")
	var s = g.screen
	enter(s.dialogue)
	await wait(0.7)
	await shot("2_wayra_talks")
	await wait(1.6)
	await shot("3_wayra_fact")
	await step(s.dialogue)
	await wait(1.0)
	await shot("4_inti_low")
	await step(s.dialogue)
	await wait(1.0)
	await shot("5_killa")
	await step(s.dialogue)
	await wait(1.4)
	await shot("6_rumi")
	await step(s.dialogue)
	await step(s.dialogue)           # to the next scene's title card
	await wait(1.6)
	s = g.screen
	await shot("7_title2")
	enter(s.dialogue)
	await wait(0.25)
	await shot("8_bang")
	await wait(1.5)
	await shot("9_bang_after")
	await step(s.dialogue)
	await wait(1.2)
	await shot("10_alarm")
	await step(s.dialogue)
	await step(s.dialogue)
	await wait(1.4)
	await shot("11_dim_inti")
	await step(s.dialogue)
	await wait(1.2)
	await shot("12_killa_worried")
	s.dialogue._end(true)
	await wait(0.8)
	# a scene over the flight, with the live portrait
	GameState.start_solo()
	GameState.start_mission("volcanes")
	GameState.mission.from_dict({"bus": "small", "instruments": ["ir_adv", "gas_adv", "cam_ms"], "panels": "dep_m", "battery": "b1k", "comms": "xband", "adcs": "rw", "propulsion": "cold", "launcher": "ride", "orbit": "sso", "years": 3})
	g.world.rebuild_ship()
	g.go("design", {"step": 0})
	await wait(1.0)
	var d = Dialogue.play(g, "apollo13", "problem")
	await step(d)
	await wait(1.2)
	await shot("13_design_live")
	await step(d)
	await step(d)
	await wait(0.6)
	await shot("14_design_live2")
	d._end(true)
	get_tree().quit()
