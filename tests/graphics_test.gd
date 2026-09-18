extends SceneTree
const Settings = preload("res://scripts/settings.gd")
var failures = 0
var checks = 0
var game

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("GRAPHICS FAIL: " + message)

func _initialize(): call_deferred("run")

func frame():
	await process_frame
	await process_frame

func find_button(node: Node, text: String):
	if node is BaseButton and node.get("text") == text: return node
	for child in node.get_children():
		var found = find_button(child, text)
		if found: return found
	return null

func shot(file: String):
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + file + ".png")

func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	check(game.title_screen.visible and not game.campaign_started, "Startup is a real main menu")
	check(find_button(game.title_screen, "Partie fortsetzen").disabled, "Resume requires a campaign")
	await shot("screen-main-menu")
	root.size = Vector2i(1152, 720)
	await frame()
	var exit_button = find_button(game.title_screen, "Spiel beenden")
	if exit_button == null: exit_button = find_button(game.title_screen, "Beenden")
	check(exit_button != null and exit_button.get_global_rect().end.y <= 720, "Main menu fits minimum height")
	find_button(game.title_screen, "Einstellungen").pressed.emit()
	await frame()
	check(game.settings_window.visible, "Settings accessible before campaign")
	check(game.settings_window.size.y < 650 and game.settings_window.position.y + game.settings_window.size.y <= 720, "Settings fit minimum viewport height")
	await shot("screen-settings")
	var toggle = find_button(game.settings_window, "Ländernamen anzeigen")
	var original = toggle.button_pressed
	toggle.button_pressed = not original
	var restored = Settings.new()
	restored.read()
	check(restored.labels == not original and game.map.settings.labels == not original, "Map setting applied and persisted")
	toggle.button_pressed = original
	game.settings_window.queue_free()
	await frame()
	find_button(game.title_screen, "Neue Kampagne").pressed.emit()
	await frame()
	check(game.modal.size.y < 680, "Scenario selection fits minimum viewport")
	var country_button = find_button(game.modal, "Deutschland")
	if country_button == null: country_button = find_button(game.modal, "Deutsches Reich")
	country_button.pressed.emit()
	await frame()
	game.show_menu()
	await frame()
	var pause_menu = game.get_child(game.get_child_count() - 1)
	check(pause_menu is AcceptDialog and pause_menu.size.y < 680, "Pause menu fits minimum viewport")
	pause_menu.queue_free()
	root.size = Vector2i(1440, 900)
	await frame()
	check(game.campaign_started and not game.title_screen.visible and not game.detail_panel.visible, "Campaign opens on unobstructed world map")
	check(game.map.world.size() == 177, "Complete world reference dataset")
	for point in [Vector2(-100,40),Vector2(134,-25),Vector2(-52,-12),Vector2(102,35),Vector2(25,-28)]:
		check(not game.map.reference_at(game.map.transform_point(point)).is_empty(), "Reference continent is present")
		check(game.map.hit(game.map.transform_point(point)) == -1, "Reference regions do not invent playable countries")
	await shot("screen-world")
	var anchor = game.map.transform_point(Vector2.ZERO)
	game.map.zoom_at(anchor, 2)
	check(game.map.zoom > 1 and game.map.transform_point(Vector2.ZERO).distance_to(anchor) < 0.01, "Zoom stays under mouse")
	game.map.focus_country(0)
	check(game.map.zoom == 10 and Rect2(Vector2.ZERO,game.map.size).has_point(game.map.transform_point(game.map.center(0))), "Focus own country")
	game.tab_buttons[2].pressed.emit()
	await frame()
	check(game.map_area.visible and game.detail_panel.visible, "Map stays visible behind campaign panels")
	check(game.map.transform_point(game.map.center(0)).distance_to(game.map.size / 2) < 2, "Opening a panel preserves geographic focus")
	check(game.content.get_child(1).size.y > 10, "Wrapped panel description remains readable")
	await shot("screen-strategy")
	game.tab_buttons[3].pressed.emit()
	await frame()
	var ledger = VBoxContainer.new()
	game.content.add_child(ledger)
	game.ledger_row(ledger, "Test", 123.4)
	await frame()
	check(ledger.get_child(0).get_child(1).size.x > 30, "Ledger values retain readable width")
	ledger.queue_free()
	await frame()
	await shot("screen-economy")
	find_button(game, "Akte schließen  ×").pressed.emit()
	await frame()
	check(not game.detail_panel.visible, "Closing drawer restores large map")
	game.map.fit_world()
	check(game.map.zoom == 1 and game.map.pan == Vector2.ZERO, "World view reset")
	game.session.running = true
	game.show_main_menu()
	await frame()
	check(not game.session.running and not find_button(game.title_screen,"Partie fortsetzen").disabled, "Menu pauses and allows resume")
	find_button(game.title_screen,"Partie fortsetzen").pressed.emit()
	check(not game.title_screen.visible, "Resume returns to same campaign")
	var config = Settings.new()
	config.fps_limit = 120
	config.zoom_speed = 1.7
	config.map_grid = false
	check(config.save("user://graphics-test.cfg") == OK, "Save preference file")
	var copy = Settings.new()
	copy.read("user://graphics-test.cfg")
	check(copy.fps_limit == 120 and is_equal_approx(copy.zoom_speed,1.7) and not copy.map_grid, "Preference round-trip")
	DirAccess.remove_absolute("user://graphics-test.cfg")
	print("GRAPHICS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
