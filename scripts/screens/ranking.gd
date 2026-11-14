extends "res://scripts/screens/screen.gd"
## Overlay: the local ranking of saved missions (GameState.ranking). Opened with main.overlay("ranking").


func enter(_args: Dictionary) -> void:
	var v := Kit.overlay(self, "Ranking de misiones", 760, 560, queue_free)
	var ranking: Array = GameState.ranking
	if ranking.is_empty():
		v.add_child(Kit.lbl("Todavía no hay misiones guardadas. ¡Sé el primero!", 16, Kit.C_DIM))
		return
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 22)
	sc.add_child(g)
	for hdr in ["#", "Equipo", "Puntos", "Misión", "Dificultad"]:
		g.add_child(Kit.lbl(hdr, 14, Kit.C_ACCENT, Kit.FONT_B))
	for i in ranking.size():
		var e: Dictionary = ranking[i]
		g.add_child(Kit.lbl(str(i + 1), 15, Kit.C_DIM))
		g.add_child(Kit.lbl(str(e.team), 15, Color.WHITE, Kit.FONT_B))
		g.add_child(Kit.lbl("%d (%s)" % [int(e.score), e.grade], 15, Kit.C_WARN, Kit.FONT_B))
		g.add_child(Kit.lbl(str(e.scenario), 14, Kit.C_DIM))
		g.add_child(Kit.lbl(str(e.difficulty), 14, Kit.C_DIM))
