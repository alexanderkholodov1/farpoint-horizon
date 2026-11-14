extends RefCounted
## Construye los escenarios 3D: cielo estrellado, Tierra, Luna, órbitas, cohete y plataforma de lanzamiento.

const EARTH_SHADER := preload("res://shaders/earth.gdshader")
const CLOUD_SHADER := preload("res://shaders/clouds.gdshader")
const ATMO_SHADER := preload("res://shaders/atmosphere.gdshader")
const MOON_SHADER := preload("res://shaders/moon.gdshader")
const SKY_SHADER := preload("res://shaders/sky.gdshader")
const GLOW := preload("res://shaders/engine_glow.gdshader")
const EARTH_TEX := preload("res://textures/earth_albedo.jpg")
const Ship := preload("res://scripts/ship_builder.gd")
const FONT := preload("res://fonts/Inter-SemiBold.otf")


static func make_space_sky() -> Sky:
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = SKY_SHADER
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	return sky


static func make_day_sky() -> Sky:
	var sky := Sky.new()
	var p := ProceduralSkyMaterial.new()
	p.sky_top_color = Color(0.18, 0.4, 0.78)
	p.sky_horizon_color = Color(0.62, 0.74, 0.88)
	p.ground_bottom_color = Color(0.2, 0.22, 0.2)
	p.ground_horizon_color = Color(0.55, 0.62, 0.7)
	sky.sky_material = p
	return sky


static func make_environment() -> WorldEnvironment:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = make_space_sky()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.42)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	we.environment = env
	return we


## Posición sobre una esfera (radio 1) con la misma convención de UV que SphereMesh de Godot.
static func latlon_to_vec(lat_deg: float, lon_deg: float) -> Vector3:
	var u := (lon_deg + 180.0) / 360.0
	var lat := deg_to_rad(lat_deg)
	return Vector3(sin(u * TAU) * cos(lat), sin(lat), cos(u * TAU) * cos(lat))


static func make_earth(radius := 1.0, with_marker := true) -> Node3D:
	var root := Node3D.new()
	root.name = "Earth"
	var surface := Node3D.new()
	surface.name = "Surface"
	root.add_child(surface)
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 128
	s.rings = 64
	var em := ShaderMaterial.new()
	em.shader = EARTH_SHADER
	em.set_shader_parameter("albedo_tex", EARTH_TEX)
	Ship.add_mesh(surface, s, Vector3.ZERO, em)
	# nubes
	var cs := SphereMesh.new()
	cs.radius = radius * 1.012
	cs.height = radius * 2.024
	cs.radial_segments = 96
	cs.rings = 48
	var cm := ShaderMaterial.new()
	cm.shader = CLOUD_SHADER
	Ship.add_mesh(surface, cs, Vector3.ZERO, cm).name = "Clouds"
	# atmósfera
	var as_ := SphereMesh.new()
	as_.radius = radius * 1.045
	as_.height = radius * 2.09
	as_.radial_segments = 96
	as_.rings = 48
	var am := ShaderMaterial.new()
	am.shader = ATMO_SHADER
	Ship.add_mesh(root, as_, Vector3.ZERO, am)
	# marcador de Ecuador (Quito: -0.2°, -78.5°)
	if with_marker:
		var mk := Node3D.new()
		mk.name = "Ecuador"
		mk.position = latlon_to_vec(-1.5, -78.5) * radius * 1.004
		surface.add_child(mk)
		var dot := Ship.add_mesh(mk, Ship._sphere(radius * 0.018), Vector3.ZERO, Ship.mat(Color(1, 0.85, 0.2), 0.0, 0.5, Color(1.0, 0.7, 0.1)))
		dot.name = "Dot"
		var ring := TorusMesh.new()
		ring.inner_radius = radius * 0.022
		ring.outer_radius = radius * 0.027
		var rm := Ship.add_mesh(mk, ring, Vector3.ZERO, Ship.mat(Color(1, 0.8, 0.2), 0.0, 0.5, Color(1.0, 0.6, 0.1)))
		rm.name = "Pulse"
		mk.basis = Basis(Quaternion(Vector3.UP, mk.position.normalized()))
		var el := make_label("Ecuador", Color(1, 0.85, 0.35))
		el.name = "Label"
		el.position = Vector3(0, radius * 0.09, 0)
		mk.add_child(el)
	return root


