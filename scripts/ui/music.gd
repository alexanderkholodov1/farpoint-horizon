extends Node
## The game's music (issue #12): "Horizon", our own piece composed by tools/audio/compose_music.py, a seamless loop.
## One player for the whole game, started by the menu (Music.ensure(main)). It reads which screen is showing and sets
## its own level: under the menus and the design, louder in the credits film, nearly silent during the launch, the
## trip and the landing, where the engines and the call-outs speak. It plays on the Master bus, so the menu's Sound
## off silences it with everything else, and it pauses while the game's window is not in front.
##   const Music := preload("res://scripts/ui/music.gd")

const TRACK := preload("res://audio/music_horizon.ogg")
const LEVEL := {"credits_film": -9.0, "launch": -38.0, "flight": -32.0, "landing": -40.0}
const DEFAULT_DB := -17.0

var main
var player: AudioStreamPlayer


## Starts the music once, for the whole game.
static func ensure(m) -> void:
	var root: Window = m.get_tree().root
	if root.has_node("Music"):
		return
	var n = load("res://scripts/ui/music.gd").new()
	n.name = "Music"
	n.main = m
	root.add_child.call_deferred(n)


func _ready() -> void:
	player = AudioStreamPlayer.new()
	var s: AudioStreamOggVorbis = TRACK.duplicate()
	s.loop = true
	player.stream = s
	player.volume_db = -60.0
	add_child(player)
	player.play()


func _process(delta: float) -> void:
	if player == null:
		return
	var id: String = main.screen_id if main and is_instance_valid(main) else ""
	var goal: float = LEVEL.get(id, DEFAULT_DB)
	# fades of about two seconds, in decibels
	player.volume_db = move_toward(player.volume_db, goal, delta * 12.0)


func _notification(what: int) -> void:
	if player == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		player.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		player.stream_paused = false
