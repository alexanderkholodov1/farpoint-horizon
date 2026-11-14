extends RefCounted
## The UI kit every screen builds with: theme, colors, fonts, and helpers for labels, buttons, cards, panels, boxes,
## toasts, overlays and number formatting. Everything is static and stateless:
##   const Kit := preload("res://scripts/ui/kit.gd")   (screens already have it from scripts/screens/screen.gd)
##   add_child(Kit.lbl("Hola", 16, Kit.C_ACCENT, Kit.FONT_B))

const FONT_R := preload("res://fonts/Inter-Regular.otf")
const FONT_B := preload("res://fonts/Inter-SemiBold.otf")
const FONT_T := preload("res://fonts/InterDisplay-Bold.otf")

const C_BG := Color(0.03, 0.055, 0.1, 0.9)
const C_CARD := Color(0.06, 0.1, 0.17, 0.92)
const C_ACCENT := Color(0.35, 0.72, 1.0)
const C_OK := Color(0.35, 0.95, 0.55)
const C_WARN := Color(1.0, 0.78, 0.25)
const C_BAD := Color(1.0, 0.38, 0.38)
const C_DIM := Color(0.62, 0.7, 0.82)
const C_TEXT := Color(0.93, 0.96, 1.0)


# ===================================================================================== THEME
static func flat(bg: Color, border := Color(0, 0, 0, 0), radius := 8, bw := 0, mx := 12.0, my := 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.anti_aliasing = true
	return s


## The theme of the whole UI; main.gd sets it on the UI root, so every screen inherits it.
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_R
	t.default_font_size = 16
	var panel := flat(C_BG, Color(0.35, 0.6, 1.0, 0.28), 12, 1, 16, 14)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", flat(Color(0.1, 0.19, 0.32, 0.95), Color(0.4, 0.65, 1.0, 0.45), 8, 1, 16, 8))
	t.set_stylebox("hover", "Button", flat(Color(0.15, 0.3, 0.5, 1.0), Color(0.5, 0.78, 1.0, 0.9), 8, 1, 16, 8))
	t.set_stylebox("pressed", "Button", flat(Color(0.2, 0.45, 0.75, 1.0), Color(0.6, 0.85, 1.0, 1.0), 8, 1, 16, 8))
	t.set_stylebox("disabled", "Button", flat(Color(0.12, 0.13, 0.16, 0.8), Color(0.3, 0.3, 0.35, 0.5), 8, 1, 16, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", FONT_B)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.55))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("normal", "LineEdit", flat(Color(0.05, 0.09, 0.15, 1.0), Color(0.4, 0.65, 1.0, 0.5), 6, 1, 10, 8))
	t.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0), Color(0.5, 0.8, 1.0, 1.0), 6, 2, 10, 8))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_stylebox("background", "ProgressBar", flat(Color(0.1, 0.13, 0.2, 1.0), Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", flat(C_ACCENT, Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_font("normal_font", "RichTextLabel", FONT_R)
	t.set_font("bold_font", "RichTextLabel", FONT_B)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_font_size("bold_font_size", "RichTextLabel", 16)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	return t


# ===================================================================================== WIDGETS
## Sets anchors (al, at, ar, ab: 0..1 of the parent) and offsets in pixels; returns the control.
static func place(c: Control, al: float, at: float, ar: float, ab: float, ol: float, ot: float, orr: float, ob: float) -> Control:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob
	return c


static func lbl(text: String, size := 16, color := C_TEXT, font: Font = FONT_R, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func btn(text: String, cb: Callable, size := 16, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if min_w > 0.0:
		b.custom_minimum_size.x = min_w
	return b


## Colors a button (the main action, the selected option); returns it.
static func accent_btn(b: Button, col: Color) -> Button:
	b.add_theme_stylebox_override("normal", flat(col.darkened(0.45), col, 8, 2, 18, 10))
	b.add_theme_stylebox_override("hover", flat(col.darkened(0.25), col.lightened(0.3), 8, 2, 18, 10))
	b.add_theme_stylebox_override("pressed", flat(col.darkened(0.1), Color.WHITE, 8, 2, 18, 10))
	return b


static func panel_box(pad := 16.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if pad != 16.0:
		p.add_theme_stylebox_override("panel", flat(C_BG, Color(0.35, 0.6, 1.0, 0.28), 12, 1, pad, pad))
	return p


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(h := 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## A selectable option. on_hover(title, text) is called when the mouse enters it (text is info_body, else body).
static func card(title: String, body: String, selected: bool, on_click: Callable, info_body := "", badge := "", badge_col := C_DIM, dimmed := false, on_hover := Callable()) -> PanelContainer:
	var pc := PanelContainer.new()
	var base_bg := Color(0.09, 0.22, 0.38, 0.96) if selected else C_CARD
	var border := C_ACCENT if selected else Color(1, 1, 1, 0.08)
	var sb := flat(base_bg, border, 8, 2 if selected else 1, 12, 9)
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var v := vbox(3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	var t := lbl(("● " if selected else "○ ") + title, 16, Color.WHITE if selected else C_TEXT, FONT_B, true)
	h.add_child(t)
	if badge != "":
		var b := lbl(badge, 12, badge_col, FONT_B)
		h.add_child(b)
	if body != "":
		v.add_child(lbl(body, 13, C_DIM, FONT_R, true))
	if dimmed:
		pc.modulate = Color(1, 1, 1, 0.55)
	pc.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on_click.call())
	pc.mouse_entered.connect(func():
		sb.bg_color = base_bg.lightened(0.08)
		if on_hover.is_valid():
			on_hover.call(title, info_body if info_body != "" else body))
	pc.mouse_exited.connect(func(): sb.bg_color = base_bg)
	return pc


## A short message at the top center that fades out; it lives in `parent` (a screen), so it goes with it.
static func toast(parent: Control, text: String, col := C_ACCENT, time := 2.5) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(Color(0.03, 0.05, 0.09, 0.95), col, 10, 2, 18, 12))
	p.add_child(lbl(text, 16, col, FONT_B))
	place(p, 0.5, 0, 0.5, 0, -300, 122, 300, 176)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(time)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


## A dimmed full-screen layer with a centered panel, a title and a close button; returns the panel's box to fill.
## The close button calls on_close, or removes the layer when none is given.
static func overlay(parent: Control, title: String, w := 900.0, h := 640.0, on_close := Callable()) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(shade)
	var p := panel_box(24)
	place(p, 0.5, 0.5, 0.5, 0.5, -w / 2.0, -h / 2.0, w / 2.0, h / 2.0)
	shade.add_child(p)
	var v := vbox(10)
	p.add_child(v)
	var hh := hbox(8)
	v.add_child(hh)
	var t := lbl(title, 28, Color.WHITE, FONT_T)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(t)
	var close: Callable = on_close if on_close.is_valid() else shade.queue_free
	hh.add_child(btn(TranslationServer.translate("Close ×"), close, 14))
	return v


# ===================================================================================== NUMBERS
static func pct(x: float) -> String:
	return "%d %%" % int(round(x * 100.0))


static func money(x: float) -> String:
	if x >= 100.0:
		return "%.0f M$" % x
	if x >= 1.0:
		return "%.1f M$" % x
	return "%.2f M$" % x


static func kg(x: float) -> String:
	if x >= 1000.0:
		return "%.2f t" % (x / 1000.0)
	if x >= 10.0:
		return "%.0f kg" % x
	return "%.1f kg" % x


static func watts(x: float) -> String:
	if x >= 1000.0:
		return "%.1f kW" % (x / 1000.0)
	return "%.0f W" % x


static func gb(x: float) -> String:
	if x >= 10.0:
		return "%.0f GB" % x
	if x >= 0.1:
		return "%.1f GB" % x
	return "%.3f GB" % x


## Minutes as "45 min", "1.5 h" or "24 h".
static func mins(m: float) -> String:
	if m >= 1440.0:
		return "24 h"
	if m >= 60.0:
		return "%.1f h" % (m / 60.0)
	if m <= 0.0:
		return "0 min"
	return "%d min" % int(m)
