extends Control
signal selected(id: int)
var sim
var selected_id = 0
var player_id = 0
var hovered = -1
const POLYGONS = [
	[Vector2(130,115),Vector2(220,83),Vector2(345,105),Vector2(360,192),Vector2(310,243),Vector2(210,260),Vector2(120,213)],
	[Vector2(345,105),Vector2(410,54),Vector2(493,78),Vector2(530,126),Vector2(510,219),Vector2(425,236),Vector2(360,192)],
	[Vector2(530,126),Vector2(625,104),Vector2(715,139),Vector2(751,212),Vector2(678,251),Vector2(590,239),Vector2(510,219)],
	[Vector2(120,213),Vector2(210,260),Vector2(310,243),Vector2(326,331),Vector2(251,375),Vector2(157,358),Vector2(91,285)],
	[Vector2(360,192),Vector2(425,236),Vector2(510,219),Vector2(590,239),Vector2(568,333),Vector2(500,381),Vector2(411,376),Vector2(326,331),Vector2(310,243)],
	[Vector2(157,358),Vector2(251,375),Vector2(326,331),Vector2(411,376),Vector2(394,457),Vector2(311,495),Vector2(232,455),Vector2(210,401)],
	[Vector2(590,239),Vector2(678,251),Vector2(751,212),Vector2(796,304),Vector2(739,351),Vector2(727,420),Vector2(642,405),Vector2(568,333)],
	[Vector2(411,376),Vector2(500,381),Vector2(568,333),Vector2(642,405),Vector2(727,420),Vector2(654,480),Vector2(552,502),Vector2(462,474),Vector2(394,457)]
]
const CENTERS = [Vector2(238,177),Vector2(439,152),Vector2(626,186),Vector2(208,307),Vector2(446,301),Vector2(308,417),Vector2(686,327),Vector2(555,435)]

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): hovered = -1; queue_redraw())

func transform_point(point: Vector2) -> Vector2:
	var scale_factor = minf(size.x / 900, size.y / 560)
	return point * scale_factor + (size - Vector2(900,560) * scale_factor) / 2

func polygon(id: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for p in POLYGONS[id]: points.append(transform_point(p))
	return points

func _gui_input(event):
	if event is InputEventMouseMotion:
		hovered = hit(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id = hit(event.position)
		if id >= 0: selected.emit(id)

func hit(point: Vector2) -> int:
	for i in range(8):
		if Geometry2D.is_point_in_polygon(point, polygon(i)): return i
	return -1

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("10232b"))
	for x in range(0, int(size.x), 48): draw_line(Vector2(x,0), Vector2(x,size.y), Color(0.4,0.65,0.7,0.045))
	for y in range(0, int(size.y), 48): draw_line(Vector2(0,y), Vector2(size.x,y), Color(0.4,0.65,0.7,0.045))
	if sim == null: return
	var font = ThemeDB.fallback_font
	for i in range(8):
		var owner = int(sim.country(i).owner)
		var color = Color(sim.COLORS[owner]).darkened(0.40)
		if i == hovered: color = color.lightened(0.13)
		if i == selected_id: color = color.lightened(0.15)
		var points = polygon(i)
		draw_colored_polygon(points, color)
		var outline = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, Color("132b32"), 3, true)
		if i == selected_id: draw_polyline(outline, Color("e1c381"), 2.5, true)
		var center = transform_point(CENTERS[i])
		var text_value = sim.country(i).name.to_upper()
		var font_size = 14 if size.x > 720 else 11
		var width = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, center - Vector2(width / 2, 0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("e7e9df"))
		draw_circle(center + Vector2(0, 17), 3, Color("dfc48e") if owner == player_id else Color("b4c6c7"))
		if owner == player_id: draw_arc(center + Vector2(0,17), 7, 0, TAU, 24, Color("dfc48e"), 1.0, true)
	for w in sim.state.wars:
		var start = transform_point(CENTERS[int(w.a)])
		var end = transform_point(CENTERS[int(w.b)])
		draw_dashed_line(start, end, Color("efb19b"), 2, 7)
		var mid = (start + end) / 2
		draw_circle(mid, 13, Color("392b2b"))
		draw_string(font, mid + Vector2(-4,5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffccb0"))
	draw_string(font, transform_point(Vector2(43,440)), "WESTLICHES MEER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("64818b"))
	draw_string(font, transform_point(Vector2(635,70)), "NORDSEE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("64818b"))
	var compass = Vector2(size.x - 45, size.y - 45)
	draw_line(compass - Vector2(0,17), compass + Vector2(0,17), Color("58737b"), 1)
	draw_line(compass - Vector2(17,0), compass + Vector2(17,0), Color("58737b"), 1)
	draw_string(font, compass + Vector2(-4,-24), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a5b9b9"))
