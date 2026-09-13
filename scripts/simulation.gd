extends RefCounted
## All gameplay state lives here. Only the host advances or mutates it.
const Scenarios = preload("res://scripts/scenarios.gd")
const Politics = preload("res://scripts/politics.gd")
const Economy = preload("res://scripts/economy.gd")
var NAMES: Array:
	get: return state.countries.map(func(c): return c.name)
const BASE_ACTIONS = {
	"industry": ["Industrie ausbauen", "180 M · 35 Einfluss · 45 Tage → +8 Industrie", 180.0, 35.0],
	"research": ["Modernisierung", "140 M · 30 Einfluss · 60 Tage → +0,25 Qualität", 140.0, 30.0],
	"recruit": ["Freiwillige anwerben", "90 M · 20 Einfluss · 30 Tage → +15 Tsd. Soldaten", 90.0, 20.0],
	"welfare": ["Sozialpakt", "100 M · 35 Einfluss → +12 Stabilität", 100.0, 35.0],
	"democratize": ["Demokratische Verfassung", "180 M · 120 Einfluss → freie Wahlen, −8 Stabilität", 180.0, 120.0],
	"tax_up": ["Steuern erhöhen", "20 Einfluss → +5 Prozentpunkte Steuern, −5 Stabilität", 0.0, 20.0],
	"tax_down": ["Steuern senken", "20 Einfluss → −5 Prozentpunkte Steuern, +4 Stabilität", 0.0, 20.0],
	"trade": ["Energie importieren", "50 M · 25 Einfluss → Vertrag: bis zu 10 Energie/Monat zu 1 M je Einheit", 50.0, 25.0],
	"diplomacy": ["Staatsbesuch", "40 M · 20 Einfluss → +20 Beziehungen, +3 Stabilität", 40.0, 20.0],
	"war": ["Krieg erklären", "70 Einfluss · −12 Stabilität · automatische Kriegsführung", 0.0, 70.0],
	"peace": ["Waffenstillstand anbieten", "30 Einfluss · bei ausgeglichenem Krieg nach 30 Tagen", 0.0, 30.0]
}
var state: Dictionary = {}
var ACTIONS: Dictionary:
	get:
		var actions = BASE_ACTIONS.duplicate(true)
		if year() == 2026:
			actions.industry = ["Digitale Infrastruktur", "220 M · 35 Einfluss · 45 Tage → +8 Industrie", 220.0, 35.0]
			actions.research = ["Technologieprogramm", "180 M · 30 Einfluss · 60 Tage → +0,25 Qualität", 180.0, 30.0]
			actions.recruit = ["Berufsarmee erweitern", "110 M · 20 Einfluss · 30 Tage → +15 Tsd. Soldaten", 110.0, 20.0]
		for key in {"energy": "Energiekapazität", "farms": "Landwirtschaft", "services": "Dienstleistungen"}:
			actions[key] = [{"energy": "Kraftwerke & Netze", "farms": "Landwirtschaft ausbauen", "services": "Dienstleistungen fördern"}[key], "160 M · 30 Einfluss · 45 Tage → +12 Kapazität", 160.0, 30.0]
		for key in ["social", "education", "defense", "corporate", "vat"]:
			for direction in ["up", "down"]:
				actions[key + "_" + direction] = [("Erhöhen" if direction == "up" else "Senken"), "15 Einfluss · Budget ±10 Punkte / Steuer ±5 Prozentpunkte", 0.0, 15.0]
		actions.loan = ["Staatsanleihe ausgeben", "+200 M Kasse und Schulden · 10 Einfluss · Zinsen steigen mit Verschuldung", 0.0, 10.0]
		actions.repay = ["200 M Schulden tilgen", "200 M aus der Kasse · 10 Einfluss", 200.0, 10.0]
		actions.import_food = ["Nahrung importieren", "50 M · 25 Einfluss → bis zu 10 Nahrung/Monat zu 0,8 M je Einheit", 50.0, 25.0]
		actions.import_materials = ["Material importieren", "50 M · 25 Einfluss → bis zu 10 Material/Monat zu 1,4 M je Einheit", 50.0, 25.0]
		actions.restore_monarchy = ["Konstitutionelle Monarchie", "1936: Wilhelm II. aus dem Exil zurückrufen · 200 M · 200 Einfluss · Alternativgeschichte", 200.0, 200.0]
		return actions

