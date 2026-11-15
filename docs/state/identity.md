# Visual identity: the palette of the horizon arc (issue #12)

The UI's colours are the brand's arc and nothing else (`scripts/ui/kit.gd`): horizon blue (`C_ACCENT`), sunrise amber
(`C_GOLD`, the one main action of a screen) and navy-tinted neutrals. Status stays inside it: fine is ice blue
(`C_OK`), attention is pale sunrise (`C_WARN`), and one red (`C_BAD`) only for what blocks the mission. No green, pink
or violet. The four stations are four points along the arc (`data/roles.json`); missions no longer carry a colour of
their own on screen.

The mission select (`scripts/screens/missions.gd`) is cards to pick: a NASA picture already in the game, the name, the
brief's first sentence and the facts as chips (`Kit.chip`, `Kit.cover`); the whole brief is the tooltip.

Look at it: `tools/godot.sh --path . --resolution 1600x900 res://tests/identityshot.tscn` (LOOK_MODE=light for the
light appearance), shots in `shots/id_*.png`.

Left to do: the launch's pitch gauge still has a green marker (its text says "the green marker"); the map's planned
path in the flight is green; the design's left column is still text-heavy.
