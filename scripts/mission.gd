extends RefCounted
## Modelo de la misión: guarda las decisiones del equipo, calcula los presupuestos
## (masa, energía, datos, delta-v, costo), revisa compatibilidades y simula la operación.

var scenario := "volcanes"
var difficulty := "normal"
var orbit := "sso"
var bus := "cube12"
var instruments: Array = []
var panels := "dep_s"
var battery := "b120"
var comms := "sband"
var adcs := "mag"
var propulsion := "none"
var launcher := "ride"
var years := 2
var redundancy := false
var shielding := false

const DOD := 0.6            # profundidad de descarga segura de la batería
const KEYS := ["scenario", "difficulty", "orbit", "bus", "instruments", "panels", "battery", "comms",
	"adcs", "propulsion", "launcher", "years", "redundancy", "shielding"]


func to_dict() -> Dictionary:
	var d := {}
	for k in KEYS:
		var v = get(k)
		d[k] = v.duplicate() if v is Array else v
	return d


func from_dict(d: Dictionary) -> void:
	for k in KEYS:
		if d.has(k):
			var v = d[k]
			set(k, v.duplicate() if v is Array else v)


func toggle_instrument(id: String) -> void:
	if instruments.has(id):
		instruments.erase(id)
	else:
		instruments.append(id)


