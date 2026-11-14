extends Node
## The state of the game being played (autoload `GameState`): the mission being designed, the team, the difficulty,
## the phase, and the last flight with its report. Screens read it and change it; whatever changes it emits `changed`
## (the methods and setters here do; a screen that edits `mission` directly emits it after the edit).

signal changed
## The online room could not do something: a text for the player.
signal room_failed(text: String)

const Mission := preload("res://scripts/mission.gd")
const RoomLocal := preload("res://scripts/net/room_local.gd")
const RoomOnline := preload("res://scripts/net/room_online.gd")
const TransportWeb := preload("res://scripts/net/transport_web.gd")
const RANKING_PATH := "user://ranking.json"

var mission = Mission.new()     ## The mission being designed (scripts/mission.gd).
var room                        ## The shared state of the crew (scripts/net/room.gd): stations, sign-offs, bots' lines, launch.
var players: Array = []         ## [{"name": String, "roles": [station ids of GameData.ROLES]}] of the people (not bots), from the room.
var team_mode := false          ## True when two or more people share the game (or it is online): each station signs off.
## Station id -> true once that station signed off the design (the room's state). Setting it to {} clears the sign-offs.
var approvals: Dictionary:
	get:
		return room.state.approvals
	set(value):
		if value.is_empty():
			room.submit({"k": "clear"})
var _launch_seen := 0
var last_report := {}           ## mission.compute() at the last launch.
var last_sim := {}              ## mission.simulate() of the last launch: events, timeline, months, score.
var saved_to_ranking := false   ## The last flight is already in the ranking.
var ranking: Array = []         ## Local ranking, best first: [{"team", "score", "grade", "scenario", "difficulty", "date"}].

## The id of the screen being played ("menu", "design", "launch"...). main.gd sets it on every screen change.
var phase := "":
	set(value):
		phase = value
		changed.emit()

## The difficulty id (GameData.DIFFICULTY); it lives in the mission, which uses it in its numbers.
var difficulty: String:
	get:
		return mission.difficulty
	set(value):
		mission.difficulty = value
		changed.emit()


func _ready() -> void:
	_set_room(RoomLocal.new())
	load_ranking()


func _process(_delta: float) -> void:
	if room:
		room.poll()


## Prints a startup trace line tagged [SKH] (see docs/STATE.md, open problem).
func trace(msg: String) -> void:
	print("[SKH] ", msg)


# ===================================================================================== TEAM
func _set_room(r) -> void:
	if room:
		room.changed.disconnect(_on_room_changed)
		room.failed.disconnect(_on_room_failed)
		room.leave()
	room = r
	room.local_mission = func(): return mission.to_dict()
	room.changed.connect(_on_room_changed)
	room.failed.connect(_on_room_failed)
	_rebuild_players()
	changed.emit()


func _on_room_failed(text: String) -> void:
	room_failed.emit(text)


## Every change of the room: the shared design becomes this machine's design, and a guest follows the host.
func _on_room_changed(_by_me: bool) -> void:
	var m: Dictionary = room.state.mission
	if not m.is_empty():
		var d := m.duplicate()
		if d.has("years"):
			d["years"] = int(d["years"])   # JSON numbers arrive as floats
		mission.from_dict(d)
	_rebuild_players()
	var main = get_tree().current_scene if get_tree() else null
	if room.is_online() and main and main.has_method("launch"):
		var n := int(room.state.launch.n)
		if n > _launch_seen:
			_launch_seen = n
			main.launch(int(room.state.launch.seed))
		elif not room.is_host() and room.state.phase == "design" and phase == "team":
			main.go("design", {"step": 0})
	changed.emit()


func _rebuild_players() -> void:
	var by_pid := {}
	players = []
	for st in GameData.ROLE_ORDER:
		var h: Dictionary = room.holder(st)
		if h.kind == "human":
			if not by_pid.has(h.pid):
				by_pid[h.pid] = {"name": h.name, "roles": []}
				players.append(by_pid[h.pid])
			by_pid[h.pid].roles.append(st)
	team_mode = room.human_count() > 1 or room.is_online()


