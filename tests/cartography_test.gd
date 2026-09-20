extends SceneTree
var game
var checks = 0
var failures = 0

func _initialize(): call_deferred("run")

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("CARTOGRAPHY FAIL: " + message)

func frame():
	await process_frame
	await process_frame

func shot(name_value: String):
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name_value + ".png")

func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.title_screen.hide()
	game.campaign_started = true
	game.session.solo(0, 2026)
	game.panel_open = false
	game.refresh()
	await frame()
	check(game.map.RELIEF.get_width() == 10800 and game.map.RELIEF.get_height() == 5400, "Offline equirectangular relief texture")
	check(game.map.capitals.size() == 200, "Capital geography loaded")
	check(game.map.country_color("DEU") != game.map.country_color("POL"), "Neighboring major countries remain distinguishable")
	for window_size in [Vector2i(1440, 900), Vector2i(1152, 720)]:
		root.size = window_size
		await frame()
		check(game.map.size.y > root.size.y * 0.70, "Map occupies over 70 percent of viewport height")
		for zoom_value in [1.0, 4.5, 10.0]:
			game.map.zoom = zoom_value
			game.map.pan = -game.map.projection(Vector2(15, 51)) * game.map.map_scale() * zoom_value if zoom_value > 1 else Vector2.ZERO
			game.map.queue_redraw()
			await frame()
			if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
			var collision = false
			for a in range(game.map.label_rects.size()):
				for b in range(a + 1, game.map.label_rects.size()):
					if game.map.label_rects[a].intersects(game.map.label_rects[b]): collision = true
			check(not collision, "Country and city labels do not overlap")
			if window_size.x == 1440:
				await shot("screen-relief-world" if zoom_value == 1 else "screen-relief-europe" if zoom_value == 4.5 else "screen-relief-detail")
	# UV checks do not require the rendering backend to draw a frame.
	var ring = game.map.reference("DEU").rings[0]
	var uv = Vector2((ring[0].x + 180) / 360, (90 - ring[0].y) / 180)
	check(uv.x > 0.5 and uv.x < 0.55 and uv.y > 0.18 and uv.y < 0.3, "German geometry maps to European relief coordinates")
	game.map.focus_country(0)
	game.tab_buttons[2].pressed.emit()
	await frame()
	check(game.detail_panel.visible and game.map.size.x >= 300, "Cabinet and map remain usable at minimum resolution")
	root.size = Vector2i(1440, 900)
	await frame()
	await shot("screen-relief-cabinet")
	print("CARTOGRAPHY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