func year() -> int:
	return int(state.get("scenario", 1936))

func count() -> int:
	return state.countries.size()

func new_game(scenario_year: int = 1936, seed_value: int = 1936):
	if not Scenarios.available(scenario_year): scenario_year = 1936
	var setup = Scenarios.get_scenario(scenario_year)
	state = {"version": 3, "scenario": scenario_year, "seed": seed_value, "day": 0, "countries": [], "wars": [], "war_archive": [], "trades": [], "log": [], "winner": -1}
	for entry in setup.countries:
		var c = entry.duplicate(true)
		for key in ["polygons", "neighbors", "sea_neighbors", "center", "color"]: c.erase(key)
		c.merge({"owner": int(c.id), "tax": 25, "trade": 0, "projects": [], "relations": {}, "event": -1, "event_day": 0, "cooldowns": {}, "truce": {}})
		Politics.initialize(c, scenario_year)
		Economy.initialize(c)
		state.countries.append(c)
	log_entry("%d · %s. Dein Kabinett wartet auf Entscheidungen." % [scenario_year, setup.title])

func country(id: int) -> Dictionary:
	return state.countries[id]

func alive(id: int) -> bool:
	return id >= 0 and id < count() and int(country(id).owner) == id

func territories(id: int) -> int:
	var total = 0
	for c in state.countries:
		if int(c.owner) == id: total += 1
	return total

func power(id: int) -> float:
	var c = country(id)
	return c.army * c.quality * (0.6 + c.stability / 200.0) * Economy.supply(c) * (0.5 + c.econ.defense / 120.0) * (1 + Politics.bonus(c, year(), "defense"))

func parties(id: int) -> Array:
	return Politics.roster(year(), country(id).code).parties

func income(id: int) -> float:
	return Economy.ledger(country(id), year(), war_count(id)).balance

func war_count(id: int) -> int:
	var count = 0
	for w in state.wars:
		if int(w.a) == id or int(w.b) == id: count += 1
	return count

func relation(a: int, b: int) -> int:
	return int(country(a).relations.get(str(b), 0))

func borders(a: int, b: int) -> bool:
	for i in range(count()):
		if int(country(i).owner) != a: continue
		var entry = Scenarios.get_scenario(year()).countries[i]
		for n in entry.neighbors + entry.sea_neighbors:
			if int(country(int(n)).owner) == b: return true
	return false

func at_war(a: int, b: int) -> bool:
	for w in state.wars:
		if (int(w.a) == a and int(w.b) == b) or (int(w.a) == b and int(w.b) == a): return true
	return false

func reason(id: int, action: String, target: int = -1) -> String:
	if not alive(id): return "Dein Staat wurde eingegliedert. Starte eine neue Partie."
	if int(state.winner) >= 0: return "Diese Partie ist abgeschlossen."
	var c = country(id)
	var political_error = politics_reason(id, action)
	if political_error != "__other__": return political_error
	if action.begins_with("campaign_"):
		var suffix = action.trim_prefix("campaign_")
		if not suffix.is_valid_int() or int(suffix) not in range(parties(id).size()): return "Unbekannte Partei."
		if not c.democratic: return "Keine freien Wahlen. Zuerst eine demokratische Verfassung beschließen."
		if c.influence < 25: return "25 Einfluss erforderlich."
		if int(c.cooldowns.get("campaign", -1)) > int(state.day): return "Wahlkampagne erst in 15 Tagen wieder möglich."
		return ""
	if action.begins_with("event_"):
		if action not in ["event_0", "event_1"] or int(c.event) < 0: return "Keine offene Entscheidung."
		if action == "event_0" and c.money < 60: return "60 M erforderlich."
		return ""
	if not ACTIONS.has(action): return "Unbekannte Entscheidung."
	if action == "restore_monarchy" and (year() != 1936 or c.code != "DEU" or not c.democratic or c.head_title == "Kaiser"): return "Nur im demokratischen deutschen Alternativpfad 1936 verfügbar."
	var budget = action.get_slice("_", 0)
	if budget in ["social", "education", "defense", "corporate", "vat"]:
		var ceiling = 40 if budget in ["corporate", "vat"] else 100
		var floor_value = 5 if budget in ["corporate", "vat"] else 10
		if (action.ends_with("up") and c.econ[budget] >= ceiling) or (action.ends_with("down") and c.econ[budget] <= floor_value): return "Grenze erreicht."
	if action == "loan" and c.econ.debt + 200 > Economy.ledger(c, year(), war_count(id)).gdp * 18: return "Kreditlimit erreicht (150 % des Modell-Jahres-BIP)."
	if action == "repay" and c.econ.debt < 200: return "Weniger als 200 M Schulden."
	if action == "democratize" and c.democratic: return "Es gibt bereits freie Wahlen."
	if c.money < ACTIONS[action][2]: return "Nicht genug Staatsmittel."
	if c.influence < ACTIONS[action][3]: return "Nicht genug politischer Einfluss."
	if int(c.cooldowns.get(action, -1)) > int(state.day): return "Diese Entscheidung hat 15 Tage Abklingzeit."
	if action in ["industry", "research", "recruit", "energy", "farms", "services"]:
		if c.projects.size() >= 2: return "Beide Projektplätze sind belegt."
		if action == "research" and c.quality >= 3: return "Maximale Qualität erreicht."
	if action == "tax_up" and c.tax >= 45: return "Maximaler Steuersatz erreicht."
	if action == "tax_down" and c.tax <= 10: return "Minimaler Steuersatz erreicht."
	if action in ["trade", "import_food", "import_materials", "diplomacy", "war", "peace"]:
		if not alive(target) or id == target: return "Wähle einen anderen unabhängigen Staat auf der Karte."
		if action in ["trade", "import_food", "import_materials", "diplomacy"] and at_war(id, target): return "Im Krieg nicht möglich."
		if action in ["trade", "import_food", "import_materials"] and c.trade >= 4: return "Alle vier Handelsplätze sind belegt."
		if action in ["trade", "import_food", "import_materials"] and relation(id, target) < -20: return "Beziehungen zuerst verbessern."
		if action == "war":
			if not borders(id, target): return "Kein gemeinsamer Grenz- oder Seezugang im Szenario."
			if at_war(id, target): return "Ihr befindet euch bereits im Krieg."
			if war_count(id) >= 1 or war_count(target) >= 1: return "Ein Staat kann nur einen Krieg gleichzeitig führen."
			if int(c.truce.get(str(target), -1)) > int(state.day): return "Der Waffenstillstand gilt noch."
		if action == "peace":
			for w in state.wars:
				if (int(w.a) == id and int(w.b) == target) or (int(w.b) == id and int(w.a) == target):
					if int(w.days) >= 30 and absf(w.progress) <= 45: return ""
			return "Nur nach 30 Kriegstagen bei Fortschritt zwischen −45 und +45."
	return ""

