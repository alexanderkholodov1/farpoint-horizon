extends Node
## The whole story played through as a player would (development only, needs a window): The crew screen, then the
## prologue and every chapter with its mission played right, from the menu's crew screen back to it. A screenshot at
## every new screen, every title card, the first line of every scene, key moments of each mission and every few
## seconds; a timeout so it always ends. Saves to shots/full_*.png.
## Run: tools/godot.sh --path . --resolution 1600x900 res://tests/fullrun.tscn
var g
var n := 0
var t0 := 0
var last_shot := 0.0
var last_tag := ""

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/full_%03d_%s.png" % [dir, n, name])
	print("shot ", n, " ", name, "  t=", int(secs()), " fps=", Engine.get_frames_per_second())
	n += 1
	last_shot = secs()

func secs() -> float:
	return (Time.get_ticks_msec() - t0) / 1000.0

func wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func key(k: int, target = null) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = k
	if target == null:
		target = g.screen
	if target.has_method("_unhandled_input"):
		target._unhandled_input(e)

func enter_dialogue(d) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = KEY_ENTER
	d._input(e)

func _ready() -> void:
	t0 = Time.get_ticks_msec()
	g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await wait(1.0)
	g.go("crew_gallery")
	await wait(2.0)
	await shot("crew")
	g.screen._focus(1)
	await wait(1.5)
	await shot("crew_killa")
	g.go("story", {"scenes": load("res://scripts/screens/story.gd").story(), "back": "crew_gallery"})
	var last_screen := ""
	var started := false
	while secs() < 1500.0:
		var id: String = g.screen_id
		if id != last_screen:
			last_screen = id
			await wait(1.2)
			await shot("screen_" + id)
		if id == "crew_gallery" and started:
			break
		started = true
		match id:
			"story":
				await _story_step()
			"apollo13":
				await _apollo13()
			"sts61":
				await _sts61()
			"pathfinder":
				await _pathfinder()
			_:
				await wait(0.5)
	await shot("end")
	print("fullrun done in ", int(secs()), " s, ", n, " shots")
	get_tree().quit()

func _story_step() -> void:
	var s = g.screen
	var d = s.dialogue
	if d == null or not is_instance_valid(d) or d.at < 0:
		await wait(0.2)
		return
	var at: int = d.at
	var L: Dictionary = d.lines[at]
	var tag := ("%s_%d" % [s.scenes[s.scene_at], at]).replace("/", "-")
	if L.has("title") and not L.has("who"):
		await wait(1.4)
		await shot(tag + "_title")
		if L.has("play"):
			enter_dialogue(d)
			await wait(1.0)
			return
		enter_dialogue(d)
	elif not L.has("who"):
		await wait(minf(float(L.get("wait", 2.0)) * 0.5, 3.0))
		await shot(tag + "_beat")
		while is_instance_valid(d) and d.at == at:
			await wait(0.1)
	else:
		await wait(1.1)
		if at == 0 or (L.has("set") and str(L.set) != last_tag) or secs() - last_shot > 6.0:
			await shot(tag + "_" + str(L.who))
		last_tag = str(L.get("set", last_tag))
		if is_instance_valid(d) and d.at == at:
			enter_dialogue(d)
			await wait(0.5)
		if is_instance_valid(d) and d.at == at:
			enter_dialogue(d)
	await wait(0.15)

func _apollo13() -> void:
	var s = g.screen
	await wait(1.0)
	await shot("a13_start")
	var steps := 0
	while is_instance_valid(s) and not s.A.done and not s.A.lost and steps < 20:
		steps += 1
		var id: String = s.A.needed()
		key(KEY_1 + s.part_keys.find(id))
		await wait(0.6)
		while is_instance_valid(s) and s.taping:
			if absf(1.0 - s.ring_t / (s.RING_PERIOD * 0.8)) < 0.05:
				key(KEY_SPACE)
				await wait(0.2)
			await get_tree().process_frame
	await wait(1.0)
	await shot("a13_win")
	await wait(3.0)
	await shot("a13_photo")
	key(KEY_ENTER)
	await wait(1.0)

func _sts61() -> void:
	var s = g.screen
	await wait(1.0)
	await shot("s61_start")
	var guard := 0
	while is_instance_valid(s) and not s.W.done() and guard < 200:
		guard += 1
		if s.phase == "walks" and s.W.picked == "":
			key(KEY_1 + s.keys.find(s.W.needed()))
			await wait(0.7)
			var w = s.work
			if w.mode in ["unroll", "slide", "aim", "screw"] and secs() - last_shot > 4.0:
				await shot("s61_job_" + w.mode)
			if w.mode == "drag":
				while not w.done:
					w.key_space()
					await wait(0.08)
			else:
				w._finish()
			await wait(0.8)
		else:
			await wait(0.3)
	await wait(3.0)
	await shot("s61_focus")
	s.dial = s.target
	await wait(1.5)
	await shot("s61_sharp")
	var t := secs()
	while is_instance_valid(s) and not s.photo_shown and secs() - t < 10.0:
		await get_tree().process_frame
	await shot("s61_photo")
	key(KEY_ENTER)
	await wait(1.0)

func _pathfinder() -> void:
	var s = g.screen
	await wait(1.5)
	await shot("mpf_brief")
	key(KEY_ENTER)
	await wait(0.5)
	await shot("mpf_descent")
	var t := secs()
	while is_instance_valid(s) and s.L.alt > 98.0 and secs() - t < 60.0:
		await get_tree().process_frame
	key(KEY_SPACE)
	await wait(0.3)
	await shot("mpf_rockets")
	while is_instance_valid(s) and s.L.alt > 21.5 and secs() - t < 70.0:
		await get_tree().process_frame
	key(KEY_C)
	t = secs()
	while is_instance_valid(s) and s.phase == "descent" and secs() - t < 20.0:
		await get_tree().process_frame
	await wait(2.5)
	await shot("mpf_bounce")
	t = secs()
	while is_instance_valid(s) and s.phase in ["bounce", "deflate"] and secs() - t < 60.0:
		await get_tree().process_frame
	await shot("mpf_ramp")
	while is_instance_valid(s) and s.phase == "ramp":
		s.ramp_s = minf(1.0, s.ramp_s + 0.008)
		s.ramp_off = 0.0
		await get_tree().process_frame
	await wait(0.6)
	await shot("mpf_wheel")
	t = secs()
	while is_instance_valid(s) and not s.photo_shown and secs() - t < 10.0:
		await get_tree().process_frame
	await shot("mpf_photo")
	key(KEY_ENTER)
	await wait(1.0)
