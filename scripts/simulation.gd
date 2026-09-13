extends RefCounted
## All gameplay state lives here. Only the host advances or mutates it.
const PARTIES = ["Liberale", "Sozialbund", "Konservative", "Nationalblock"]
const NAMES = ["Aurelia", "Nordmark", "Valdora", "Westhain", "Eisenbund", "Südküste", "Ostwald", "Lydien"]
const COLORS = ["6caa9a", "8eabbc", "b49aca", "c4a471", "ac7870", "88a27c", "929bbb", "c792ab"]
const NEIGHBORS = [[1, 3, 4], [0, 2, 4], [1, 4, 6], [0, 4, 5], [0, 1, 2, 3, 5, 6, 7], [3, 4, 7], [2, 4, 7], [4, 5, 6]]
const ACTIONS = {
	"industry": ["Industrie ausbauen", "180 M · 35 Einfluss · 45 Tage → +8 Industrie", 180.0, 35.0],
	"research": ["Modernisierung", "140 M · 30 Einfluss · 60 Tage → +0,25 Qualität", 140.0, 30.0],
	"recruit": ["Freiwillige anwerben", "90 M · 20 Einfluss · 30 Tage → +15 Tsd. Soldaten", 90.0, 20.0],
	"welfare": ["Sozialpakt", "100 M · 35 Einfluss → +12 Stabilität, +8 Sozialbund", 100.0, 35.0],
	"tax_up": ["Steuern erhöhen", "20 Einfluss → +5 Prozentpunkte Steuern, −5 Stabilität", 0.0, 20.0],
	"tax_down": ["Steuern senken", "20 Einfluss → −5 Prozentpunkte Steuern, +4 Stabilität", 0.0, 20.0],
	"trade": ["Handelsabkommen", "50 M · 25 Einfluss → +1 Handel (max. 4), bessere Beziehungen", 50.0, 25.0],
	"diplomacy": ["Staatsbesuch", "40 M · 20 Einfluss → +20 Beziehungen, +3 Stabilität", 40.0, 20.0],
	"war": ["Krieg erklären", "70 Einfluss · −12 Stabilität · automatische Kriegsführung", 0.0, 70.0],
	"peace": ["Waffenstillstand anbieten", "30 Einfluss · bei ausgeglichenem Krieg nach 30 Tagen", 0.0, 30.0]
}
var state: Dictionary = {}

func new_game(seed_value: int = 1936):
	state = {"version": 1, "seed": seed_value, "day": 0, "countries": [], "wars": [], "log": [], "winner": -1}
	for i in range(8):
		state.countries.append({"id": i, "name": NAMES[i], "owner": i, "money": 310.0 + i * 8,
			"industry": 35.0 + (i * 7 % 19), "stability": 68.0, "influence": 100.0,
			"army": 48.0 + (i * 11 % 35), "quality": 1.0 + (i % 3) * 0.15,
			"tax": 25, "trade": 0, "ruling": i % 4, "support": [30.0, 27.0, 25.0, 18.0],
			"projects": [], "relations": {}, "event": -1, "event_day": 0, "cooldowns": {}, "truce": {}})
	log_entry("Ein Kontinent am Wendepunkt. Dein Kabinett wartet auf Entscheidungen.")

func country(id: int) -> Dictionary:
	return state.countries[id]

func alive(id: int) -> bool:
	return id >= 0 and id < 8 and int(country(id).owner) == id

func territories(id: int) -> int:
	var total = 0
	for c in state.countries:
		if int(c.owner) == id: total += 1
	return total

func power(id: int) -> float:
	var c = country(id)
	return c.army * c.quality * (0.6 + c.stability / 200.0)

func income(id: int) -> float:
	var c = country(id)
	var party_income = c.industry * 0.16 if int(c.ruling) == 0 else (-6.0 if int(c.ruling) == 1 else 0.0)
	return c.industry * c.tax / 25.0 * (0.65 + c.stability / 150.0) + c.trade * 14 + (territories(id) - 1) * 12 - c.army * 0.29 * c.quality - war_count(id) * 24 + party_income

func war_count(id: int) -> int:
	var count = 0
	for w in state.wars:
		if int(w.a) == id or int(w.b) == id: count += 1
	return count

func relation(a: int, b: int) -> int:
	return int(country(a).relations.get(str(b), 0))

func borders(a: int, b: int) -> bool:
	for i in range(8):
		if int(country(i).owner) != a: continue
		for n in NEIGHBORS[i]:
			if int(country(n).owner) == b: return true
	return false

func at_war(a: int, b: int) -> bool:
	for w in state.wars:
		if (int(w.a) == a and int(w.b) == b) or (int(w.a) == b and int(w.b) == a): return true
	return false