func act(id: int, action: String, target: int = -1) -> String:
	var error = reason(id, action, target)
	if error != "": return error
	var c = country(id)
	if politics_reason(id, action) != "__other__": return politics_act(id, action)
	if action.begins_with("campaign_"):
		c.influence -= 25
		shift_support(c, int(action.get_slice("_", 1)), 9)
		c.cooldowns.campaign = int(state.day) + 15
		return "Wahlkampagne gestartet. Die nächste Wahl ist an Tag %d." % ((int(state.day) / 180 + 1) * 180)
	if action.begins_with("event_"):
		if action == "event_0":
			c.money -= 60
			c.stability = minf(100, c.stability + 7)
			c.industry += 2
		else:
			c.influence = minf(250, c.influence + 20)
			c.stability = maxf(0, c.stability - 5)
		c.event = -1
		return "Das Kabinett hat entschieden."
	c.money -= ACTIONS[action][2]
	c.influence -= ACTIONS[action][3]
	c.cooldowns[action] = int(state.day) + 15
	match action:
		"democratize":
			c.democratic = true
			if c.code == "DEU" and year() == 1936:
				c.head_name = "Paul Löbe"
				c.head_title = "Übergangspräsident"
			c.stability = maxf(0, c.stability - 8)
			log_entry("%s beschließt eine demokratische Verfassung." % c.name)
		"restore_monarchy":
			c.head_name = "Wilhelm II."
			c.head_title = "Kaiser"
			c.stability = maxf(0, c.stability - 12)
			log_entry("Deutschland ruft Wilhelm II. zurück: konstitutionelle Monarchie (Alternativgeschichte).")
		"industry", "research", "recruit", "energy", "farms", "services":
			var duration = {"industry": 45, "research": 60, "recruit": 30}.get(action, 45)
			c.projects.append({"kind": action, "finish": int(state.day) + duration})
		"welfare":
			c.stability = minf(100, c.stability + 12)

		"tax_up":
			c.tax += 5
			c.stability = maxf(0, c.stability - 5)
		"tax_down":
			c.tax -= 5
			c.stability = minf(100, c.stability + 4)
			shift_support(c, 0, 3)
		"trade", "import_food", "import_materials":
			c.trade += 1
			var good = {"trade": "energy", "import_food": "food", "import_materials": "materials"}[action]
			state.trades.append({"a": id, "b": target, "good": good, "delivered": 0.0, "spent": 0.0})
			change_relation(id, target, 10)
		"loan":
			c.money += 200
			c.econ.debt += 200
		"repay": c.econ.debt -= 200
		"diplomacy":
			change_relation(id, target, 20 + int(Politics.bonus(c, year(), "foreign") * 100))
			c.stability = minf(100, c.stability + 3)
		"war":
			c.stability = maxf(0, c.stability - 12)
			change_relation(id, target, -80)
			state.wars.append({"a": id, "b": target, "progress": 0.0, "days": 0, "loss_a": 0.0, "loss_b": 0.0, "cost_a": 0.0, "cost_b": 0.0, "history": [], "reports": [{"day": int(state.day), "text": "Kriegserklärung. Mobilisierung und Versorgung laufen an."}], "milestone": 0, "winner": -1})
			log_entry("%s erklärt %s den Krieg." % [c.name, country(target).name])
		"peace":
			for w in state.wars.duplicate():
				if int(w.a) in [id, target] and int(w.b) in [id, target]: archive_war(w, -1)
			c.truce[str(target)] = int(state.day) + 180
			country(target).truce[str(id)] = int(state.day) + 180
			log_entry("%s und %s schließen 180 Tage Waffenstillstand." % [c.name, country(target).name])
	var budget = action.get_slice("_", 0)
	if budget in ["social", "education", "defense", "corporate", "vat"]:
		var change = 5 if budget in ["corporate", "vat"] else 10
		c.econ[budget] += change if action.ends_with("up") else -change
	return "%s beschlossen." % ACTIONS[action][0]

func change_relation(a: int, b: int, amount: int):
	var value = clampi(relation(a, b) + amount, -100, 100)
	country(a).relations[str(b)] = value
	country(b).relations[str(a)] = value

func shift_support(c: Dictionary, party: int, amount: float):
	for i in range(c.support.size()): c.support[i] = maxf(1, float(c.support[i]) + (amount if i == party else -amount / maxf(1, c.support.size() - 1)))
	var total = 0.0
	for value in c.support: total += value
	for i in range(c.support.size()): c.support[i] = c.support[i] / total * 100.0

