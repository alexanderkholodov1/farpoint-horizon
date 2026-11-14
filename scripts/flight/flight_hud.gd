extends Control
## The pilot's panel, shared by the launch, the burn toward the Moon and the landing: readouts on the top left, an
## instrument on the bottom left (the attitude dial, or the landing radar), the controls on the bottom right (steering,
## throttle lever, a big action button, the autopilot switch), a message in the middle and a plain-words hint at the
## bottom. It only shows and reports: the screen that owns it runs the flight. Its own node, so the look (issue #12)
## can restyle it without touching the flight.
##   var hud := FlightHud.new(); add_child(hud); hud.build(tr("LAUNCH"), ...)

signal action_pressed                       ## The big button (STAGE, BURN...) or its key (Space).
signal throttle_changed(value: float)       ## The pilot moved the lever.
signal autopilot_toggled(on: bool)
signal skip_pressed

const Kit := preload("res://scripts/ui/kit.gd")
const Instruments := preload("res://scripts/flight/instruments.gd")
const Sound := preload("res://scripts/flight/sound.gd")

var title: Label
var clock: Label
var readouts: GridContainer
var gauges: VBoxContainer
var dial: Instruments.Dial
var instrument_box: PanelContainer
var lever: Instruments.Lever
var action: Instruments.BigButton
var autopilot_btn: Button
var left_btn: Instruments.HoldButton
var right_btn: Instruments.HoldButton
var up_btn: Instruments.HoldButton
var down_btn: Instruments.HoldButton
var keys_lbl: Label
var big: Label
var sub: Label
var hint_lbl: Label
var hint_panel: PanelContainer
var _values := {}          ## readout name -> Label
var _gauges := {}          ## gauge name -> Instruments.Gauge
var _msg_tw: Tween
var autopilot := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Builds the panel. action_label is the big button's word; four_way adds forward and back steering (the lander).
func build(heading: String, action_label: String, keys_text: String, four_way := false, with_dial := true) -> void:
	# readouts, top left
	var p := Kit.panel_box(14)
	Kit.place(p, 0, 0, 0, 0, 16, 16, 436, 16)
	add_child(p)
	var v := Kit.vbox(6)
	p.add_child(v)
	title = Kit.lbl(heading, 14, Kit.C_ACCENT, Kit.FONT_B)
	v.add_child(title)
	clock = Kit.lbl("", 30, Color.WHITE, Kit.FONT_T)
	v.add_child(clock)
	readouts = GridContainer.new()
	readouts.columns = 2
	readouts.add_theme_constant_override("h_separation", 22)
	readouts.add_theme_constant_override("v_separation", 2)
	v.add_child(readouts)
	gauges = Kit.vbox(4)
	v.add_child(gauges)
	# the instrument, bottom left
	instrument_box = Kit.panel_box(12)
	Kit.place(instrument_box, 0, 1, 0, 1, 16, -236, 300, -16)
	add_child(instrument_box)
	if with_dial:
		dial = Instruments.Dial.new()
		dial.caption = TranslationServer.translate("Needle on the green")
		instrument_box.add_child(dial)
	else:
		instrument_box.visible = false
	# controls, bottom right
	var cp := Kit.panel_box(12)
	Kit.place(cp, 1, 1, 1, 1, -420, -282, -16, -16)
	add_child(cp)
	var ch := Kit.hbox(12)
	cp.add_child(ch)
	var steer := Kit.vbox(6)
	steer.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(steer)
	if four_way:
		up_btn = Instruments.HoldButton.new("▲")
		steer.add_child(up_btn)
	var lr := Kit.hbox(6)
	steer.add_child(lr)
	left_btn = Instruments.HoldButton.new("◀")
	right_btn = Instruments.HoldButton.new("▶")
	lr.add_child(left_btn)
	lr.add_child(right_btn)
	if four_way:
		down_btn = Instruments.HoldButton.new("▼")
		steer.add_child(down_btn)
	autopilot_btn = Kit.btn(TranslationServer.translate("Autopilot"), func(): set_autopilot(not autopilot, true), 13)
	autopilot_btn.focus_mode = Control.FOCUS_NONE
	autopilot_btn.custom_minimum_size = Vector2(118, 44)
	steer.add_child(autopilot_btn)
	lever = Instruments.Lever.new()
	lever.changed.connect(func(x): throttle_changed.emit(x))
	ch.add_child(lever)
	var av := Kit.vbox(8)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(av)
	action = Instruments.BigButton.new()
	action.label = action_label
	action.pressed.connect(func(): action_pressed.emit())
	av.add_child(action)
	keys_lbl = Kit.lbl(keys_text, 11, Kit.C_DIM, Kit.FONT_R, true)
	keys_lbl.custom_minimum_size.x = 110
	av.add_child(keys_lbl)
	# sound and skip, top right
	var tr_box := Kit.hbox(8)
	Kit.place(tr_box, 1, 0, 1, 0, -330, 16, -16, 60)
	tr_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(tr_box)
	var snd := Button.new()
	snd.text = _sound_text()
	snd.add_theme_font_size_override("font_size", 13)
	snd.focus_mode = Control.FOCUS_NONE
	snd.pressed.connect(func():
		Sound.set_muted(not Sound.is_muted())
		snd.text = _sound_text())
	tr_box.add_child(snd)
	var skip := Kit.btn(TranslationServer.translate("Skip ▶▶"), func(): skip_pressed.emit(), 13)
	skip.focus_mode = Control.FOCUS_NONE
	tr_box.add_child(skip)
	# the message and the hint
	big = Kit.lbl("", 58, Color.WHITE, Kit.FONT_T)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_constant_override("outline_size", 10)
	big.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	Kit.place(big, 0.5, 0.2, 0.5, 0.2, -560, -50, 560, 30)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(big)
	sub = Kit.lbl("", 19, Color(1, 1, 1, 0.92), Kit.FONT_B, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_constant_override("outline_size", 6)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	Kit.place(sub, 0.5, 0.2, 0.5, 0.2, -460, 34, 460, 100)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)
	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", Kit.flat(Color(0.03, 0.05, 0.09, 0.82), Color(1, 1, 1, 0.1), 10, 1, 16, 10))
	Kit.place(hint_panel, 0.5, 1, 0.5, 1, -340, -96, 340, -20)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_panel)
	hint_lbl = Kit.lbl("", 15, Kit.C_TEXT, Kit.FONT_R, true)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_panel.add_child(hint_lbl)
	hint_panel.visible = false


