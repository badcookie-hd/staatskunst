extends Control
signal selected(id: int)
const Scenarios = preload("res://scripts/scenarios.gd")
var sim
var selected_id = 0
var player_id = 0
var hovered = -1
var zoom = 1.0
var pan = Vector2.ZERO
var cached_year = 0
var regions: Array = []
var background: Array = []

func _ready():
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hovered = -1; queue_redraw())

func projection(point: Vector2) -> Vector2:
	return Vector2((point.x + 12) * 0.75, 72 - point.y)

func transform_point(point: Vector2) -> Vector2:
	var extent = Vector2(47 * 0.75, 38)
	var scale_factor = minf(size.x / extent.x, size.y / extent.y) * 0.96
	return (projection(point) - extent / 2) * scale_factor * zoom + size / 2 + pan

func center(id: int) -> Vector2:
	var value = Scenarios.get_scenario(sim.year()).countries[id].center
	return Vector2(value[0], value[1])

func ensure_cache():
	if sim == null or cached_year == sim.year(): return
	cached_year = sim.year()
	zoom = 1.0
	pan = Vector2.ZERO
	regions.clear()
	background.clear()
	for ring in Scenarios.all_data().background: background.append(to_points(ring))
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
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE: pan += event.relative
		hovered = hit(event.position)
		tooltip_text = sim.country(hovered).name if hovered >= 0 else "Mausrad: Zoom · Mittlere Maustaste: Karte verschieben"
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var id = hit(event.position)
			if id >= 0: selected.emit(id)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var old_zoom = zoom
			zoom = clampf(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), 1, 4)
			pan = event.position - size / 2 - (event.position - size / 2 - pan) * zoom / old_zoom
			if zoom == 1: pan = Vector2.ZERO
			queue_redraw()

func hit(point: Vector2) -> int:
	ensure_cache()
	for i in range(regions.size()):
		for ring in regions[i]:
			if Geometry2D.is_point_in_polygon(point, screen_polygon(ring)): return i
	return -1

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("10232b"))
	for x in range(0, int(size.x), 48): draw_line(Vector2(x,0), Vector2(x,size.y), Color(0.4,0.65,0.7,0.04))
	for y in range(0, int(size.y), 48): draw_line(Vector2(0,y), Vector2(size.x,y), Color(0.4,0.65,0.7,0.04))
	if sim == null: return
	ensure_cache()
	var setup = Scenarios.get_scenario(sim.year())
	var font = ThemeDB.fallback_font
	for ring in background: draw_colored_polygon(screen_polygon(ring), Color("23343a"))
	for i in range(regions.size()):
		var owner = int(sim.country(i).owner)
		var color = Color(setup.countries[owner].color).darkened(0.33)
		if i == hovered or i == selected_id: color = color.lightened(0.18)
		for ring in regions[i]:
			var points = screen_polygon(ring)
			draw_colored_polygon(points, color)
			var outline = points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, Color("10232b"), 1.2, true)
			if i == selected_id: draw_polyline(outline, Color("e1c381"), 2, true)
	for i in range(regions.size()):
		var pos = transform_point(center(i))
		var full = i in [0,1,2,3,4,5,14,15] or zoom >= 2
		var text_value = sim.country(i).name.to_upper() if full else setup.countries[i].code
		if i == 2 and full: text_value = "GROSSBRITANNIEN"
		var font_size = 11 if full else 9
		var width = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string_outline(font, pos - Vector2(width / 2,0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("122329"))
		draw_string(font, pos - Vector2(width / 2,0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("e7e9df"))
		if int(sim.country(i).owner) == player_id: draw_circle(pos + Vector2(0,7), 2.5, Color("dfc48e"))
	for w in sim.state.wars:
		draw_dashed_line(transform_point(center(int(w.a))), transform_point(center(int(w.b))), Color("efb19b"), 2, 7)
	draw_string(font, Vector2(20,28), "EUROPA / %d" % sim.year(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9eb7bc"))
	draw_string(font, Vector2(20,48), "Mausrad: Zoom · Mittlere Taste: Verschieben", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7e979e"))
	draw_string(font, transform_point(Vector2(-8,49)), "ATLANTIK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("64818b"))
	draw_string(font, transform_point(Vector2(2,58)), "NORDSEE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("64818b"))