# ======================================================================= CÁLCULOS
func compute() -> Dictionary:
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var B: Dictionary = GameData.BUSES[bus]
	var O: Dictionary = GameData.ORBITS[orbit]
	var P: Dictionary = GameData.PANELS[panels]
	var BT: Dictionary = GameData.BATTERIES[battery]
	var C: Dictionary = GameData.COMMS[comms]
	var A: Dictionary = GameData.ADCS[adcs]
	var PR: Dictionary = GameData.PROPULSION[propulsion]
	var L: Dictionary = GameData.LAUNCHERS[launcher]
	var D: Dictionary = GameData.DIFFICULTY[difficulty]
	var r := {}

	# ---------- masa
	var instr_mass := 0.0
	var instr_power := 0.0
	var instr_cost := 0.0
	var instr_data := 0.0
	var max_point := 0
	for id in instruments:
		var I: Dictionary = GameData.INSTRUMENTS[id]
		instr_mass += I.mass
		instr_power += I.power
		instr_cost += I.cost
		instr_data += I.data
		max_point = max(max_point, I.pointing)
	var adcs_mass: float = max(0.05, B.dry * A.mass_pct)
	var dry_sub: float = B.dry + instr_mass + P.mass + BT.mass + C.mass + adcs_mass
	var extra_mass := 0.0
	if redundancy:
		extra_mass += dry_sub * 0.10
	if shielding:
		extra_mass += dry_sub * 0.04
	var dry_total := dry_sub + extra_mass
	var prop_mass: float = dry_total * PR.mass_pct
	var mass_total := dry_total + prop_mass
	var launch_cap: float = L.cap[orbit]
	var mass_limit: float = min(B.max, launch_cap) if launch_cap > 0.0 else B.max
	r.mass = {"bus": B.dry, "instruments": instr_mass, "power": P.mass + BT.mass, "comms": C.mass,
		"adcs": adcs_mass, "extras": extra_mass, "propellant": prop_mass, "total": mass_total}
	r.mass_total = mass_total
	r.mass_bus_max = B.max
	r.launch_cap = launch_cap
	r.mass_limit = mass_limit
	r.mass_margin = (mass_limit - mass_total) / mass_limit if mass_limit > 0.0 else -1.0

	# ---------- energía
	var adcs_power: float = B.base_power * A.power_pct
	var ep_power: float = B.ep_power * 0.5 if PR.electric else 0.0
	var load: float = B.base_power + instr_power + C.power + adcs_power + ep_power
	var gen: float = P.power * (1.0 - O.eclipse_frac)
	r.power_load = load
	r.power_gen = gen
	r.power_margin = (gen - load) / load if load > 0.0 else 1.0
	r.power_parts = {"bus": B.base_power, "instruments": instr_power, "comms": C.power, "adcs": adcs_power, "propulsion": ep_power}
	var batt_need: float = load * O.eclipse_min / 60.0 / DOD
	r.battery_need = batt_need
	r.battery_wh = BT.wh
	r.battery_ratio = BT.wh / batt_need if batt_need > 0.0 else 99.0

	# ---------- datos
	var downlink: float = C.rate * O.comm_factor * O.contact_min * 60.0 / 8.0 / 1000.0
	r.data_gen = instr_data
	r.data_down = downlink
	r.data_ratio = downlink / instr_data if instr_data > 0.0 else 99.0

	# ---------- delta-v y vida útil
	var dv_have: float = PR.dv
	var dv_left: float = dv_have - O.insert_dv
	r.dv_have = dv_have
	r.dv_insert = O.insert_dv
	r.dv_need = O.insert_dv + O.maint_dv * years
	r.insertion_ok = dv_left >= 0.0
	var life := 0.0
	if not r.insertion_ok:
		life = 0.0
	elif O.drag_life < 900.0:
		life = O.drag_life + dv_left / O.maint_dv
	else:
		var grace := {"geo": 3.0, "lunar": 0.5, "l2": 1.0}
		life = dv_left / O.maint_dv + grace.get(orbit, 1.0)
	r.life_years = life

	# ---------- apuntado
	var bad_point: Array = []
	for id in instruments:
		if GameData.INSTRUMENTS[id].pointing > A.level:
			bad_point.append(GameData.INSTRUMENTS[id].name)
	r.pointing_bad = bad_point
	r.pointing_need = max_point

	# ---------- costo
	var hw: float = B.cost + instr_cost + P.cost + BT.cost + C.cost + B.cost * A.cost_pct + B.cost * PR.cost_pct
	if propulsion != "none":
		hw += 0.05
	var extras_cost := 0.0
	if redundancy:
		extras_cost += hw * 0.20
	if shielding:
		extras_cost += hw * 0.05
	var launch_cost: float = max(L.min_cost, L.cost + L.cost_per_kg * mass_total)
	var ops_cost: float = O.ops * B.ops_mult * years
	var total_cost := hw + extras_cost + launch_cost + ops_cost
	var budget: float = S.budget * D.budget
	r.cost = {"hardware": hw, "extras": extras_cost, "launch": launch_cost, "ops": ops_cost, "total": total_cost}
	r.cost_total = total_cost
	r.budget = budget
	r.reserve = (budget - total_cost) / budget

	# ---------- objetivos
	var tags := {}
	for id in instruments:
		for t in GameData.INSTRUMENTS[id].tags:
			tags[t] = true
	var needs_status: Array = []
	var met := 0
	for n in S.needs:
		var ok := false
		for t in n.any:
			if tags.has(t):
				ok = true
		needs_status.append({"label": n.label, "ok": ok})
		if ok:
			met += 1
	r.needs = needs_status
	r.needs_frac = float(met) / S.needs.size() if S.needs.size() > 0 else 1.0
	r.orbit_mult = S.orbit_mult.get(orbit, 0.0)

	# ---------- ciencia esperada
	r.monthly_science = science_rate(instruments, A.level, 1.0)
	r.science_target = S.science_target
	var op_years: float = min(float(years), life)
	r.expected_science = r.monthly_science * op_years * 12.0

	# ---------- revisiones
	r.checks = _checks(r, S, B, O, L, PR)
	r.fatal = false
	for c in r.checks:
		if c.level == "fatal":
			r.fatal = true
	r.goals = role_goals(r)
	return r


