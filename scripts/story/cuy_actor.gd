extends Node3D
## A cuy on stage (issue #66): one crew model (assets/models/crew/crew_<id>_meshy.glb) brought to life without a rig.
## The models keep their face as separate parts (brows, eyes, glints, mouth and its corners, ears...; assets/source/
## crew_*.py), so the actor moves them: it blinks, raises or knits its brows, smiles or frowns, flaps its mouth while it
## talks, nods, tilts and turns its head toward whoever speaks, breathes, and hops when glad or trembles when scared.
## Each cuy has its own way of doing it (PERSONALITY): Rumi barely moves and keeps his eyes half shut, Killa tilts her
## head at everything, Inti bounces with pride, Wayra is slow and sleepy.
##   var a = CuyActor.new(); a.id = "killa"; add_child(a); a.set_mood("worried"); a.talking = true

## Parts that move with the head (the start of each node's name).
const HEAD_PARTS := ["Head", "Brow", "Eye", "Glint", "Mouth", "Nose", "Whisker", "Ear", "Lid", "Tuft", "Goggle",
	"Headband", "CupRim", "Mic", "Antenna"]

## What a mood does to the face and the body. brow: inner ends up (+) or down (-); brow_y: brows raised; eye: how open
## (1 = as modelled); smile: mouth corners up (+) or down (-); tilt, nod: the head (radians); lean: the body forward;
## bounce: how lively the idle is.
const MOODS := {
	"neutral": {"brow": 0.0, "brow_y": 0.0, "eye": 1.0, "smile": 0.0, "tilt": 0.0, "nod": 0.0, "lean": 0.0, "bounce": 1.0},
	"happy": {"brow": 0.15, "brow_y": 0.006, "eye": 0.75, "smile": 1.0, "tilt": 0.08, "nod": -0.05, "lean": 0.0, "bounce": 1.6},
	"pleased": {"brow": 0.1, "brow_y": 0.004, "eye": 0.6, "smile": 0.8, "tilt": 0.1, "nod": 0.0, "lean": 0.0, "bounce": 1.2},
	"proud": {"brow": -0.1, "brow_y": 0.004, "eye": 0.85, "smile": 0.7, "tilt": 0.0, "nod": -0.14, "lean": -0.06, "bounce": 1.3},
	"curious": {"brow": 0.25, "brow_y": 0.008, "eye": 1.15, "smile": 0.25, "tilt": 0.22, "nod": 0.04, "lean": 0.05, "bounce": 1.2},
	"alert": {"brow": 0.3, "brow_y": 0.012, "eye": 1.3, "smile": -0.4, "tilt": 0.0, "nod": -0.04, "lean": 0.04, "bounce": 1.4},
	"worried": {"brow": 0.55, "brow_y": 0.006, "eye": 1.1, "smile": -0.8, "tilt": -0.1, "nod": 0.08, "lean": 0.03, "bounce": 0.8},
	"scared": {"brow": 0.6, "brow_y": 0.014, "eye": 1.35, "smile": -1.0, "tilt": 0.0, "nod": 0.1, "lean": -0.08, "bounce": 0.6},
	"calm": {"brow": 0.0, "brow_y": 0.0, "eye": 0.8, "smile": 0.2, "tilt": 0.0, "nod": 0.02, "lean": 0.0, "bounce": 0.7},
	"determined": {"brow": -0.45, "brow_y": -0.003, "eye": 0.85, "smile": -0.1, "tilt": 0.0, "nod": 0.06, "lean": 0.07, "bounce": 1.0},
	"flat": {"brow": -0.05, "brow_y": -0.004, "eye": 0.55, "smile": -0.1, "tilt": 0.0, "nod": 0.02, "lean": 0.0, "bounce": 0.4},
	"sleepy": {"brow": 0.1, "brow_y": -0.004, "eye": 0.4, "smile": 0.05, "tilt": -0.12, "nod": 0.12, "lean": 0.0, "bounce": 0.5},
	"tired": {"brow": 0.3, "brow_y": -0.004, "eye": 0.5, "smile": -0.3, "tilt": -0.08, "nod": 0.15, "lean": 0.04, "bounce": 0.5},
	"relieved": {"brow": 0.35, "brow_y": 0.004, "eye": 0.55, "smile": 0.9, "tilt": 0.12, "nod": -0.06, "lean": -0.03, "bounce": 1.1},
	"thoughtful": {"brow": 0.2, "brow_y": 0.003, "eye": 0.75, "smile": 0.1, "tilt": 0.18, "nod": -0.1, "lean": 0.0, "bounce": 0.7},
}

