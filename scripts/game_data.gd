extends Node
## Catálogos del juego. Valores simplificados pero con órdenes de magnitud reales.
## Unidades: masa en kg, potencia en W, energía en Wh, dinero en millones de USD (M$),
## datos en GB/día, velocidad de enlace en Mbps, delta-v en m/s.

const SIZE_NAMES := {1: "CubeSat", 2: "Pequeño", 3: "Mediano", 4: "Gigante"}

# ---------------------------------------------------------------- ESCENARIOS
const SCENARIOS := {
	"volcanes": {
		"name": "Vigía de Volcanes del Ecuador",
		"type": "Observación de la Tierra",
		"desc": "Ecuador tiene decenas de volcanes activos, como el Cotopaxi y el Tungurahua. Tu misión: detectar calor y gases (SO2) antes de una erupción para alertar a tiempo a la población. Ojo: las nubes andinas cubren la zona gran parte del año.",
		"budget": 90.0, "min_years": 2, "science_target": 2600.0, "body": "tierra",
		"needs": [
			{"any": ["termico", "gases"], "label": "Detectar calor o gases volcánicos"},
			{"any": ["optico", "radar"], "label": "Tomar imágenes de la superficie"},
		],
		"relevance": {"termico": 1.0, "gases": 1.0, "radar": 1.1, "multiespectral": 0.9, "optico": 0.7},
		"orbit_mult": {"leo": 0.9, "sso": 1.2, "geo": 0.9, "lunar": 0.0, "l2": 0.0},
		"real": "Landsat 9 y Sentinel-2 (imágenes), Sentinel-5P (mide gases como el SO2) y ASTER (térmico).",
		"color": Color(1.0, 0.45, 0.2),
	},
	"clima": {
		"name": "Guardianes del Océano y El Niño",
		"type": "Clima y océanos",
		"desc": "El fenómeno de El Niño calienta el Pacífico y trae lluvias e inundaciones a la Costa ecuatoriana. Mide la altura y la temperatura del océano para anticiparlo meses antes.",
		"budget": 220.0, "min_years": 3, "science_target": 3200.0, "body": "tierra",
		"needs": [
			{"any": ["altimetro", "microondas"], "label": "Medir altura o temperatura del océano"},
			{"any": ["multiespectral", "termico", "radar"], "label": "Observar color, calor o viento del mar"},
		],
		"relevance": {"altimetro": 1.0, "microondas": 1.0, "radar": 0.8, "multiespectral": 0.8, "termico": 0.7, "optico": 0.3, "gases": 0.4},
		"orbit_mult": {"leo": 0.8, "sso": 1.2, "geo": 0.7, "lunar": 0.0, "l2": 0.0},
		"real": "Sentinel-6 Michael Freilich (altura del mar), SMAP (microondas) y la serie Jason.",
		"color": Color(0.2, 0.6, 1.0),
	},
	"luna": {
		"name": "Cartógrafo Lunar",
		"type": "Exploración de la Luna",
		"desc": "Haz un mapa de la Luna y descubre de qué está hecha su superficie para elegir dónde aterrizarán futuras misiones tripuladas. Llegar allá exige propulsión y comunicaciones de espacio profundo.",
		"budget": 320.0, "min_years": 1, "science_target": 2200.0, "body": "luna",
		"needs": [
			{"any": ["optico", "multiespectral"], "label": "Cartografiar la superficie"},
			{"any": ["composicion", "termico", "altimetro"], "label": "Analizar composición o relieve"},
		],
		"relevance": {"optico": 1.0, "multiespectral": 1.0, "composicion": 1.1, "termico": 0.7, "altimetro": 0.9, "radar": 0.7, "campos": 0.4, "particulas": 0.4},
		"orbit_mult": {"leo": 0.0, "sso": 0.0, "geo": 0.0, "lunar": 1.0, "l2": 0.0},
		"real": "Lunar Reconnaissance Orbiter (NASA, 2009) y Chandrayaan-2 (India, 2019).",
		"color": Color(0.8, 0.8, 0.85),
	},
	"telescopio": {
		"name": "Ojo al Universo",
		"type": "Astronomía",
		"desc": "Construye un telescopio espacial para estudiar galaxias lejanas y planetas de otras estrellas. Para observar en infrarrojo necesita estar lejos del calor de la Tierra.",
		"budget": 1000.0, "min_years": 3, "science_target": 7000.0, "body": "tierra",
		"needs": [
			{"any": ["telescopio"], "label": "Llevar un telescopio"},
		],
		"relevance": {"telescopio": 1.0, "particulas": 0.2, "campos": 0.2},
		"orbit_mult": {"leo": 0.6, "sso": 0.65, "geo": 0.8, "lunar": 0.4, "l2": 1.5},
		"real": "Hubble (órbita baja, 1990) y James Webb (punto L2, 2021).",
		"color": Color(0.7, 0.45, 1.0),
	},
	"libre": {
		"name": "Modo libre (sandbox)",
		"type": "Experimenta sin límites",
		"desc": "Presupuesto enorme y cualquier órbita. Prueba combinaciones locas y mira qué pasa. No hay objetivos obligatorios.",
		"budget": 5000.0, "min_years": 1, "science_target": 4000.0, "body": "tierra",
		"needs": [],
		"relevance": {},
		"default_relevance": 0.7,
		"orbit_mult": {"leo": 1.0, "sso": 1.0, "geo": 1.0, "lunar": 1.0, "l2": 1.0},
		"real": "Cada misión real es un compromiso distinto: no existe un diseño perfecto.",
		"color": Color(0.3, 1.0, 0.6),
	},
}

