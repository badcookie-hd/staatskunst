extends RefCounted
## Abstract alternate-history game rules, not a model of lawful abolition of democracy.
const TITLES = {"crisis": "Verfassungskrise auslösen", "centralize": "Macht zentralisieren", "dictatorship": "Diktatur ausrufen", "defend": "Verfassung verteidigen"}
const COSTS = {"crisis": 100.0, "centralize": 100.0, "dictatorship": 150.0, "defend": 60.0}

static func initialize(c: Dictionary, year: int):
	c.law = {"name": "Grundgesetz" if c.code == "DEU" and year == 2026 else "Verfassungsordnung", "stage": 0 if c.democratic else 3, "rule_of_law": 100.0 if c.democratic else 20.0, "press": 100.0 if c.democratic else 15.0, "resistance": 0.0, "party": -1, "started": 0, "initial_ruling": int(c.ruling), "term_start": 0, "breached": false}

static func reason(c: Dictionary, action: String, day: int, coalition: float) -> String:
	var key = action.trim_prefix("law_")
	if key not in TITLES: return "Unbekannte Verfassungsentscheidung."
	var law = c.law
	if c.influence < COSTS[key]: return "%.0f Einfluss erforderlich." % COSTS[key]
	if key == "defend":
		if not c.democratic: return "Zuerst eine demokratische Verfassung beschließen."
		if int(law.stage) == 0: return "Die demokratische Ordnung ist intakt."
		return ""
	if not c.democratic: return "Der Staat wird bereits autoritär regiert."
	if key == "crisis":
		if int(c.ruling) == int(law.initial_ruling): return "Zuerst eine andere Partei an die Regierung bringen, zum Beispiel AfD oder CfD."
		if int(law.stage) != 0: return "Eine Verfassungskrise läuft bereits."
		if coalition <= 50: return "Die neue Regierung braucht eine Koalitionsmehrheit."
		if day - int(law.term_start) < 15: return "Die neue Regierung muss zunächst 15 Tage im Amt sein."
	else:
		if int(law.party) != int(c.ruling): return "Die Regierung hat gewechselt; der alte Machtpfad ist beendet."
		if int(law.stage) != (1 if key == "centralize" else 2): return "Zuerst die vorherige Stufe des Machtpfads abschließen."
		if day - int(law.started) < 30: return "Der nächste Schritt ist erst nach 30 Tagen möglich."
		if key == "dictatorship" and c.support[int(c.ruling)] < 30: return "Die Regierungspartei braucht im Spiel mindestens 30 % Unterstützung."
	return ""

static func act(c: Dictionary, action: String, day: int) -> String:
	var key = action.trim_prefix("law_")
	c.influence -= COSTS[key]
	var law = c.law
	law.started = day
	match key:
		"defend":
			law.stage = 0
			law.party = -1
			law.rule_of_law = 100.0
			law.press = 100.0
			law.breached = false
			law.resistance = maxf(0, law.resistance - 20)
			c.stability = minf(100, c.stability + 5)
		"crisis":
			law.stage = 1
			law.party = int(c.ruling)
			law.rule_of_law = 65.0
			law.resistance = 20.0
			law.breached = true
			c.stability = maxf(0, c.stability - 8)
		"centralize":
			law.stage = 2
			law.rule_of_law = 35.0
			law.press = 35.0
			law.resistance += 20
			c.stability = maxf(0, c.stability - 10)
		"dictatorship":
			law.stage = 3
			law.rule_of_law = 10.0
			law.press = 10.0
			law.resistance += 20
			c.democratic = false
			c.head_name = c.premier
			c.head_title = "Staatsführer"
			c.premier_title = "Regierungschef"
			c.coalition = [int(c.ruling)]
			c.stability = maxf(0, c.stability - 12)
	return TITLES[key] + " · " + c.name

static func new_government(c: Dictionary, day: int):
	c.law.term_start = day
	if c.democratic and int(c.law.stage) in [1, 2] and int(c.law.party) != int(c.ruling):
		c.law.stage = 0
		c.law.party = -1
		c.law.rule_of_law = 100.0
		c.law.press = 100.0
		c.law.breached = false

static func advance(c: Dictionary):
	if c.law.breached:
		c.law.resistance = clampf(c.law.resistance + (60 - c.stability) / 300.0, 0, 100)
		c.stability = maxf(0, c.stability - c.law.resistance / 2500.0)
	else: c.law.resistance = maxf(0, c.law.resistance - 0.1)
