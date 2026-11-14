extends "res://scripts/screens/screen.gd"
## Team setup: first how many players, then their names and the roles each one takes.
## args: {"players": n} with n from 2 to 4 opens the names step; without it, the count step.

## Roles of each player, by number of players.
const ROLE_SPLIT := {
	1: [["director", "cientifico", "ingeniero", "operaciones"]],
	2: [["director", "cientifico"], ["ingeniero", "operaciones"]],
	3: [["director", "operaciones"], ["cientifico"], ["ingeniero"]],
	4: [["director"], ["cientifico"], ["ingeniero"], ["operaciones"]],
}


func enter(args: Dictionary) -> void:
	var n: int = args.get("players", 0)
	if n == 0:
		_show_count()
	else:
		_show_names(n)


func _show_count() -> void:
	var p := Kit.panel_box(26)
	Kit.place(p, 0.5, 0.5, 0.5, 0.5, -330, -260, 330, 260)
	add_child(p)
	var v := Kit.vbox(12)
	p.add_child(v)
	v.add_child(Kit.lbl(tr("Team mode"), 30, Color.WHITE, Kit.FONT_T))
	v.add_child(Kit.lbl(tr("As in NASA's Mission Design Lab, each member is responsible for a part of the mission. You will have to negotiate, because what one gains another gives up."), 15, Kit.C_DIM, Kit.FONT_R, true))
	v.add_child(Kit.lbl(tr("How many players?"), 16, Kit.C_TEXT, Kit.FONT_B))
	var h := Kit.hbox(10)
	v.add_child(h)
	for n in [2, 3, 4]:
		h.add_child(Kit.accent_btn(Kit.btn(tr("%d players") % n, func(): go("team", {"players": n}), 18, 180), Color(0.5, 1.0, 0.6)))
	v.add_child(Kit.spacer(10))
	v.add_child(Kit.btn(tr("◀ Back"), func(): go("menu")))


func _show_names(n: int) -> void:
	var p := Kit.panel_box(26)
	Kit.place(p, 0.5, 0.5, 0.5, 0.5, -480, -330, 480, 330)
	add_child(p)
	var v := Kit.vbox(10)
	p.add_child(v)
	v.add_child(Kit.lbl(tr("Your mission team"), 30, Color.WHITE, Kit.FONT_T))
	v.add_child(Kit.lbl(tr("Type your names. Each role has its own goal, and if everyone meets theirs the team earns bonus points."), 15, Kit.C_DIM, Kit.FONT_R, true))
	var split: Array = ROLE_SPLIT[n]
	var edits: Array = []
	for i in n:
		var row := Kit.hbox(12)
		v.add_child(row)
		var e := LineEdit.new()
		e.placeholder_text = tr("Player %d") % (i + 1)
		e.text = tr("Player %d") % (i + 1)
		e.custom_minimum_size = Vector2(220, 0)
		row.add_child(e)
		edits.append(e)
		var rv := Kit.vbox(2)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rv)
		for role in split[i]:
			var R: Dictionary = GameData.ROLES[role]
			rv.add_child(Kit.lbl(R.name, 16, R.color, Kit.FONT_B))
			rv.add_child(Kit.lbl(tr("Goal") + " · " + R.goal, 13, Kit.C_DIM, Kit.FONT_R, true))
		v.add_child(HSeparator.new())
	var h := Kit.hbox(10)
	v.add_child(h)
	h.add_child(Kit.btn(tr("◀ Back"), func(): go("team")))
	h.add_child(Kit.accent_btn(Kit.btn(tr("Continue ▶"), func():
		var team: Array = []
		for i in n:
			var nm: String = edits[i].text.strip_edges()
			team.append({"name": nm if nm != "" else tr("Player %d") % (i + 1), "roles": split[i].duplicate()})
		GameState.set_team(team)
		go("missions"), 18), Kit.C_ACCENT))