# ---------------------------------------------------------------- PLATAFORMAS (bus)
const BUSES := {
	"cube3": {"name": "CubeSat 3U", "desc": "Del tamaño de una caja de zapatos (10×10×34 cm). Muy barato, pero con poco espacio y energía.",
		"dry": 2.0, "max": 5.0, "cost": 0.4, "base_power": 2.0, "slots": 1, "max_size": 1, "ep_power": 15.0, "ops_mult": 0.3, "cots": true,
		"dims": Vector3(0.35, 0.35, 1.0)},
	"cube6": {"name": "CubeSat 6U", "desc": "Dos CubeSats 3U lado a lado. Cabe un par de instrumentos pequeños.",
		"dry": 4.0, "max": 12.0, "cost": 0.9, "base_power": 3.0, "slots": 2, "max_size": 1, "ep_power": 20.0, "ops_mult": 0.35, "cots": true,
		"dims": Vector3(0.7, 0.35, 1.0)},
	"cube12": {"name": "CubeSat 12U", "desc": "El CubeSat más grande común. Hasta 3 instrumentos pequeños.",
		"dry": 8.0, "max": 24.0, "cost": 1.8, "base_power": 5.0, "slots": 3, "max_size": 1, "ep_power": 30.0, "ops_mult": 0.4, "cots": true,
		"dims": Vector3(0.7, 0.7, 1.0)},
	"small": {"name": "SmallSat (~200 kg)", "desc": "Del tamaño de una refrigeradora pequeña. Acepta instrumentos medianos.",
		"dry": 60.0, "max": 200.0, "cost": 15.0, "base_power": 40.0, "slots": 4, "max_size": 2, "ep_power": 300.0, "ops_mult": 1.0, "cots": false,
		"dims": Vector3(1.0, 1.0, 1.2)},
	"medium": {"name": "Plataforma mediana (~1,5 t)", "desc": "Como un auto pequeño. Lleva instrumentos grandes y mucha energía.",
		"dry": 400.0, "max": 1500.0, "cost": 70.0, "base_power": 150.0, "slots": 6, "max_size": 3, "ep_power": 1500.0, "ops_mult": 2.0, "cots": false,
		"dims": Vector3(1.4, 1.4, 1.8)},
	"large": {"name": "Gran observatorio (~7 t)", "desc": "Del tamaño de un bus escolar. Para los instrumentos más ambiciosos.",
		"dry": 2000.0, "max": 7000.0, "cost": 250.0, "base_power": 500.0, "slots": 8, "max_size": 4, "ep_power": 4000.0, "ops_mult": 4.0, "cots": false,
		"dims": Vector3(1.8, 1.8, 2.6)},
}

