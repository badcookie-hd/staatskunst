extends SceneTree
var checks = 0
var failures = 0
var game

func _initialize(): call_deferred("run")

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("INPUT FAIL: " + message)

func key(code: Key, pressed: bool):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func blocked(message: String):
	var before: Vector2 = game.map.pan
	game.map.pan_with_keyboard(0.1)
	check(game.map.pan == before, message)

func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.map.set_process(false)
	game.map.ensure_cache()
	game.map.zoom = 10.0
	game.map.pan = Vector2.ZERO
	key(KEY_W, true)
	blocked("No movement before a campaign")
	game.campaign_started = true
	blocked("Main menu blocks held keys")
	game.title_screen.hide()
	key(KEY_W, false)
	for entry in [[KEY_W, Vector2(0, 1)], [KEY_A, Vector2(1, 0)], [KEY_S, Vector2(0, -1)], [KEY_D, Vector2(-1, 0)]]:
		game.map.pan = Vector2.ZERO
		key(entry[0], true)
		game.map.pan_with_keyboard(0.1)
		check(game.map.pan.is_equal_approx(entry[1] * 65.0), "Correct camera direction: " + OS.get_keycode_string(entry[0]))
		key(entry[0], false)
		blocked("Release stops movement")
	game.map.pan = Vector2.ZERO
	key(KEY_W, true)
	for i in range(30): game.map.pan_with_keyboard(1.0 / 30.0)
	var at_30: Vector2 = game.map.pan
	game.map.pan = Vector2.ZERO
	for i in range(144): game.map.pan_with_keyboard(1.0 / 144.0)
	check(game.map.pan.distance_to(at_30) < 0.01 and absf(at_30.length() - 650.0) < 0.01, "Held movement is consistent at 30 and 144 FPS")
	game.map.pan = Vector2.ZERO
	key(KEY_D, true)
	game.map.pan_with_keyboard(0.1)
	check(absf(game.map.pan.length() - 65.0) < 0.01, "Diagonal movement is normalized")
	key(KEY_D, false)
	game.map.pan = Vector2.ZERO
	key(KEY_SHIFT, true)
	game.map.pan_with_keyboard(0.1)
	check(game.map.pan.is_equal_approx(Vector2(0, 130)), "Shift doubles movement speed")
	key(KEY_SHIFT, false)
	key(KEY_S, true)
	blocked("Opposite directions cancel")
	key(KEY_S, false)
	game.show_country_search()
	await process_frame
	blocked("Country search blocks movement while typing")
	game.country_search_window.queue_free()
	await process_frame
	game.show_network()
	await process_frame
	blocked("LAN address dialog blocks movement")
	game.network_window.queue_free()
	await process_frame
	game.show_menu()
	await process_frame
	blocked("Pause menu blocks movement")
	game.get_child(game.get_child_count() - 1).queue_free()
	await process_frame
	for field in [LineEdit.new(), TextEdit.new()]:
		game.add_child(field)
		field.grab_focus()
		blocked("Text entry blocks movement: " + field.get_class())
		field.queue_free()
		await process_frame
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	blocked("Inactive application blocks movement")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	game.map.pan = Vector2.ZERO
	game.map.pan_with_keyboard(0.1)
	check(game.map.pan.is_equal_approx(Vector2(0, 65)), "Movement resumes after closing dialogs and restoring focus")
	game.map.hide()
	blocked("Hidden map blocks movement")
	game.map.show()
	game.map.pan_with_keyboard(1000.0)
	var at_edge: Vector2 = game.map.pan
	blocked("Movement stops at world boundary")
	check(at_edge.y > 65 and at_edge.y < 10000, "World boundary remains finite")
	key(KEY_W, false)
	game.map.pan = Vector2.ZERO
	game.map.set_process(true)
	key(KEY_D, true)
	await process_frame
	await process_frame
	check(game.map.pan.x < 0, "Actual frame loop polls held keys")
	key(KEY_D, false)
	game.map.set_process(false)
	game.queue_free()
	await process_frame
	print("Input checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
