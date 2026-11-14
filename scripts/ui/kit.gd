extends RefCounted
## The UI kit every screen builds with: theme, colors, fonts, and helpers for labels, buttons, cards, panels, boxes,
## toasts, overlays and number formatting. Everything is static and stateless:
##   const Kit := preload("res://scripts/ui/kit.gd")   (screens already have it from scripts/screens/screen.gd)
##   add_child(Kit.lbl("Hola", 16, Kit.C_ACCENT, Kit.FONT_B))

const FONT_R := preload("res://fonts/Inter-Regular.otf")
const FONT_B := preload("res://fonts/Inter-SemiBold.otf")
const FONT_T := preload("res://fonts/InterDisplay-Bold.otf")

## Two appearances the player chooses on the menu, remembered between sessions (user://settings.cfg, [ui] mode):
## - "dark" (the default): deep navy frosted glass over the scene, light text, bright status colours.
## - "light": the lead's "clean room" (direction A, issue #12): light frosted glass, dark text, dark status colours.
## Both keep the same language: frosted panels over the 3D scene, hairlines, large tabular numerals, the deep blue and
## the gold of thermal blankets, contrast at least WCAG AA. The brand's horizon arc is scripts/ui/horizon.gd.
## Screens read these as Kit.C_*; set_mode() changes them and main.gd rebuilds the theme and the screen.
const MODES := ["dark", "light"]
const SETTINGS_PATH := "user://settings.cfg"
static var mode := "dark"
static var C_BG := Color(0.045, 0.07, 0.12, 1.0)      ## Panel fill (the frost shader mixes it over the blurred scene).
static var C_CARD := Color(1, 1, 1, 0.045)            ## Cards and tiles inside a panel.
static var C_CARD_SEL := Color(0.16, 0.36, 0.7, 0.32) ## A selected card.
static var C_CARD_HOVER := Color(1, 1, 1, 0.09)
static var C_BTN := Color(1, 1, 1, 0.06)
static var C_BTN_HOVER := Color(1, 1, 1, 0.13)
static var C_BTN_PRESS := Color(0.2, 0.42, 0.8, 0.45)
static var C_EDGE := Color(0.6, 0.75, 1.0, 0.22)      ## A panel's hairline edge.
static var C_ACCENT := Color(0.47, 0.72, 1.0)         ## Blue: selection, headings, links, the default bar fill.
static var C_GOLD := Color(0.93, 0.68, 0.27)          ## Thermal-blanket gold: the one main action of a screen.
static var C_OK := Color(0.4, 0.86, 0.56)
static var C_WARN := Color(1.0, 0.76, 0.32)
static var C_BAD := Color(1.0, 0.47, 0.44)
static var C_DIM := Color(0.66, 0.72, 0.82)
static var C_TEXT := Color(0.94, 0.96, 1.0)
static var C_LINE := Color(0.6, 0.75, 1.0, 0.16)      ## Hairlines: borders, dividers, empty bars.
static var C_SHADE := Color(0.0, 0.01, 0.03, 0.55)    ## Behind an overlay.
const C_ON_DARK := Color(0.96, 0.97, 1.0)             ## Text drawn straight on the 3D scene (space, sky).
const FROST := preload("res://shaders/ui_frost.gdshader")

static var _frost: ShaderMaterial
static var _num_font: FontVariation
static var _mode_loaded := false


## Loads the remembered appearance (once) and applies it.
static func load_mode() -> void:
	if _mode_loaded:
		return
	_mode_loaded = true
	var cfg := ConfigFile.new()
	var m := "dark"
	if cfg.load(SETTINGS_PATH) == OK:
		m = str(cfg.get_value("ui", "mode", "dark"))
	_apply(m if MODES.has(m) else "dark")


## Switches the appearance and remembers it. The caller rebuilds the theme (build_theme) and redraws the screen.
static func set_mode(m: String) -> void:
	if not MODES.has(m):
		return
	_apply(m)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("ui", "mode", m)
	cfg.save(SETTINGS_PATH)


