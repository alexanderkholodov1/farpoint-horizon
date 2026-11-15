extends CanvasLayer
## The ground-control desk (issue #9): what the ground-control station does during the flight, over the flight's own
## screens. When a person holds the station it opens its mini-games at the real moments: "Find the carrier" when the
## craft leaves for the Moon (scripts/minigames/carrier.gd) and the 1202 during the descent (scripts/minigames/triage.gd,
## as GameState.ground_answer). When a bot holds it, Echo does the same work and says so. Solving adds a bonus to the
## flight (GameState.flight.ground, counted by settle_extras); missing it costs nothing.
##   preload("res://scripts/minigames/desk.gd").install(main)   # main.gd, when a flight begins

const Kit := preload("res://scripts/ui/kit.gd")
const Dsn := preload("res://scripts/minigames/dsn.gd")
const Carrier := preload("res://scripts/minigames/carrier.gd")
const Triage := preload("res://scripts/minigames/triage.gd")
const Bots := preload("res://scripts/crew/bots.gd")
const UNIX_DAY0 := 1794700800          ## 15 November 2026 00:00 UTC: time zero of scripts/flight/transfer.gd.
const CARRIER_AFTER_S := 1800.0        ## Mission seconds after the burn to the Moon: far enough for the Deep Space Network.
const ENDS := ["report", "menu", "ranking", "team", "missions", "design"]

var main
var human := false
var root: Control
var panel: PanelContainer
var tli_t := -1.0
var carrier_done := false


static func install(m) -> void:
	var old: Node = m.get_node_or_null("GroundDesk")
	if old:
		old.name = "GroundDeskOld"
		old.queue_free()
	var d = load("res://scripts/minigames/desk.gd").new()
	d.main = m
	d.name = "GroundDesk"
	m.add_child(d)


func _ready() -> void:
	layer = 6
	var room = GameState.room
	human = room != null and not room.is_bot("ground") and (not room.is_online() or room.mine("ground"))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Kit.build_theme()
	add_child(root)
	GameState.ground_answer = _answer if human else Callable()
	GameState.flight_event.connect(_on_event)


func _exit_tree() -> void:
	if GameState.flight_event.is_connected(_on_event):
		GameState.flight_event.disconnect(_on_event)
	if GameState.ground_answer.is_valid() and GameState.ground_answer.get_object() == self:
		GameState.ground_answer = Callable()


func _on_event(kind: String, data: Dictionary) -> void:
	match kind:
		"tli":
			tli_t = float(data.get("met_s", -1.0))
			var fl = _flight()
			if fl:
				tli_t = fl.m.t
		"touchdown", "impact", "launch_lost":
			_close()


func _process(_delta: float) -> void:
	if main == null or not is_instance_valid(main) or main.screen_id in ENDS:
		queue_free()
		return
	var fl = _flight()
	if fl == null and panel and is_instance_valid(panel) and panel.get_child_count() > 0 and panel.get_child(0) is Carrier:
		panel.get_child(0)._finish("bot")      # the trip is over: Echo locks it
	if fl and tli_t >= 0.0 and not carrier_done and fl.phase == "coast" and fl.m.t - tli_t >= CARRIER_AFTER_S:
		carrier_done = true
		_open_carrier(fl)


## The flight screen while it shows the trip, or null.
func _flight():
	if main.screen_id == "flight" and main.screen and "m" in main.screen and main.screen.m:
		return main.screen
	return null


# ===================================================================================== THE CARRIER
func _open_carrier(fl) -> void:
	var m = fl.m
	var unix: float = UNIX_DAY0 + m.t
	var st: Dictionary = Dsn.best_station(unix, m.x, m.y)
	var dist: float = sqrt(m.x * m.x + m.y * m.y)
	var v: float = Dsn.radial(m.x, m.y, m.vx, m.vy)
	# the tone as the pass begins: time may run thousands of times faster meanwhile, and a line that races across
	# the waterfall could not be tuned (our simplification: the real tone drifts by a few hertz a second)
	var f0 := Dsn.doppler_hz(v)
	var f_now := func() -> float: return f0
	if not human:
		var words := tr("%s: %s has the craft's carrier, %d° up. Light time %.2f s.") % [Bots.NAMES.ground, st.name, roundi(st.elev), Dsn.light_s(dist)]
		Kit.toast(root, words, Kit.C_ACCENT, 3.5)
		_record("carrier", {"by": "bot", "bonus": 0, "station": st.id})
		return
	var g = Carrier.new()
	g.setup(st, f_now, Dsn.light_s(dist), v)
	g.done.connect(func(r: Dictionary):
		r["station"] = st.id
		_record("carrier", r)
		_close_later(r))
	_show(g)


# ===================================================================================== THE 1202
## GameState.ground_answer while a person holds the station: the failure's mini-game, then done(answer).
func _answer(failure: Dictionary, done: Callable) -> void:
	if str(failure.get("code", "")) != "1202":
		done.call({"go": true, "by": "bot", "bonus": 0, "words": tr("Ground here. We're go, keep flying.")})
		return
	var g = Triage.new()
	g.say = func(text: String, col: Color): Kit.toast(root, text, col, 1.2)
	g.setup(failure)
	g.done.connect(func(r: Dictionary):
		_record("1202", r)
		done.call(r)
		_close_later(r))
	_show(g)


# ===================================================================================== PANEL AND RESULTS
func _show(game: Control) -> void:
	_close()
	panel = Kit.panel_box(Kit.PAD)
	if Kit.compact:   # on a phone in the middle, over the scene: there is no free corner
		Kit.place(panel, 0.5, 0.5, 0.5, 0.5, -212, 0, 212, 0)
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	else:
		Kit.place(panel, 0, 0, 0, 0, Kit.MARGIN, 446, Kit.MARGIN + 424, 446)   # under the time panel, clear of the messages and the controls
	panel.add_child(game)
	root.add_child(panel)
	panel.modulate.a = 0.0
	panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.3)
	Kit.UiSound.play("notify")


func _close_later(r: Dictionary) -> void:
	var p := panel
	if p == null:
		return
	if r.get("by", "") == "bot":
		Kit.toast(root, str(r.get("words", "")), Kit.C_ACCENT, 2.5)
	var tw := p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		if panel == p:
			panel = null
		p.queue_free())


func _close() -> void:
	if panel and is_instance_valid(panel):
		panel.queue_free()
	panel = null


## Keeps what ground control did in GameState.flight.ground ({"bonus", "done": {id: result}}) and, when a person
## solved it, tells it in the mission's log as good news.
func _record(id: String, r: Dictionary) -> void:
	var g: Dictionary = GameState.flight.get("ground", {"bonus": 0, "done": {}})
	g.done[id] = r
	g.bonus = int(g.bonus) + int(r.get("bonus", 0))
	GameState.flight["ground"] = g
	if r.get("by", "") == "player" and GameState.last_sim.has("events"):
		var title := tr("Ground control · carrier locked") if id == "carrier" else tr("Ground control · go on the 1202")
		GameState.last_sim.events.append({"month": 0, "kind": "good", "title": title, "text": str(r.get("words", ""))})
	GameState.flight_moment("ground", {"id": id, "by": r.get("by", ""), "bonus": int(r.get("bonus", 0))})
