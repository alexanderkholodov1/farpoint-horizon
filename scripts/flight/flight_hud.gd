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
signal warp_changed(value: float)           ## The pilot changed how fast time runs.

## How fast time can run: real time, then faster. The screen multiplies its real seconds by `warp`.
const WARPS := [1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0]

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
var warp := 1.0             ## Mission seconds per real second (1 is real time).
var warp_cap := 1.0         ## The fastest allowed now (an engine on, the ground near).
var warp_box: HBoxContainer
var warp_note: Label
var _warp_btns := {}        ## warp -> Button
var _top: VBoxContainer
var _cap_why := ""         ## Why time may not run faster now, said beside the warp.


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Builds the panel. action_label is the big button's word; four_way adds forward and back steering (the lander).
## Built with the UI kit's pieces, as the menu and the builder are (issue #12): frosted panels with room to breathe,
## small spaced capitals for section labels, joined choices, tabular numbers, the appearance's own colours.
func build(heading: String, action_label: String, keys_text: String, four_way := false, with_dial := true) -> void:
	# readouts, top left
	var p := Kit.panel_box(Kit.PAD)
	Kit.place(p, 0, 0, 0, 0, Kit.MARGIN, Kit.MARGIN, 480, Kit.MARGIN)
	add_child(p)
	var v := Kit.vbox(Kit.GAP)
	p.add_child(v)
	_top = v
	title = Kit.caps(heading)
	v.add_child(title)
	clock = Kit.lbl("", Kit.T_CLOCK, Kit.C_TEXT, Kit.font_num())
	v.add_child(clock)
	v.add_child(Kit.rule())
	readouts = GridContainer.new()
	readouts.columns = 2
	v.add_child(readouts)
	gauges = Kit.vbox(8)
	v.add_child(gauges)
	# the instrument, bottom left
	instrument_box = Kit.panel_box(18)
	Kit.place(instrument_box, 0, 1, 0, 1, 24, -262, 340, -24)
	add_child(instrument_box)
	if with_dial:
		dial = Instruments.Dial.new()
		dial.caption = TranslationServer.translate("Needle on the green")
		instrument_box.add_child(dial)
	else:
		instrument_box.visible = false
	# controls, bottom right
	var cp := Kit.panel_box(20)
	Kit.place(cp, 1, 1, 1, 1, -476, -330, -24, -24)
	add_child(cp)
	var ch := Kit.hbox(18)
	cp.add_child(ch)
	var steer := Kit.vbox(8)
	steer.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(steer)
	if four_way:
		up_btn = Instruments.HoldButton.new("▲")
		up_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steer.add_child(up_btn)
	var lr := Kit.hbox(8)
	steer.add_child(lr)
	left_btn = Instruments.HoldButton.new("◀")
	right_btn = Instruments.HoldButton.new("▶")
	lr.add_child(left_btn)
	lr.add_child(right_btn)
	if four_way:
		down_btn = Instruments.HoldButton.new("▼")
		down_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steer.add_child(down_btn)
	autopilot_btn = Kit.btn(TranslationServer.translate("Autopilot"), func(): set_autopilot(not autopilot, true), Kit.T_BODY)
	autopilot_btn.focus_mode = Control.FOCUS_NONE
	autopilot_btn.custom_minimum_size = Vector2(136, Kit.BTN_H)
	steer.add_child(autopilot_btn)
	lever = Instruments.Lever.new()
	lever.changed.connect(func(x): throttle_changed.emit(x))
	ch.add_child(lever)
	var av := Kit.vbox(10)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(av)
	action = Instruments.BigButton.new()
	action.label = action_label
	action.pressed.connect(func(): action_pressed.emit())
	av.add_child(action)
	keys_lbl = Kit.lbl(keys_text, Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R, true)
	keys_lbl.custom_minimum_size.x = 132
	keys_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(keys_lbl)
	# sound and skip, top right
	var tr_box := Kit.hbox(8)
	Kit.place(tr_box, 1, 0, 1, 0, -380, 24, -24, 70)
	tr_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(tr_box)
	var snd := Kit.btn(_sound_text(), func(): pass, Kit.T_BODY, 128)
	snd.focus_mode = Control.FOCUS_NONE
	snd.custom_minimum_size.y = Kit.BTN_H
	snd.pressed.connect(func():
		Sound.set_muted(not Sound.is_muted())
		snd.text = _sound_text())
	tr_box.add_child(snd)
	var skip := Kit.btn(TranslationServer.translate("Skip ▶▶"), func(): skip_pressed.emit(), Kit.T_BODY, 128)
	skip.focus_mode = Control.FOCUS_NONE
	skip.custom_minimum_size.y = Kit.BTN_H
	tr_box.add_child(skip)
	# the message, straight on the scene, and the hint in its own panel
	big = Kit.lbl("", Kit.T_SHOUT, Kit.C_ON_DARK, Kit.FONT_T)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_constant_override("outline_size", 12)
	big.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	Kit.place(big, 0.5, 0.2, 0.5, 0.2, -600, -50, 600, 32)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(big)
	sub = Kit.lbl("", Kit.T_ACTION, Kit.C_ON_DARK, Kit.FONT_B, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_constant_override("outline_size", 7)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	Kit.place(sub, 0.5, 0.2, 0.5, 0.2, -500, 38, 500, 110)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)
	var hb: Array = Kit.hint_box()
	hint_panel = hb[0]
	hint_lbl = hb[1]
	Kit.place(hint_panel, 0.5, 1, 0.5, 1, -440, -128, 300, -Kit.MARGIN)
	add_child(hint_panel)
	hint_panel.visible = false


