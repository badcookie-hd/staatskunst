extends Control
signal selected(id: int)
signal reference_selected(country_name: String)
const Scenarios = preload("res://scripts/scenarios.gd")
var sim
var settings
var selected_id = 0
var player_id = 0
var hovered = -1
var zoom = 1.0
var pan = Vector2.ZERO
var cached_year = 0
var regions: Array = []
var background: Array = []
var world: Array = []
var mode = "political"
var previous_size = Vector2.ZERO
const PALETTE = ["7c8669", "a38b68", "8d7775", "758b83", "93947b", "b09a78", "778b96", "938769"]

func _ready():
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	previous_size = size
	resized.connect(preserve_view_on_resize)
	mouse_exited.connect(func(): hovered = -1; queue_redraw())
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
		if hovered >= 0: tooltip_text = sim.country(hovered).name + " · Kampagnenland"
		else:
			var reference = reference_at(event.position)
			tooltip_text = reference + " · Kartenregion, derzeit nicht spielbar" if not reference.is_empty() else "Mausrad: Zoom · Rechts / Mitte ziehen: Karte verschieben"
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var id = hit(event.position)
			if id >= 0: selected.emit(id)
			else:
				var reference = reference_at(event.position)
				if not reference.is_empty(): reference_selected.emit(reference)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]: zoom_at(event.position, 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1)

func hit(point: Vector2) -> int:
	ensure_cache()
	for i in range(regions.size()):
		for ring in regions[i]:
			if Geometry2D.is_point_in_polygon(point, screen_polygon(ring)): return i
	return -1

func reference_at(point: Vector2) -> String:
	for entry in world:
		for ring in entry.rings:
			if Geometry2D.is_point_in_polygon(point, screen_polygon(ring)): return entry.name
	return ""

func country_shape(ring: PackedVector2Array, color: Color, border: Color, width: float = 0.8):
	var points = screen_polygon(ring)
	var bounds = Rect2(points[0], Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	if not bounds.intersects(Rect2(Vector2.ZERO, size)): return
	draw_colored_polygon(points, color)
	var outline = points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, border, width, true)

func map_text(pos: Vector2, value: String, font_size: int, color: Color):
	if not Rect2(Vector2.ZERO, size).has_point(pos): return
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin = pos - Vector2(width / 2, 0)
	draw_string_outline(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("243039"))
	draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("233a43"))
	# Latitudes and longitudes move with the world, rather than with the screen.
	if settings == null or settings.map_grid:
		for lon in range(-180,181,30): draw_line(transform_point(Vector2(lon,-90)), transform_point(Vector2(lon,90)), Color(0.6,0.75,0.77,0.1), 1)
		for lat in range(-90,91,30): draw_line(transform_point(Vector2(-180,lat)), transform_point(Vector2(180,lat)), Color(0.6,0.75,0.77,0.1), 1)
	if sim == null: return
	ensure_cache()
	var setup = Scenarios.get_scenario(sim.year())
	for i in range(world.size()):
		var color = Color(PALETTE[i % PALETTE.size()]).darkened(0.12)
		if mode == "diplomatic": color = Color("65716a")
		for ring in world[i].rings: country_shape(ring, color, Color("39463e"))
	for i in range(regions.size()):
		var owner = int(sim.country(i).owner)
		var color = Color(setup.countries[owner].color).darkened(0.16)
		if mode == "diplomatic":
			color = Color("b9a36a") if owner == player_id else Color("73958b")
		for war in sim.state.wars:
			var pressured = int(war.b) if war.progress > 0 else int(war.a)
			if owner == pressured: color = color.lerp(Color("ac5f4d"), absf(war.progress) / 110.0)
		if i == hovered or i == selected_id: color = color.lightened(0.16)
		for ring in regions[i]: country_shape(ring, color, Color("ecd8a0") if i == selected_id else Color("344236"), 2.0 if i == selected_id else 1.0)
	if settings == null or settings.labels:
		for entry in world:
			if sim.year() == 1936 and entry.code in ["CZE", "SVK"]: continue
			if zoom < 2 and entry.code not in ["USA","CAN","BRA","ARG","RUS","CHN","IND","AUS","ZAF","DZA"]: continue
			if zoom >= 2 and entry.code in setup.countries.map(func(c): return c.code): continue
			map_text(transform_point(entry.center), entry.name.to_upper(), 11, Color("d6d6b8"))
		if zoom > 3:
			for i in range(regions.size()):
				var text_value = sim.country(i).name.to_upper() if zoom > 8 else setup.countries[i].code
				map_text(transform_point(center(i)), text_value, 11, Color("fff0c9"))
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