static func make_moon(radius := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Moon"
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 128
	s.rings = 64
	var mm := ShaderMaterial.new()
	mm.shader = MOON_SHADER
	Ship.add_mesh(root, s, Vector3.ZERO, mm).name = "Surface"
	return root


static func make_orbit_ring(radius: float, incl_deg: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(0, 0, incl_deg if incl_deg <= 90.0 else 180.0 - incl_deg)
	var t := TorusMesh.new()
	t.inner_radius = radius - 0.004
	t.outer_radius = radius + 0.004
	t.rings = 128
	t.ring_segments = 6
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	Ship.add_mesh(pivot, t, Vector3.ZERO, m)
	return pivot


static func particle_mat(unshaded := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var gg := Gradient.new()
	gg.set_color(0, Color(1, 1, 1, 1))
	gg.set_color(1, Color(1, 1, 1, 0))
	gg.add_point(0.5, Color(1, 1, 1, 0.55))
	gt.gradient = gg
	m.albedo_texture = gt
	return m


static func make_label(text: String, color: Color, depth_test := false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = 30
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0006
	l.no_depth_test = not depth_test
	return l


static func make_flame(scale: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Flame"
	p.amount = 160
	p.lifetime = 0.9
	p.local_coords = false
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.5) * scale
	q.material = particle_mat()
	p.mesh = q
	p.direction = Vector3(0, -1, 0)
	p.spread = 10.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 7.0 * scale
	p.initial_velocity_max = 10.0 * scale
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.5))
	sc.add_point(Vector2(0.3, 1.2))
	sc.add_point(Vector2(1, 3.0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	g.set_color(1, Color(0.5, 0.5, 0.52, 0.0))
	g.add_point(0.15, Color(1.0, 0.6, 0.15, 1.0))
	g.add_point(0.4, Color(0.75, 0.72, 0.7, 0.6))
	p.color_ramp = g
	p.emitting = false
	return p


static func make_rocket(launcher_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Rocket"
	var L: Dictionary = GameData.LAUNCHERS[launcher_id]
	var h: float = L.height
	if launcher_id == "ride":
		h = 1.3
	var r := 0.16 * h
	var white := Ship.mat(Color(0.93, 0.93, 0.93), 0.1, 0.45)
	var black := Ship.mat(Color(0.08, 0.08, 0.09), 0.3, 0.5)
	var grey := Ship.mat(Color(0.35, 0.35, 0.37), 0.9, 0.4)
	var s1 := 2.6 * h
	var s2 := 0.9 * h
	Ship.cyl(root, r, r, s1, Vector3(0, s1 / 2.0, 0), white)
	Ship.cyl(root, r, r, 0.25 * h, Vector3(0, s1 + 0.125 * h, 0), black)
	Ship.cyl(root, r, r, s2, Vector3(0, s1 + 0.25 * h + s2 / 2.0, 0), white)
	var fz := s1 + 0.25 * h + s2
	Ship.cyl(root, r * 1.15, r * 1.15, 0.5 * h, Vector3(0, fz + 0.25 * h, 0), white)
	Ship.cyl(root, 0.0, r * 1.15, 0.55 * h, Vector3(0, fz + 0.5 * h + 0.275 * h, 0), white)
	# aletas de rejilla y motores
	for i in 4:
		var a := i * PI / 2.0
		Ship.box(root, Vector3(0.02, 0.18 * h, 0.14 * h), Vector3(cos(a) * r * 1.05, s1 - 0.2 * h, sin(a) * r * 1.05), black, Vector3(0, -rad_to_deg(a), 0))
	Ship.cyl(root, r * 0.6, r * 0.95, 0.18 * h, Vector3(0, -0.09 * h, 0), grey)
	var flames := Node3D.new()
	flames.name = "Flames"
	root.add_child(flames)
	var f := make_flame(h)
	f.position = Vector3(0, -0.2 * h, 0)
	flames.add_child(f)
	var gm := ShaderMaterial.new()
	gm.shader = GLOW
	var plume := Ship.cyl(flames, r * 0.7, r * 0.35, 1.2 * h, Vector3(0, -0.8 * h, 0), gm)
	plume.name = "Plume"
	if launcher_id == "heavy":
		for sx in [-1, 1]:
			var bx: float = sx * r * 2.1
			Ship.cyl(root, r, r, s1, Vector3(bx, s1 / 2.0, 0), white)
			Ship.cyl(root, 0.0, r, 0.4 * h, Vector3(bx, s1 + 0.2 * h, 0), white)
			Ship.cyl(root, r * 0.6, r * 0.95, 0.18 * h, Vector3(bx, -0.09 * h, 0), grey)
			var fb := make_flame(h)
			fb.position = Vector3(bx, -0.2 * h, 0)
			flames.add_child(fb)
	root.set_meta("height", fz + 1.05 * h)
	return root


static func make_pad() -> Node3D:
	var root := Node3D.new()
	root.name = "Pad"
	var ground := PlaneMesh.new()
	ground.size = Vector2(600, 600)
	Ship.add_mesh(root, ground, Vector3.ZERO, Ship.mat(Color(0.28, 0.33, 0.24), 0.0, 0.95))
	Ship.box(root, Vector3(3.0, 0.2, 3.0), Vector3(0, 0.1, 0), Ship.mat(Color(0.5, 0.5, 0.5), 0.1, 0.8))
	# torre de servicio
	var steel := Ship.mat(Color(0.55, 0.15, 0.1), 0.6, 0.5)
	Ship.box(root, Vector3(0.35, 5.5, 0.35), Vector3(-0.9, 2.75, 0), steel)
	for i in 5:
		Ship.box(root, Vector3(0.6, 0.06, 0.08), Vector3(-0.6, 1.0 + i, 0), steel)
	# volcanes andinos de fondo (con nieve)
	var rock := Ship.mat(Color(0.35, 0.33, 0.32), 0.0, 0.95)
	var snow := Ship.mat(Color(0.95, 0.96, 1.0), 0.0, 0.7)
	var volcanoes := [[Vector3(-60, 0, -140), 40.0, 30.0], [Vector3(50, 0, -170), 55.0, 26.0], [Vector3(120, 0, -120), 30.0, 22.0], [Vector3(-140, 0, -100), 35.0, 18.0]]
	for v in volcanoes:
		var pos: Vector3 = v[0]
		var rr: float = v[1]
		var hh: float = v[2]
		Ship.cyl(root, rr * 0.06, rr, hh, pos + Vector3(0, hh / 2.0, 0), rock)
		Ship.cyl(root, rr * 0.06, rr * 0.3, hh * 0.25, pos + Vector3(0, hh * 0.875 + 0.05, 0), snow)
	return root
