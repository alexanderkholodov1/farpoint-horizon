extends SceneTree
## Mission 1, Apollo 13 (issue #45): the adapter game's rules played through. A clean run finishes with three stars
## and turns the CO2 around; wrong parts cost air and stars but never end the game; at the top of the scale the gauge
## holds and Mission Control lights the part; the data's facts name sources listed in docs/sources.md, and every text
## has its Spanish version in i18n/apollo13.csv.
## Run: tools/godot.sh --headless --path . -s res://tests/apollo13.gd
## check: ^ok apollo13

var bad := 0


func fail(m: String) -> void:
	print("FAIL apollo13: ", m)
	bad += 1


func _initialize() -> void:
	var Adapter = load("res://scripts/missions/apollo13/adapter.gd")
	# a clean run
	var A = Adapter.new()
	var order: Array = A.steps().map(func(s): return s.part)
	if order != ["cardboard", "bag", "tape", "hose"]:
		fail("steps: %s" % [order])
	for id in order:
		A.update(1.0)
		var r: String = A.pick(id)
		if A.presses_needed() > 0 and r == "ok":
			for i in A.presses_needed():
				A.press("perfect")
		elif r != "next":
			fail("pick %s gave %s" % [id, r])
	if not A.done or A.stars() != 3:
		fail("clean run: done=%s stars=%d" % [A.done, A.stars()])
	var before: float = A.co2
	A.update(2.0)
	if A.co2 >= before:
		fail("the CO2 did not turn around")
	# mistakes and a long wait: never a fail
	var B = Adapter.new()
	var c0: float = B.co2
	if B.pick("food") != "wrong" or B.co2 <= c0:
		fail("a wrong part costs no air")
	for i in 400:
		B.update(0.5)
	if B.co2 > 1.0 or not B.hinted:
		fail("top of the scale: co2=%.2f hinted=%s" % [B.co2, B.hinted])
	for id in order:
		if B.pick(id) == "ok":
			for i in B.presses_needed():
				B.press("late")
	if not B.done or B.stars() != 1:
		fail("slow run: done=%s stars=%d" % [B.done, B.stars()])
	# sources and Spanish
	var md := FileAccess.get_file_as_string("res://docs/sources.md")
	var D: Dictionary = A.D
	for F in D.facts + [D.photo]:
		if ("- **%s**" % F.source) not in md:
			fail("source not listed: " + F.source)
	if not FileAccess.file_exists(D.photo.file):
		fail("no photo")
	var es := {}
	var f := FileAccess.open("res://i18n/apollo13.csv", FileAccess.READ)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 2:
			es[row[0]] = row[1]
	var texts := [D.wrong, D.hint, D.win, D.win_sub, D.photo.caption]
	for P in D.parts:
		texts += [P.name, P.line]
	for St in D.steps:
		texts += [St.houston, St.done]
	for F in D.facts:
		texts.append(F.text)
	for t in texts:
		if not es.has(t):
			fail("no Spanish for: " + t)
	print("ok apollo13 %d steps, stars clean %d, slow %d" % [order.size(), A.stars(), B.stars()] if bad == 0 else "FAILED apollo13 %d" % bad)
	quit()