func advance(humans: Array = [0]):
	if int(state.winner) >= 0: return
	state.day += 1
	var day = int(state.day)
	for c in state.countries:
		var id = int(c.id)
		if not alive(id): continue
		Economy.advance(c, year(), war_count(id), day)
		c.influence = minf(250, c.influence + 0.7 + c.support[int(c.ruling)] / 100.0)
		var drift = (0.04 if c.tax <= 25 else -0.06) - war_count(id) * 0.07
		c.stability = clampf(c.stability + drift, 0, 100)
		if c.money < 0:
			c.money = 0
			c.army = maxf(5, c.army - 0.25)
			c.stability = maxf(0, c.stability - 0.3)
		for project in c.projects.duplicate():
			if day >= int(project.finish):
				match project.kind:
					"industry": c.industry += 8
					"research": c.quality = minf(3, c.quality + 0.25)
					"recruit": c.army += 15
					"energy", "farms", "services": c.econ[project.kind] += 12
				c.projects.erase(project)
				if id in humans: log_entry("%s: %s abgeschlossen." % [c.name, ACTIONS[project.kind][0]])
		if day % 180 == 0 and c.democratic:
			var elected = c.support.find(c.support.max())
			c.coalition = [elected]
			for i in range(parties(id).size()):
				if Politics.coalition_support(c) > 50: break
				if i not in c.coalition: c.coalition.append(i)
			Politics.form_government(c, year(), elected)
			c.stability = minf(100, c.stability + 3)
			log_entry("Wahl in %s: %s führt die neue Koalition." % [c.name, parties(id)[elected].name])
		if day % 75 == 0 and int(c.event) < 0:
			c.event = (day / 75 + id + int(state.seed)) % 3
			c.event_day = day
		if int(c.event) >= 0 and day - int(c.event_day) >= 30:
			act(id, "event_1")
		if id not in humans and day % 30 == 0: ai_turn(id)
	advance_trade()
	for w in state.wars.duplicate():
		var a = int(w.a)
		var b = int(w.b)
		w.days += 1
		var pa = power(a)
		var pb = power(b)
		var advantage = (pa - pb) / maxf(1, pa + pb)
		w.progress = clampf(w.progress + advantage * 4.0, -100, 100)
		# No unit combat: one strategic balance, with daily attrition and costs.
		var loss_a = minf(maxf(0, country(a).army - 5), country(a).army * (0.001 - advantage * 0.0004))
		var loss_b = minf(maxf(0, country(b).army - 5), country(b).army * (0.001 + advantage * 0.0004))
		country(a).army -= loss_a
		country(b).army -= loss_b
		w.loss_a += loss_a
		w.loss_b += loss_b
		w.cost_a += (24 + country(a).army * 0.15) / 30.0
		w.cost_b += (24 + country(b).army * 0.15) / 30.0
		for combatant in [a, b]: country(combatant).econ.damage = minf(65, country(combatant).econ.damage + 0.045)
		if int(w.days) % 7 == 0:
			w.history.append({"day": state.day, "progress": w.progress})
			if w.history.size() > 104: w.history.pop_front()
			war_report(w, "Lage: %+.1f / 100 · Stärke %.0f : %.0f · Versorgung %.0f %% : %.0f %%" % [w.progress, pa, pb, Economy.supply(country(a)) * 100, Economy.supply(country(b)) * 100])
		var milestone = int(absf(w.progress) / 25)
		if milestone > int(w.milestone):
			w.milestone = milestone
			war_report(w, "%s erreicht %.0f %% strategischen Kriegsfortschritt." % [country(a if w.progress > 0 else b).name, absf(w.progress)])
		if absf(w.progress) >= 100:
			var victor = a if w.progress > 0 else b
			var loser = b if victor == a else a
			for c in state.countries:
				if int(c.owner) == loser: c.owner = victor
			country(victor).industry += country(loser).industry * 0.35
			country(victor).stability = maxf(0, country(victor).stability - 8)
			archive_war(w, victor)
			log_entry("%s siegt nach %d Tagen. %s wird eingegliedert." % [country(victor).name, w.days, country(loser).name])
	for c in state.countries:
		var id = int(c.id)
		if alive(id) and (territories(id) >= 5 or (day >= 365 and c.industry >= 100 and c.stability >= 75)):
			state.winner = id
			log_entry("%s gewinnt: eine neue Ordnung für den Kontinent." % c.name)
			break

func ai_turn(id: int):
	var c = country(id)
	if int(c.event) >= 0: act(id, "event_0" if c.money > 130 else "event_1")
	if c.stability < 55: act(id, "welfare")
	var choice = ["industry", "research", "recruit"][(int(state.day) / 30 + id) % 3]
	act(id, choice)
	if int(state.day) >= 240 and not c.democratic and c.stability > 50:
		for target in range(count()):
			if alive(target) and target != id and power(id) > power(target) * 1.65 and reason(id, "war", target) == "":
				act(id, "war", target)
				break

func log_entry(message: String):
	state.log.push_front({"day": state.day, "text": message})
	if state.log.size() > 60: state.log.resize(60)

func save_game(path: String, player: int) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"state": state, "player": player}))
	return OK

