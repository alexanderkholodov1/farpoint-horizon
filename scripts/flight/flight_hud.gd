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
func build(heading: String, action_label: String, keys_text: String, four_way := false, with_dial := true) -> void:
	# readouts, top left
	var p := Kit.panel_box(14)
	Kit.place(p, 0, 0, 0, 0, 16, 16, 436, 16)
	add_child(p)
	var v := Kit.vbox(6)
	p.add_child(v)
	_top = v
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


## Adds the time control under the clock: real time and faster, chosen with the buttons or the keys , and . ;
## `cap` is the fastest allowed at first. A note says in words how fast time runs, so the clock never misleads.
func add_time_warp(cap := 1.0) -> void:
	warp_box = Kit.hbox(4)
	for w in WARPS:
		var b := Kit.btn(_warp_label(w), func(): set_warp(w, true), 12, 46)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 26
		_warp_btns[w] = b
		warp_box.add_child(b)
	_top.add_child(warp_box)
	_top.move_child(warp_box, 2)
	warp_note = Kit.lbl("", 12, Kit.C_DIM, Kit.FONT_R)
	_top.add_child(warp_note)
	_top.move_child(warp_note, 3)
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
	elif e is InputEventKey and e.pressed and not e.echo and warp_box and (e.physical_keycode == KEY_PERIOD or e.physical_keycode == KEY_COMMA):
		var i := WARPS.find(warp)
		i = clampi(i + (1 if e.physical_keycode == KEY_PERIOD else -1), 0, WARPS.size() - 1)
		set_warp(WARPS[i], true)
		get_viewport().set_input_as_handled()