func reason(id: int, action: String, target: int = -1) -> String:
	if not alive(id): return "Dein Staat wurde eingegliedert. Starte eine neue Partie."
	if int(state.winner) >= 0: return "Diese Partie ist abgeschlossen."
	var c = country(id)
	if action.begins_with("campaign_"):
		if action not in ["campaign_0", "campaign_1", "campaign_2", "campaign_3"]: return "Unbekannte Partei."
		if c.influence < 25: return "25 Einfluss erforderlich."
		if int(c.cooldowns.get("campaign", -1)) > int(state.day): return "Wahlkampagne erst in 15 Tagen wieder möglich."
		return ""
	if action.begins_with("event_"):
		if action not in ["event_0", "event_1"] or int(c.event) < 0: return "Keine offene Entscheidung."
		if action == "event_0" and c.money < 60: return "60 M erforderlich."
		return ""
	if not ACTIONS.has(action): return "Unbekannte Entscheidung."
	if c.money < ACTIONS[action][2]: return "Nicht genug Staatsmittel."
	if c.influence < ACTIONS[action][3]: return "Nicht genug politischer Einfluss."
	if int(c.cooldowns.get(action, -1)) > int(state.day): return "Diese Entscheidung hat 15 Tage Abklingzeit."
	if action in ["industry", "research", "recruit"]:
		if c.projects.size() >= 2: return "Beide Projektplätze sind belegt."
		if action == "research" and c.quality >= 3: return "Maximale Qualität erreicht."
	if action == "tax_up" and c.tax >= 45: return "Maximaler Steuersatz erreicht."
	if action == "tax_down" and c.tax <= 10: return "Minimaler Steuersatz erreicht."
	if action in ["trade", "diplomacy", "war", "peace"]:
		if not alive(target) or id == target: return "Wähle einen anderen unabhängigen Staat auf der Karte."
		if action in ["trade", "diplomacy"] and at_war(id, target): return "Im Krieg nicht möglich."
		if action == "trade" and c.trade >= 4: return "Alle vier Handelsplätze sind belegt."
		if action == "trade" and relation(id, target) < -20: return "Beziehungen zuerst verbessern."
		if action == "war":
			if not borders(id, target): return "Kriege sind nur gegen Nachbarstaaten möglich."
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
		"industry", "research", "recruit":
			var duration = {"industry": 45, "research": 60, "recruit": 30}[action]
			c.projects.append({"kind": action, "finish": int(state.day) + duration})
		"welfare":
			c.stability = minf(100, c.stability + 12)
			shift_support(c, 1, 8)
		"tax_up":
			c.tax += 5
			c.stability = maxf(0, c.stability - 5)
		"tax_down":
			c.tax -= 5
			c.stability = minf(100, c.stability + 4)
			shift_support(c, 0, 3)
		"trade":
			c.trade += 1
			change_relation(id, target, 10)
		"diplomacy":
			change_relation(id, target, 20)
			c.stability = minf(100, c.stability + 3)
		"war":
			c.stability = maxf(0, c.stability - 12)
			change_relation(id, target, -80)
			state.wars.append({"a": id, "b": target, "progress": 0.0, "days": 0})
			log_entry("%s erklärt %s den Krieg." % [c.name, country(target).name])
		"peace":
			for w in state.wars.duplicate():
				if int(w.a) in [id, target] and int(w.b) in [id, target]: state.wars.erase(w)
			c.truce[str(target)] = int(state.day) + 180
			country(target).truce[str(id)] = int(state.day) + 180
			log_entry("%s und %s schließen 180 Tage Waffenstillstand." % [c.name, country(target).name])
	return "%s beschlossen." % ACTIONS[action][0]

func change_relation(a: int, b: int, amount: int):
	var value = clampi(relation(a, b) + amount, -100, 100)
	country(a).relations[str(b)] = value
	country(b).relations[str(a)] = value

func shift_support(c: Dictionary, party: int, amount: float):
	for i in range(4): c.support[i] = maxf(1, float(c.support[i]) + (amount if i == party else -amount / 3.0))
	var total = 0.0
	for value in c.support: total += value
	for i in range(4): c.support[i] = c.support[i] / total * 100.0

