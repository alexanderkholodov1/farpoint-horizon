extends RefCounted
## The pilot's instruments, drawn in code so they feel like hardware: the attitude dial with the guidance marker, the
## throttle lever, a stage button that glows when it is time, gauges, and hold-to-steer buttons for touch screens.
##   const Instruments := preload("res://scripts/flight/instruments.gd")
##   var dial := Instruments.Dial.new()

const Kit := preload("res://scripts/ui/kit.gd")

const C_PANEL := Color(0.05, 0.08, 0.13, 0.92)
const C_EDGE := Color(0.45, 0.62, 0.85, 0.35)
const C_MARK := Color(0.42, 0.95, 0.6)
const C_NEEDLE := Color(1.0, 0.97, 0.9)


## Where the rocket points (pitch, degrees from straight up toward downrange) against where guidance wants it (marker).
## The green wedge is the marker; the white needle is the rocket. Inside the wedge you are on course.
class Dial extends Control:
	var pitch := 0.0
	var marker := 0.0
	var tolerance := 5.0
	var caption := ""
	var _pulse := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(230, 150)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_pulse += delta
		queue_redraw()

	func _draw() -> void:
		var r := minf(size.y - 46.0, size.x - 92.0)
		var c := Vector2(26.0, size.y - 26.0)
		# the arc from straight up (0) to flat (90) and a little below
		var a0 := deg_to_rad(-92.0)
		var a1 := deg_to_rad(12.0)
		draw_arc(c, r, a0, a1, 48, Color(1, 1, 1, 0.1), 16.0, true)
		# marker wedge
		var on := absf(pitch - marker) <= tolerance
		var mk := deg_to_rad(clampf(marker, -2.0, 102.0) - 90.0)
		var w := deg_to_rad(tolerance)
		var mc: Color = C_MARK if on else C_MARK.lerp(Color(1, 0.8, 0.3), 0.5 + 0.5 * sin(_pulse * 6.0))
		draw_arc(c, r, mk - w, mk + w, 12, Color(mc.r, mc.g, mc.b, 0.85), 16.0, true)
		draw_line(c + Vector2.from_angle(mk) * (r - 14.0), c + Vector2.from_angle(mk) * (r + 14.0), mc, 3.0, true)
		# ticks every 15 degrees
		for d in range(0, 106, 15):
			var a := deg_to_rad(float(d) - 90.0)
			var len := 10.0 if d % 45 == 0 else 5.0
			draw_line(c + Vector2.from_angle(a) * (r + 10.0), c + Vector2.from_angle(a) * (r + 10.0 + len), Color(1, 1, 1, 0.45), 1.5, true)
		# the rocket needle, drawn as a small rocket
		var pa := deg_to_rad(clampf(pitch, -5.0, 110.0) - 90.0)
		var dir := Vector2.from_angle(pa)
		var side := dir.orthogonal()
		draw_line(c, c + dir * (r - 4.0), Color(1, 1, 1, 0.25), 1.0, true)
		var tip := c + dir * (r * 0.66)
		var base := c + dir * (r * 0.16)
		draw_colored_polygon(PackedVector2Array([tip, base + side * 7.0, base - side * 7.0]), C_NEEDLE)
		draw_circle(c, 5.0, C_NEEDLE)
		# labels
		var f: Font = Kit.FONT_B
		draw_string(f, c + Vector2(22, -r + 4), TranslationServer.translate("UP"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
		draw_string(f, c + Vector2(r - 30, -10), TranslationServer.translate("FLAT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
		if caption != "":
			draw_string(Kit.FONT_R, Vector2(size.x - 170, size.y - 4), caption, HORIZONTAL_ALIGNMENT_RIGHT, 170, 12, Color(1, 1, 1, 0.55))


## A throttle lever, 0 to 1. Drag it, or set `value`. Emits changed(value) when the pilot moves it.
class Lever extends Control:
	signal changed(value: float)
	var value := 1.0
	var title := "THROTTLE"
	var marks: Array = []          ## Values to draw a notch at (hover, for the lander).
	var _drag := false

	func _init() -> void:
		custom_minimum_size = Vector2(96, 220)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_VSIZE

	func _process(_d: float) -> void:
		queue_redraw()

	func _slot() -> Rect2:
		return Rect2(Vector2(size.x / 2.0 - 9.0, 34.0), Vector2(18.0, size.y - 74.0))

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			_drag = e.pressed
			if e.pressed:
				_set_from(e.position.y)
			accept_event()
		elif e is InputEventMouseMotion and _drag:
			_set_from(e.position.y)
			accept_event()
		elif e is InputEventScreenTouch or e is InputEventScreenDrag:
			_set_from(e.position.y)
			accept_event()

	func _set_from(y: float) -> void:
		var s := _slot()
		value = clampf(1.0 - (y - s.position.y) / s.size.y, 0.0, 1.0)
		changed.emit(value)

	func _draw() -> void:
		var s := _slot()
		draw_style_box(Kit.flat(Color(0.02, 0.03, 0.05, 0.95), Color(1, 1, 1, 0.12), 9, 1, 0, 0), s)
		var fill := Rect2(s.position + Vector2(3, s.size.y * (1.0 - value)), Vector2(s.size.x - 6, s.size.y * value))
		var col := Color(1.0, 0.62, 0.22).lerp(Color(1.0, 0.86, 0.45), value)
		draw_style_box(Kit.flat(Color(col.r, col.g, col.b, 0.85), Color(0, 0, 0, 0), 6, 0, 0, 0), fill)
		for m in marks:
			var my: float = s.position.y + s.size.y * (1.0 - float(m))
			draw_line(Vector2(s.position.x - 8, my), Vector2(s.end.x + 8, my), Color(0.6, 0.95, 0.7, 0.8), 2.0)
		for i in 5:
			var ty := s.position.y + s.size.y * i / 4.0
			draw_line(Vector2(s.end.x + 4, ty), Vector2(s.end.x + 10, ty), Color(1, 1, 1, 0.35), 1.0)
		# the handle
		var hy := s.position.y + s.size.y * (1.0 - value)
		var hr := Rect2(Vector2(s.position.x - 20, hy - 9), Vector2(s.size.x + 40, 18))
		draw_style_box(Kit.flat(Color(0.86, 0.9, 0.96), Color(1, 1, 1), 5, 1, 0, 0), hr)
		draw_line(Vector2(hr.position.x + 8, hy), Vector2(hr.end.x - 8, hy), Color(0.3, 0.35, 0.42), 2.0)
		draw_string(Kit.FONT_B, Vector2(0, 18), TranslationServer.translate(title), HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(1, 1, 1, 0.7))
		draw_string(Kit.FONT_T, Vector2(0, size.y - 14), "%d %%" % roundi(value * 100.0), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)


## A labeled horizontal gauge, 0 to 1, colored by `warn_at` and `bad_at` (or reversed when `high_is_good`).
class Gauge extends Control:
	var title := ""
	var value := 0.0
	var text := ""
	var warn_at := 2.0
	var bad_at := 2.0
	var color := Color(0.4, 0.75, 1.0)

	func _init() -> void:
		custom_minimum_size = Vector2(200, 38)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var col := color
		if value >= bad_at:
			col = Kit.C_BAD
		elif value >= warn_at:
			col = Kit.C_WARN
		draw_string(Kit.FONT_B, Vector2(0, 13), title, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.6, 12, Color(1, 1, 1, 0.65))
		draw_string(Kit.FONT_B, Vector2(0, 13), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x, 13, Color.WHITE)
		var bar := Rect2(Vector2(0, 20), Vector2(size.x, 10))
		draw_style_box(Kit.flat(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 5, 0, 0, 0), bar)
		var v := clampf(value, 0.0, 1.0)
		if v > 0.0:
			draw_style_box(Kit.flat(col, Color(0, 0, 0, 0), 5, 0, 0, 0), Rect2(bar.position, Vector2(maxf(bar.size.x * v, 10.0), bar.size.y)))


## A big round push button (STAGE). `lit` makes it glow; pressed emits `pressed`.
class BigButton extends Control:
	signal pressed
	var label := "STAGE"
	var lit := false
	var color := Color(1.0, 0.55, 0.2)
	var _t := 0.0
	var _down := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(110, 110)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _process(delta: float) -> void:
		_t += delta
		_down = maxf(0.0, _down - delta * 4.0)
		queue_redraw()

	func press() -> void:
		_down = 1.0
		pressed.emit()

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			press()
			accept_event()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 6.0
		var glow := 0.5 + 0.5 * sin(_t * 7.0) if lit else 0.0
		if lit:
			draw_circle(c, r + 5.0 + glow * 4.0, Color(color.r, color.g, color.b, 0.25 + glow * 0.3))
		draw_circle(c, r, Color(0.08, 0.06, 0.05))
		var face := color.darkened(0.55 - glow * 0.35) if lit else Color(0.22, 0.2, 0.2)
		draw_circle(c + Vector2(0, _down * 3.0), r - 6.0, face)
		draw_arc(c + Vector2(0, _down * 3.0), r - 6.0, 0, TAU, 40, Color(1, 1, 1, 0.25), 2.0, true)
		# the word shrinks to fit inside the face (CORRECT, CORREGIR)
		var word := TranslationServer.translate(label)
		var fs := 18
		while fs > 10 and Kit.FONT_T.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > (r - 10.0) * 2.0:
			fs -= 1
		draw_string(Kit.FONT_T, c + Vector2(-r, fs * 0.38 + _down * 3.0), word, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, Color.WHITE if lit else Color(1, 1, 1, 0.55))


## A button that reports while it is held (hold-to-steer for touch screens and mice). `held` is true while down.
class HoldButton extends Button:
	var held := false

	func _init(text_: String = "") -> void:
		text = text_
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(56, 48)
		add_theme_font_size_override("font_size", 20)
		button_down.connect(func(): held = true)
		button_up.connect(func(): held = false)
