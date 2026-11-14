extends Node3D
## Farpoint HORIZON. The flow controller: it owns the 3D world and the UI root, and switches screens.
## Flow: menu -> team -> missions (CML 1) -> design (CML 2-4, with the rocket builder) -> launch -> [flight -> landing,
## for a mission that lands] -> operation -> report.
## Each screen is a script in scripts/screens/ (see screen.gd); the shared state is the autoload GameState.

const World := preload("res://scripts/world.gd")
const Kit := preload("res://scripts/ui/kit.gd")
const Screen := preload("res://scripts/screens/screen.gd")

## Every screen by id. A new screen is a script in scripts/screens/ and one line here.
const SCREENS := {
	"menu": preload("res://scripts/screens/menu.gd"),
	"team": preload("res://scripts/screens/team.gd"),
	"missions": preload("res://scripts/screens/missions.gd"),
	"design": preload("res://scripts/screens/design.gd"),
	"builder": preload("res://scripts/screens/builder.gd"),
	"launch": preload("res://scripts/screens/launch.gd"),
	"flight": preload("res://scripts/screens/flight.gd"),
	"landing": preload("res://scripts/screens/landing.gd"),
	"operation": preload("res://scripts/screens/operation.gd"),
	"report": preload("res://scripts/screens/report.gd"),
}
## Overlays by id: drawn on top of the current screen, which stays.
const OVERLAYS := {
	"ranking": preload("res://scripts/screens/ranking.gd"),
	"howto": preload("res://scripts/screens/howto.gd"),
}

var world: World
var ui: CanvasLayer
var root_ui: Control
var fade_rect: ColorRect
var screen: Screen          ## The current screen.
var screen_id := ""
var launching := false      ## A launch is fading in: a second click on the launch button does nothing.


func _ready() -> void:
	randomize()
	GameState.trace("inicio")
	world = World.new()
	add_child(world)
	world.setup()
	GameState.trace("mundo listo")
	_setup_ui()
	GameState.trace("interfaz lista")
	go("menu")
	GameState.trace("menu listo")


func _setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = Kit.build_theme()
	ui.add_child(root_ui)
	var top := CanvasLayer.new()
	top.layer = 10
	add_child(top)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fade_rect)


func _process(delta: float) -> void:
	world.update(delta)
	if screen and is_instance_valid(screen):
		screen.process(delta)


# ===================================================================================== FLOW
## Leaves the current screen and enters screen `id` (a key of SCREENS) with args.
func go(id: String, args := {}) -> void:
	if screen and is_instance_valid(screen):
		screen.exit()
		screen.queue_free()
	world.cam_free = true
	screen_id = id
	screen = _make(SCREENS[id], root_ui)
	GameState.phase = id
	screen.enter(args)


## Fades to black in out_time, goes to screen `id`, and fades back in in_time.
func go_faded(id: String, out_time: float, in_time: float, args := {}) -> void:
	await fade(1.0, out_time).finished
	go(id, args)
	fade(0.0, in_time)


## Opens overlay `id` (a key of OVERLAYS) on top of the current screen.
func overlay(id: String, args := {}) -> void:
	var o: Screen = _make(OVERLAYS[id], screen)
	o.enter(args)


func _make(script: GDScript, parent: Control) -> Screen:
	var s: Screen = script.new()
	s.main = self
	s.world = world
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return s


func fade(to: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", to, time)
	return tw


## Launches GameState's mission if it can fly: records the flight (GameState.begin_flight) and fades to the launch.
## In an online room the press only asks the room: every machine then launches with the same seed (`seed_value`), so
## everyone flies the same random events.
func launch(seed_value := -1) -> void:
	if launching:
		return
	var r: Dictionary = GameState.mission.compute()
	if seed_value < 0 and not GameState.can_launch(r):
		screen.toast(tr("Fix the red items first"), Kit.C_BAD)
		return
	if seed_value < 0 and GameState.room.is_online():
		GameState.room.request_launch(randi() % 1000000)
		return
	launching = true
	GameState.begin_flight(r, seed_value)
	await go_faded("launch", 0.5, 0.6)
	launching = false


var _frames_traced := 0
func _physics_process(_d: float) -> void:
	if _frames_traced < 3:
		_frames_traced += 1
		GameState.trace("frame %d dibujado" % _frames_traced)