func advance(humans: Array = [0]):
	if int(state.winner) >= 0: return
	state.day += 1
	var day = int(state.day)
	for c in state.countries:
		var id = int(c.id)
		if not alive(id): continue
		c.money += income(id) / 30.0
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
				c.projects.erase(project)
				if id in humans: log_entry("%s: %s abgeschlossen." % [c.name, ACTIONS[project.kind][0]])
		if day % 180 == 0:
			c.ruling = c.support.find(c.support.max())
			c.stability = minf(100, c.stability + 3)
			log_entry("Wahl in %s: %s bilden die Regierung." % [c.name, PARTIES[int(c.ruling)]])
		# Governing parties have distinct economic consequences.
		match int(c.ruling):
			1: c.stability = minf(100, c.stability + 0.035)
			2: c.influence = minf(250, c.influence + 0.25)
			3: c.army += 0.025; c.stability = maxf(0, c.stability - 0.02)
		if day % 75 == 0 and int(c.event) < 0:
			c.event = (day / 75 + id + int(state.seed)) % 3
			c.event_day = day
		if int(c.event) >= 0 and day - int(c.event_day) >= 30:
			act(id, "event_1")
		if id not in humans and day % 30 == 0: ai_turn(id)
	for w in state.wars.duplicate():
		var a = int(w.a)
		var b = int(w.b)
		w.days += 1
		var pa = power(a)
		var pb = power(b)
		var advantage = (pa - pb) / maxf(1, pa + pb)
		w.progress = clampf(w.progress + advantage * 4.0, -100, 100)
		# No unit combat: one strategic balance, with daily attrition and costs.
		country(a).army = maxf(5, country(a).army * 0.999)
		country(b).army = maxf(5, country(b).army * 0.999)
		if absf(w.progress) >= 100:
			var victor = a if w.progress > 0 else b
			var loser = b if victor == a else a
			for c in state.countries:
				if int(c.owner) == loser: c.owner = victor
			country(victor).industry += country(loser).industry * 0.35
			country(victor).stability = maxf(0, country(victor).stability - 8)
			state.wars.erase(w)
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
	if int(state.day) >= 240 and int(c.ruling) == 3 and c.stability > 50:
		for target in range(8):
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

func read_game(path: String) -> int:
	if not FileAccess.file_exists(path): return -1
	var source = FileAccess.open(path, FileAccess.READ)
	if source == null or source.get_length() > 2000000: return -1
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.has("state") or not data.has("player"): return -1
	var s = data.state
	if not s is Dictionary or s.get("version", 0) != 1 or not s.get("countries", null) is Array or s.countries.size() != 8: return -1
	if not s.get("wars", null) is Array or not s.get("log", null) is Array or not s.has_all(["day", "seed", "winner"]): return -1
	if not number_in(s.day, 0, 1000000) or not number_in(s.seed, 0, 100000000) or not number_in(s.winner, -1, 7): return -1
	if not data.player is float and not data.player is int: return -1
	if int(data.player) < 0 or int(data.player) >= 8: return -1
	for index in range(8):
		var c = s.countries[index]
		if not c is Dictionary or not c.has_all(["id", "name", "owner", "money", "industry", "stability", "influence", "army", "quality", "tax", "trade", "ruling", "support", "projects", "relations", "event", "event_day", "cooldowns", "truce"]): return -1
		if not c.name is String or c.name != NAMES[index] or not number_in(c.id, index, index): return -1
		for key in ["owner", "ruling", "money", "industry", "stability", "influence", "army", "quality", "tax", "trade", "event", "event_day"]:
			if not number_in(c[key], -1 if key == "event" else 0, 100000000): return -1
		if int(c.owner) not in range(8) or int(c.ruling) not in range(4) or int(c.event) not in [-1,0,1,2]: return -1
		if c.stability > 100 or c.quality < 1 or c.quality > 3 or c.tax < 10 or c.tax > 45 or c.trade > 4: return -1
		if not c.support is Array or c.support.size() != 4: return -1
		for value in c.support:
			if not number_in(value, 0, 100): return -1
		if not c.projects is Array or c.projects.size() > 2: return -1
		for p in c.projects:
			if not p is Dictionary or not p.has_all(["kind", "finish"]): return -1
			if p.kind not in ["industry", "recruit", "research"] or not number_in(p.finish, 0, 10000000): return -1
		for key in ["relations", "cooldowns", "truce"]:
			if not c[key] is Dictionary: return -1
			for value in c[key].values():
				if not number_in(value, -100, 10000000): return -1
	for w in s.wars:
		if not w is Dictionary or not w.has_all(["a", "b", "progress", "days"]): return -1
		if not number_in(w.a, 0, 7) or not number_in(w.b, 0, 7) or w.a == w.b: return -1
		if not number_in(w.progress, -100, 100) or not number_in(w.days, 0, 1000000): return -1
	for entry in s.log:
		if not entry is Dictionary or not entry.has_all(["day", "text"]): return -1
		if not number_in(entry.day, 0, 1000000) or not entry.text is String: return -1
	state = s
	return int(data.player)

func number_in(value, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum
