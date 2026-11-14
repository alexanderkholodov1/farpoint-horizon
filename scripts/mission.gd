extends RefCounted
## The mission model: keeps the team's decisions, works out the budgets (mass, power, data, delta-v, cost), checks
## that the parts fit together and simulates the operation. Every text a player sees goes through tr().
## Margins used in the checks: mass 10 % and power 15 %, simplified from [S-gsfc-std-1000].

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

const DOD := 0.6            # safe battery depth of discharge in low orbit, simplified from [S-ntrs-dod]
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
		c.append(_ck("fatal", tr("Your craft needs an instrument"), tr("A craft with no instruments makes no science. Head to the Instruments step.")))
	if instruments.size() > B.slots:
		c.append(_ck("fatal", tr("Too many instruments for this platform"), tr("%s has room for %d instrument(s) and you picked %d. Use a bigger platform or drop some instruments.") % [B.name, B.slots, instruments.size()]))
	for id in instruments:
		var I: Dictionary = GameData.INSTRUMENTS[id]
		if I.size > B.max_size:
			c.append(_ck("fatal", tr("%s is too big") % I.name, tr("It needs a platform of size “%s” or larger.") % GameData.SIZE_NAMES[I.size]))
	if r.mass_total > B.max:
		c.append(_ck("fatal", tr("The craft outweighs its platform"), tr("%.1f kg against %.1f kg allowed. The structure won't hold, so pick lighter parts or a bigger platform.") % [r.mass_total, B.max]))
	if r.launch_cap <= 0.0:
		c.append(_ck("fatal", tr("This launcher can't reach that orbit"), tr("%s can't carry cargo to %s. Every rocket has its own destinations and capacity.") % [L.name, O.name]))
	elif r.mass_total > r.launch_cap:
		c.append(_ck("fatal", tr("Too heavy for the rocket"), tr("The launcher carries at most %.0f kg to %s and your craft weighs %.1f kg. The farther or higher the orbit, the less it can carry.") % [r.launch_cap, O.short, r.mass_total]))
	if r.cost_total > r.budget:
		c.append(_ck("fatal", tr("Over budget"), tr("The mission costs %.1f M$ and only %.1f M$ is available. The agency won't sign off on it.") % [r.cost_total, r.budget]))
	if r.orbit_mult <= 0.0:
		c.append(_ck("fatal", tr("This orbit can't serve the goal"), tr("The goal of “%s” can't be observed from %s.") % [S.name, O.name]))
	# --- advertencias (consecuencias que se verán en la simulación)
	for n in r.needs:
		if not n.ok:
			c.append(_ck("warn", tr("Still to cover · %s") % n.label, tr("None of the chosen instruments serves this science goal.")))
	if r.power_margin < 0.0:
		c.append(_ck("warn", tr("Power falls short (%d %%)") % int(r.power_margin * 100), tr("The panels average %.0f W and the craft draws %.0f W. Instruments will have to take turns, which means less science.") % [r.power_gen, r.power_load]))
	elif r.power_margin < 0.15:
		c.append(_ck("warn", tr("Power margin is thin (%d %%)") % int(r.power_margin * 100), tr("Panels wear out over the years. A margin of at least 15 % is recommended.")))
	if r.battery_ratio < 1.0:
		c.append(_ck("warn", tr("The battery can't cover the eclipses"), tr("In Earth's shadow (%.0f min) you need ~%.0f Wh and have %.0f Wh. Instruments will switch off in every eclipse.") % [O.eclipse_min, r.battery_need, r.battery_wh]))
	if r.data_ratio < 1.0:
		c.append(_ck("warn", tr("Not all the data fits down the link"), tr("You make %.1f GB per day and can send only %.2f GB per day. %d %% of the science will be lost.") % [r.data_gen, r.data_down, int((1.0 - r.data_ratio) * 100)]))
	if r.pointing_bad.size() > 0:
		c.append(_ck("warn", tr("Pointing is too coarse"), tr("%s need(s) finer attitude control. Images will come out blurred.") % ", ".join(r.pointing_bad)))
	if not r.insertion_ok:
		c.append(_ck("warn", tr("Not enough delta-v to reach the final orbit"), tr("You need %.0f m/s to enter %s and the propulsion gives %.0f m/s. The craft won't reach its destination.") % [r.dv_insert, O.short, r.dv_have]))
	elif r.life_years < years:
		c.append(_ck("warn", tr("The craft won't last %d years") % years, tr("With this orbit and propulsion it lasts ~%.1f years (fuel or air drag).") % r.life_years))
	if years < S.min_years:
		c.append(_ck("warn", tr("Design life is short"), tr("The goal asks for at least %d years of operation.") % S.min_years))
	if B.cots and O.radiation >= 2 and not shielding:
		c.append(_ck("warn", tr("Unshielded CubeSat in a radiation zone"), tr("CubeSats use off-the-shelf electronics, and far from Earth radiation can damage them.")))
	if r.reserve >= 0.0 and r.reserve < 0.10:
		c.append(_ck("warn", tr("Budget reserve is low"), tr("%.0f %% of the budget is left. Real missions keep 10 to 30 %% for surprises.") % (r.reserve * 100)))
	# --- buenas noticias
	if r.power_margin >= 0.15 and r.battery_ratio >= 1.0:
		c.append(_ck("ok", tr("Power in balance"), tr("A margin of %d %% and enough battery for the eclipses.") % int(r.power_margin * 100)))
	if r.data_ratio >= 1.0 and not instruments.is_empty():
		c.append(_ck("ok", tr("Data link is enough"), tr("You can send %.1f GB per day and make %.1f GB per day.") % [r.data_down, r.data_gen]))
	if r.mass_margin >= 0.1 and r.mass_total <= B.max and r.launch_cap > 0.0:
		c.append(_ck("ok", tr("Mass within limits"), tr("A mass margin of %d %%.") % int(r.mass_margin * 100)))
	if r.reserve >= 0.10:
		c.append(_ck("ok", tr("Budget with a reserve"), tr("%.0f %% is left for surprises.") % (r.reserve * 100)))
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
		events.append(_ev(0, "info", tr("Launch delayed %d months") % dm,
			tr("The rocket slipped (weather, technical checks or the main customer). Keeping the team ready cost %.2f M$ extra.") % ec))

	# --- lanzamiento
	if rng.randf() < L.fail * D.launch_fail:
		sim.launch_failed = true
		sim.status = "lost"
		sim.end_reason = tr("Launcher failure")
		events.append(_ev(0, "bad", tr("Rocket failure!"),
			tr("The launcher failed during ascent (about %d %% chance). It happens in real life, which is why agencies buy insurance and choose reliable rockets.") % int(L.fail * 100)))
		_finish(sim, r)
		return sim
	events.append(_ev(0, "good", tr("Liftoff"), tr("%s put the craft in space.") % L.name))

	# --- inserción en órbita
	var dv_left: float = PR.dv - O.insert_dv
	var orbit_penalty := 1.0
	if dv_left < 0.0:
		if orbit == "lunar":
			sim.status = "lost"
			sim.end_reason = tr("Couldn't brake at the Moon")
			events.append(_ev(0, "bad", tr("The craft flew past the Moon"),
				tr("It took %.0f m/s of braking to stay in lunar orbit and only %.0f m/s was there. The craft sailed on into space.") % [O.insert_dv, PR.dv]))
			_finish(sim, r)
			return sim
		elif orbit == "geo":
			orbit_penalty = 0.2
			events.append(_ev(0, "bad", tr("Stuck in the transfer orbit"),
				tr("The rocket left it in an elliptical orbit and without propulsion it couldn't climb to GEO. It sees Earth only part of the time and crosses the radiation belts.")))
		else:
			orbit_penalty = 0.5
			events.append(_ev(0, "bad", tr("Wrong orbit"), tr("There wasn't enough delta-v for the final insertion.")))
		dv_left = 0.0
	else:
		events.append(_ev(0, "good", tr("In orbit at %s") % O.short, tr("Panels deployed and first contact with the ground station.")))

	# --- avisos iniciales que explican el rendimiento
	if r.power_margin < 0.0:
		events.append(_ev(1, "bad", tr("Power saving mode"),
			tr("The panels can't power everything. Instruments take turns and science drops to %d %%.") % int(clamp(r.power_gen / r.power_load, 0.1, 1.0) * 100)))
	if r.battery_ratio < 1.0:
		events.append(_ev(1, "bad", tr("Blackouts in every eclipse"),
			tr("The battery can't cover the %.0f minute shadow, so instruments switch off every lap.") % O.eclipse_min))
	if r.data_ratio < 1.0:
		events.append(_ev(1, "bad", tr("Memory full"),
			tr("More data is made than the antenna can send. %d %% of the observations are lost.") % int((1.0 - r.data_ratio) * 100)))
	if r.pointing_bad.size() > 0:
		events.append(_ev(1, "bad", tr("Blurry images"),
			tr("Attitude control isn't precise enough for %s.") % ", ".join(r.pointing_bad)))

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
			var why := tr("The fuel to hold the orbit ran out.")
			if O.drag_life < 900.0 and r.insertion_ok:
				why = tr("Drag from the thin upper air slowed it until it reentered and burned up. With propulsion it could have made up for it.")
			elif orbit == "lunar":
				why = tr("With no fuel to correct the orbit, the Moon's lumpy gravity brought it down onto the surface.")
			sim.end_reason = tr("Early end of life")
			events.append(_ev(m, "bad", tr("Mission ended early"), why))
			break
		var month_sci := science_rate(working, point_level, power_mult) * orbit_penalty

		# tormenta solar / radiación
		if rng.randf() < 0.012 * rad * ev_mult:
			var dmg: float = 0.35 * (1.6 if is_cots else 1.0) * (0.25 if shielding else 1.0) * (0.5 if redundancy else 1.0)
			if rng.randf() < dmg and working.size() > 0:
				if rng.randf() < 0.25 and not redundancy:
					sim.status = "lost"
					sim.end_reason = tr("Computer damaged by radiation")
					events.append(_ev(m, "bad", tr("Solar storm fries the computer"),
						tr("A high-energy particle damaged the onboard computer and there is no backup. The craft went silent. Shielding and redundancy reduce this risk.")))
					sim.timeline.append(sim.science)
					sim.months = m
					break
				var lost: String = working[rng.randi_range(0, working.size() - 1)]
				working.erase(lost)
				sim.lost_instruments.append(lost)
				events.append(_ev(m, "bad", tr("Solar storm damages an instrument"),
					tr("Radiation damaged the %s. %s") % [GameData.INSTRUMENTS[lost].name, tr("Without shielding the electronics are more vulnerable.") if not shielding else tr("Even the shielding wasn't enough this time.")]))
			else:
				events.append(_ev(m, "good", tr("Solar storm weathered"),
					tr("A solar storm hit and the craft rode it out%s.") % (tr(" thanks to the shielding") if shielding else tr(", with a bit of luck"))))

		# falla de rueda de reacción
		if point_level >= 2 and rng.randf() < 0.008 * ev_mult:
			if redundancy:
				events.append(_ev(m, "info", tr("Reaction wheel failed, backup switched on"), tr("Redundancy saved the fine pointing.")))
			else:
				point_level -= 1
				events.append(_ev(m, "bad", tr("A reaction wheel failed"), tr("With no spare wheel, pointing stays less precise for the rest of the mission.")))

		# basura espacial
		if (orbit == "leo" or orbit == "sso") and rng.randf() < 0.006 * ev_mult:
			if dv_left >= 5.0:
				dv_left -= 5.0
				events.append(_ev(m, "info", tr("Dodging space debris"), tr("A fragment was on a collision course and the propulsion let the craft dodge it.")))
			elif rng.randf() < 0.35:
				power_mult *= 0.7
				events.append(_ev(m, "bad", tr("Micrometeoroid hit"), tr("With no propulsion there was no dodging it, and a solar panel lost 30 % of its power.")))
			else:
				events.append(_ev(m, "info", tr("Space debris flew by"), tr("With no propulsion there was no way to dodge… luckily it passed 200 m away.")))

		# estación terrena
		if rng.randf() < 0.02 * ev_mult:
			month_sci *= 0.5
			events.append(_ev(m, "info", tr("Ground station offline"), tr("A week without contact cost half of this month's data.")))

		# envejecimiento de batería
		if not aged and m > months_total * 0.6 and r.battery_ratio < 1.3 and rng.randf() < 0.3:
			aged = true
			power_mult *= 0.85
			events.append(_ev(m, "bad", tr("The battery is aging"), tr("Thousands of charge cycles cut its capacity. With more margin nobody would have noticed.")))

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
		events.append(_ev(months_total, "good", tr("Mission complete"), tr("The craft served its full %d years of design life.") % years))
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
					return [tr("Early warning at Cotopaxi!"), tr("You detected a rise in temperature and SO2. The Geophysical Institute got the alert days before the activity peaked.")]
				return [tr("Sangay ash plume"), tr("You tracked the ash cloud and airports and Chimborazo farmers were warned in time.")]
		"clima":
			if tags.has("altimetro") or tags.has("microondas"):
				if idx == 0:
					return [tr("El Niño is coming!"), tr("The sea rose and warmed off the South American coast. The alert came months ahead, in time to prepare the Coast.")]
				return [tr("Galápagos currents"), tr("You measured how the Humboldt current shifts around Galápagos, key data to protect its marine life.")]
		"luna":
			if tags.has("composicion") or tags.has("termico"):
				return [tr("Possible ice in a polar crater"), tr("The data show hydrogen in a crater that never sees the Sun, a key resource for future lunar bases.")]
			if tags.has("optico"):
				return [tr("New crater photographed"), tr("Comparing images, you found a recent impact.")]
		"telescopio":
			if tags.has("telescopio"):
				if idx == 0:
					return [tr("New exoplanet!"), tr("A planet crossed in front of its star and your telescope measured the shadow.")]
				return [tr("A very distant galaxy"), tr("You caught light from a galaxy that traveled billions of years to reach your mirror.")]
		_:
			if working.size() > 0:
				return [tr("Unexpected discovery"), tr("Your instruments recorded something nobody expected. That's how science moves forward!")]
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
	var label := tr("Mission lost, and a lot learned!")
	if s.total >= 900:
		grade = "S"
		label = tr("Legendary mission!")
	elif s.total >= 750:
		grade = "A"
		label = tr("Successful mission")
	elif s.total >= 600:
		grade = "B"
		label = tr("Mission done, with limits")
	elif s.total >= 400:
		grade = "C"
		label = tr("Partial success")
	s.grade = grade
	s.label = label
	return s


## Misiones reales parecidas, para conectar el juego con el mundo real.
func real_missions() -> Array:
	var S: Dictionary = GameData.SCENARIOS[scenario]
	var out: Array = [S.real]
	if GameData.BUSES[bus].cots:
		# [S-pegaso] NEE-01 Pegaso, 1U, 2013; [S-capstone] CAPSTONE, 12U, 2022
		out.append(tr("Ecuador did it too. NEE-01 Pegaso (2013), the first Ecuadorian satellite, was a 1U CubeSat."))
		if orbit == "lunar":
			out.append(tr("CAPSTONE (NASA, 2022) was a 12U CubeSat that reached lunar orbit."))
	return out