## Ciencia por mes con los instrumentos indicados, nivel de apuntado y multiplicador de energía.
func science_rate(instr_list: Array, point_level: int, power_mult: float) -> float:
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var O: Dictionary = GameData.ORBITS[orbit]
	var C: Dictionary = GameData.COMMS[comms]
	var P: Dictionary = GameData.PANELS[panels]
	var BT: Dictionary = GameData.BATTERIES[battery]
	var B: Dictionary = GameData.BUSES[bus]
	var A: Dictionary = GameData.ADCS[adcs]
	var PR: Dictionary = GameData.PROPULSION[propulsion]
	var default_rel: float = S.get("default_relevance", 0.1)
	var total := 0.0
	var data := 0.0
	var ipower := 0.0
	for id in instr_list:
		var I: Dictionary = GameData.INSTRUMENTS[id]
		var rel := 0.0
		for t in I.tags:
			rel = max(rel, S.relevance.get(t, default_rel))
		if S.relevance.is_empty():
			rel = default_rel
		var pf := 1.0 if point_level >= I.pointing else 0.35
		total += I.sci * rel * pf
		data += I.data
		ipower += I.power
	# limitación por enlace de datos
	var downlink: float = C.rate * O.comm_factor * O.contact_min * 60.0 / 8.0 / 1000.0
	var data_f: float = 1.0 if data <= 0.0 else min(1.0, downlink / data)
	# limitación por energía
	var ep_power: float = B.ep_power * 0.5 if PR.electric else 0.0
	var load: float = B.base_power + ipower + C.power + B.base_power * A.power_pct + ep_power
	var gen: float = P.power * (1.0 - O.eclipse_frac) * power_mult
	var power_f: float = 1.0 if gen >= load else clamp(gen / load, 0.1, 1.0)
	# batería: si no alcanza, los instrumentos se apagan en los eclipses
	var need: float = load * O.eclipse_min / 60.0 / DOD
	var batt_f: float = 1.0 if (need <= 0.0 or BT.wh >= need) else 1.0 - O.eclipse_frac * 0.9
	return total * S.orbit_mult.get(orbit, 0.0) * data_f * power_f * batt_f


func _checks(r: Dictionary, S: Dictionary, B: Dictionary, O: Dictionary, L: Dictionary, PR: Dictionary) -> Array:
	var c: Array = []
	# --- bloqueantes
	if instruments.is_empty():
		c.append(_ck("fatal", "Sin instrumentos", "Una nave sin instrumentos no produce ciencia. Ve al paso Instrumentos."))
	if instruments.size() > B.slots:
		c.append(_ck("fatal", "No caben tantos instrumentos", "%s tiene espacio para %d instrumento(s) y elegiste %d. Usa una plataforma más grande o quita instrumentos." % [B.name, B.slots, instruments.size()]))
	for id in instruments:
		var I: Dictionary = GameData.INSTRUMENTS[id]
		if I.size > B.max_size:
			c.append(_ck("fatal", "%s es demasiado grande" % I.name, "Necesita una plataforma de tamaño «%s» o mayor." % GameData.SIZE_NAMES[I.size]))
	if r.mass_total > B.max:
		c.append(_ck("fatal", "La nave pesa más de lo que soporta la plataforma", "%.1f kg de %.1f kg permitidos. La estructura no aguanta: elige piezas más livianas o una plataforma mayor." % [r.mass_total, B.max]))
	if r.launch_cap <= 0.0:
		c.append(_ck("fatal", "Este lanzador no llega a esa órbita", "%s no puede llevar carga a %s. Cada cohete tiene destinos y capacidades distintas." % [L.name, O.name]))
	elif r.mass_total > r.launch_cap:
		c.append(_ck("fatal", "Demasiado pesada para el cohete", "El lanzador lleva máximo %.0f kg a %s y tu nave pesa %.1f kg. Cuanto más lejos o alta la órbita, menos carga puede llevar." % [r.launch_cap, O.short, r.mass_total]))
	if r.cost_total > r.budget:
		c.append(_ck("fatal", "Presupuesto excedido", "La misión cuesta %.1f M$ y solo hay %.1f M$. La agencia no aprobará la misión." % [r.cost_total, r.budget]))
	if r.orbit_mult <= 0.0:
		c.append(_ck("fatal", "Desde esta órbita no se cumple el objetivo", "El objetivo de «%s» no se puede observar desde %s." % [S.name, O.name]))
	# --- advertencias (consecuencias que se verán en la simulación)
	for n in r.needs:
		if not n.ok:
			c.append(_ck("warn", "Objetivo sin cubrir: " + n.label, "Ningún instrumento elegido cumple este objetivo científico."))
	if r.power_margin < 0.0:
		c.append(_ck("warn", "Energía insuficiente (%d %%)" % int(r.power_margin * 100), "Los paneles generan %.0f W en promedio y la nave consume %.0f W. Los instrumentos tendrán que turnarse: menos ciencia." % [r.power_gen, r.power_load]))
	elif r.power_margin < 0.15:
		c.append(_ck("warn", "Margen de energía bajo (%d %%)" % int(r.power_margin * 100), "Los paneles se degradan con los años. Se recomienda al menos 15 % de margen."))
	if r.battery_ratio < 1.0:
		c.append(_ck("warn", "La batería no aguanta los eclipses", "En la sombra de la Tierra (%.0f min) necesitas ~%.0f Wh y tienes %.0f Wh. Los instrumentos se apagarán en cada eclipse." % [O.eclipse_min, r.battery_need, r.battery_wh]))
	if r.data_ratio < 1.0:
		c.append(_ck("warn", "No se pueden bajar todos los datos", "Generas %.1f GB/día y solo puedes enviar %.2f GB/día. Se perderá el %d %% de la ciencia." % [r.data_gen, r.data_down, int((1.0 - r.data_ratio) * 100)]))
	if r.pointing_bad.size() > 0:
		c.append(_ck("warn", "Apuntado insuficiente", "%s necesita(n) un control de actitud más preciso. Las imágenes saldrán movidas." % ", ".join(r.pointing_bad)))
	if not r.insertion_ok:
		c.append(_ck("warn", "No hay delta-v para llegar a la órbita final", "Se necesitan %.0f m/s para entrar en %s y la propulsión da %.0f m/s. La nave no llegará a su destino." % [r.dv_insert, O.short, r.dv_have]))
	elif r.life_years < years:
		c.append(_ck("warn", "La nave no durará %d años" % years, "Con esta órbita y propulsión dura ~%.1f años (combustible o frenado atmosférico)." % r.life_years))
	if years < S.min_years:
		c.append(_ck("warn", "Vida de diseño corta", "El objetivo pide al menos %d años de operación." % S.min_years))
	if B.cots and O.radiation >= 2 and not shielding:
		c.append(_ck("warn", "CubeSat sin blindaje en zona de radiación", "Los CubeSats usan electrónica comercial; lejos de la Tierra la radiación puede dañarla."))
	if r.reserve >= 0.0 and r.reserve < 0.10:
		c.append(_ck("warn", "Reserva de presupuesto baja", "Queda %.0f %% del presupuesto. Las misiones reales guardan 10-30 %% para imprevistos." % (r.reserve * 100)))
	# --- buenas noticias
	if r.power_margin >= 0.15 and r.battery_ratio >= 1.0:
		c.append(_ck("ok", "Energía equilibrada", "Margen de %d %% y batería suficiente para los eclipses." % int(r.power_margin * 100)))
	if r.data_ratio >= 1.0 and not instruments.is_empty():
		c.append(_ck("ok", "Enlace de datos suficiente", "Puedes bajar %.1f GB/día; generas %.1f GB/día." % [r.data_down, r.data_gen]))
	if r.mass_margin >= 0.1 and r.mass_total <= B.max and r.launch_cap > 0.0:
		c.append(_ck("ok", "Masa dentro de límites", "Margen de masa de %d %%." % int(r.mass_margin * 100)))
	if r.reserve >= 0.10:
		c.append(_ck("ok", "Presupuesto con reserva", "Queda %.0f %% para imprevistos." % (r.reserve * 100)))
	return c


