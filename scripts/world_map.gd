extends Control
signal selected(id: int)
signal reference_selected(code: String)
const Scenarios = preload("res://scripts/scenarios.gd")
var sim
var settings
var selected_id = 0
var player_id = 0
var hovered = -1
var hovered_reference = ""
var selected_reference = ""
var label_rects: Array[Rect2] = []
var drawn_labels: Array[String] = []
var ring_bounds: Dictionary = {}
var ring_meshes: Dictionary = {}
var tiny_regions: Array = []
var zoom = 1.0
var pan = Vector2.ZERO
var cached_year = 0
var regions: Array = []
var background: Array = []
var world: Array = []
var mode = "political"
var previous_size = Vector2.ZERO
const PALETTE = ["738783", "82938d", "758d96", "929c94", "7c8991", "88978a"]

func _ready():
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	previous_size = size
	resized.connect(preserve_view_on_resize)
	mouse_exited.connect(func(): hovered = -1; hovered_reference = ""; queue_redraw())
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	for entry in data.countries:
		var rings = []
		for ring in entry.polygons:
			var points = to_points(ring)
			if not Geometry2D.triangulate_polygon(points).is_empty(): rings.append(points)
			else:
				# Normalize self-touching source outlines; discard only zero-area remnants.
				for repaired in Geometry2D.merge_polygons(points, points):
					if not Geometry2D.triangulate_polygon(repaired).is_empty(): rings.append(repaired)
		world.append({"code":entry.code, "name":entry.name, "center":Vector2(entry.center[0],entry.center[1]), "rings":rings})
		for ring in rings: cache_bounds(ring)
		var area = 0.0
		for ring in rings: area += cache_bounds(ring).get_area()
		if area < 0.08: tiny_regions.append(world.back())

func cache_bounds(ring: PackedVector2Array) -> Rect2:
	var key = hash(ring)
	if ring_bounds.has(key): return ring_bounds[key]
	var bounds = Rect2(ring[0], Vector2.ZERO)
	for point in ring: bounds = bounds.expand(point)
	ring_bounds[key] = bounds
	return bounds

func reference(code: String) -> Dictionary:
	for entry in world:
		if entry.code == code: return entry
	return {}

func focus_reference(code: String):
	var entry = reference(code)
	if entry.is_empty(): return
	zoom = 6.0
	pan = -projection(entry.center) * map_scale() * zoom
	clamp_pan()
	queue_redraw()

func geographic(point: Vector2) -> Vector2:
	return projection((point - size / 2 - pan) / (map_scale() * zoom))

func projection(point: Vector2) -> Vector2:
	return Vector2(point.x, -point.y)

func preserve_view_on_resize():
	var old_scale = minf(previous_size.x / 360.0, previous_size.y / 180.0) * 0.96
	if old_scale > 0: pan *= map_scale() / old_scale
	previous_size = size
	clamp_pan()
	queue_redraw()

func map_scale() -> float:
	return minf(size.x / 360.0, size.y / 180.0) * 0.96

func transform_point(point: Vector2) -> Vector2:
	return projection(point) * map_scale() * zoom + size / 2 + pan

func center(id: int) -> Vector2:
	var value = Scenarios.get_scenario(sim.year()).countries[id].center
	return Vector2(value[0], value[1])

func fit_world():
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()

func focus_country(id: int):
	ensure_cache()
	zoom = 10.0
	pan = -projection(center(id)) * map_scale() * zoom
	clamp_pan()
	queue_redraw()

func clamp_pan():
	var extent = Vector2(360, 180) * map_scale() * zoom / 2
	var limit = (extent - size / 2 + Vector2(80, 80)).max(Vector2.ZERO)
	pan.x = clampf(pan.x, -limit.x, limit.x)
	pan.y = clampf(pan.y, -limit.y, limit.y)

func zoom_at(point: Vector2, direction: float):
	var old_zoom = zoom
	zoom = clampf(zoom * pow(1.2, direction * (settings.zoom_speed if settings else 1.0)), 1.0, 24.0)
	pan = point - size / 2 - (point - size / 2 - pan) * zoom / old_zoom
	if zoom == 1.0: pan = Vector2.ZERO
	clamp_pan()
	queue_redraw()

func ensure_cache():
	if sim == null or cached_year == sim.year(): return
	cached_year = sim.year()
	fit_world()
	regions.clear()
	for c in Scenarios.get_scenario(cached_year).countries:
		var rings: Array = []
		var detailed = reference(c.code)
		if not detailed.is_empty() and (cached_year != 1936 or c.code not in ["DEU", "POL", "CSK", "ITA"]):
			regions.append(detailed.rings)
			continue
		for ring in c.polygons:
			var points = to_points(ring)
			var merged = false
			for index in range(rings.size()):
				var union = Geometry2D.merge_polygons(rings[index], points)
				if union.size() == 1:
					rings[index] = union[0]
					merged = true
					break
			if not merged: rings.append(points)
		regions.append(rings)
		for ring in rings: cache_bounds(ring)

func to_points(ring: Array) -> PackedVector2Array:
	var points = PackedVector2Array()
	for p in ring: points.append(Vector2(p[0], p[1]))
	return points

