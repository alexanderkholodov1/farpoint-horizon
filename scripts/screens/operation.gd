extends "res://scripts/screens/screen.gd"
## Operation: the craft on its orbit while the months of GameState.last_sim play back: the mission log, the time bar,
## the science bar, and speed controls. At the end (or if the craft is lost) it fades to the report.

var months_total := 0
var speed := 1.0            ## Months per 0.7 s.
var month_f := 0.0          ## Playback position in months; 9999 jumps to the end.
var shown_month := -1
var shown_events := 0
var end_t := -1.0           ## Seconds since the last month was shown (-1 before).
var leaving := false
var month_lbl: Label
var time_bar: ProgressBar
var sci_bar: ProgressBar
var sci_lbl: Label
var log_box: VBoxContainer
var log_scroll: ScrollContainer


func enter(_args: Dictionary) -> void:
	world.stage_orbit()
	months_total = mission.years * 12
	speed = max(1.0, months_total / 36.0)
	var S: Dictionary = GameData.SCENARIOS[mission.scenario]
	# top bar
	var top := Kit.panel_box(12)
	Kit.place(top, 0, 0, 1, 0, 468, 12, -16, 112)
	add_child(top)
	var tv := Kit.vbox(4)
	top.add_child(tv)
	var th := Kit.hbox(10)
	tv.add_child(th)
	var tt := Kit.lbl(tr("OPERATIONS") + " · " + GameData.ORBITS[mission.orbit].name, 15, Kit.C_ACCENT, Kit.FONT_B)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tt)
	month_lbl = Kit.lbl(tr("Month 0 of %d") % months_total, 15, Kit.C_TEXT, Kit.FONT_B)
	th.add_child(month_lbl)
	time_bar = ProgressBar.new()
	time_bar.show_percentage = false
	time_bar.custom_minimum_size = Vector2(0, 8)
	time_bar.max_value = months_total
	tv.add_child(time_bar)
	var sh := Kit.hbox(10)
	tv.add_child(sh)
	var sl := Kit.lbl(tr("Science"), 14, Kit.C_TEXT, Kit.FONT_B)
	sh.add_child(sl)
	sci_bar = ProgressBar.new()
	sci_bar.show_percentage = false
	sci_bar.custom_minimum_size = Vector2(0, 12)
	sci_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sci_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sci_bar.max_value = S.science_target
	sci_bar.add_theme_stylebox_override("fill", Kit.flat(Kit.C_OK, Color(0, 0, 0, 0), 4, 0, 0, 0))
	sh.add_child(sci_bar)
	sci_lbl = Kit.lbl("0 / %d" % int(S.science_target), 13, Kit.C_DIM)
	sh.add_child(sci_lbl)
	# mission log
	var log_p := Kit.panel_box(12)
	Kit.place(log_p, 0, 0, 0, 1, 12, 12, 452, -12)
	add_child(log_p)
	var lv := Kit.vbox(6)
	log_p.add_child(lv)
	lv.add_child(Kit.lbl(tr("Mission log"), 20, Kit.C_TEXT, Kit.FONT_T))
	log_scroll = ScrollContainer.new()
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(log_scroll)
	log_box = Kit.vbox(6)
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_box)
	# speed controls
	var ctl := Kit.hbox(6)
	Kit.place(ctl, 1, 1, 1, 1, -420, -60, -16, -16)
	ctl.alignment = BoxContainer.ALIGNMENT_END
	add_child(ctl)
	for sp in [1.0, 3.0, 10.0]:
		ctl.add_child(Kit.btn("×%d" % int(sp), func(): speed = sp * max(1.0, months_total / 36.0), 14))
	ctl.add_child(Kit.accent_btn(Kit.btn(tr("See report ▶▶"), func(): month_f = 9999.0, 14), Kit.C_WARN))


func process(delta: float) -> void:
	var sim: Dictionary = GameState.last_sim
	if sim.is_empty() or leaving:
		return
	month_f += delta * speed / 0.7
	var target := int(floor(month_f))
	var months: int = sim.months
	var events: Array = sim.events
	while shown_month < min(target, months):
		shown_month += 1
		while shown_events < events.size() and events[shown_events].month <= shown_month:
			_log_event(events[shown_events])
			shown_events += 1
		if shown_month > 0 and shown_month <= sim.timeline.size():
			var s: float = sim.timeline[shown_month - 1]
			sci_bar.value = s
			sci_lbl.text = "%d / %d" % [int(s), int(GameData.SCENARIOS[mission.scenario].science_target)]
		month_lbl.text = tr("Month %d of %d") % [shown_month, months_total]
		time_bar.value = shown_month
	if shown_month >= months and end_t < 0.0:
		while shown_events < events.size():
			_log_event(events[shown_events])
			shown_events += 1
		end_t = 0.0
		if sim.status == "lost" or months < months_total:
			world.lose_ship()
	if end_t >= 0.0:
		end_t += delta
		if end_t > (2.5 if month_f < 9000.0 else 0.3):
			leaving = true
			main.go_faded("report", 0.8, 0.6)


func _log_event(e: Dictionary) -> void:
	var col: Color = Kit.C_OK if e.kind == "good" else (Kit.C_BAD if e.kind == "bad" else Kit.C_ACCENT)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Kit.flat(Color(col.r, col.g, col.b, 0.08), Color(col.r, col.g, col.b, 0.55), 6, 1, 10, 7))
	var v := Kit.vbox(2)
	pc.add_child(v)
	v.add_child(Kit.lbl(tr("Month %d · %s") % [e.month, e.title], 14, col, Kit.FONT_B, true))
	v.add_child(Kit.lbl(e.text, 13, Kit.C_DIM, Kit.FONT_R, true))
	log_box.add_child(pc)
	pc.modulate.a = 0.0
	pc.create_tween().tween_property(pc, "modulate:a", 1.0, 0.4)
	if e.kind != "info" and month_f < 9000.0:
		toast(e.title, col, 1.8)
	# scroll to the newest entry once the log has its new size (next frame); freed with the screen if it leaves first
	if not get_tree().process_frame.is_connected(_scroll_log_to_end):
		get_tree().process_frame.connect(_scroll_log_to_end, CONNECT_ONE_SHOT)


func _scroll_log_to_end() -> void:
	log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)
