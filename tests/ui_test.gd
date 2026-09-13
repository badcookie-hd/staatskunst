extends SceneTree
var failures = 0
var checks = 0
var game

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("UI FAIL: " + message)

func _initialize():
	call_deferred("run")

func find_button(node: Node, caption: String):
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var found = find_button(child, caption)
		if found: return found
	return null

func frame():
	await process_frame
	await process_frame

func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	check(game.modal.visible, "Welcome opens")
	find_button(game.modal, "Nordmark").pressed.emit()
	await frame()
	check(game.session.player_id == 1 and not game.modal.visible, "Country choice starts campaign")
	game.session.solo(0)
	game.selected = 0
	game.refresh()
	await frame()
	check(game.map.hit(game.map.transform_point(game.map.CENTERS[4])) == 4, "Map hit test")
	game.map.selected.emit(4)
	check(game.selected == 4, "Map selection signal")
	for i in range(4):
		game.tab_buttons[i].pressed.emit()
		await frame()
		check(game.tab == i and game.content.get_child_count() > 2, "Tab renders %d" % i)
		check(game.content.size.x <= game.scroll.size.x + 1, "Sidebar width fits %d" % i)
		if "--screenshots" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://docs")
			root.get_texture().get_image().save_png("res://docs/screen-%d.png" % i)
	game.tab_buttons[2].pressed.emit()
	await frame()
	find_button(game.content, "Industrie ausbauen").pressed.emit()
	check(game.session.sim.country(0).projects.size() == 1, "Economy button queues project")
	game.pause_button.pressed.emit()
	await create_timer(1.2).timeout
	check(game.session.sim.state.day >= 1, "Real game loop advances")
	game.show_menu()
	check(not game.session.running, "Menu pauses host")
	find_button(game, "LAN / Direkte IP").pressed.emit()
	await frame()
	check(find_button(game.network_window, "Per IP beitreten") != null, "Network controls render")
	game.network_window.hide()
	game.show_help()
	await frame()
	check(game.get_child_count() > 4, "Help dialog renders")
	print("UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
