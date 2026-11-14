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
	v.add_child(Kit.lbl("Modo equipo", 30, Color.WHITE, Kit.FONT_T))
	v.add_child(Kit.lbl("Como en el Mission Design Lab de la NASA, cada integrante es responsable de una parte de la misión. Tendrán que negociar: lo que uno gana, otro lo pierde.", 15, Kit.C_DIM, Kit.FONT_R, true))
	v.add_child(Kit.lbl("¿Cuántos jugadores?", 16, Kit.C_TEXT, Kit.FONT_B))
	var h := Kit.hbox(10)
	v.add_child(h)
	for n in [2, 3, 4]:
		h.add_child(Kit.accent_btn(Kit.btn("%d jugadores" % n, func(): go("team", {"players": n}), 18, 180), Color(0.5, 1.0, 0.6)))
	v.add_child(Kit.spacer(10))
	v.add_child(Kit.btn("◀ Volver", func(): go("menu")))


func _show_names(n: int) -> void:
	var p := Kit.panel_box(26)
	Kit.place(p, 0.5, 0.5, 0.5, 0.5, -480, -330, 480, 330)
	add_child(p)
	var v := Kit.vbox(10)
	p.add_child(v)
	v.add_child(Kit.lbl("Su equipo de misión", 30, Color.WHITE, Kit.FONT_T))
	v.add_child(Kit.lbl("Escriban sus nombres. Cada rol tiene una meta propia: si todos la cumplen, el equipo gana puntos extra.", 15, Kit.C_DIM, Kit.FONT_R, true))
	var split: Array = ROLE_SPLIT[n]
	var edits: Array = []
	for i in n:
		var row := Kit.hbox(12)
		v.add_child(row)
		var e := LineEdit.new()
		e.placeholder_text = "Jugador %d" % (i + 1)
		e.text = "Jugador %d" % (i + 1)
		e.custom_minimum_size = Vector2(220, 0)
		row.add_child(e)
		edits.append(e)
		var rv := Kit.vbox(2)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rv)
		for role in split[i]:
			var R: Dictionary = GameData.ROLES[role]
			rv.add_child(Kit.lbl(R.name, 16, R.color, Kit.FONT_B))
			rv.add_child(Kit.lbl("Meta: " + R.goal, 13, Kit.C_DIM, Kit.FONT_R, true))
		v.add_child(HSeparator.new())
	var h := Kit.hbox(10)
	v.add_child(h)
	h.add_child(Kit.btn("◀ Volver", func(): go("team")))
	h.add_child(Kit.accent_btn(Kit.btn("Continuar ▶", func():
		var team: Array = []
		for i in n:
			var nm: String = edits[i].text.strip_edges()
			team.append({"name": nm if nm != "" else "Jugador %d" % (i + 1), "roles": split[i].duplicate()})
		GameState.set_team(team)
		go("missions"), 18), Kit.C_ACCENT))
