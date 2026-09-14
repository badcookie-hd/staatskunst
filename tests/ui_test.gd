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
	find_button(game.modal, "Frankreich").pressed.emit()
	await frame()
	check(game.session.player_id == 1 and not game.modal.visible, "Country choice starts campaign")
	game.session.solo(0)
	game.selected = 0
	game.refresh()
	await frame()
	check(game.map.hit(game.map.transform_point(game.map.center(4))) == 4, "Map hit test")
	game.map.selected.emit(4)
	check(game.selected == 4, "Map selection signal")
	for i in range(7):
		game.tab_buttons[i].pressed.emit()
		await frame()
		check(game.tab == i and game.content.get_child_count() > 2, "Tab renders %d" % i)
		check(game.content.size.x <= game.scroll.size.x + 1, "Sidebar width fits %d" % i)
		if "--screenshots" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://docs")
			root.get_texture().get_image().save_png("res://docs/screen-%d.png" % i)
	game.tab_buttons[3].pressed.emit()
	await frame()
	find_button(game.content, "Industrie ausbauen").pressed.emit()
	check(game.session.sim.country(0).projects.size() == 1, "Economy button queues project")
	game.session.solo(0, 2026)
	game.tab_buttons[2].pressed.emit()
	await frame()
	find_button(game.content, "Minister ernennen …").pressed.emit()
	await frame()
	var appointment = find_button(game, "Alexander Dobrindt · CSU")
	check(appointment != null and not appointment.disabled, "Coalition minister selectable")
	appointment.pressed.emit()
	await frame()
	check(game.session.sim.country(0).cabinet.finance == "1:1", "UI appointment updates cabinet")
	game.pause_button.pressed.emit()
	await create_timer(1.2).timeout
	check(game.session.sim.state.day >= 1, "Real game loop advances")
	game.show_menu()
	check(not game.session.running, "Menu pauses host")
	find_button(game, "LAN / Direkte IP").pressed.emit()
	await frame()
	check(find_button(game.network_window, "Per IP beitreten") != null, "Network controls render")
	game.network_window.hide()
	game.show_start()
	find_button(game.modal, "2026 · Europa der Gegenwart").pressed.emit()
	await frame()
	check(find_button(game.modal, "Slowakei") != null, "2026 includes independent Slovakia")
	find_button(game.modal, "Slowakei").pressed.emit()
	await frame()
	check(game.session.sim.year() == 2026 and game.session.player_id == 16, "Modern scenario starts")
	check(game.date_label.text.begins_with("01.01.2026"), "2026 date displayed")
	check(game.map.regions.size() == 17, "Modern map rebuilt")
	check(game.map.hit(game.map.transform_point(Vector2(19.5,48.8))) == 16, "Slovakia clickable in 2026")
	game.tab_buttons[3].pressed.emit()
	await frame()
	check(find_button(game.content, "Digitale Infrastruktur") != null, "Modern decisions shown")
	if "--screenshots" in OS.get_cmdline_user_args(): root.get_texture().get_image().save_png("res://docs/screen-2026.png")
	game.show_start()
	find_button(game.modal, "1936 · Europa am Scheideweg").pressed.emit()
	await frame()
	check(find_button(game.modal,"Slowakei") == null and find_button(game.modal,"Tschechoslowakei") != null, "Historical country selection restored")
	find_button(game.modal,"Tschechoslowakei").pressed.emit()
	await frame()
	check(game.map.regions.size() == 16 and game.session.player_id == 7, "Switching back resets world safely")
	check(game.map.hit(game.map.transform_point(Vector2(19.5,48.8))) == 7, "Slovakia belongs to Czechoslovakia in 1936")
	for era in [1936,2026]:
		game.session.solo(0,era)
		await frame()
		for id in range(game.session.sim.count()):
			check(game.map.hit(game.map.transform_point(game.map.center(id))) == id, "Country center clickable: %d / %d" % [era,id])
	game.session.solo(0, 2026)
	game.selected = 1
	game.session.sim.country(0).influence = 250
	game.session.command("war", 1)
	for day in range(40): game.session.sim.advance(range(game.session.sim.count()))
	game.tab_buttons[4].pressed.emit()
	await frame()
	check(game.session.sim.state.wars[0].reports.size() > 4, "War report panel populated")
	if "--screenshots" in OS.get_cmdline_user_args():
		root.get_texture().get_image().save_png("res://docs/screen-war.png")
		game.session.solo(0, 2026)
		for day in range(120): game.session.sim.advance(range(game.session.sim.count()))
		for section in [1, 2, 3]:
			game.tab_buttons[section].pressed.emit()
			await frame()
			root.get_texture().get_image().save_png("res://docs/screen-modern-%d.png" % section)
	root.size = Vector2i(1152, 720)
	for section in range(7):
		game.tab_buttons[section].pressed.emit()
		await frame()
		check(game.content.size.x <= game.scroll.size.x + 1, "Minimum-width panel fits %d" % section)
	root.size = Vector2i(1440, 900)
	game.session.solo(0, 2026)
	game.session.sim.country(0).influence = 250
	game.session.command("coalition_7")
	game.session.command("government_7")
	game.tab_buttons[2].pressed.emit()
	await frame()
	check(game.session.sim.country(0).premier == "Jan Mertens", "Fictional CfD cabinet rendered")
	if "--screenshots" in OS.get_cmdline_user_args(): root.get_texture().get_image().save_png("res://docs/screen-cfd-cabinet.png")
	game.tab_buttons[6].pressed.emit()
	await frame()
	check(game.tab == 6 and find_button(game.content, "Verfassungskrise auslösen").disabled, "Constitution path requires waiting")
	if "--screenshots" in OS.get_cmdline_user_args(): root.get_texture().get_image().save_png("res://docs/screen-constitution.png")
	game.session.sim.state.day = 15
	game.session.sim.country(0).influence = 250
	game.refresh()
	await frame()
	var crisis = find_button(game.content, "Verfassungskrise auslösen")
	check(not crisis.disabled, "Crisis unlocked after new government tenure")
	crisis.pressed.emit()
	await frame()
	var confirmation = game.get_child(game.get_child_count() - 1)
	check(confirmation is ConfirmationDialog and confirmation.visible, "Explicit in-game constitutional breach confirmation")
	confirmation.confirmed.emit()
	await frame()
	check(game.session.sim.country(0).law.stage == 1, "Confirmed constitutional choice applied")
	game.show_help()
	await frame()
	check(game.get_child_count() > 4, "Help dialog renders")
	print("UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
