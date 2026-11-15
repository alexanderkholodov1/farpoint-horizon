extends Node
## A look at mission 2 (issue #46; development only, needs a window): the five spacewalks (a wrong part, the cloth,
## a spacewalk that runs out and is tried again), the first image brought into focus, the photo; then the story's
## intro, the Your turn card and the outro. Saves to shots/s61_*.png.
## Run: tools/godot.sh --path . --resolution 1600x900 res://tests/sts61shot.tscn
var g
var n := 0

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/s61_%02d_%s.png" % [dir, n, name])
	print("shot ", n, " ", name)
	n += 1

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func key(k: int) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = k
	g.screen._unhandled_input(e)

func pick(id: String) -> void:
	var s = g.screen
	var i: int = s.keys.find(id)
	key(KEY_1 + i)

func fit() -> void:
	var s = g.screen
	while is_instance_valid(s) and absf(1.0 - s.ring_t / (s.RING_PERIOD * 0.8)) > 0.05:
		await get_tree().process_frame
	key(KEY_SPACE)

func _ready() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.0)
	g.go("sts61", {"back": "menu"})
	await wait(2.0)
	await shot("walk1")
	pick("cloth")
	await wait(0.4)
	await shot("cloth")
	await wait(1.6)
	pick(g.screen.W.needed())
	await wait(0.5)
	await shot("in_hand")
	await fit()
	await wait(0.4)
	await shot("fitted")
	# let spacewalk one run out
	g.screen.W.left = 2.0
	await wait(2.6)
	await shot("lost")
	key(KEY_ENTER)
	await wait(1.5)
	var w := 0
	while not g.screen.W.done():
		if g.screen.phase == "walks" and g.screen.W.picked == "":
			pick(g.screen.W.needed())
			await wait(0.6)
			if g.screen.W.needed() in ["arrays", "wfpc2", "costar", "magnetometers"]:
				await shot("walk_" + g.screen.W.needed())
			await fit()
			await wait(0.3)
		elif g.screen.phase == "between":
			if w < 2:
				await shot("between")
			w += 1
			await wait(2.6)
		else:
			await wait(0.2)
	await wait(3.0)
	await shot("focus_start")
	g.screen.dial = g.screen.target - 0.2
	await wait(0.3)
	await shot("focus_near")
	g.screen.dial = g.screen.target
	await wait(1.0)
	await shot("sharp")
	await wait(2.6)
	await shot("photo")
	# the story around it
	g.go("story", {"scenes": ["sts61/intro"], "back": "menu"})
	var d = null
	for i in 8:
		await wait(1.6 if i == 0 else 1.3)
		await shot("intro_%d" % i)
		d = g.screen.dialogue
		if d == null or not is_instance_valid(d):
			break
		var e := InputEventKey.new()
		e.pressed = true
		e.physical_keycode = KEY_ENTER
		d._input(e)
		await wait(0.3)
		if is_instance_valid(d):
			d._input(e)
	get_tree().quit()
