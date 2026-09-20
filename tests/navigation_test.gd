extends SceneTree
var checks = 0
var failures = 0
var game
func _initialize(): call_deferred("run")
func check(ok: bool, text: String):
	checks += 1
	if not ok: failures += 1; printerr("NAVIGATION FAIL: " + text)
func frame():
	await process_frame
	await process_frame
func mouse(point: Vector2, pressed: bool):
	var event = InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event)
func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.title_screen.hide()
	game.campaign_started = true
	game.session.solo(0, 2026)
	game.preferences.minimap = true
	game.panel_open = false
	game.refresh()
	await frame()
	var mini = game.map.minimap
	check(mini.visible and Rect2(Vector2.ZERO, game.map.size).encloses(mini.get_rect()), "Minimap fits the map")
	var target = Vector2(134, -25)
	var screen_point = mini.global_position + mini.project(target)
	mouse(screen_point, true)
	mouse(screen_point, false)
	await frame()
	check(game.map.zoom >= 3 and game.map.geographic(game.map.size / 2).distance_to(target) < 0.1, "Real minimap click centers on Australia")
	check(not game.panel_open and game.reference_code.is_empty(), "Minimap click does not select a country underneath")
	check(not mini.dragging, "Mouse release ends minimap drag")
	mouse(mini.global_position + mini.project(target), true)
	var motion = InputEventMouseMotion.new()
	motion.position = mini.global_position + mini.project(Vector2(25, 0))
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion)
	mouse(motion.position, false)
	await frame()
	check(game.map.geographic(game.map.size / 2).distance_to(Vector2(25, 0)) < 0.1, "Real minimap drag moves view to Africa")
	check(not mini.dragging and not game.panel_open, "Dragging ends without opening a country file")
	mini.navigate(mini.project(Vector2(-100, 40)))
	check(game.map.geographic(game.map.size / 2).distance_to(Vector2(-100, 40)) < 0.1, "Can navigate back across the world")
	check(mini.map_rect().encloses(mini.viewport_rect()), "Viewport indicator stays inside overview")
	var before = mini.viewport_rect().size
	game.map.zoom_at(game.map.size / 2, 2)
	check(mini.viewport_rect().size.x < before.x, "Viewport indicator shrinks when zooming in")
	game.map_mode_button.pressed.emit()
	check(game.map.mode == "diplomatic" and game.map_mode_button.text == "Beziehungen", "Mode button describes active mode")
	game.map_mode_button.pressed.emit()
	game.map.focus_reference("VAT")
	check(game.map.reference_code_at(game.map.transform_point(game.map.reference("VAT").center)) == "VAT", "Microstate selection remains usable")
	for window_size in [Vector2i(1440, 900), Vector2i(1152, 720)]:
		root.size = window_size
		await frame()
		for zoom_value in [1.0, 4.5, 10.0]:
			game.map.zoom = zoom_value
			game.map.pan = -game.map.projection(Vector2(15, 51)) * game.map.map_scale() * zoom_value if zoom_value > 1 else Vector2.ZERO
			game.map.queue_redraw()
			await frame()
			if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
			var inside = true
			for entry in game.map.drawn_label_locations:
				if not game.map.inside_rings(entry.point, entry.rings): inside = false
			check(inside, "Country labels stay on their own land")
			if DisplayServer.get_name() != "headless":
				check(not game.map.drawn_label_locations.is_empty(), "Renderer produced labels to validate")
	game.panel_open = true
	game.refresh()
	await frame()
	check(Rect2(Vector2.ZERO, game.map.size).encloses(mini.get_rect()), "Minimap fits beside open drawer at minimum width")
	check(game.map_mode_button.get_global_rect().end.x <= game.map.get_global_rect().end.x + 1, "Toolbar fits at minimum map width")
	game.preferences.minimap = false
	game.map.update_minimap_layout()
	check(not mini.visible, "Minimap can be hidden")
	game.preferences.save("user://navigation-test.cfg")
	var restored = game.Settings.new()
	restored.read("user://navigation-test.cfg")
	check(not restored.minimap, "Minimap preference round-trips")
	DirAccess.remove_absolute("user://navigation-test.cfg")
	game.preferences.minimap = true
	root.size = Vector2i(1440,900)
	game.panel_open = false
	game.refresh()
	await frame()
	game.map.zoom = 4.5
	game.map.pan = -game.map.projection(Vector2(15, 51)) * game.map.map_scale() * 4.5
	game.map.queue_redraw()
	await frame()
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screen-navigation.png")
	print("NAVIGATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
