extends "res://scripts/screens/screen.gd"
## The main menu: the logo, play, the difficulty, the appearance (dark or light), how to play and the ranking. The real
## Earth turns behind it, framed by a viewfinder with live telemetry (UTC clock, Quito's coordinates).

const Horizon := preload("res://scripts/ui/horizon.gd")
const VERSION := "v0.2.0"
const QUITO := "0.18° S · 78.47° W"   ## Quito, the team's city (the Ecuador marker on the globe).

var clock: Label
var arc: Control


func enter(_args: Dictionary) -> void:
	world.stage_menu()
	# ---------- the panel on the left: frosted glass over space
	var panel := Kit.panel_box(34)
	Kit.place(panel, 0, 0, 0, 0, 56, 60, 616, 60)   # grows to its content
	add_child(panel)
	var box := Kit.vbox(12)
	panel.add_child(box)
	var head := Kit.hbox(8)
	box.add_child(head)
	var ch := caps("NASA SPACE APPS CHALLENGE 2026")
	ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(ch)
	head.add_child(caps(VERSION))
	box.add_child(rule())
	var lg := logo(1.0)
	box.add_child(lg)
	arc = lg.get_child(0)
	arc.progress = 0.0
	arc.create_tween().tween_property(arc, "progress", 1.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	box.add_child(Kit.lbl(tr("Design, launch and operate your own space mission. Every decision has consequences, in mass, power, data, budget and time."), 17, Kit.C_DIM, Kit.FONT_R, true))
	box.add_child(Kit.spacer(6))
	var play := Kit.accent_btn(Kit.btn(tr("▶  Play"), func(): go("team"), 21, 340), Kit.C_GOLD)
	play.custom_minimum_size.y = 56
	box.add_child(play)
	box.add_child(Kit.spacer(4))
	# ---------- settings: difficulty and appearance, each a row of joined choices
	box.add_child(rule())
	box.add_child(caps(tr("Difficulty")))
	var dh := segmented()
	box.add_child(dh)
	for d in ["facil", "normal", "dificil"]:
		var b := Kit.btn(GameData.DIFFICULTY[d].name, func(): GameState.difficulty = d; go("menu"), 15, 120)
		if GameState.difficulty == d:
			Kit.accent_btn(b, Kit.C_ACCENT)
		dh.add_child(b)
	box.add_child(Kit.lbl(GameData.DIFFICULTY[GameState.difficulty].desc, 13, Kit.C_DIM))
	box.add_child(Kit.spacer(4))
	# appearance and sound side by side
	var prefs := Kit.hbox(24)
	box.add_child(prefs)
	var av := Kit.vbox(8)
	prefs.add_child(av)
	av.add_child(caps(tr("Appearance")))
	var mh := segmented()
	av.add_child(mh)
	for m in Kit.MODES:
		var b := Kit.btn(tr("Dark") if m == "dark" else tr("Light"), func(): _set_mode(m), 15, 110)
		if Kit.mode == m:
			Kit.accent_btn(b, Kit.C_ACCENT)
		mh.add_child(b)
	var sv := Kit.vbox(8)
	prefs.add_child(sv)
	sv.add_child(caps(tr("Sound")))
	var sh := segmented()
	sv.add_child(sh)
	for on in [true, false]:
		var b := Kit.btn(tr("On") if on else tr("Off"), func(): Kit.UiSound.set_muted(not on); go("menu"), 15, 110)
		if Kit.UiSound.is_muted() != on:
			Kit.accent_btn(b, Kit.C_ACCENT)
		sh.add_child(b)
	box.add_child(rule())
	var hh := Kit.hbox(8)
	box.add_child(hh)
	hh.add_child(Kit.btn(tr("How to play"), func(): main.overlay("howto"), 15, 150))
	hh.add_child(Kit.btn("Ranking", func(): main.overlay("ranking"), 15, 150))
	hh.add_child(Kit.btn(tr("Credits"), func(): main.overlay("credits"), 15, 150))
	box.add_child(Kit.spacer(2))
	box.add_child(Kit.lbl(tr("The Earth behind is NASA data: Blue Marble by day, Black Marble city lights at night, and the real clouds of 31 August 2024 from the VIIRS instrument."), 12, Kit.C_DIM, Kit.FONT_R, true))
	# entrance: the panel slides in from the left as the arc draws itself
	panel.modulate.a = 0.0
	panel.position.x -= 24
	var tw := panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.5)
	tw.tween_property(panel, "position:x", panel.position.x + 24, 0.5)
	# ---------- the viewfinder around the Earth, with live telemetry
	var vf := Viewfinder.new()
	Kit.place(vf, 0.5, 0.5, 0.5, 0.5, 20, -360, 700, 330)
	add_child(vf)
	var tele := Kit.vbox(2)
	Kit.place(tele, 1, 1, 1, 1, -380, -112, -100, -36)
	add_child(tele)
	var t1 := Kit.lbl(tr("EARTH") + " · QUITO " + QUITO, 12, Color(Kit.C_ON_DARK, 0.7), spaced(Kit.FONT_B, 1))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tele.add_child(t1)
	clock = Kit.lbl("", 24, Kit.C_ON_DARK, Kit.font_num())
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tele.add_child(clock)
	var tag := Kit.lbl("● Ecuador", 13, Color(1, 0.8, 0.3), Kit.FONT_B)
	tag.add_theme_color_override("font_color", Color(1, 0.8, 0.3))   # on the dark scene: keep the light gold
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tele.add_child(tag)
	_tick()
	# ---------- along the edges: the team line and the languages
	var foot := Kit.lbl(tr("Space Mission Design Game challenge · Team SK Horizon · Quito, Ecuador"), 12, Color(Kit.C_ON_DARK, 0.55))
	Kit.place(foot, 0, 1, 0, 1, 60, -38, 900, -14)
	add_child(foot)
	var langs := Kit.hbox(6)
	Kit.place(langs, 1, 0, 1, 0, -270, 24, -30, 64)
	langs.alignment = BoxContainer.ALIGNMENT_END
	add_child(langs)
	for code in GameData.LANGUAGES:
		var lb := Kit.btn(GameData.LANGUAGES[code], func(): _set_language(code), 14, 110)
		if GameData.language == code:
			Kit.accent_btn(lb, Kit.C_ACCENT)
		langs.add_child(lb)