## Each cuy's way of being: how much they move (sway), how often they blink, how open their eyes are at rest, and the
## mood they fall back to.
const PERSONALITY := {
	"rumi": {"sway": 0.35, "blink": 5.5, "eye": 0.8, "rest": "flat", "talk": 0.7},
	"killa": {"sway": 1.0, "blink": 3.0, "eye": 1.05, "rest": "curious", "talk": 1.0},
	"inti": {"sway": 1.2, "blink": 3.5, "eye": 1.0, "rest": "proud", "talk": 1.1},
	"wayra": {"sway": 0.6, "blink": 4.5, "eye": 0.85, "rest": "sleepy", "talk": 0.8},
}

var id := "rumi"
var talking := false         ## While true the mouth flaps.
var look_target = null       ## A global point the head turns toward (null: straight ahead).
var mood := ""
var model: Node3D
var head: Node3D             ## The pivot at the neck that carries every head part.
var brows: Array = []        ## [node, rest position, side (-1 left, +1 right)]
var eyes: Array = []         ## [node, rest scale]
var corners: Array = []      ## [node, rest position, side]
var glints: Array = []
var mouth_open: MeshInstance3D
var mouth_rest := Vector3.ZERO
var p := {}                  ## The face and body now (eased toward the mood).
var goal := {}
var _t := 0.0
var _blink_in := 2.0
var _blink := 0.0            ## 1 while the eyes are shut.
var _hop := 0.0
var _shake := 0.0
var _flap := 0.0
var _phase := 0.0


func _ready() -> void:
	var path := "res://assets/models/crew/crew_%s_meshy.glb" % id
	if not ResourceLoader.exists(path):
		return
	model = load(path).instantiate()
	paint(model)
	add_child(model)
	_phase = float(hash(id) % 100) / 10.0
	_rig()
	var rest: String = PERSONALITY.get(id, {}).get("rest", "neutral")
	set_mood(rest)
	p = goal.duplicate()


## Sets the mood (a key of MOODS; an unknown one is the cuy's resting mood). Glad moods make a hop; scared ones a tremble.
func set_mood(m: String) -> void:
	if not MOODS.has(m):
		m = PERSONALITY.get(id, {}).get("rest", "neutral")
	if m == mood:
		return
	mood = m
	goal = MOODS[m].duplicate()
	goal.eye *= PERSONALITY.get(id, {}).get("eye", 1.0)
	if m in ["happy", "relieved", "proud", "pleased"]:
		hop()
	elif m in ["scared", "alert"]:
		_shake = 0.6


func hop() -> void:
	_hop = 1.0


func shake(t := 0.8) -> void:
	_shake = t


## Where the cuy's face is (for the camera).
func face_point() -> Vector3:
	if head:
		return head.global_transform * Vector3(0, _head_h * 0.45, _face_z)
	return global_position + Vector3(0, 0.75, 0)


var _head_h := 0.3
var _face_z := 0.2


func _rig() -> void:
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	var head_mi: MeshInstance3D = null
	for mi in meshes:
		if (mi as Node).name == "Head":
			head_mi = mi
	if head_mi == null:
		return
	var hb := _box(head_mi)
	_head_h = hb.size.y
	head = Node3D.new()
	head.name = "HeadPivot"
	model.add_child(head)       # under the model, so the head rides the body's breathing, hops and lean
	head.position = Vector3(hb.get_center().x, hb.position.y + hb.size.y * 0.12, hb.get_center().z - hb.size.z * 0.1)
	_face_z = hb.end.z - head.position.z
	for mi in meshes:
		var n: String = (mi as Node).name
		var ok := false
		for k in HEAD_PARTS:
			if n.begins_with(k):
				ok = true
		if not ok:
			continue
		var g: Transform3D = _local(mi)
		mi.get_parent().remove_child(mi)
		head.add_child(mi)
		mi.transform = head.transform.affine_inverse() * g
		var side := -1.0 if mi.position.x < 0.0 else 1.0
		if n.begins_with("Brow"):
			brows.append([mi, mi.position, side])
		elif n.begins_with("Eye"):
			eyes.append([mi, mi.scale])
		elif n.begins_with("Glint"):
			glints.append(mi)
		elif n.begins_with("MouthL"):
			corners.append([mi, mi.position, side])
		elif n == "Mouth":
			mouth_rest = mi.position
	# a dark open mouth behind the line of the lips, shown while talking
	mouth_open = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 16
	sm.rings = 8
	mouth_open.mesh = sm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.22, 0.05, 0.07)
	mm.roughness = 0.8
	mouth_open.material_override = mm
	mouth_open.position = mouth_rest + Vector3(0, -0.016, 0.004)
	mouth_open.scale = Vector3(0.03, 0.0, 0.012)
	head.add_child(mouth_open)


## The node's transform relative to the model (the model sits at the actor's origin while rigging).
func _local(n: Node3D) -> Transform3D:
	var t := n.transform
	var q := n.get_parent()
	while q and q != model:
		if q is Node3D:
			t = (q as Node3D).transform * t
		q = q.get_parent()
	return t


