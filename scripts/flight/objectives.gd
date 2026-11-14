extends RefCounted
## Extra objectives (data/objectives.json): the pool of a scenario, the three drawn at random for a mission, and whether
## a flight met each one. Texts come translated (GameData's own preparation).
##   const Objectives := preload("res://scripts/flight/objectives.gd")

const GD := preload("res://scripts/game_data.gd")


## Every objective, id -> entry (texts translated).
static func all() -> Dictionary:
	return GD._entries("objectives")


## Ids of the objectives of a scenario.
static func pool(scenario_id: String) -> Array:
	var out: Array = []
	var a := all()
	for id in a:
		if a[id].get("scenario", "") == scenario_id:
			out.append(id)
	return out


## n ids drawn at random from the scenario's pool (all of them when the pool is smaller).
static func draw(scenario_id: String, n := 3, rng: RandomNumberGenerator = null) -> Array:
	var p := pool(scenario_id)
	var out: Array = []
	while not p.is_empty() and out.size() < n:
		var i := (rng.randi() if rng else randi()) % p.size()
		out.append(p[i])
		p.remove_at(i)
	return out


## True when the flight (GameState.flight) met the objective. Unknown measures count as not met yet.
static func met(id: String, flight: Dictionary) -> bool:
	var e: Dictionary = all().get(id, {})
	if e.is_empty():
		return false
	var c: Dictionary = e.check
	var land: Dictionary = flight.get("landing", {})
	match str(c.kind):
		"target_m", "pole_m", "shadow_edge_m":
			return land.get("landed", false) and float(land.get(c.kind, INF)) <= float(c.max)
		"touchdown_mps":
			return land.get("landed", false) and float(land.get("touchdown_mps", INF)) <= float(c.max)
		"fuel_left":
			return land.get("landed", false) and float(land.get("fuel_left", 0.0)) >= float(c.min)
		"contact_kept":
			return land.get("landed", false) and bool(land.get("contact_kept", false))
		"tli_error":
			return flight.has("tli") and absf(float(flight.tli.get("error", 1.0))) <= float(c.max)
		"ascent_error_deg":
			# flown by a person for most of the climb, not by the flight computer
			return flight.has("ascent") and bool(flight.ascent.get("orbit", false)) and float(flight.ascent.get("own_share", 0.0)) >= 0.6 				and float(flight.ascent.get("mean_error_deg", 99.0)) <= float(c.max)
	return false
