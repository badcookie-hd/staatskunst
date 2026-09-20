extends RefCounted
## Offline, dated reference information. Never participates in simulation commands.
static var _countries: Dictionary = {}

static func countries() -> Dictionary:
	if _countries.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_profiles.json"))
		for entry in data.countries: _countries[entry.code] = entry
	return _countries

static func country(code: String) -> Dictionary:
	return countries().get(code, {})

static func search(query: String) -> Array:
	var results: Array = []
	query = query.strip_edges().to_lower()
	for entry in countries().values():
		if query.is_empty() or query in (entry.name + " " + entry.english + " " + entry.code).to_lower(): results.append(entry)
	results.sort_custom(func(a,b): return a.name.naturalnocasecmp_to(b.name) < 0)
	return results