func _box(mi: MeshInstance3D) -> AABB:
	return _local(mi) * mi.get_aabb()


func _process(delta: float) -> void:
	if head == null:
		return
	_t += delta
	var per: Dictionary = PERSONALITY.get(id, {})
	var sway: float = per.get("sway", 1.0)
	var k := clampf(delta * 6.0, 0.0, 1.0)
	for key in goal:
		p[key] = lerpf(p.get(key, goal[key]), goal[key], k)
	# blinking
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 1.0
		_blink_in = per.get("blink", 4.0) * randf_range(0.6, 1.4)
	_blink = maxf(0.0, _blink - delta * 7.0)
	var shut := 1.0 - clampf(_blink * 2.0, 0.0, 1.0) * (1.0 if _blink > 0.0 else 0.0)
	# the mouth while talking: open and close on an uneven beat, like syllables
	var flap_goal := 0.0
	if talking:
		flap_goal = (0.5 + 0.5 * sin(_t * 17.0 * per.get("talk", 1.0))) * (0.6 + 0.4 * sin(_t * 5.3 + 1.0))
	_flap = lerpf(_flap, flap_goal, clampf(delta * 20.0, 0.0, 1.0))
	# face
	for b in brows:
		var node: Node3D = b[0]
		node.position = b[1] + Vector3(0, p.brow_y + _flap * 0.002, 0)
		node.rotation.z = -b[2] * p.brow * 0.6
	for e in eyes:
		var s: Vector3 = e[1]
		(e[0] as Node3D).scale = Vector3(s.x, s.y * maxf(0.06, p.eye * shut), s.z)
	for gl in glints:
		(gl as Node3D).visible = p.eye * shut > 0.35
	for c in corners:
		var node: Node3D = c[0]
		node.position = c[1] + Vector3(c[2] * absf(p.smile) * 0.002, p.smile * 0.006, 0)
		node.rotation.z = c[2] * p.smile * 0.45
	mouth_open.visible = _flap > 0.05
	mouth_open.scale = Vector3(0.026 + _flap * 0.012, 0.004 + _flap * 0.03, 0.012)
	# head: the mood's tilt and nod, a slow idle sway, a nod on each syllable, and a turn toward who is talking
	var yaw := 0.0
	if look_target != null:
		var to: Vector3 = global_transform.affine_inverse() * (look_target as Vector3)
		yaw = clampf(atan2(to.x, to.z), -0.7, 0.7)
	head.rotation.y = lerp_angle(head.rotation.y, yaw + sin(_t * 0.7 + _phase) * 0.05 * sway, k * 0.6)
	head.rotation.z = p.tilt + sin(_t * 0.9 + _phase) * 0.04 * sway
	head.rotation.x = p.nod + _flap * 0.04 + sin(_t * 1.3 + _phase) * 0.015 * sway
	# body: breathing, the mood's lean, a hop, a tremble
	_hop = maxf(0.0, _hop - delta * 2.2)
	var jump: float = sin((1.0 - _hop) * PI) * 0.07 * p.bounce if _hop > 0.0 else 0.0
	_shake = maxf(0.0, _shake - delta)
	var tremble := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.006 * _shake
	var breath: float = sin(_t * 2.0 + _phase) * 0.012 * p.bounce
	model.position = Vector3(0, jump, 0) + tremble
	model.scale = Vector3(1.0 - breath * 0.4, 1.0 + breath, 1.0 - breath * 0.4)
	model.rotation.x = p.lean + sin(_t * 1.1 + _phase) * 0.01 * sway


## The fur and the coat's lining are painted on the meshes' vertices (assets/source/crew_*.py): the imported materials
## need to be told to show them. glTF keeps vertex colours linear; this renderer shows them as they are, so they are
## brought back to sRGB.
static func paint(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var src: Mesh = mi.mesh
		var painted := false
		for k in src.get_surface_count():
			var cols = src.surface_get_arrays(k)[Mesh.ARRAY_COLOR]
			painted = painted or (cols != null and cols.size() > 0)
		if painted:
			var out := ArrayMesh.new()
			for k in src.get_surface_count():
				var arrays: Array = src.surface_get_arrays(k)
				var mat := mi.get_active_material(k)
				var cols = arrays[Mesh.ARRAY_COLOR]
				if cols != null and cols.size() > 0:
					var c2 := PackedColorArray()
					c2.resize(cols.size())
					for i in cols.size():
						c2[i] = cols[i].linear_to_srgb()
					arrays[Mesh.ARRAY_COLOR] = c2
					if mat is StandardMaterial3D:
						mat = mat.duplicate()
						mat.vertex_color_use_as_albedo = true
						mat.albedo_color = Color.WHITE
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				out.surface_set_material(out.get_surface_count() - 1, mat)
			mi.mesh = out
	for c in n.get_children():
		paint(c)