static func _apply(m: String) -> void:
	mode = m
	if m == "light":
		C_BG = Color(0.97, 0.975, 0.985, 1.0)
		C_CARD = Color(1, 1, 1, 0.62)
		C_CARD_SEL = Color(0.88, 0.93, 1.0, 0.97)
		C_CARD_HOVER = Color(1, 1, 1, 0.95)
		C_BTN = Color(1, 1, 1, 0.72)
		C_BTN_HOVER = Color(1, 1, 1, 0.98)
		C_BTN_PRESS = Color(0.85, 0.9, 0.98, 1.0)
		C_EDGE = Color(1, 1, 1, 0.95)
		C_ACCENT = Color(0.08, 0.3, 0.68)
		C_GOLD = Color(0.86, 0.6, 0.16)
		C_OK = Color(0.08, 0.5, 0.26)
		C_WARN = Color(0.68, 0.42, 0.0)
		C_BAD = Color(0.76, 0.14, 0.14)
		C_DIM = Color(0.32, 0.38, 0.48)
		C_TEXT = Color(0.05, 0.09, 0.18)
		C_LINE = Color(0.08, 0.2, 0.4, 0.16)
		C_SHADE = Color(0.02, 0.05, 0.12, 0.35)
	else:
		C_BG = Color(0.045, 0.07, 0.12, 1.0)
		C_CARD = Color(1, 1, 1, 0.045)
		C_CARD_SEL = Color(0.16, 0.36, 0.7, 0.32)
		C_CARD_HOVER = Color(1, 1, 1, 0.09)
		C_BTN = Color(1, 1, 1, 0.06)
		C_BTN_HOVER = Color(1, 1, 1, 0.13)
		C_BTN_PRESS = Color(0.2, 0.42, 0.8, 0.45)
		C_EDGE = Color(0.6, 0.75, 1.0, 0.22)
		C_ACCENT = Color(0.47, 0.72, 1.0)
		C_GOLD = Color(0.93, 0.68, 0.27)
		C_OK = Color(0.4, 0.86, 0.56)
		C_WARN = Color(1.0, 0.76, 0.32)
		C_BAD = Color(1.0, 0.47, 0.44)
		C_DIM = Color(0.66, 0.72, 0.82)
		C_TEXT = Color(0.94, 0.96, 1.0)
		C_LINE = Color(0.6, 0.75, 1.0, 0.16)
		C_SHADE = Color(0.0, 0.01, 0.03, 0.55)
	var f := frost()
	f.set_shader_parameter("tint", 0.84 if m == "light" else 0.8)
	f.set_shader_parameter("lift", 0.55 if m == "light" else 0.0)
	f.set_shader_parameter("lift_to", Color(1, 1, 1) if m == "light" else Color(0, 0, 0))


## The frosted-glass material of the panels (one shared instance).
static func frost() -> ShaderMaterial:
	if _frost == null:
		_frost = ShaderMaterial.new()
		_frost.shader = FROST
	return _frost


## Inter Display with tabular figures, so numbers that change keep their width: gauges, clocks, telemetry.
static func font_num() -> FontVariation:
	if _num_font == null:
		_num_font = FontVariation.new()
		_num_font.base_font = FONT_T
		var ts := TextServerManager.get_primary_interface()
		_num_font.opentype_features = {ts.name_to_tag("tnum"): 1}
	return _num_font


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


## The theme of the whole UI in the current appearance; main.gd sets it on the UI root, so every screen inherits it.
static func build_theme() -> Theme:
	load_mode()
	var t := Theme.new()
	t.default_font = FONT_R
	t.default_font_size = 16
	# a panel that is not given the frost material still reads as frosted glass: a little translucent
	var panel := flat(Color(C_BG.r, C_BG.g, C_BG.b, 0.9), C_EDGE, 14, 1, 16, 14)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", flat(C_BTN, C_LINE, 7, 1, 16, 8))
	t.set_stylebox("hover", "Button", flat(C_BTN_HOVER, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55), 7, 1, 16, 8))
	t.set_stylebox("pressed", "Button", flat(C_BTN_PRESS, C_ACCENT, 7, 1, 16, 8))
	t.set_stylebox("disabled", "Button", flat(Color(C_BTN.r, C_BTN.g, C_BTN.b, C_BTN.a * 0.5), Color(C_LINE.r, C_LINE.g, C_LINE.b, 0.08), 7, 1, 16, 8))
	t.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), C_ACCENT, 7, 2, 16, 8))
	t.set_font("font", "Button", FONT_B)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_ACCENT if mode == "light" else Color.WHITE)
	t.set_color("font_pressed_color", "Button", C_ACCENT if mode == "light" else Color.WHITE)
	t.set_color("font_focus_color", "Button", C_TEXT)
	t.set_color("font_disabled_color", "Button", Color(C_DIM.r, C_DIM.g, C_DIM.b, 0.6))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("normal", "LineEdit", flat(Color(C_BTN.r, C_BTN.g, C_BTN.b, minf(1.0, C_BTN.a * 1.4)), C_LINE, 6, 1, 10, 8))
	t.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0), C_ACCENT, 6, 2, 10, 8))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", C_DIM)
	t.set_color("caret_color", "LineEdit", C_ACCENT)
	t.set_stylebox("background", "ProgressBar", flat(Color(C_LINE.r, C_LINE.g, C_LINE.b, 0.14), Color(0, 0, 0, 0), 3, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", flat(C_ACCENT, Color(0, 0, 0, 0), 3, 0, 0, 0))
	t.set_color("font_color", "ProgressBar", C_TEXT)
	t.set_stylebox("panel", "TooltipPanel", flat(Color(C_BG.r, C_BG.g, C_BG.b, 0.97), C_EDGE, 6, 1, 10, 6))
	t.set_color("font_color", "TooltipLabel", C_TEXT)
	t.set_color("font_color", "CheckBox", C_TEXT)
	t.set_color("font_hover_color", "CheckBox", C_ACCENT)
	t.set_color("font_pressed_color", "CheckBox", C_TEXT)
	t.set_stylebox("grabber", "VScrollBar", flat(Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.35), Color(0, 0, 0, 0), 4, 0, 4, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.6), Color(0, 0, 0, 0), 4, 0, 4, 4))
	t.set_stylebox("scroll", "VScrollBar", flat(Color(C_LINE.r, C_LINE.g, C_LINE.b, 0.06), Color(0, 0, 0, 0), 4, 0, 4, 4))
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