func screen_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var transformed = PackedVector2Array()
	for p in points: transformed.append(transform_point(p))
	return transformed

func _gui_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_MIDDLE | MOUSE_BUTTON_MASK_RIGHT):
			pan += event.relative
			clamp_pan()
		hovered = hit(event.position)
		hovered_reference = reference_code_at(event.position) if hovered < 0 else ""
		if hovered >= 0: tooltip_text = sim.country(hovered).name + " · Kampagnenland"
		else:
			var entry = reference(hovered_reference)
			tooltip_text = entry.name + " · Klicken: Länderakte" if not entry.is_empty() else "Mausrad: Zoom · Rechts / Mitte ziehen: Karte verschieben"
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var id = hit(event.position)
			if id >= 0: selected.emit(id)
			else:
				var code = reference_code_at(event.position)
				if not code.is_empty(): reference_selected.emit(code)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]: zoom_at(event.position, 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1)

func hit(point: Vector2) -> int:
	ensure_cache()
	if zoom >= 2:
		for entry in tiny_regions:
			if transform_point(entry.center).distance_to(point) < 8: return -1
	var geo = geographic(point)
	for i in range(regions.size()):
		for ring in regions[i]:
			if cache_bounds(ring).has_point(geo) and Geometry2D.is_point_in_polygon(geo, ring): return i
	return -1

func reference_at(point: Vector2) -> String:
	return reference(reference_code_at(point)).get("name", "")

func reference_code_at(point: Vector2) -> String:
	if zoom >= 2:
		for entry in tiny_regions:
			if transform_point(entry.center).distance_to(point) < 8: return entry.code
	var geo = geographic(point)
	for entry in world:
		for ring in entry.rings:
			if cache_bounds(ring).has_point(geo) and Geometry2D.is_point_in_polygon(geo, ring): return entry.code
	# Small islands and microstates also have a minimum clickable marker.
	if zoom >= 2:
		var nearest = ""
		var distance = 8.0
		for entry in world:
			var d = transform_point(entry.center).distance_to(point)
			if d < distance: nearest = entry.code; distance = d
		return nearest
	return ""

func country_shape(ring: PackedVector2Array, color: Color, border: Color, width: float = 0.8):
	var geo_bounds = cache_bounds(ring)
	var bounds = Rect2(transform_point(Vector2(geo_bounds.position.x, geo_bounds.end.y)), geo_bounds.size * map_scale() * zoom)
	if not bounds.grow(2).intersects(Rect2(Vector2.ZERO, size)): return
	var points = screen_polygon(ring)
	var key = hash(ring)
	if not ring_meshes.has(key):
		var indices = Geometry2D.triangulate_polygon(ring)
		if indices.is_empty(): return
		var vertices = PackedVector3Array()
		for point in ring: vertices.append(Vector3(point.x, point.y, 0))
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		ring_meshes[key] = mesh
	var scale_value = map_scale() * zoom
	draw_mesh(ring_meshes[key], null, Transform2D(Vector2(scale_value, 0), Vector2(0, -scale_value), size / 2 + pan), color)
	if bounds.size.x < 1 or bounds.size.y < 1: return
	var outline = points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, border, width, true)

func country_color(code: String) -> Color:
	var index = 0
	for letter in code.to_utf8_buffer(): index = (index * 31 + letter) % PALETTE.size()
	return Color(PALETTE[index])

func country_label(pos: Vector2, value: String, priority: bool = false):
	var short_names = {"Vereinigte Staaten": "USA", "Volksrepublik China": "China", "Vereinigtes Königreich": "Großbritannien", "Demokratische Republik Kongo": "DR Kongo", "Zentralafrikanische Republik": "Zentralafrika", "Bosnien und Herzegowina": "Bosnien-Herzegowina"}
	value = short_names.get(value, value)
	var font = ThemeDB.fallback_font
	var font_size = 16 if priority else 14
	var text_size = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect = Rect2(pos - Vector2(text_size.x / 2 + 6, 17), Vector2(text_size.x + 12, 25))
	if not Rect2(Vector2(12, 12), size - Vector2(24, 50)).encloses(rect): return
	for occupied in label_rects:
		if occupied.grow(5).intersects(rect): return
	label_rects.append(rect)
	drawn_labels.append(value)
	if priority: draw_style_box(label_style(), rect.grow(2))
	map_text(pos, value, font_size, Color("fff0ca") if priority else Color("eaf0ed"))

func label_style() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.11, 0.14, 0.88)
	box.set_corner_radius_all(3)
	return box

