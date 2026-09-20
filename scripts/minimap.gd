extends Control
var world_map
var dragging = false
var last_view: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Minikarte · Klicken oder ziehen: Kartenausschnitt versetzen"

func map_rect() -> Rect2:
	return Rect2(Vector2(7, 25), size - Vector2(14, 32))

func project(point: Vector2) -> Vector2:
	return map_rect().position + Vector2((point.x + 180) / 360, (90 - point.y) / 180) * map_rect().size

func navigate(point: Vector2):
	var fraction = ((point - map_rect().position) / map_rect().size).clamp(Vector2.ZERO, Vector2.ONE)
	var geo = Vector2(fraction.x * 360 - 180, 90 - fraction.y * 180)
	world_map.zoom = maxf(world_map.zoom, 4.0)
	world_map.pan = -world_map.projection(geo) * world_map.map_scale() * world_map.zoom
	world_map.clamp_pan()
	world_map.hovered = -1
	world_map.hovered_reference = ""
	world_map.queue_redraw()
	queue_redraw()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed and map_rect().has_point(event.position)
			if dragging: navigate(event.position)
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			world_map.zoom_at(world_map.size / 2, 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT: navigate(event.position)
		else: dragging = false
		accept_event()

func _process(_delta):
	if not is_visible_in_tree() or world_map == null: return
	var view = [world_map.pan, world_map.zoom, world_map.size, world_map.cached_year]
	if view != last_view:
		last_view = view
		queue_redraw()

func viewport_rect() -> Rect2:
	var start = project(world_map.geographic(Vector2.ZERO))
	var end = project(world_map.geographic(world_map.size))
	return Rect2(start, end - start).intersection(map_rect())

func _draw():
	if world_map == null: return
	var box = StyleBoxFlat.new()
	box.bg_color = Color("15212bf5")
	box.border_color = Color("8e886e")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	draw_string(ThemeDB.fallback_font, Vector2(9, 17), "WELTÜBERSICHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d8c597"))
	draw_rect(map_rect(), Color("0c233d"))
	for entry in world_map.world:
		for ring in entry.rings:
			var bounds = world_map.cache_bounds(ring)
			if bounds.size.x / 360 * map_rect().size.x < 1.5: continue
			var key = hash(ring)
			if world_map.ring_meshes.has(key):
				var scale_value = map_rect().size.x / 360
				draw_mesh(world_map.ring_meshes[key], null, Transform2D(Vector2(scale_value, 0), Vector2(0, -scale_value), project(Vector2.ZERO)), Color("708778"))
				continue
			var outline = PackedVector2Array()
			var step = maxi(1, ring.size() / 90)
			for i in range(0, ring.size(), step): outline.append(project(ring[i]))
			outline.append(outline[0])
			draw_polyline(outline, Color("87988b"), 0.65, true)
	var view = viewport_rect()
	if view.has_area():
		draw_rect(view, Color(0.91, 0.78, 0.48, 0.14))
		draw_rect(view, Color("f2d58e"), false, 1.5)