# ---------------------------------------------------------------- INSTRUMENTOS
# size: 1 CubeSat, 2 pequeño, 3 mediano, 4 gigante | pointing: precisión de apuntado requerida (0-3)
const INSTRUMENTS := {
	"cam_basic": {"name": "Cámara óptica compacta", "tags": ["optico"], "size": 1, "mass": 0.4, "power": 3.0, "cost": 0.2, "data": 2.0, "sci": 10.0, "pointing": 1,
		"desc": "Fotos en color visible, como un celular muy bueno apuntando a la Tierra.", "shape": "box"},
	"cam_ms": {"name": "Cámara multiespectral", "tags": ["optico", "multiespectral"], "size": 2, "mass": 20.0, "power": 35.0, "cost": 6.0, "data": 40.0, "sci": 30.0, "pointing": 2,
		"desc": "Ve en varios colores, incluso invisibles: distingue vegetación, ceniza, agua y roca.", "shape": "cyl"},
	"cam_hr": {"name": "Cámara de alta resolución", "tags": ["optico"], "size": 3, "mass": 150.0, "power": 180.0, "cost": 45.0, "data": 250.0, "sci": 60.0, "pointing": 3,
		"desc": "Distingue objetos de menos de 1 metro. Genera muchísimos datos y necesita apuntar con gran precisión.", "shape": "cyl"},
	"ir_mini": {"name": "Cámara térmica miniatura", "tags": ["termico"], "size": 1, "mass": 1.0, "power": 6.0, "cost": 0.6, "data": 4.0, "sci": 16.0, "pointing": 1,
		"desc": "Mide el calor de la superficie. Detecta zonas que se calientan antes de una erupción.", "shape": "box"},
	"ir_adv": {"name": "Radiómetro térmico avanzado", "tags": ["termico"], "size": 2, "mass": 35.0, "power": 60.0, "cost": 14.0, "data": 30.0, "sci": 42.0, "pointing": 2,
		"desc": "Mide temperaturas con precisión de décimas de grado.", "shape": "box"},
	"sar": {"name": "Radar de apertura sintética (SAR)", "tags": ["radar"], "size": 3, "mass": 350.0, "power": 1500.0, "cost": 70.0, "data": 400.0, "sci": 70.0, "pointing": 2,
		"desc": "Envía microondas y escucha el eco: ve a través de nubes y de noche, y mide si el suelo se hincha. Consume muchísima energía.", "shape": "panel"},
	"gas_mini": {"name": "Espectrómetro de gases miniatura", "tags": ["gases"], "size": 1, "mass": 1.2, "power": 5.0, "cost": 0.8, "data": 1.0, "sci": 14.0, "pointing": 1,
		"desc": "Separa la luz en colores para identificar gases como el dióxido de azufre (SO2).", "shape": "box"},
	"gas_adv": {"name": "Espectrómetro UV de gases", "tags": ["gases"], "size": 2, "mass": 30.0, "power": 45.0, "cost": 12.0, "data": 15.0, "sci": 40.0, "pointing": 2,
		"desc": "Mapea columnas de gas volcánico y contaminación en todo el planeta.", "shape": "cyl"},
	"mw": {"name": "Radiómetro de microondas", "tags": ["microondas"], "size": 3, "mass": 90.0, "power": 120.0, "cost": 30.0, "data": 10.0, "sci": 45.0, "pointing": 1,
		"desc": "Mide la temperatura del mar y la humedad del suelo incluso con nubes.", "shape": "dish"},
	"alt": {"name": "Altímetro radar", "tags": ["altimetro"], "size": 2, "mass": 60.0, "power": 90.0, "cost": 18.0, "data": 5.0, "sci": 38.0, "pointing": 1,
		"desc": "Mide la altura del mar con precisión de centímetros: así se ve llegar El Niño.", "shape": "dish"},
	"gamma": {"name": "Espectrómetro de rayos gamma", "tags": ["composicion"], "size": 2, "mass": 25.0, "power": 25.0, "cost": 10.0, "data": 2.0, "sci": 35.0, "pointing": 1,
		"desc": "Detecta qué elementos (hierro, titanio, hidrógeno…) hay en el suelo de la Luna.", "shape": "cyl"},
	"tel_small": {"name": "Telescopio de 30 cm", "tags": ["telescopio"], "size": 2, "mass": 40.0, "power": 60.0, "cost": 25.0, "data": 15.0, "sci": 40.0, "pointing": 3,
		"desc": "Un telescopio pequeño pero sin atmósfera que lo moleste.", "shape": "tube"},
	"tel_med": {"name": "Telescopio de 1 m", "tags": ["telescopio"], "size": 3, "mass": 400.0, "power": 250.0, "cost": 120.0, "data": 40.0, "sci": 85.0, "pointing": 3,
		"desc": "Espejo de un metro: observa galaxias y estrellas débiles.", "shape": "tube"},
	"tel_ir": {"name": "Gran telescopio infrarrojo (4 m)", "tags": ["telescopio"], "size": 4, "mass": 2200.0, "power": 700.0, "cost": 400.0, "data": 50.0, "sci": 160.0, "pointing": 3,
		"desc": "Ve el calor de las primeras galaxias. Necesita estar muy frío y lejos de la Tierra.", "shape": "bigtube"},
	"mag": {"name": "Magnetómetro", "tags": ["campos"], "size": 1, "mass": 0.3, "power": 1.0, "cost": 0.15, "data": 0.1, "sci": 6.0, "pointing": 0,
		"desc": "Mide campos magnéticos. Barato y liviano, ciencia de apoyo.", "shape": "boom"},
	"part": {"name": "Detector de partículas", "tags": ["particulas"], "size": 1, "mass": 0.8, "power": 2.0, "cost": 0.3, "data": 0.5, "sci": 8.0, "pointing": 0,
		"desc": "Cuenta partículas de radiación del Sol y del espacio.", "shape": "box"},
}

