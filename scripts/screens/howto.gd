extends "res://scripts/screens/screen.gd"
## Overlay: how to play, in plain words. Opened with main.overlay("howto").


func enter(_args: Dictionary) -> void:
	var v := Kit.overlay(self, tr("How to play"), 960, 680, queue_free)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = false
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.text = tr("""[b]1. Choose a goal[/b] (CML 1). Every mission starts with a science question. When will a volcano erupt? Is El Niño coming?

[b]2. Design the mission step by step[/b] (CML 2 to 4), like NASA's Mission Design Lab: orbit, platform, instruments, power, communications, control, propulsion and launcher. Every decision changes the others, and the board on the right shows it live.

[b]3. Review and launch.[/b] Red blocks the launch (it doesn't fit, or the money isn't there). Yellow can launch… but will have consequences in operations.

[b]4. Operate the mission.[/b] Watch the months go by with solar storms, space debris, failures… and discoveries. A good design rides out the surprises.

[b]5. Learn from the report[/b] and redesign. There is no single right answer.

[b]Key resources[/b]
• [b]Mass.[/b] Everything weighs. The platform and the rocket both have a limit.
• [b]Power.[/b] Panels make nothing in Earth's shadow, and the battery must cover that time.
• [b]Data.[/b] An instrument that makes more data than the antenna can send wastes science.
• [b]Delta-v.[/b] The “change of speed” propulsion gives you. Going to the Moon or GEO takes a lot.
• [b]Budget and time.[/b] More years in operation means more science and more cost.

[b]Team mode.[/b] Up to 4 players with roles (Direction, Science, Engineering and Operations). Each role has its goal, and everyone must approve the design before launch.

[b]Controls.[/b] Drag with the mouse to turn the camera, scroll to zoom.

Based on NASA resources, “Design and Develop Science Missions”, “CubeSat 101”, and JPL's Concept Maturity Levels (CML).""")
	v.add_child(rt)
