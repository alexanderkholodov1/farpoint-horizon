extends "res://scripts/screens/screen.gd"
## Overlay: how to play, in plain words. Opened with main.overlay("howto") (the menu) or from the pause card.
## Esc, Enter or Backspace close it (issue #58).

const PARTS := [
	["1. Choose a mission.", "Each one starts with a real science question: when will a volcano erupt, is El Niño coming? Missions open one after another."],
	["2. Design your craft, one question at a time.", "Where it flies, how big it is, what it carries, its power, antenna and engine, and the rocket. The option with a star is the best fit; the board on the right says what is fine, and Your resources (bottom right) shows what you have and what you have used."],
	["3. Fix what is red, then LAUNCH!", "Red blocks the launch; amber flies but costs science. Every problem has a button that takes you to the step that fixes it."],
	["4. Fly it.", "Lean the rocket with the arrows to keep the needle on the green marker, Space drops an empty stage. Faster time is a visible control; the flight computer helps when you let go."],
	["5. Keep it talking to Earth.", "Ground control finds your craft's radio signal and answers the alarms. Then the months of work go by and the report shows the real NASA photos your mission sent home."],
	["Keys.", "Enter goes on, Backspace goes back, the numbers choose, Esc pauses a mission. Drag to turn the camera, scroll to zoom."],
]


func enter(_args: Dictionary) -> void:
	var v := Kit.overlay(self, tr("How to play"), 960, 560, queue_free)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = false
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var text := ""
	for p in PARTS:
		text += "[b]" + tr(p[0]) + "[/b] " + tr(p[1]) + "\n\n"
	text += "[b]" + tr("Words you will meet") + "[/b]\n"
	for e in preload("res://scripts/ui/glossary.gd").all():
		text += "• [b]" + tr(str(e.term)) + "[/b]: " + tr(str(e.meaning)) + "\n"
	text += "\n" + tr("Every number comes from NASA or a real mission; the Credits list every source.")
	rt.text = text
	v.add_child(rt)
	v.add_child(Kit.lbl(tr("Esc or Enter closes this."), Kit.T_SMALL, Kit.C_DIM))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE]:
		get_viewport().set_input_as_handled()
		queue_free()
