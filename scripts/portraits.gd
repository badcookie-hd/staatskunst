extends RefCounted
## Offline portrait catalogue. Photos retain the licenses recorded in portraits.json.
static var _catalogue: Dictionary = {}
static var _textures: Dictionary = {}

static func catalogue() -> Dictionary:
	if _catalogue.is_empty():
		_catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits.json"))
		if FileAccess.file_exists("res://data/world_portraits.json"):
			var atlas = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_portraits.json"))
			_catalogue.merge(atlas, false)
	return _catalogue

static func credit(person: Dictionary) -> Dictionary:
	return catalogue().get(person.get("name", ""), {})

static func texture(person: Dictionary) -> Texture2D:
	var key: String = person.get("name", "")
	if _textures.has(key): return _textures[key]
	var result: Texture2D
	if person.get("fictional", false) and person.has("portrait"):
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/cfd-portraits.png")
		var cell = atlas.atlas.get_size() / Vector2(3, 2)
		var index = int(person.portrait)
		atlas.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		result = atlas
	else:
		var entry = credit(person)
		if entry.has("file"): result = load(entry.file)
	if result != null: _textures[key] = result
	return result