## A colour made readable as text on the panels of the current appearance: on light panels a saturated light colour
## (a role's, a scenario's) is darkened until it holds AA contrast; on dark panels a saturated dark one is lightened.
## Neutrals pass unchanged.
static func ink(c: Color) -> Color:
	if c.s < 0.3:
		return c
	var out := c
	if mode == "light":
		for i in 12:
			if out.get_luminance() <= 0.33:
				break
			out = out.darkened(0.12)
	else:
		for i in 12:
			if out.get_luminance() >= 0.5:
				break
			out = out.lightened(0.12)
	out.a = c.a
	return out


static func lbl(text: String, size := 16, color := C_TEXT, font: Font = FONT_R, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ink(color))
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


## Colors a button (the main action, the selected option): filled with the colour, its text white or dark, whichever
## reads better on it; returns it.
static func accent_btn(b: Button, col: Color) -> Button:
	b.add_theme_stylebox_override("normal", flat(col, col.darkened(0.18), 7, 1, 18, 10))
	b.add_theme_stylebox_override("hover", flat(col.lightened(0.1), col.darkened(0.3), 7, 1, 18, 10))
	b.add_theme_stylebox_override("pressed", flat(col.darkened(0.12), col.darkened(0.4), 7, 1, 18, 10))
	var fg := Color(0.03, 0.06, 0.13) if col.get_luminance() > 0.45 else Color.WHITE
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fg)
	return b


## A frosted-glass panel over the 3D scene: the scene behind it blurred and washed light, a hairline edge.
static func panel_box(pad := 16.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_theme_stylebox_override("panel", flat(C_BG, C_EDGE, 14, 1, pad, pad))
	p.material = frost()
	return p


## A card-like panel with a tinted border (a station's color, a status): the one place screens get that look from.
static func tile(border: Color, pad_x := 12.0, pad_y := 10.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(C_CARD, Color(border.r, border.g, border.b, 0.55), 8, 1, pad_x, pad_y))
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
	var base_bg := C_CARD_SEL if selected else C_CARD
	var border := C_ACCENT if selected else C_LINE
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
	var t := lbl(("● " if selected else "○ ") + title, 16, C_ACCENT if selected else C_TEXT, FONT_B, true)
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
		sb.bg_color = C_CARD_HOVER if not selected else base_bg.lightened(0.04)
		if on_hover.is_valid():
			on_hover.call(title, info_body if info_body != "" else body))
	pc.mouse_exited.connect(func(): sb.bg_color = base_bg)
	return pc


## A short message at the top center that fades out; it lives in `parent` (a screen), so it goes with it.
static func toast(parent: Control, text: String, col := C_ACCENT, time := 2.5) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(Color(C_BG.r, C_BG.g, C_BG.b, 0.97), col, 10, 2, 18, 12))
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
	shade.color = C_SHADE
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
	var t := lbl(title, 28, C_TEXT, FONT_T)
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
