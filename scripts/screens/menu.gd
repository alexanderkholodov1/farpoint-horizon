extends "res://scripts/screens/screen.gd"
## The main menu: the logo and a list (play, the guided first mission, how to play, credits, settings, quit) drawn
## straight on space, with no box. The real Earth turns behind it, framed by a viewfinder with live telemetry (UTC
## clock, Quito's coordinates). Settings (language, difficulty, missions, appearance, sound) open in its place.

const Horizon := preload("res://scripts/ui/horizon.gd")
const Music := preload("res://scripts/ui/music.gd")
const VERSION := "v0.2.0"
const Coach := preload("res://scripts/tutorial/coach.gd")
const Progress := preload("res://scripts/progress.gd")
const QUITO := "0.18° S · 78.47° W"   ## Quito, the team's city (the Ecuador marker on the globe).

var clock: Label
var arc: Control


func enter(args: Dictionary) -> void:
	world.stage_menu()
	Music.ensure(main)   # the game's music, from here on (scripts/ui/music.gd)
	# ---------- no box: the logo and the list sit straight on space, over a soft shade that fades toward the Earth
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.0, 0.01, 0.04, 0.82))
	g.set_color(1, Color(0.0, 0.01, 0.04, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 4
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Kit.place(shade, 0, 0, 0.56, 1, 0, 0, 0, 0)
	add_child(shade)
	var box := Kit.vbox(8)
	Kit.place(box, 0, 0.5, 0, 0.5, 84, 0, 644, 0)
	box.grow_vertical = Control.GROW_DIRECTION_BOTH   # centred on the screen's height, whatever it holds
	add_child(box)
	var lg := logo(1.0)
	box.add_child(lg)
	arc = lg.get_child(0)
	if args.get("settings", false):
		_settings(box)
	else:
		arc.progress = 0.0
		arc.create_tween().tween_property(arc, "progress", 1.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_main_list(box)
		# entrance: it slides in from the left as the arc draws itself
		box.modulate.a = 0.0
		var tw := box.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(box, "modulate:a", 1.0, 0.7)
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
	var foot := Kit.lbl("NASA Space Apps Challenge 2026  ·  " + tr("Team SK Horizon · Quito, Ecuador") + "  ·  " + VERSION, 12, Color(Kit.C_ON_DARK, 0.5))
	Kit.place(foot, 0, 1, 0, 1, 84, -38, 900, -14)
	add_child(foot)


## The menu itself: one line about the game and the list of what the player can do, the first one the main action.
## Playing is alone for now: the crew of friends (same screen, online) and the ranking come back in v0.3.0.
func _main_list(box: VBoxContainer) -> void:
	var lead := Kit.lbl(tr("Design, launch and fly your own space mission."), Kit.T_LEAD, Color(Kit.C_ON_DARK, 0.72), Kit.FONT_R, true)
	lead.add_theme_color_override("font_color", Color(Kit.C_ON_DARK, 0.72))
	box.add_child(lead)
	box.add_child(Kit.spacer(18))
	var play := Kit.accent_btn(Kit.btn(tr("▶  Play"), _play, Kit.T_ACTION, 300), Kit.C_GOLD)
	play.custom_minimum_size.y = 60
	play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(play)
	play.grab_focus.call_deferred()   # the keyboard starts on Play: arrows move along the list, Enter chooses
	box.add_child(Kit.spacer(10))
	var items := [
		[tr("First mission · guided"), func(): Coach.start(main)],
		[tr("How to play"), func(): main.overlay("howto")],
		[tr("The crew"), func(): go("crew_gallery")],
		[tr("Credits"), func(): go("credits_film")],
		[tr("Settings"), func(): go("menu", {"settings": true})]]
	if not OS.has_feature("web"):
		items.append([tr("Quit"), func(): get_tree().quit()])
	for it in items:
		var b := Kit.menu_item(it[0], it[1])
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(b)


func _play() -> void:
	GameState.start_solo()
	go("missions")


## The settings, in the menu's own place: language, difficulty, appearance, sound. Each choice is kept and shown at once.
func _settings(box: VBoxContainer) -> void:
	var again := {"settings": true}
	var rows := Kit.vbox(Kit.GAP)
	var pn := Kit.panel_box(Kit.PAD)
	pn.add_child(rows)
	box.add_child(Kit.spacer(8))
	box.add_child(pn)
	rows.add_child(Kit.lbl(tr("Settings"), Kit.T_STAT, Kit.C_TEXT, Kit.FONT_T))
	rows.add_child(caps(tr("Language")))
	var lh := segmented()
	rows.add_child(lh)
	for code in GameData.LANGUAGES:
		lh.add_child(Kit.choice(GameData.LANGUAGES[code], GameData.language == code, func():
			GameData.set_language(code)
			go("menu", again), 130))
	rows.add_child(caps(tr("Difficulty")))
	var dh := segmented()
	rows.add_child(dh)
	for d in ["facil", "normal", "dificil"]:
		dh.add_child(Kit.choice(GameData.DIFFICULTY[d].name, GameState.difficulty == d, func():
			GameState.difficulty = d
			go("menu", again), 130))
	rows.add_child(Kit.lbl(GameData.DIFFICULTY[GameState.difficulty].desc, Kit.T_SMALL, Kit.C_DIM))
	rows.add_child(caps(tr("Missions")))
	var uh := segmented()
	rows.add_child(uh)
	for open in [false, true]:
		uh.add_child(Kit.choice(tr("All open") if open else tr("In order"), Progress.all_open() == open, func():
			Progress.set_all_open(open)
			go("menu", again), 130))
	rows.add_child(caps(tr("Appearance")))
	var mh := segmented()
	rows.add_child(mh)
	for m in Kit.MODES:
		mh.add_child(Kit.choice(tr("Dark") if m == "dark" else tr("Light"), Kit.mode == m, func():
			if m != Kit.mode:
				Kit.set_mode(m)
				main.root_ui.theme = Kit.build_theme()
				go("menu", again), 130))
	rows.add_child(caps(tr("Sound")))
	var sh := segmented()
	rows.add_child(sh)
	for on in [true, false]:
		sh.add_child(Kit.choice(tr("On") if on else tr("Off"), Kit.UiSound.is_muted() != on, func():
			Kit.UiSound.set_muted(not on)
			go("menu", again), 130))
	rows.add_child(Kit.rule())
	rows.add_child(Kit.lbl(tr("The Earth behind is NASA data: Blue Marble by day, Black Marble city lights at night, and the real clouds of 31 August 2024 from the VIIRS instrument."), 12, Kit.C_DIM, Kit.FONT_R, true))
	var back := Kit.btn(tr("◀ Menu"), func(): go("menu"), Kit.T_BODY, 340)
	back.custom_minimum_size.y = Kit.BTN_H
	rows.add_child(back)
	# the keyboard reaches every choice: arrows move, Enter chooses
	for n in rows.find_children("*", "Button", true, false):
		(n as Button).focus_mode = Control.FOCUS_ALL
	back.grab_focus.call_deferred()


func process(_delta: float) -> void:
	_tick()


func _tick() -> void:
	if clock and is_instance_valid(clock):
		var t := Time.get_datetime_dict_from_system(true)
		clock.text = "UTC %02d:%02d:%02d" % [t.hour, t.minute, t.second]


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
