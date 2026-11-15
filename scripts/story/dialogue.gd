extends CanvasLayer
## A story scene (v0.3.0, issue #66): the cuyes talk, one line at a time, in a card at the bottom of the screen with
## the speaker's portrait, name and station; a line may carry a NASA fact (with its source id) and may light a control
## on screen, the way the guided first mission does. It plays over any screen without stopping it, or pauses the game
## while it plays (pause = true). Click the card or press Enter to go on (the first press completes a line still being
## written); Esc skips the scene. Scenes are data: data/story/<chapter>.json, {"scenes": {id: [line, ...]}}, a line
## being {"who": cast id, "text", "mood" (optional), "fact" (optional), "source" (optional, a docs/sources.md id),
## "light" (optional, the visible text of a control to light)}.
##   const Dialogue := preload("res://scripts/story/dialogue.gd")
##   Dialogue.play(main, "apollo13", "problem", func(): ...)

signal finished(skipped: bool)

const Kit := preload("res://scripts/ui/kit.gd")
const Cast := preload("res://scripts/story/cast.gd")
const CHARS_PER_S := 55.0             ## How fast a line is written out.

var lines: Array = []
var at := -1
var pause := false
var card: PanelContainer
var portrait: TextureRect
var initial: Label
var frame: PanelContainer
var name_lbl: Label
var text_lbl: Label
var fact_box: Control
var fact_lbl: Label
var ring: Panel
var lit: Control
var _t := 0.0


## Plays scene `scene` of chapter `chapter` over the game; on_done(skipped) is called at the end. Returns the player.
static func play(main: Node, chapter: String, scene: String, on_done := Callable(), pause_game := false) -> Node:
	var d = load("res://scripts/story/dialogue.gd").new()
	d.lines = load_scene(chapter, scene)
	d.pause = pause_game
	if on_done.is_valid():
		d.finished.connect(on_done)
	main.add_child(d)
	return d


## The lines of a scene, from data/story/<chapter>.json ([] when it is not there).
static func load_scene(chapter: String, scene: String) -> Array:
	var path := "res://data/story/%s.json" % chapter
	if not FileAccess.file_exists(path):
		return []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data.get("scenes", {}).get(scene, [])


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause:
		get_tree().paused = true
	_build()
	next()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	card = Kit.panel_box(Kit.PAD)
	Kit.place(card, 0.5, 1, 0.5, 1, -460, -Kit.MARGIN - 60, 460, -Kit.MARGIN)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN       # as tall as its line, from the bottom up
	card.material = null      # solid, not frosted: what is behind it (a screen's own hints) must not read through
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			advance())
	root.add_child(card)
	var h := Kit.hbox(Kit.PAD)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	# the portrait in a round frame of the speaker's colour
	frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(132, 132)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	h.add_child(frame)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)
	initial = Kit.lbl("", Kit.T_CLOCK, Color(0.03, 0.06, 0.13), Kit.FONT_T)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(initial)
	var v := Kit.vbox(Kit.GAP)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	name_lbl = Kit.lbl("", Kit.T_BODY, Kit.C_TEXT, Kit.spaced(Kit.FONT_B, 2))
	v.add_child(name_lbl)
	text_lbl = Kit.lbl("", Kit.T_ACTION, Kit.C_TEXT, Kit.FONT_B, true)
	text_lbl.custom_minimum_size.x = 600
	v.add_child(text_lbl)
	# a NASA fact under the line, with where it comes from
	var fh := Kit.hbox(Kit.GAP)
	fh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fact_box = fh
	v.add_child(fh)
	fh.add_child(Kit.chip("NASA", Kit.C_GOLD))
	fact_lbl = Kit.lbl("", Kit.T_SMALL + 1, Kit.C_DIM, Kit.FONT_R, true)
	fact_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(fact_lbl)
	var foot := Kit.lbl(tr("Click or Enter to go on  ·  Esc skips"), Kit.T_CAPS, Kit.C_DIM, Kit.FONT_R)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(foot)
	ring = Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := Kit.flat(Color(Kit.C_GOLD, 0.08), Kit.C_GOLD, 10, 3, 0, 0)
	sb.shadow_color = Color(Kit.C_GOLD, 0.45)
	sb.shadow_size = 10
	ring.add_theme_stylebox_override("panel", sb)
	ring.visible = false
	root.add_child(ring)


## Shows the next line, or ends the scene.
func next() -> void:
	at += 1
	if at >= lines.size():
		_end(false)
		return
	var L: Dictionary = lines[at]
	var who := str(L.get("who", ""))
	var col: Color = Cast.colour(who)
	name_lbl.text = (Cast.display_name(who) + "  ·  " + Cast.station(who)).to_upper()
	name_lbl.add_theme_color_override("font_color", Kit.ink(col))
	var tex := Cast.portrait(who)
	portrait.texture = tex
	initial.text = "" if tex else Cast.display_name(who).left(1)
	# opaque: the round frame clips the portrait by its own alpha
	frame.add_theme_stylebox_override("panel", Kit.flat(col.darkened(0.55) if tex else col, col, 66, 3, 0, 0))
	card.add_theme_stylebox_override("panel", Kit.flat(Kit.C_BG, Color(col, 0.55), 14, 2, Kit.PAD, Kit.PAD))
	text_lbl.text = tr(str(L.get("text", "")))
	text_lbl.visible_ratio = 0.0
	_t = 0.0
	var fact := str(L.get("fact", ""))
	fact_box.visible = false              # the fact follows once the line is written
	fact_lbl.text = tr(fact)
	lit = _find(tr(str(L.get("light", "")))) if L.has("light") else null
	ring.visible = lit != null
	Kit.UiSound.play("notify", 0.0)
	# the card answers each new line with a small lift
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.97, 0.97)
	card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


## Click or Enter: finish writing the line, or go to the next one.
func advance() -> void:
	if text_lbl.visible_ratio < 1.0:
		text_lbl.visible_ratio = 1.0
	else:
		next()


func _process(delta: float) -> void:
	if text_lbl and text_lbl.visible_ratio < 1.0:
		_t += delta
		var n := maxi(text_lbl.text.length(), 1)
		text_lbl.visible_ratio = minf(1.0, _t * CHARS_PER_S / n)
	if text_lbl and text_lbl.visible_ratio >= 1.0 and fact_lbl.text != "" and not fact_box.visible:
		fact_box.visible = true
	if lit and is_instance_valid(lit) and lit.is_visible_in_tree():
		var r := lit.get_global_rect().grow(6)
		ring.position = r.position
		ring.size = r.size
		ring.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 160.0)
	else:
		ring.visible = false


func _input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	if e.physical_keycode == KEY_ENTER or e.physical_keycode == KEY_KP_ENTER:
		advance()
	elif e.physical_keycode == KEY_ESCAPE:
		_end(true)
	else:
		return
	get_viewport().set_input_as_handled()


func _end(skipped: bool) -> void:
	if pause:
		get_tree().paused = false
	finished.emit(skipped)
	queue_free()


## The visible button whose text is `txt` (what a line lights).
func _find(txt: String) -> Control:
	if txt == "":
		return null
	for n in get_tree().root.find_children("*", "Button", true, false):
		var b := n as Button
		if b.is_visible_in_tree() and b.text.strip_edges() == txt:
			return b
	return null