# ---------------------------------------------------------------- ENERGÍA
const PANELS := {
	"body": {"name": "Paneles fijos al cuerpo", "power": 7.0, "mass": 0.2, "cost": 0.05, "desc": "Celdas pegadas a las caras de la nave. Simples, sin piezas móviles, poca energía.", "span": 0.0},
	"dep_s": {"name": "Paneles desplegables pequeños", "power": 40.0, "mass": 1.2, "cost": 0.4, "desc": "Se abren como alas al llegar al espacio.", "span": 0.8},
	"dep_m": {"name": "Paneles desplegables medianos", "power": 450.0, "mass": 18.0, "cost": 4.0, "desc": "Lo típico en un SmallSat.", "span": 1.6},
	"wing_l": {"name": "Alas solares grandes", "power": 2500.0, "mass": 110.0, "cost": 18.0, "desc": "Varios metros de envergadura.", "span": 2.6},
	"wing_xl": {"name": "Alas solares gigantes", "power": 9000.0, "mass": 380.0, "cost": 50.0, "desc": "Como las de la Estación Espacial, en pequeño.", "span": 3.8},
}

const BATTERIES := {
	"b20": {"name": "Batería 20 Wh", "wh": 20.0, "mass": 0.15, "cost": 0.03, "desc": "Como una batería de power bank."},
	"b120": {"name": "Batería 120 Wh", "wh": 120.0, "mass": 0.9, "cost": 0.15, "desc": "Como la batería de una laptop grande."},
	"b1k": {"name": "Batería 1 kWh", "wh": 1000.0, "mass": 7.0, "cost": 1.2, "desc": "Paquete de ion-litio para un SmallSat."},
	"b6k": {"name": "Batería 6 kWh", "wh": 6000.0, "mass": 40.0, "cost": 5.0, "desc": "Para naves medianas."},
	"b25k": {"name": "Batería 25 kWh", "wh": 25000.0, "mass": 160.0, "cost": 15.0, "desc": "Para naves que consumen kilovatios."},
}

