extends RefCounted
## Which missions the player has finished, kept between sessions (user://settings.cfg, [progress]). The mission select
## opens the missions in order: each one opens when the one before it is done. "All open" (settings) lifts that, for a
## demo or a player who wants to choose freely. Missions flagged "soon" in data/scenarios.json are never open.
##   const Progress := preload("res://scripts/progress.gd")

const PATH := "user://settings.cfg"
## The order missions open in, from the simplest to the hardest; the sandbox last.
const ORDER := ["volcanes", "clima", "luna", "moon_south_pole", "telescopio", "libre"]


static func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	c.load(PATH)
	return c


static func is_done(id: String) -> bool:
	return bool(_cfg().get_value("progress", id, false))


## Records a finished mission (the report screen calls it).
static func done(id: String) -> void:
	var c := _cfg()
	c.set_value("progress", id, true)
	c.save(PATH)


static func all_open() -> bool:
	return bool(_cfg().get_value("progress", "_all_open", false))


static func set_all_open(on: bool) -> void:
	var c := _cfg()
	c.set_value("progress", "_all_open", on)
	c.save(PATH)


## "" when the mission can be played; else why not: "soon" (not built yet) or the id of the mission to finish first.
static func locked_by(id: String, scenario: Dictionary) -> String:
	if scenario.get("soon", false):
		return "soon"
	if all_open():
		return ""
	var i := ORDER.find(id)
	if i <= 0:
		return ""
	return "" if is_done(ORDER[i - 1]) else ORDER[i - 1]
