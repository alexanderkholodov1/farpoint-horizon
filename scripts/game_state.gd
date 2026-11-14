extends Node
## The state of the game being played (autoload `GameState`): the mission being designed, the team, the difficulty,
## the phase, and the last flight with its report. Screens read it and change it; whatever changes it emits `changed`
## (the methods and setters here do; a screen that edits `mission` directly emits it after the edit).

signal changed

const Mission := preload("res://scripts/mission.gd")
const Objectives := preload("res://scripts/flight/objectives.gd")
const RANKING_PATH := "user://ranking.json"

var mission = Mission.new()     ## The mission being designed (scripts/mission.gd).
var players: Array = []         ## [{"name": String, "roles": [role ids of GameData.ROLES]}], in turn order.
var team_mode := false          ## True when 2 to 4 players share the game: each role decides its steps and approves.
var approvals := {}             ## Role id -> true once that role approved the design (team mode).
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
	load_ranking()


## Prints a startup trace line tagged [SKH] (see docs/STATE.md, open problem).
func trace(msg: String) -> void:
	print("[SKH] ", msg)


# ===================================================================================== TEAM
func start_solo() -> void:
	team_mode = false
	players = [{"name": tr("Player"), "roles": GameData.ROLE_ORDER.duplicate()}]
	changed.emit()


func set_team(team: Array) -> void:
	team_mode = true
	players = team
	changed.emit()


func player_for_role(role: String) -> String:
	for p in players:
		if p.roles.has(role):
			return p.name
	return tr("Player")


func all_approved() -> bool:
	for role in GameData.ROLE_ORDER:
		if not approvals.get(role, false):
			return false
	return true


## Every role approves (used to fly the same design again).
func approve_all() -> void:
	approvals = {}
	for role in GameData.ROLE_ORDER:
		approvals[role] = true
	changed.emit()


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
	mission.orbit = GameData.SCENARIOS[scenario_id].get("orbit", "lunar" if scenario_id == "luna" else ("l2" if scenario_id == "telescopio" else "sso"))
	mission.years = GameData.SCENARIOS[scenario_id].min_years
	mission.extras_offered = Objectives.draw(scenario_id, 3)
	mission.extras = mission.extras_offered.duplicate()
	approvals = {}
	changed.emit()


## The design can fly: nothing fatal and, in team mode, every role approved. r is mission.compute().
func can_launch(r: Dictionary) -> bool:
	return not r.fatal and (not team_mode or all_approved())


## Records a launch: the report at launch and its simulated flight (random events).
func begin_flight(r: Dictionary) -> void:
	last_report = r
	last_sim = mission.simulate()
	saved_to_ranking = false
	flight = {}
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


# ===================================================================================== FLIGHT (the pilot, issue #8)
## A moment of the pilot's flight, for ground control (#9) and the celebration (#11). kind is one of "launch",
## "staging", "orbit", "launch_lost", "burn_start", "burn_end", "coast", "arrival", "descent_start", "alarm",
## "alarm_cleared", "touchdown", "impact"; data holds the numbers of that moment (see docs/architecture.md, "Flight").
signal flight_event(kind: String, data: Dictionary)

## What the pilot did on the last flight, filled as it happens; begin_flight() empties it. Keys: "ascent", "tli",
## "landing" (each a Dictionary, see docs/architecture.md), "extras" (objective id -> true when met), "photos" (the
## pictures the mission sent home, res:// paths), "bonus" (points of the extra objectives met).
var flight := {}
## True when a bot holds the pilot's station (the room, #5, sets it): the flight then flies itself, and a person can
## still take the controls.
var pilot_bot := false
## Ground control's answer to a failure in flight. Issue #9 sets it to its mini-game:
## func(failure: Dictionary, done: Callable), and calls done.call({"go": true, "by": "player", "bonus": points}) when
## solved. While it is unset, the ground-control bot answers (scripts/flight/ground.gd).
var ground_answer := Callable()


## Tells everyone listening that a moment of the flight happened, and keeps it in flight.log.
func flight_moment(kind: String, data := {}) -> void:
	if not flight.has("log"):
		flight.log = []
	flight.log.append({"kind": kind, "data": data})
	flight_event.emit(kind, data)
	changed.emit()


## The flight ended before the mission could work (the rocket flew apart, or the lander made a crater): the operation
## is skipped and the report tells it. title and text are shown in the report.
func end_flight_early(title: String, text: String, science_frac := 0.0) -> void:
	var sim := last_sim
	sim.launch_failed = sim.get("launch_failed", false) or flight.get("landing", {}).is_empty()
	sim.status = "lost"
	sim.end_reason = title
	sim.months = 0
	sim.timeline = []
	var science_target: float = GameData.SCENARIOS[mission.scenario].science_target
	sim.science = science_target * science_frac
	var kept: Array = []
	for e in sim.events:
		if e.month == 0 and e.kind != "good":
			kept.append(e)
	kept.append({"month": 0, "kind": "bad", "title": title, "text": text})
	sim.events = kept
	sim.score = mission.score(last_report, sim)
	last_sim = sim
	changed.emit()


## Adds the extra objectives the flight met to flight.extras, flight.bonus and flight.photos, and to the mission log as
## good news. Called when the flight is over (after touchdown).
func settle_extras() -> void:
	var met := {}
	var bonus := 0
	var photos: Array = flight.get("photos", [])
	var all: Dictionary = Objectives.all()
	for id in mission.extras:
		if not all.has(id):
			continue
		var ok: bool = Objectives.met(id, flight)
		met[id] = ok
		if ok:
			bonus += int(all[id].points)
			if all[id].has("photo") and not photos.has(all[id].photo):
				photos.append(all[id].photo)
			if last_sim.has("events"):
				last_sim.events.append({"month": 0, "kind": "good", "title": tr("Extra objective · %s") % all[id].name, "text": all[id].desc})
	flight.extras = met
	flight.bonus = bonus
	flight.photos = photos
	changed.emit()