func _sound_text() -> String:
	return TranslationServer.translate("Sound off") if Sound.is_muted() else TranslationServer.translate("Sound on")


## Adds the time control under the clock: real time and faster, chosen with the buttons or the keys , and . ;
## `cap` is the fastest allowed at first. A note says in words how fast time runs, so the clock never misleads.
func add_time_warp(cap := 1.0) -> void:
	var head := Kit.caps(TranslationServer.translate("Time"))
	_top.add_child(head)
	_top.move_child(head, 2)
	warp_box = Kit.segmented()
	for w in WARPS:
		var b := Kit.choice(_warp_label(w), false, func(): set_warp(w, true), 66)
		_warp_btns[w] = b
		warp_box.add_child(b)
	_top.add_child(warp_box)
	_top.move_child(warp_box, 3)
	warp_note = Kit.lbl("", Kit.T_SMALL, Kit.C_DIM, Kit.FONT_R)
	_top.add_child(warp_note)
	_top.move_child(warp_note, 4)
	cap_warp(cap)


static func _warp_label(w: float) -> String:
	return "×1" if w <= 1.0 else "×" + ("%dk" % roundi(w / 1000.0) if w >= 1000.0 else "%d" % roundi(w))


## Sets how fast time runs (kept at most warp_cap).
func set_warp(w: float, _by_pilot := false) -> void:
	w = clampf(w, 1.0, warp_cap)
	var changed := w != warp
	warp = w
	_show_warp()
	if changed:
		warp_changed.emit(warp)


## The fastest time may run now; why is said in the note. Lowers the current warp when it is above.
func cap_warp(cap: float, why := "") -> void:
	warp_cap = cap
	if warp > cap:
		set_warp(cap)
	_cap_why = why
	_show_warp()


func _show_warp() -> void:
	if warp_box == null:
		return
	for w in _warp_btns:
		var b: Button = _warp_btns[w]
		b.disabled = w > warp_cap
		if w == warp:
			Kit.accent_btn(b, Kit.C_ACCENT)
		else:
			_plain(b)
	var t: String = TranslationServer.translate("Real time") if warp <= 1.0 else TranslationServer.translate("Time runs %s times faster") % _thousands(warp)
	if _cap_why != "":
		t += " · " + _cap_why
	warp_note.text = t


## 100000 as "100,000".
static func _thousands(v: float) -> String:
	var s := str(roundi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


## Mission elapsed time as the clock shows it: "T+ 00:52:10", with days when there are.
static func met_text(seconds: float) -> String:
	var s := maxi(roundi(seconds), 0)
	var d := s / 86400
	var h := (s % 86400) / 3600
	var m := (s % 3600) / 60
	var text := "T+ %02d:%02d:%02d" % [h, m, s % 60]
	if d > 0:
		text = "T+ %d d %02d:%02d:%02d" % [d, h, m, s % 60]
	return text


## Adds a readout (name, then its value label); set it with value(name, text).
func add_readout(name_: String, label: String) -> void:
	_values[name_] = Kit.readout(readouts, label)


## Sets a readout. col is a status colour (Kit.C_OK...); white or none means the appearance's plain text colour, and
## any colour is made readable on the current panels (Kit.ink).
func value(name_: String, text: String, col := Color.WHITE) -> void:
	var l: Label = _values[name_]
	l.text = text
	l.add_theme_color_override("font_color", Kit.C_TEXT if col == Color.WHITE else Kit.ink(col))


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
	elif e is InputEventKey and e.pressed and not e.echo and warp_box and (e.physical_keycode == KEY_PERIOD or e.physical_keycode == KEY_COMMA):
		var i := WARPS.find(warp)
		i = clampi(i + (1 if e.physical_keycode == KEY_PERIOD else -1), 0, WARPS.size() - 1)
		set_warp(WARPS[i], true)
		get_viewport().set_input_as_handled()