func process(_delta: float) -> void:
	_tick()


func _tick() -> void:
	if clock and is_instance_valid(clock):
		var t := Time.get_datetime_dict_from_system(true)
		clock.text = "UTC %02d:%02d:%02d" % [t.hour, t.minute, t.second]


## Switches the language (the choice is remembered) and draws the menu again in it.
func _set_language(code: String) -> void:
	GameData.set_language(code)
	go("menu")


## Switches the appearance (remembered), rebuilds the theme and draws the menu again in it.
func _set_mode(m: String) -> void:
	if m == Kit.mode:
		return
	Kit.set_mode(m)
	main.root_ui.theme = Kit.build_theme()
	go("menu")


# ===================================================================================== PIECES
## The game's logo: the horizon arc rising over the name, "HORIZON" spaced and in the blue of the arc's ends.
## `k` scales it (1 on the menu). Its first child is the arc.
static func logo(k := 1.0) -> Control:
	var v := Kit.vbox(0)
	var a := Horizon.new()
	a.custom_minimum_size = Vector2(500 * k, 36 * k)
	a.thickness = 2.5 * k
	a.sun_at = 0.36
	v.add_child(a)
	var h := Kit.hbox(int(14 * k))
	v.add_child(h)
	h.add_child(Kit.lbl("Farpoint", int(56 * k), Kit.C_TEXT, Kit.FONT_T))
	h.add_child(Kit.lbl("HORIZON", int(56 * k), Kit.C_ACCENT, spaced(Kit.FONT_B, int(7 * k))))
	return v


## A small spaced section label, in capitals.
static func caps(text: String) -> Label:
	return Kit.lbl(text.to_upper(), 11, Kit.C_DIM, spaced(Kit.FONT_B, 2))


## A hairline across the panel.
static func rule() -> Control:
	var r := ColorRect.new()
	r.color = Kit.C_LINE
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A row of joined choices (a segmented control).
static func segmented() -> HBoxContainer:
	return Kit.hbox(4)


static func spaced(font: Font, px: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = font
	f.spacing_glyph = px
	return f


## Four corner brackets around the Earth, as a camera's viewfinder, with fine tick marks on the sides.
class Viewfinder:
	extends Control
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c := Color(0.75, 0.85, 1.0, 0.35)
		var w := size.x
		var h := size.y
		var l := 28.0
		for p in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
			var sx := 1.0 if p.x == 0.0 else -1.0
			var sy := 1.0 if p.y == 0.0 else -1.0
			draw_line(p, p + Vector2(l * sx, 0), c, 1.5, true)
			draw_line(p, p + Vector2(0, l * sy), c, 1.5, true)
		for i in range(1, 12):
			var y := h * i / 12.0
			var tl := 10.0 if i == 6 else 5.0
			draw_line(Vector2(0, y), Vector2(tl, y), Color(c, 0.25), 1.0)
			draw_line(Vector2(w, y), Vector2(w - tl, y), Color(c, 0.25), 1.0)
		var m := Vector2(w / 2.0, h / 2.0)
		draw_line(m + Vector2(-8, 0), m + Vector2(-3, 0), Color(c, 0.5), 1.0)
		draw_line(m + Vector2(3, 0), m + Vector2(8, 0), Color(c, 0.5), 1.0)
