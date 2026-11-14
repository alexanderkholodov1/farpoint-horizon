extends RefCounted
## Construye en 3D la nave a partir de las decisiones de la misión, usando formas simples.
## Cada pieza elegida se ve: paneles, antena, instrumentos, propulsor, seguidor de estrellas.

const SOLAR := preload("res://shaders/solar_cell.gdshader")
const GLOW := preload("res://shaders/engine_glow.gdshader")


static func mat(color: Color, metallic := 0.0, rough := 0.5, emission := Color.BLACK, cull_off := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 2.0
	if cull_off:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material, rot := Vector3.ZERO, node_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = material
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add_mesh(parent, b, pos, material, rot)


static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = 24
	return add_mesh(parent, c, pos, material, rot)


static func solar_mat(cells: Vector2) -> ShaderMaterial:
	var s := ShaderMaterial.new()
	s.shader = SOLAR
	s.set_shader_parameter("cells", cells)
	return s


static func dish(parent: Node3D, radius: float, pos: Vector3, rot: Vector3, color := Color(0.92, 0.92, 0.9)) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees = rot
	parent.add_child(holder)
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 0.7
	s.is_hemisphere = true
	s.radial_segments = 32
	s.rings = 8
	# la semiesfera apunta hacia arriba: la volteamos para que sea un plato abierto hacia +Y
	add_mesh(holder, s, Vector3(0, radius * 0.35, 0), mat(color, 0.2, 0.35, Color.BLACK, true), Vector3(180, 0, 0))
	cyl(holder, radius * 0.03, radius * 0.03, radius * 0.6, Vector3(0, radius * 0.45, 0), mat(Color(0.3, 0.3, 0.3)))
	add_mesh(holder, _sphere(radius * 0.07), Vector3(0, radius * 0.75, 0), mat(Color(0.2, 0.2, 0.2)))
	return holder


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


## Devuelve un Node3D con la nave. Metadatos: "radius" (tamaño para encuadrar la cámara).
static func build(m) -> Node3D:
	var root := Node3D.new()
	root.name = "Spacecraft"
	var B: Dictionary = GameData.BUSES[m.bus]
	var P: Dictionary = GameData.PANELS[m.panels]
	var C: Dictionary = GameData.COMMS[m.comms]
	var A: Dictionary = GameData.ADCS[m.adcs]
	var PR: Dictionary = GameData.PROPULSION[m.propulsion]
	var d: Vector3 = B.dims
	var cots: bool = B.cots
	var k: float = d.x   # escala de detalles

	# ---------------- cuerpo
	var gold := mat(Color(0.9, 0.66, 0.22), 0.35, 0.38)
	var alu := mat(Color(0.78, 0.79, 0.8), 0.45, 0.35)
	var dark := mat(Color(0.12, 0.12, 0.14), 0.3, 0.6)
	var white := mat(Color(0.9, 0.9, 0.88), 0.1, 0.5)
	if cots:
		var body_m: Material = solar_mat(Vector2(2, 6)) if m.panels == "body" else dark
		box(root, d * 0.96, Vector3.ZERO, body_m)
		# rieles de aluminio en las esquinas (estándar CubeSat)
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				box(root, Vector3(0.05, 0.05, d.z * 1.04), Vector3(sx * d.x / 2.0, sy * d.y / 2.0, 0), alu)
		# separaciones de unidades 1U
		var units := int(round(d.z / 0.33))
		for i in range(1, units):
			box(root, Vector3(d.x * 1.0, d.y * 1.0, 0.015), Vector3(0, 0, -d.z / 2.0 + i * d.z / units), alu)
	else:
		box(root, d, Vector3.ZERO, gold)
		box(root, Vector3(d.x * 1.02, d.y * 0.04, d.z * 1.02), Vector3(0, d.y / 2.0, 0), white)
		box(root, Vector3(d.x * 1.02, d.y * 0.04, d.z * 1.02), Vector3(0, -d.y / 2.0, 0), white)
		if m.panels == "body":
			box(root, Vector3(0.01, d.y * 0.8, d.z * 0.8), Vector3(d.x / 2.0 + 0.006, 0, 0), solar_mat(Vector2(4, 4)))
			box(root, Vector3(0.01, d.y * 0.8, d.z * 0.8), Vector3(-d.x / 2.0 - 0.006, 0, 0), solar_mat(Vector2(4, 4)))

	# ---------------- paneles solares
	var span: float = P.span
	if span > 0.0:
		var h: float = d.z * 0.85
		var segs := int(ceil(span / 1.3))
		var seg_w := span / segs
		for side in [-1, 1]:
			var wing := Node3D.new()
			wing.name = "Wing" + ("L" if side < 0 else "R")
			wing.position = Vector3(side * d.x / 2.0, 0, 0)
			root.add_child(wing)
			cyl(wing, 0.015 * max(k, 0.5), 0.015 * max(k, 0.5), 0.18, Vector3(side * 0.09, 0, 0), alu, Vector3(0, 0, 90))
			for s in segs:
				var cx: float = side * (0.18 + seg_w * s + seg_w / 2.0)
				box(wing, Vector3(seg_w * 0.97, 0.02, h), Vector3(cx, 0, 0), solar_mat(Vector2(max(2.0, seg_w / 0.12), max(2.0, h / 0.12))))

	# ---------------- comunicaciones
	if C.dish > 0.0:
		var dr: float = C.dish * max(0.6, k * 0.55)
		dish(root, dr, Vector3(0, d.y / 2.0, -d.z * 0.2), Vector3(0, 0, 0))
	else:
		var wire := mat(Color(0.85, 0.85, 0.85), 0.9, 0.2)
		for sx in [-1, 1]:
			cyl(root, 0.006, 0.006, 0.5, Vector3(sx * d.x * 0.35, -d.y / 2.0 - 0.22, d.z * 0.45), wire, Vector3(0, 0, sx * 25))
			cyl(root, 0.006, 0.006, 0.5, Vector3(sx * d.x * 0.35, d.y / 2.0 + 0.22, d.z * 0.45), wire, Vector3(0, 0, -sx * 25))

	# ---------------- instrumentos (cara frontal +Z)
	var list: Array = m.instruments
	var n := list.size()
	var cols := int(ceil(sqrt(float(n)))) if n > 0 else 1
	var rows := int(ceil(float(n) / cols)) if n > 0 else 1
	var lens := mat(Color(0.05, 0.08, 0.12), 0.9, 0.05, Color(0.05, 0.15, 0.35))
	var black := mat(Color(0.06, 0.06, 0.07), 0.4, 0.4)
	for i in n:
		var I: Dictionary = GameData.INSTRUMENTS[list[i]]
		var cx: float = (float(i % cols) - (cols - 1) / 2.0) * d.x / cols
		var cy: float = (float(i / cols) - (rows - 1) / 2.0) * d.y / rows
		var s: float = min(d.x / cols, d.y / rows) * 0.7
		var front: float = d.z / 2.0
		match I.shape:
			"box":
				box(root, Vector3(s, s, s * 0.5), Vector3(cx, cy, front + s * 0.25), black)
				cyl(root, s * 0.28, s * 0.28, s * 0.12, Vector3(cx, cy, front + s * 0.55), lens, Vector3(90, 0, 0))
			"cyl":
				cyl(root, s * 0.42, s * 0.42, s * 0.8, Vector3(cx, cy, front + s * 0.4), white, Vector3(90, 0, 0))
				cyl(root, s * 0.3, s * 0.3, s * 0.05, Vector3(cx, cy, front + s * 0.82), lens, Vector3(90, 0, 0))
			"tube":
				cyl(root, s * 0.45, s * 0.45, d.z * 0.9, Vector3(cx, cy, front + d.z * 0.45), mat(Color(0.2, 0.2, 0.25), 0.5, 0.4), Vector3(90, 0, 0))
				cyl(root, s * 0.47, s * 0.47, 0.04, Vector3(cx, cy, front + d.z * 0.9), white, Vector3(90, 0, 0))
			"bigtube":
				# telescopio con espejo segmentado dorado y parasol
				var mirror := mat(Color(1.0, 0.8, 0.35), 0.5, 0.15, Color(0.25, 0.16, 0.02))
				var tel := Node3D.new()
				tel.position = Vector3(0, d.y / 2.0 + 0.1, 0)
				root.add_child(tel)
				var shield_m := mat(Color(0.85, 0.7, 0.85), 0.35, 0.3)
				for layer in 4:
					box(tel, Vector3(d.x * 2.6 - layer * 0.1, 0.01, d.z * 1.7 - layer * 0.08), Vector3(0, layer * 0.06, 0), shield_m)
				var optics := Node3D.new()
				optics.position = Vector3(0, 0.95, -0.1)
				optics.rotation_degrees = Vector3(-20, 0, 0)
				tel.add_child(optics)
				var hexm := CylinderMesh.new()
				hexm.top_radius = 0.26
				hexm.bottom_radius = 0.26
				hexm.height = 0.04
				hexm.radial_segments = 6
				for q in 7:
					var off := Vector2.ZERO if q == 0 else Vector2(cos(q * PI / 3.0 + PI / 6.0), sin(q * PI / 3.0 + PI / 6.0)) * 0.46
					add_mesh(optics, hexm, Vector3(off.x, off.y, 0), mirror, Vector3(90, 0, 0))
				box(optics, Vector3(0.3, 0.9, 0.12), Vector3(0, -0.75, -0.1), mat(Color(0.15, 0.15, 0.17), 0.3, 0.5))
				for sx in [-1, 1]:
					cyl(optics, 0.012, 0.012, 1.2, Vector3(sx * 0.3, 0.0, 0.55), alu, Vector3(90, 0, sx * 14))
				add_mesh(optics, _sphere(0.07), Vector3(0, 0, 1.1), mirror)
			"panel":
				box(root, Vector3(d.x * 1.8, 0.04, d.z * 1.2), Vector3(0, -d.y / 2.0 - 0.06, 0), mat(Color(0.25, 0.27, 0.3), 0.6, 0.4))
			"dish":
				dish(root, s * 0.6, Vector3(cx, -d.y / 2.0, cy), Vector3(180, 0, 0), Color(0.75, 0.78, 0.82))
			"boom":
				cyl(root, 0.01, 0.01, 1.2, Vector3(-d.x / 2.0 - 0.4, d.y / 2.0, -d.z / 2.0), alu, Vector3(0, 0, 60))
				add_mesh(root, _sphere(0.04), Vector3(-d.x / 2.0 - 0.92, d.y / 2.0 + 0.3, -d.z / 2.0), white)

	# ---------------- control de actitud
	if A.level >= 3:
		for sx in [-1, 1]:
			cyl(root, 0.05 * k, 0.04 * k, 0.12 * k, Vector3(sx * d.x * 0.3, d.y / 2.0 + 0.05 * k, d.z * 0.35), black, Vector3(-30, 0, 0))

	# ---------------- propulsión (cara trasera -Z)
	if m.propulsion != "none":
		var nz := Node3D.new()
		nz.name = "Thruster"
		nz.position = Vector3(0, 0, -d.z / 2.0)
		root.add_child(nz)
		var r: float = 0.08 * max(k, 0.5)
		if PR.electric:
			cyl(nz, r * 1.2, r * 1.2, r * 0.5, Vector3(0, 0, -r * 0.25), mat(Color(0.4, 0.4, 0.45), 0.8, 0.3), Vector3(90, 0, 0))
			add_mesh(nz, _sphere(r * 0.9), Vector3(0, 0, -r * 0.5), mat(Color(0.2, 0.5, 1.0), 0.0, 0.5, Color(0.3, 0.6, 1.0)))
		else:
			cyl(nz, r * 0.4, r, r * 2.0, Vector3(0, 0, -r), mat(Color(0.3, 0.3, 0.32), 0.9, 0.4), Vector3(-90, 0, 0))
			if PR.dv > 500.0:
				for sx in [-1, 1]:
					add_mesh(root, _sphere(d.x * 0.18), Vector3(sx * d.x * 0.22, 0, -d.z * 0.25), white)
		var g := ShaderMaterial.new()
		g.shader = GLOW
		g.set_shader_parameter("glow", Color(0.35, 0.6, 1.0) if PR.electric else Color(1.0, 0.6, 0.25))
		var plume := cyl(nz, r * 0.3, r * 0.9, r * 6.0, Vector3(0, 0, -r * 5.0), g, Vector3(-90, 0, 0))
		plume.name = "Plume"
		plume.visible = false

	var radius: float = max(d.length() * 0.6, span + d.x / 2.0 + 0.2)
	root.set_meta("radius", radius)
	return root
