extends RefCounted
static var cache: Dictionary = {}

static func all_data() -> Dictionary:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios.json"))
	return cache

static func get_scenario(year: int) -> Dictionary:
	return all_data().scenarios[str(year)]

static func available(year: int) -> bool:
	return year in [1936, 2026]