func draw_country_labels(setup: Dictionary):
	label_rects.clear()
	drawn_labels.clear()
	var campaign_codes = setup.countries.map(func(c): return c.code)
	if selected_reference != "":
		var entry = reference(selected_reference)
		if not entry.is_empty(): country_label(transform_point(entry.center), entry.name, true)
	elif selected_id >= 0: country_label(transform_point(center(selected_id)), sim.country(selected_id).name, true)
	if hovered >= 0: country_label(transform_point(center(hovered)), sim.country(hovered).name, true)
	elif hovered_reference != "":
		var entry = reference(hovered_reference)
		if not entry.is_empty(): country_label(transform_point(entry.center), entry.name, true)
	var candidates: Array = []
	for entry in world:
		if entry.code in campaign_codes or (sim.year() == 1936 and entry.code in ["CZE", "SVK"]): continue
		var area = 0.0
		for ring in entry.rings: area = maxf(area, cache_bounds(ring).get_area())
		candidates.append({"name":entry.name,"center":entry.center,"area":area})
	for i in range(regions.size()):
		var area = 0.0
		for ring in regions[i]: area = maxf(area, cache_bounds(ring).get_area())
		candidates.append({"name":sim.country(i).name,"center":center(i),"area":area})
	candidates.sort_custom(func(a,b): return a.area > b.area)
	for item in candidates:
		if item.area * pow(map_scale() * zoom, 2) < 1800: continue
		country_label(transform_point(item.center), item.name)

func map_text(pos: Vector2, value: String, font_size: int, color: Color):
	if not Rect2(Vector2.ZERO, size).has_point(pos): return
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin = pos - Vector2(width / 2, 0)
	draw_string_outline(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("243039"))
	draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw():
	for y in range(0, int(size.y), 4):
		draw_rect(Rect2(0, y, size.x, 4), Color("172c3b").lerp(Color("263f4c"), float(y) / maxf(size.y, 1)))
	# Latitudes and longitudes move with the world, rather than with the screen.
	if settings == null or settings.map_grid:
		for lon in range(-180,181,30): draw_line(transform_point(Vector2(lon,-90)), transform_point(Vector2(lon,90)), Color(0.6,0.75,0.77,0.045), 1)
		for lat in range(-90,91,30): draw_line(transform_point(Vector2(-180,lat)), transform_point(Vector2(180,lat)), Color(0.6,0.75,0.77,0.045), 1)
	if sim == null: return
	ensure_cache()
	var setup = Scenarios.get_scenario(sim.year())
	for i in range(world.size()):
		var color = country_color(world[i].code)
		if mode == "diplomatic": color = Color("64777f")
		var active = world[i].code == selected_reference
		if active or world[i].code == hovered_reference: color = color.lightened(0.18)
		for ring in world[i].rings: country_shape(ring, color, Color("efd398") if active else Color("3a5057"), 2.0 if active else 0.85)
	for i in range(regions.size()):
		var owner = int(sim.country(i).owner)
		var color = country_color(setup.countries[owner].code)
		if mode == "diplomatic":
			color = Color("b9a36a") if owner == player_id else Color("73958b")
		for war in sim.state.wars:
			var pressured = int(war.b) if war.progress > 0 else int(war.a)
			if owner == pressured: color = color.lerp(Color("ac5f4d"), absf(war.progress) / 110.0)
		var active = i == selected_id and selected_reference.is_empty()
		if i == hovered or active: color = color.lightened(0.16)
		for ring in regions[i]: country_shape(ring, color, Color("efd398") if active else Color("3a5057"), 2.0 if active else 0.85)
	if zoom >= 2:
		for entry in tiny_regions:
			var position_value = transform_point(entry.center)
			if Rect2(Vector2.ZERO, size).has_point(position_value):
				draw_circle(position_value, 4, Color("192c36"))
				draw_circle(position_value, 2, Color("e2c28a"))
	if settings == null or settings.labels:
		draw_country_labels(setup)
	else:
		label_rects.clear()
		drawn_labels.clear()
	for w in sim.state.wars:
		var start = transform_point(center(int(w.a)))
		var end = transform_point(center(int(w.b)))
		if w.progress < 0:
			var swap = start
			start = end
			end = swap
		draw_dashed_line(start, end, Color("e78d68"), 2, 7)
		if settings == null or settings.animations:
			var phase = fmod(Time.get_ticks_msec() / 2400.0, 1.0)
			for i in range(3): draw_circle(start.lerp(end, fmod(phase + i / 3.0, 1)), 3, Color("ffdbb2"))
		map_text(start.lerp(end,0.5) + Vector2(0,-12), "%.0f %% · %d T" % [absf(w.progress), w.days], 12, Color("ffe1b2"))
	map_text(Vector2(size.x / 2, size.y - 18), "WELTKARTE / %d · %s · WELT: REFERENZGRENZEN" % [sim.year(), "POLITISCH" if mode == "political" else "KAMPAGNENLÄNDER"], 10, Color("c5c5a9"))
	# Compass rose, kept in the corner at every zoom level.
	var compass = Vector2(size.x-34,42)
	draw_line(compass-Vector2(0,16),compass+Vector2(0,16),Color("c8bb91"),1)
	draw_line(compass-Vector2(12,0),compass+Vector2(12,0),Color("c8bb91"),1)
	draw_circle(compass, 5, Color("c8bb91"), false, 1)
	map_text(compass-Vector2(0,22),"N",10,Color("c8bb91"))

func _process(_delta):
	if sim != null and not sim.state.wars.is_empty() and is_visible_in_tree() and (settings == null or settings.animations): queue_redraw()
