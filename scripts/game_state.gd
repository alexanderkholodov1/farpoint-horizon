extends Node
## The state of the game being played (autoload `GameState`): the mission being designed, the team, the difficulty,
## the phase, and the last flight with its report. Screens read it and change it; whatever changes it emits `changed`
## (the methods and setters here do; a screen that edits `mission` directly emits it after the edit).

signal changed

const Mission := preload("res://scripts/mission.gd")
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
	mission.orbit = "lunar" if scenario_id == "luna" else ("l2" if scenario_id == "telescopio" else "sso")
	if scenario_id == "telescopio":
		mission.orbit = "leo"
	mission.years = GameData.SCENARIOS[scenario_id].min_years
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