func _sound_text() -> String:
	return TranslationServer.translate("Sound off") if Sound.is_muted() else TranslationServer.translate("Sound on")


## Adds a readout (name, then its value label); set it with value(name, text).
func add_readout(name_: String, label: String) -> void:
	readouts.add_child(Kit.lbl(label, 13, Kit.C_DIM, Kit.FONT_B))
	var l := Kit.lbl("", 17, Color.WHITE, Kit.FONT_B)
	readouts.add_child(l)
	_values[name_] = l


func value(name_: String, text: String, col := Color.WHITE) -> void:
	var l: Label = _values[name_]
	l.text = text
	l.add_theme_color_override("font_color", col)


## Adds a gauge; set it with gauge(name, 0..1, text).
func add_gauge(name_: String, label: String, warn_at := 2.0, bad_at := 2.0, col := Color(0.4, 0.75, 1.0)) -> void:
	var g := Instruments.Gauge.new()
	g.title = label
	g.warn_at = warn_at
	g.bad_at = bad_at
	g.color = col
	gauges.add_child(g)
	_gauges[name_] = g


func gauge(name_: String, v: float, text := "") -> void:
	var g: Instruments.Gauge = _gauges[name_]
	g.value = v
	g.text = text


func show_gauge(name_: String, on: bool) -> void:
	_gauges[name_].visible = on


## A message in the middle: a big line and a small one, for `time` seconds (0 keeps it).
func message(big_text: String, small_text := "", col := Color.WHITE, time := 2.5) -> void:
	if _msg_tw and _msg_tw.is_valid():
		_msg_tw.kill()
	big.text = big_text
	sub.text = small_text
	big.add_theme_color_override("font_color", col)
	big.modulate.a = 1.0
	sub.modulate.a = 1.0
	big.scale = Vector2.ONE
	big.pivot_offset = big.size / 2.0
	big.scale = Vector2(1.18, 1.18)
	_msg_tw = create_tween()
	_msg_tw.tween_property(big, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if time > 0.0:
		_msg_tw.tween_interval(time)
		_msg_tw.tween_property(big, "modulate:a", 0.0, 0.5)
		_msg_tw.parallel().tween_property(sub, "modulate:a", 0.0, 0.5)


## The plain-words line at the bottom ("" hides it).
func hint(text: String) -> void:
	hint_panel.visible = text != ""
	if hint_lbl.text != text:
		hint_lbl.text = text
		hint_panel.modulate.a = 0.0
		hint_panel.create_tween().tween_property(hint_panel, "modulate:a", 1.0, 0.3)


func set_autopilot(on: bool, by_pilot := false) -> void:
	autopilot = on
	autopilot_btn.text = TranslationServer.translate("Autopilot on") if on else TranslationServer.translate("Autopilot")
	if on:
		Kit.accent_btn(autopilot_btn, Kit.C_OK)
	else:
		_plain(autopilot_btn)
	if by_pilot:
		autopilot_toggled.emit(on)


func _plain(b: Button) -> void:
	for s in ["normal", "hover", "pressed"]:
		b.remove_theme_stylebox_override(s)


## Steering from the keys and the on-screen buttons: x is left (-1) to right (1); y is back (-1) to forward (1).
func steer() -> Vector2:
	var s := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A) or (left_btn and left_btn.held):
		s.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D) or (right_btn and right_btn.held):
		s.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP) or (up_btn and up_btn.held):
		s.y += 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or (down_btn and down_btn.held):
		s.y -= 1.0
	return s


## Throttle keys: W or Shift up, S or Ctrl down (per second), Z full, X cut. Returns the new throttle.
func throttle_keys(current: float, delta: float, rate := 0.8) -> float:
	var t := current
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SHIFT):
		t += rate * delta
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_CTRL):
		t -= rate * delta
	if Input.is_physical_key_pressed(KEY_Z):
		t = 1.0
	if Input.is_physical_key_pressed(KEY_X):
		t = 0.0
	t = clampf(t, 0.0, 1.0)
	lever.value = t
	return t


## True when the pilot touches any control (the keys or the on-screen buttons): a person takes over the autopilot.
func pilot_input() -> bool:
	for k in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_A, KEY_D, KEY_W, KEY_S, KEY_Z, KEY_X]:
		if Input.is_physical_key_pressed(k):
			return true
	for b in [left_btn, right_btn, up_btn, down_btn]:
		if b and b.held:
			return true
	return false


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_SPACE:
		action.press()
		get_viewport().set_input_as_handled()