func _ck(level: String, title: String, detail: String) -> Dictionary:
	return {"level": level, "title": title, "detail": detail}


func role_goals(r: Dictionary) -> Dictionary:
	return {
		"director": r.reserve >= 0.10,
		"cientifico": r.needs_frac >= 1.0 and r.expected_science >= 0.8 * r.science_target,
		"ingeniero": r.mass_margin >= 0.10 and r.power_margin >= 0.15,
		"operaciones": r.data_ratio >= 1.0 and r.life_years >= years,
	}


# ======================================================================= SIMULACIÓN
func simulate(seed_value: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var r := compute()
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var B: Dictionary = GameData.BUSES[bus]
	var O: Dictionary = GameData.ORBITS[orbit]
	var L: Dictionary = GameData.LAUNCHERS[launcher]
	var A: Dictionary = GameData.ADCS[adcs]
	var PR: Dictionary = GameData.PROPULSION[propulsion]
	var D: Dictionary = GameData.DIFFICULTY[difficulty]
	var ev_mult: float = D.events

	var events: Array = []
	var sim := {"events": events, "science": 0.0, "months": 0, "timeline": [], "status": "ok",
		"end_reason": "", "extra_cost": 0.0, "launch_failed": false, "lost_instruments": []}
	var months_total := years * 12

	# --- retraso de lanzamiento
	if rng.randf() < L.delay * ev_mult:
		var dm := rng.randi_range(1, 6)
		var ec: float = O.ops * B.ops_mult * dm / 12.0 * 0.5
		sim.extra_cost += ec
		events.append(_ev(0, "info", "Lanzamiento retrasado %d meses" % dm,
			"El cohete se demoró (clima, revisiones técnicas o el cliente principal). Mantener al equipo listo costó %.2f M$ extra." % ec))

	# --- lanzamiento
	if rng.randf() < L.fail * D.launch_fail:
		sim.launch_failed = true
		sim.status = "lost"
		sim.end_reason = "Falla del lanzador"
		events.append(_ev(0, "bad", "¡Falla del cohete!",
			"El lanzador falló durante el ascenso (probabilidad ~%d %%). Ocurre en la vida real: por eso las agencias contratan seguros y eligen cohetes confiables." % int(L.fail * 100)))
		_finish(sim, r)
		return sim
	events.append(_ev(0, "good", "Despegue exitoso", "%s colocó la nave en el espacio." % L.name))

	# --- inserción en órbita
	var dv_left: float = PR.dv - O.insert_dv
	var orbit_penalty := 1.0
	if dv_left < 0.0:
		if orbit == "lunar":
			sim.status = "lost"
			sim.end_reason = "No pudo frenar en la Luna"
			events.append(_ev(0, "bad", "La nave pasó de largo de la Luna",
				"Hacía falta frenar %.0f m/s para quedar en órbita lunar y solo había %.0f m/s. La nave siguió de largo hacia el espacio." % [O.insert_dv, PR.dv]))
			_finish(sim, r)
			return sim
		elif orbit == "geo":
			orbit_penalty = 0.2
			events.append(_ev(0, "bad", "Atrapada en la órbita de transferencia",
				"El cohete la dejó en una órbita elíptica y sin propulsión no pudo subir a GEO. Solo ve la Tierra a ratos y cruza los cinturones de radiación."))
		else:
			orbit_penalty = 0.5
			events.append(_ev(0, "bad", "Órbita incorrecta", "Faltó delta-v para la inserción final."))
		dv_left = 0.0
	else:
		events.append(_ev(0, "good", "En órbita: %s" % O.short, "Paneles desplegados y primer contacto con la estación terrena."))

	# --- avisos iniciales que explican el rendimiento
	if r.power_margin < 0.0:
		events.append(_ev(1, "bad", "Modo ahorro de energía",
			"Los paneles no alcanzan para todo. Los instrumentos se turnan y la ciencia baja al %d %%." % int(clamp(r.power_gen / r.power_load, 0.1, 1.0) * 100)))
	if r.battery_ratio < 1.0:
		events.append(_ev(1, "bad", "Apagones en cada eclipse",
			"La batería no aguanta la sombra de %.0f minutos; los instrumentos se apagan en cada vuelta." % O.eclipse_min))
	if r.data_ratio < 1.0:
		events.append(_ev(1, "bad", "Memoria llena",
			"Se generan más datos de los que la antena puede enviar. Se pierde el %d %% de las observaciones." % int((1.0 - r.data_ratio) * 100)))
	if r.pointing_bad.size() > 0:
		events.append(_ev(1, "bad", "Imágenes movidas",
			"El control de actitud no es suficientemente preciso para: %s." % ", ".join(r.pointing_bad)))

	var life_months := int(floor(r.life_years * 12.0)) if r.insertion_ok else int(floor(1.0 * 12.0))
	var working: Array = instruments.duplicate()
	var point_level: int = A.level
	var power_mult := 1.0
	var bonuses := 0
	var aged := false
	var is_cots: bool = B.cots
	var rad: int = O.radiation
	if orbit_penalty < 1.0:
		rad = 3

	for m in range(1, months_total + 1):
		if m > life_months:
			var why := "Se acabó el combustible para mantener la órbita."
			if O.drag_life < 900.0 and r.insertion_ok:
				why = "El roce con la atmósfera residual la frenó hasta reingresar y quemarse. Con propulsión habría podido compensar."
			elif orbit == "lunar":
				why = "Sin combustible para corregir la órbita, la gravedad irregular de la Luna la hizo chocar contra la superficie."
			sim.end_reason = "Fin de vida anticipado"
			events.append(_ev(m, "bad", "Fin de la misión antes de tiempo", why))
			break
		var month_sci := science_rate(working, point_level, power_mult) * orbit_penalty

		# tormenta solar / radiación
		if rng.randf() < 0.012 * rad * ev_mult:
			var dmg: float = 0.35 * (1.6 if is_cots else 1.0) * (0.25 if shielding else 1.0) * (0.5 if redundancy else 1.0)
			if rng.randf() < dmg and working.size() > 0:
				if rng.randf() < 0.25 and not redundancy:
					sim.status = "lost"
					sim.end_reason = "Computadora dañada por radiación"
					events.append(_ev(m, "bad", "Tormenta solar: computadora dañada",
						"Una partícula de alta energía dañó la computadora de a bordo y no hay respaldo. La nave quedó en silencio. El blindaje y la redundancia reducen este riesgo."))
					sim.timeline.append(sim.science)
					sim.months = m
					break
				var lost: String = working[rng.randi_range(0, working.size() - 1)]
				working.erase(lost)
				sim.lost_instruments.append(lost)
				events.append(_ev(m, "bad", "Tormenta solar: instrumento dañado",
					"La radiación dañó el %s. %s" % [GameData.INSTRUMENTS[lost].name, "Sin blindaje la electrónica es más vulnerable." if not shielding else "Ni el blindaje alcanzó esta vez."]))
			else:
				events.append(_ev(m, "good", "Tormenta solar superada",
					"Hubo una tormenta solar y la nave la resistió%s." % (" gracias al blindaje" if shielding else ", con suerte")))

		# falla de rueda de reacción
		if point_level >= 2 and rng.randf() < 0.008 * ev_mult:
			if redundancy:
				events.append(_ev(m, "info", "Rueda de reacción falló… respaldo activado", "La redundancia salvó el apuntado preciso."))
			else:
				point_level -= 1
				events.append(_ev(m, "bad", "Falla de una rueda de reacción", "Sin rueda de respaldo, el apuntado pierde precisión el resto de la misión."))

		# basura espacial
		if (orbit == "leo" or orbit == "sso") and rng.randf() < 0.006 * ev_mult:
			if dv_left >= 5.0:
				dv_left -= 5.0
				events.append(_ev(m, "info", "Maniobra para esquivar basura espacial", "Un fragmento venía en curso de colisión; la propulsión permitió esquivarlo."))
			elif rng.randf() < 0.35:
				power_mult *= 0.7
				events.append(_ev(m, "bad", "Impacto de micrometeorito", "Sin propulsión no se pudo esquivar: un panel solar perdió 30 % de potencia."))
			else:
				events.append(_ev(m, "info", "Basura espacial pasó cerca", "Sin propulsión no había cómo esquivar… por suerte pasó a 200 m."))

		# estación terrena
		if rng.randf() < 0.02 * ev_mult:
			month_sci *= 0.5
			events.append(_ev(m, "info", "Estación terrena fuera de servicio", "Una semana sin contacto: se perdió la mitad de los datos de este mes."))

		# envejecimiento de batería
		if not aged and m > months_total * 0.6 and r.battery_ratio < 1.3 and rng.randf() < 0.3:
			aged = true
			power_mult *= 0.85
			events.append(_ev(m, "bad", "La batería envejece", "Miles de ciclos de carga y descarga redujeron su capacidad. Con más margen no se habría notado."))

		# descubrimientos (premian un buen diseño)
		if bonuses < 2 and rng.randf() < 0.05:
			var b := _discovery(working, bonuses)
			if not b.is_empty():
				bonuses += 1
				var bonus: float = month_sci * (3.0 if orbit != "geo" else 4.5)
				month_sci += bonus
				events.append(_ev(m, "good", b[0], b[1]))

		sim.science += month_sci
		sim.timeline.append(sim.science)
		sim.months = m

	if sim.status == "ok" and sim.months >= months_total:
		events.append(_ev(months_total, "good", "Misión completada", "La nave cumplió sus %d años de diseño." % years))
	_finish(sim, r)
	return sim


func _discovery(working: Array, idx: int) -> Array:
	var tags := {}
	for id in working:
		for t in GameData.INSTRUMENTS[id].tags:
			tags[t] = true
	match scenario:
		"volcanes":
			if tags.has("termico") or tags.has("gases"):
				if idx == 0:
					return ["¡Alerta temprana en el Cotopaxi!", "Detectaste un aumento de temperatura y de SO2. El Instituto Geofísico recibió la alerta días antes del pico de actividad."]
				return ["Columna de ceniza del Sangay", "Seguiste la nube de ceniza y se avisó a tiempo a los aeropuertos y a los agricultores de Chimborazo."]
		"clima":
			if tags.has("altimetro") or tags.has("microondas"):
				if idx == 0:
					return ["¡Se acerca El Niño!", "El mar subió y se calentó frente a las costas de Sudamérica. La alerta llegó con meses de anticipación para preparar la Costa."]
				return ["Corrientes de Galápagos", "Mediste cómo cambia la corriente de Humboldt alrededor de Galápagos: datos clave para proteger su vida marina."]
		"luna":
			if tags.has("composicion") or tags.has("termico"):
				return ["Posible hielo en un cráter polar", "Los datos muestran hidrógeno en un cráter siempre en sombra: un recurso clave para futuras bases lunares."]
			if tags.has("optico"):
				return ["Nuevo cráter fotografiado", "Comparando imágenes encontraste un impacto reciente."]
		"telescopio":
			if tags.has("telescopio"):
				if idx == 0:
					return ["¡Nuevo exoplaneta!", "Un planeta pasó frente a su estrella y tu telescopio midió la sombra."]
				return ["Galaxia muy lejana", "Captaste la luz de una galaxia que viajó miles de millones de años hasta tu espejo."]
		_:
			if working.size() > 0:
				return ["Descubrimiento inesperado", "Tus instrumentos registraron algo que nadie esperaba. ¡Así avanza la ciencia!"]
	return []


func _ev(month: int, kind: String, title: String, text: String) -> Dictionary:
	return {"month": month, "kind": kind, "title": title, "text": text}


func _finish(sim: Dictionary, r: Dictionary) -> void:
	sim.score = score(r, sim)


# ======================================================================= PUNTAJE
func score(r: Dictionary, sim: Dictionary) -> Dictionary:
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var s := {}
	var min_months: int = S.min_years * 12
	var survival: float = 0.0 if sim.launch_failed else clamp(float(sim.months) / float(min_months), 0.0, 1.0)
	var needs_f: float = 0.0 if sim.launch_failed or sim.months == 0 else r.needs_frac
	s.objectives = roundi(needs_f * 200.0 + survival * 200.0)
	s.science = roundi(300.0 * clamp(sim.science / S.science_target, 0.0, 1.0))
	var total_cost: float = r.cost_total + sim.extra_cost
	var reserve: float = (r.budget - total_cost) / r.budget
	var budget_pts := 0.0
	if total_cost <= r.budget:
		budget_pts = 60.0 + 40.0 * clamp(reserve / 0.2, 0.0, 1.0)
	var mass_pts: float = 50.0 * clamp(r.mass_margin / 0.1, 0.0, 1.0)
	var power_pts: float = 0.0 if r.power_margin < 0.0 else 50.0 * clamp(r.power_margin / 0.15, 0.0, 1.0)
	s.efficiency = roundi(budget_pts + mass_pts + power_pts)
	var g: Dictionary = r.goals
	var team := 0
	for k in g:
		if g[k]:
			team += 25
	s.team = team
	s.total = s.objectives + s.science + s.efficiency + s.team
	s.final_cost = total_cost
	var grade := "D"
	var label := "Misión fallida: ¡hay mucho que aprender!"
	if s.total >= 900:
		grade = "S"
		label = "¡Misión legendaria!"
	elif s.total >= 750:
		grade = "A"
		label = "Misión exitosa"
	elif s.total >= 600:
		grade = "B"
		label = "Misión cumplida con limitaciones"
	elif s.total >= 400:
		grade = "C"
		label = "Éxito parcial"
	s.grade = grade
	s.label = label
	return s


## Misiones reales parecidas, para conectar el juego con el mundo real.
func real_missions() -> Array:
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var out: Array = [S.real]
	if GameData.BUSES[bus].cots:
		out.append("Ecuador también lo hizo: NEE-01 Pegaso (2013), el primer satélite ecuatoriano, fue un CubeSat 1U.")
		if orbit == "lunar":
			out.append("CAPSTONE (NASA, 2022) fue un CubeSat 12U que llegó a la órbita lunar.")
	return out