func politics_reason(id: int, action: String) -> String:
	var c = country(id)
	if action.begins_with("coalition_") or action.begins_with("government_"):
		var suffix = action.get_slice("_", 1)
		if action.get_slice_count("_") != 2 or not suffix.is_valid_int() or int(suffix) not in range(parties(id).size()): return "Unbekannte Partei."
		var party = int(suffix)
		if not c.democratic and not parties(id)[party].legal: return "Partei verboten. Zuerst demokratische Verfassung beschließen."
		if action.begins_with("coalition_"):
			if party == int(c.ruling): return "Die Regierungspartei kann nicht austreten."
			if c.influence < 30: return "30 Einfluss erforderlich."
			if int(c.cooldowns.get("coalition", -1)) > int(state.day): return "Koalitionsverhandlungen: 15 Tage Abklingzeit."
		else:
			if not c.democratic: return "Zuerst freie Wahlen ermöglichen."
			if party not in c.coalition or Politics.coalition_support(c) <= 50: return "Eine Koalition mit über 50 % Unterstützung ist nötig."
			if int(c.ruling) == party: return "Diese Partei führt bereits die Regierung."
			if c.influence < 80: return "80 Einfluss erforderlich."
		return ""
	if action.begins_with("appoint_"):
		var role = action.get_slice("_", 1)
		var person_id = action.get_slice("_", 2)
		if action != "appoint_" + role + "_" + person_id or role not in Politics.ROLES: return "Ungültiges Ministeramt."
		var p = Politics.person(year(), c.code, person_id)
		if p.is_empty(): return "Unbekannte Person."
		if p.party not in c.coalition: return "Zuerst die Partei in die Koalition aufnehmen."
		if not c.democratic and not parties(id)[int(p.party)].legal: return "Diese Partei ist verboten."
		if p.name in [c.premier, c.head_name] or person_id in c.cabinet.values(): return "Diese Person hat bereits ein Amt."
		if c.influence < 20: return "20 Einfluss erforderlich."
		if int(c.cooldowns.get("appoint_" + role, -1)) > int(state.day): return "Dieses Ressort hat 15 Tage Abklingzeit."
		return ""
	return "__other__"

func politics_act(id: int, action: String) -> String:
	var c = country(id)
	if action.begins_with("coalition_"):
		var party = int(action.get_slice("_", 1))
		c.influence -= 30
		c.cooldowns.coalition = int(state.day) + 15
		if party in c.coalition:
			c.coalition.erase(party)
			for role in c.cabinet:
				var p = Politics.person(year(), c.code, c.cabinet[role])
				if not p.is_empty() and int(p.party) == party: c.cabinet[role] = ""
		else: c.coalition.append(party)
		return "Koalition geändert. Besetze freie Ressorts im Kabinett."
	if action.begins_with("government_"):
		c.influence -= 80
		Politics.form_government(c, year(), int(action.get_slice("_", 1)))
		log_entry("%s: %s übernimmt das Amt %s." % [c.name, c.premier, c.premier_title])
		return "Neue Regierung gebildet. Das Kabinett wurde neu besetzt."
	var role = action.get_slice("_", 1)
	c.cabinet[role] = action.get_slice("_", 2)
	c.influence -= 20
	c.cooldowns["appoint_" + role] = int(state.day) + 15
	return "%s: %s ernannt." % [Politics.ROLES[role], Politics.person(year(), c.code, c.cabinet[role]).name]

func advance_trade():
	for contract in state.trades.duplicate():
		var a = int(contract.a)
		var b = int(contract.b)
		if not alive(a) or not alive(b):
			country(a).trade = maxi(0, int(country(a).trade) - 1)
			state.trades.erase(contract)
			continue
		if at_war(a, b): continue
		var buyer = country(a)
		var seller = country(b)
		var good = contract.good
		var reserve = Economy.demand(seller)[good] / 30.0
		var price = Economy.PRICES[good]
		var quantity = minf(10.0 / 30.0, minf(maxf(0, seller.econ.stock[good] - reserve), buyer.money / price))
		quantity = minf(quantity, maxf(0, buyer.econ.workforce * 6 - buyer.econ.stock[good]))
		buyer.money -= quantity * price
		seller.money += quantity * price
		buyer.econ.stock[good] += quantity
		seller.econ.stock[good] -= quantity
		contract.delivered += quantity
		contract.spent += quantity * price

func war_report(w: Dictionary, message: String):
	w.reports.push_front({"day": int(state.day), "text": message})
	if w.reports.size() > 40: w.reports.resize(40)

func archive_war(w: Dictionary, victor: int):
	w.winner = victor
	w.ended = int(state.day)
	war_report(w, "Waffenstillstand vereinbart." if victor < 0 else "%s hat den Krieg gewonnen." % country(victor).name)
	state.war_archive.push_front(w.duplicate(true))
	if state.war_archive.size() > 30: state.war_archive.resize(30)
	state.wars.erase(w)