## A room on this machine: mode is "solo" or "same". humans is [{"name", "stations": [ids]}]; every other station is a bot.
func start_crew(mode: String, humans: Array) -> void:
	var r := RoomLocal.new()
	r.mode = mode
	r.state.mode = mode
	var s := {}
	for i in humans.size():
		for st in humans[i].stations:
			s[st] = {"kind": "human", "pid": "%s%d" % [r.me, i], "name": humans[i].name}
	r.apply_op({"k": "set_stations", "s": s})
	_set_room(r)


## One player. With a station, bots take the other three; with none, the player holds all four (no bots).
func start_solo(station := "") -> void:
	var stations: Array = [station] if station != "" else GameData.ROLE_ORDER.duplicate()
	start_crew("solo", [{"name": tr("Player"), "stations": stations}])


## The online room of this machine: null when the page cannot reach Firebase (the editor, a desktop run).
func new_online_room():
	if not TransportWeb.available():
		return null
	var r := RoomOnline.new()
	r.transport = TransportWeb.new()
	_set_room(r)
	return r


func player_for_role(role: String) -> String:
	return room.holder_name(role)


func all_approved() -> bool:
	for role in GameData.ROLE_ORDER:
		if not approvals.get(role, false):
			return false
	return true


## Every station has signed off, or the only person in the crew has not yet and the bots have (their sign-off is the
## launch button).
func crew_ready() -> bool:
	for role in GameData.ROLE_ORDER:
		if approvals.get(role, false):
			continue
		if room.holder(role).kind == "human" and room.human_count() <= 1:
			continue
		return false
	return true


## Every station signs off (used to fly the same design again).
func approve_all() -> void:
	for role in GameData.ROLE_ORDER:
		room.sign(role)


# ===================================================================================== MISSION
## A new mission for the scenario, with the cheapest parts and the scenario's usual orbit; keeps the difficulty.
func start_mission(scenario_id: String) -> void:
	var diff: String = mission.difficulty
	mission = Mission.new()
	mission.difficulty = diff
	mission.scenario = scenario_id
	mission.bus = "cube6"
	mission.panels = "body"
	mission.battery = "b20"
	mission.comms = "uhf"
	mission.adcs = "mag"
	mission.propulsion = "none"
	mission.launcher = "ride"
	mission.orbit = "lunar" if scenario_id == "luna" else ("l2" if scenario_id == "telescopio" else "sso")
	mission.years = GameData.SCENARIOS[scenario_id].min_years
	if room.is_host():
		room.start_design(mission.to_dict())
	changed.emit()


## The design can fly: nothing fatal and the crew signed off. r is mission.compute().
func can_launch(r: Dictionary) -> bool:
	return not r.fatal and crew_ready()


## Records a launch: the report at launch and its simulated flight (random events).
func begin_flight(r: Dictionary, seed_value := -1) -> void:
	last_report = r
	last_sim = mission.simulate(seed_value)
	saved_to_ranking = false
	changed.emit()


# ===================================================================================== RANKING
func load_ranking() -> void:
	ranking = []
	if FileAccess.file_exists(RANKING_PATH):
		var f := FileAccess.open(RANKING_PATH, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Array:
				ranking = data


func add_ranking(team: String, score: int, grade: String) -> void:
	ranking.append({"team": team.strip_edges(), "score": score, "grade": grade, "scenario": GameData.SCENARIOS[mission.scenario].name,
		"difficulty": GameData.DIFFICULTY[mission.difficulty].name, "date": Time.get_date_string_from_system()})
	ranking.sort_custom(func(a, b): return a.score > b.score)
	if ranking.size() > 20:
		ranking.resize(20)
	var f := FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ranking))
	changed.emit()
