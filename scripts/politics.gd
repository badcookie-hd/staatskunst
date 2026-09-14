extends RefCounted
## Identities are scenario data; support, coalitions and portfolio bonuses are game rules.
const ROLES = {"finance": "Finanzen", "economy": "Wirtschaft & Energie", "defense": "Verteidigung", "foreign": "Auswärtiges Amt"}
static var cache: Dictionary = {}

static func roster(year: int, code: String) -> Dictionary:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/politics.json"))
		for countries in cache.values():
			for data in countries.values():
				data.coalition = data.coalition.map(func(value): return int(value))
				for party in data.parties:
					for candidate in party.candidates: candidate.party = int(candidate.party)
	return cache[str(year)][code]

static func initialize(c: Dictionary, year: int):
	var data = roster(year, c.code)
	c.ruling = 0
	c.support = []
	for i in range(data.parties.size()): c.support.append(42.0 if i == 0 else 58.0 / (data.parties.size() - 1))
	c.coalition = data.coalition.duplicate()
	c.head_name = data.head
	c.head_title = data.head_title
	c.premier = data.premier
	c.premier_title = data.premier_title
	c.cabinet = {}
	fill_cabinet(c, year)
	for role in data.get("cabinet", {}):
		for person in candidates(year, c.code):
			if person.name == data.cabinet[role]: c.cabinet[role] = person.id

static func candidates(year: int, code: String) -> Array:
	var result: Array = []
	for p in roster(year, code).parties: result.append_array(p.candidates)
	return result

static func person(year: int, code: String, id: String) -> Dictionary:
	for candidate in candidates(year, code):
		if candidate.id == id: return candidate
	return {}

static func fill_cabinet(c: Dictionary, year: int):
	c.cabinet = {"finance": "", "economy": "", "defense": "", "foreign": ""}
	for role in ROLES:
		var pool = candidates(year, c.code)
		pool.sort_custom(func(a, b):
			var score_a = (4 if int(a.party) == int(c.ruling) else 0) + (2 if a.focus == role else 0)
			var score_b = (4 if int(b.party) == int(c.ruling) else 0) + (2 if b.focus == role else 0)
			return score_a > score_b if score_a != score_b else a.id < b.id)
		for candidate in pool:
			if candidate.party not in c.coalition or candidate.name == c.premier or candidate.name == c.head_name: continue
			if candidate.id in c.cabinet.values(): continue
			c.cabinet[role] = candidate.id
			break

static func bonus(c: Dictionary, year: int, role: String) -> float:
	var p = person(year, c.code, c.cabinet.get(role, ""))
	if p.is_empty(): return 0.0
	return 0.12 if p.focus == role else 0.04

static func form_government(c: Dictionary, year: int, party: int):
	var old_premier = c.premier
	c.ruling = party
	c.premier = roster(year, c.code).parties[party].candidates[0].name
	if c.head_name == old_premier: c.head_name = c.premier
	fill_cabinet(c, year)

static func coalition_support(c: Dictionary) -> float:
	var total = 0.0
	for i in c.coalition: total += c.support[int(i)]
	return total