# ---------------------------------------------------------------- COMUNICACIONES
const COMMS := {
	"uhf": {"name": "Radio UHF", "rate": 0.0096, "mass": 0.1, "power": 2.0, "cost": 0.05, "dish": 0.0, "desc": "9,6 kbps: como un módem de los años 90. Antena de varilla."},
	"sband": {"name": "Banda S", "rate": 2.0, "mass": 0.6, "power": 6.0, "cost": 0.4, "dish": 0.15, "desc": "2 Mbps. Fiable y común en misiones pequeñas."},
	"xband": {"name": "Banda X", "rate": 150.0, "mass": 6.0, "power": 35.0, "cost": 3.0, "dish": 0.45, "desc": "150 Mbps con antena parabólica. Estándar de la NASA en espacio profundo."},
	"ka": {"name": "Banda Ka alta ganancia", "rate": 1200.0, "mass": 25.0, "power": 90.0, "cost": 10.0, "dish": 0.9, "desc": "1,2 Gbps. Para instrumentos que generan montañas de datos."},
}

# ---------------------------------------------------------------- CONTROL DE ACTITUD
const ADCS := {
	"mag": {"name": "Magnetorquers + sensores solares", "level": 1, "mass_pct": 0.03, "power_pct": 0.2, "cost_pct": 0.05, "desc": "Usa el campo magnético de la Tierra para girar. Apuntado grueso (~5°)."},
	"rw": {"name": "Ruedas de reacción", "level": 2, "mass_pct": 0.08, "power_pct": 0.5, "cost_pct": 0.15, "desc": "Volantes que giran para orientar la nave. Apuntado fino (~0,1°)."},
	"st": {"name": "Ruedas + seguidor de estrellas", "level": 3, "mass_pct": 0.12, "power_pct": 0.7, "cost_pct": 0.3, "desc": "Una cámara reconoce constelaciones: apuntado de precisión (~0,001°)."},
}

# ---------------------------------------------------------------- PROPULSIÓN
const PROPULSION := {
	"none": {"name": "Sin propulsión", "dv": 0.0, "mass_pct": 0.0, "cost_pct": 0.0, "electric": false, "desc": "Más liviano y barato, pero la nave no puede cambiar de órbita ni esquivar basura."},
	"cold": {"name": "Gas frío", "dv": 40.0, "mass_pct": 0.08, "cost_pct": 0.05, "electric": false, "desc": "Suelta gas a presión. Sirve para pequeños ajustes y esquivar basura."},
	"chem": {"name": "Química (hidracina)", "dv": 1500.0, "mass_pct": 0.6, "cost_pct": 0.15, "electric": false, "desc": "Mucho empuje: ideal para entrar en órbita lunar o subir a GEO. El combustible pesa mucho."},
	"ion": {"name": "Eléctrica (iónica)", "dv": 4000.0, "mass_pct": 0.15, "cost_pct": 0.25, "electric": true, "desc": "Acelera iones con electricidad: muy eficiente, poco combustible, pero consume mucha energía."},
}

# ---------------------------------------------------------------- ÓRBITAS
const ORBITS := {
	"leo": {"name": "Órbita baja (400 km)", "short": "LEO", "period_min": 92.0, "eclipse_min": 36.0, "eclipse_frac": 0.38, "contact_min": 40.0, "comm_factor": 1.0,
		"insert_dv": 0.0, "maint_dv": 25.0, "drag_life": 2.0, "radiation": 1, "body": "tierra", "radius": 1.18, "incl": 51.6, "ops": 0.5,
		"desc": "Como la Estación Espacial. Cerca = imágenes nítidas y lanzamiento barato, pero el aire residual frena la nave: sin propulsión cae en unos 2 años."},
	"sso": {"name": "Heliosíncrona (700 km)", "short": "SSO", "period_min": 99.0, "eclipse_min": 33.0, "eclipse_frac": 0.34, "contact_min": 60.0, "comm_factor": 1.0,
		"insert_dv": 0.0, "maint_dv": 3.0, "drag_life": 25.0, "radiation": 1, "body": "tierra", "radius": 1.3, "incl": 98.0, "ops": 0.5,
		"desc": "Pasa por cada lugar a la misma hora solar: luz constante para comparar imágenes día tras día. La favorita para observar la Tierra."},
	"geo": {"name": "Geoestacionaria (35 786 km)", "short": "GEO", "period_min": 1436.0, "eclipse_min": 72.0, "eclipse_frac": 0.01, "contact_min": 1440.0, "comm_factor": 0.25,
		"insert_dv": 1500.0, "maint_dv": 50.0, "drag_life": 999.0, "radiation": 3, "body": "tierra", "radius": 3.2, "incl": 0.0, "ops": 1.0,
		"desc": "Gira al ritmo de la Tierra: vigila siempre el mismo hemisferio (¡incluido Ecuador!) con contacto continuo. Pero está 90 veces más lejos que la ISS y el cohete te deja en una órbita de transferencia: necesitas propulsión."},
	"lunar": {"name": "Órbita lunar (100 km)", "short": "LUNA", "period_min": 118.0, "eclipse_min": 47.0, "eclipse_frac": 0.4, "contact_min": 480.0, "comm_factor": 0.04,
		"insert_dv": 900.0, "maint_dv": 40.0, "drag_life": 999.0, "radiation": 3, "body": "luna", "radius": 1.25, "incl": 90.0, "ops": 4.0,
		"desc": "A 384 000 km. Necesitas frenar ~900 m/s para quedarte en órbita y la gravedad irregular de la Luna exige correcciones. Hablas con la Tierra por la Red de Espacio Profundo."},
	"l2": {"name": "Punto L2 Sol-Tierra", "short": "L2", "period_min": 259200.0, "eclipse_min": 0.0, "eclipse_frac": 0.0, "contact_min": 240.0, "comm_factor": 0.03,
		"insert_dv": 60.0, "maint_dv": 3.0, "drag_life": 999.0, "radiation": 2, "body": "tierra", "radius": 5.5, "incl": 0.0, "ops": 5.0,
		"desc": "A 1,5 millones de km: la Tierra y el Sol quedan siempre del mismo lado. Frío, estable y sin eclipses: ideal para telescopios infrarrojos."},
}

# ---------------------------------------------------------------- LANZADORES
const LAUNCHERS := {
	"ride": {"name": "Viaje compartido (rideshare)", "cap": {"leo": 500.0, "sso": 400.0, "geo": 0.0, "lunar": 0.0, "l2": 0.0}, "cost_per_kg": 0.0065, "cost": 0.0, "min_cost": 0.1,
		"fail": 0.03, "delay": 0.3, "desc": "Tu nave viaja junto a decenas de otras. Muy barato (~6 500 $/kg), pero vas a la órbita y en la fecha del cliente principal.", "height": 1.0},
	"light": {"name": "Lanzador ligero (tipo Electron)", "cap": {"leo": 300.0, "sso": 200.0, "geo": 0.0, "lunar": 30.0, "l2": 0.0}, "cost_per_kg": 0.0, "cost": 8.0, "min_cost": 0.0,
		"fail": 0.05, "delay": 0.1, "desc": "Cohete pequeño dedicado: tú eliges órbita y fecha.", "height": 0.8},
	"medium": {"name": "Lanzador medio (tipo Falcon 9)", "cap": {"leo": 17000.0, "sso": 12000.0, "geo": 5500.0, "lunar": 4000.0, "l2": 4000.0}, "cost_per_kg": 0.0, "cost": 70.0, "min_cost": 0.0,
		"fail": 0.02, "delay": 0.08, "desc": "El caballo de batalla actual. Muy confiable.", "height": 1.3},
	"heavy": {"name": "Lanzador pesado (tipo Falcon Heavy)", "cap": {"leo": 60000.0, "sso": 40000.0, "geo": 18000.0, "lunar": 15000.0, "l2": 12000.0}, "cost_per_kg": 0.0, "cost": 110.0, "min_cost": 0.0,
		"fail": 0.03, "delay": 0.12, "desc": "Para cargas gigantes o destinos lejanos.", "height": 1.5},
}

# ---------------------------------------------------------------- ROLES DE EQUIPO
const ROLES := {
	"director": {"name": "Director/a de Misión", "color": Color(1.0, 0.75, 0.25),
		"goal": "Dejar al menos 10 % del presupuesto como reserva",
		"why": "Las misiones reales casi siempre cuestan más de lo previsto; la reserva evita que la cancelen."},
	"cientifico": {"name": "Científico/a Principal", "color": Color(0.45, 0.85, 1.0),
		"goal": "Cubrir todos los objetivos científicos y lograr ≥ 80 % de la ciencia meta",
		"why": "Sin ciencia útil, la misión no justifica su costo."},
	"ingeniero": {"name": "Ingeniero/a de Sistemas", "color": Color(0.5, 1.0, 0.55),
		"goal": "Margen de masa ≥ 10 % y margen de energía ≥ 15 %",
		"why": "Los diseños crecen al construirse; los márgenes absorben las sorpresas."},
	"operaciones": {"name": "Operaciones y Comunicaciones", "color": Color(1.0, 0.5, 0.8),
		"goal": "Bajar el 100 % de los datos y que la nave dure toda la vida de diseño",
		"why": "Un dato que no llega a la Tierra es un dato perdido."},
}
const ROLE_ORDER := ["director", "cientifico", "ingeniero", "operaciones"]

# Pasos del diseño: id, título, rol responsable, nivel CML (Concept Maturity Level, JPL)
const STEPS := [
	{"id": "orbita", "title": "Órbita", "role": "operaciones", "cml": 2},
	{"id": "plataforma", "title": "Plataforma", "role": "ingeniero", "cml": 2},
	{"id": "instrumentos", "title": "Instrumentos", "role": "cientifico", "cml": 3},
	{"id": "energia", "title": "Energía", "role": "ingeniero", "cml": 3},
	{"id": "comunicaciones", "title": "Comunicaciones", "role": "operaciones", "cml": 3},
	{"id": "control", "title": "Control y propulsión", "role": "ingeniero", "cml": 3},
	{"id": "lanzador", "title": "Lanzador y vida útil", "role": "director", "cml": 4},
	{"id": "revision", "title": "Revisión", "role": "director", "cml": 4},
]

const DIFFICULTY := {
	"facil": {"name": "Fácil", "budget": 1.4, "events": 0.4, "launch_fail": 0.0, "desc": "Más presupuesto y pocos imprevistos."},
	"normal": {"name": "Normal", "budget": 1.0, "events": 1.0, "launch_fail": 1.0, "desc": "Como una misión real… simplificada."},
	"dificil": {"name": "Difícil", "budget": 0.8, "events": 1.7, "launch_fail": 1.5, "desc": "Presupuesto ajustado y el espacio es hostil."},
}

const CML_NAMES := {
	1: "CML 1 · Idea",
	2: "CML 2 · Arquitectura",
	3: "CML 3 · Diseño del concepto",
	4: "CML 4 · Diseño puntual",
	5: "Operación",
}
