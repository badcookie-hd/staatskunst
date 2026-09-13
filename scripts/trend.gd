extends Control
var values: Array = []
var line_color = Color("70c6b3")
var caption = ""

func _ready():
	custom_minimum_size = Vector2(180, 125)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _draw():
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(8, 18), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a1b2c5"))
	for y in [40, 70, 100]: draw_line(Vector2(8, y), Vector2(size.x - 8, y), Color("2a3b50"))
	if values.size() < 2:
		draw_string(font, Vector2(8, 70), "Verlauf entsteht mit der Spielzeit", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a1b2c5"))
		return
	var low = float(values.min())
	var high = float(values.max())
	var points = PackedVector2Array()
	for i in range(values.size()): points.append(Vector2(8 + (size.x - 16) * i / (values.size() - 1), 103 - (float(values[i]) - low) / maxf(1, high - low) * 62))
	draw_polyline(points, line_color, 2.5, true)
	draw_circle(points[-1], 4, line_color)
	draw_string(font, Vector2(8, 122), "%.1f → %.1f" % [values[0], values[-1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, line_color)