func read_game(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 4000000: return -1
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not data.get("state") is Dictionary: return -1
	var s = data.state
	if s.get("version") != 3 or not number_in(s.get("scenario"), 1936, 2026): return -1
	if not Scenarios.available(int(s.scenario)): return -1
	var template = get_script().new()
	template.new_game(int(s.scenario))
	if not structure(s, template.state): return -1
	var n = template.count()
	if not number_in(data.get("player"), 0, n - 1) or not number_in(s.winner, -1, n - 1) or not number_in(s.day, 0, 1000000): return -1
	if s.countries.size() != n or s.wars.size() > n / 2 or s.war_archive.size() > 30 or s.trades.size() > n * 4: return -1
	for i in range(n):
		var c = s.countries[i]
		var original = template.country(i)
		if not structure(c, original): return -1
		if c.id != i or c.code != original.code or c.name != original.name: return -1
		if not number_in(c.owner, 0, n - 1) or not number_in(c.ruling, 0, template.parties(i).size() - 1): return -1
		if not number_in(c.stability, 0, 100) or not number_in(c.quality, 1, 3) or not number_in(c.tax, 10, 45): return -1
		if c.support.size() != template.parties(i).size() or c.coalition.is_empty(): return -1
		for value in c.support:
			if not number_in(value, 0, 100): return -1
		for value in c.coalition:
			if not number_in(value, 0, c.support.size() - 1): return -1
		for role in Politics.ROLES:
			if c.cabinet[role] != "" and Politics.person(int(s.scenario), c.code, c.cabinet[role]).is_empty(): return -1
		if c.projects.size() > 2: return -1
		for project in c.projects:
			if not structure(project, {"kind": "", "finish": 0}): return -1
			if project.kind not in ["industry", "research", "recruit", "energy", "farms", "services"]: return -1
		for key in ["relations", "cooldowns", "truce"]:
			for value in c[key].values():
				if not number_in(value, -100, 10000000): return -1
		if not number_in(c.event, -1, 2) or not number_in(c.econ.damage, 0, 65): return -1
		for key in ["energy", "farms", "services", "workforce", "debt", "inflation", "employment", "social", "education", "defense", "corporate", "vat", "productivity"]:
			if c.econ[key] < 0: return -1
		for good in Economy.GOODS:
			if c.econ.stock[good] < 0: return -1
		if c.econ.history.size() > 120: return -1
		for point in c.econ.history:
			if not structure(point, {"day": 0, "gdp": 0, "balance": 0, "debt": 0, "inflation": 0}): return -1
	var participants = []
	for w in s.wars + s.war_archive:
		if not structure(w, {"a": 0, "b": 0, "progress": 0, "days": 0, "loss_a": 0, "loss_b": 0, "cost_a": 0, "cost_b": 0, "winner": -1, "milestone": 0, "history": [], "reports": []}): return -1
		if not number_in(w.a, 0, n - 1) or not number_in(w.b, 0, n - 1) or w.a == w.b or not number_in(w.progress, -100, 100): return -1
		if not number_in(w.winner, -1, n - 1): return -1
		if w in s.wars:
			if w.a in participants or w.b in participants: return -1
			participants.append_array([w.a, w.b])
		for point in w.history:
			if not structure(point, {"day": 0, "progress": 0}): return -1
		if not valid_log(w.reports): return -1
	for contract in s.trades:
		if not structure(contract, {"a": 0, "b": 0, "good": "", "delivered": 0, "spent": 0}): return -1
		if not number_in(contract.a, 0, n - 1) or not number_in(contract.b, 0, n - 1) or contract.good not in Economy.GOODS: return -1
	if not valid_log(s.log): return -1
	for c in s.countries: c.coalition = c.coalition.map(func(value): return int(value))
	state = s
	return int(data.player)

func valid_log(entries: Array) -> bool:
	for entry in entries:
		if not structure(entry, {"day": 0, "text": ""}): return false
	return true

func structure(value, sample) -> bool:
	if sample is Dictionary:
		if not value is Dictionary: return false
		for key in sample:
			if not value.has(key) or not structure(value[key], sample[key]): return false
		return true
	if sample is Array: return value is Array
	if sample is int or sample is float: return number_in(value, -100000000, 100000000)
	if sample is String: return value is String and value.length() < 500
	if sample is bool: return value is bool
	return false

func number_in(value, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum
