extends SceneTree
const Portraits = preload("res://scripts/portraits.gd")
const Politics = preload("res://scripts/politics.gd")
var checks = 0
var failures = 0

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("PORTRAIT FAIL: " + message)

func _initialize():
	call_deferred("run")

func frame():
	await process_frame
	await process_frame

func run():
	var people = {}
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/politics.json"))
	for year in data:
		for code in data[year]:
			var roster = Politics.roster(int(year), code)
			for person in Politics.candidates(int(year), code): people[person.name] = person
			for key in ["head", "premier"]:
				if not people.has(roster[key]): people[roster[key]] = {"name": roster[key]}
	for person_name in ["Paul Löbe", "Wilhelm II."]: people[person_name] = {"name": person_name}
	check(people.size() == 314, "314 unique portraits across both eras")
	for person in people.values():
		var texture = Portraits.texture(person)
		check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Load " + person.name)
		if not person.get("fictional", false):
			var entry = Portraits.credit(person)
			check(not entry.get("author", "").is_empty() and not entry.get("license", "").is_empty(), "Credit " + person.name)
			check(entry.get("source", "").begins_with("https://"), "Source " + person.name)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.title_screen.hide()
	game.panel_open = true
	for year in [1936, 2026]:
		game.session.solo(0, year)
		for id in range(game.session.sim.count()):
			game.session.player_id = id
			for tab in [1, 2]:
				game.tab = tab
				game.refresh()
				await frame()
				var pictures = textures_in(game.content)
				check(pictures.size() >= (Politics.candidates(year, game.session.sim.country(id).code).size() if tab == 1 else 2), "All portraits displayed %d/%d/%d" % [year, id, tab])
				for picture in pictures: check(picture.texture != null, "No blank portrait in UI")
	game.session.solo(0, 2026)
	game.tab = 2
	game.refresh()
	await frame()
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	textures_in(game.content)[0].gui_input.emit(event)
	await frame()
	var dialog = game.get_child(game.get_child_count() - 1)
	check(dialog is AcceptDialog and dialog.visible and dialog.title == "Frank-Walter Steinmeier", "Portrait click opens correct head of state")
	check(text_in(dialog).contains(Portraits.credit({"name":"Frank-Walter Steinmeier"}).author), "Credit dialog names the photographer")
	dialog.queue_free()
	await frame()
	game.show_portrait_info()
	await frame()
	var info = game.get_child(game.get_child_count() - 1)
	check(info is AcceptDialog and info.visible and text_in(info).contains("307 reale Personen"), "Portrait information opens a readable dialog")
	info.queue_free()
	await frame()
	game.queue_free()
	await frame()
	if "--gallery" in OS.get_cmdline_user_args():
		root.size = Vector2i(1440, 980)
		var names = people.keys()
		names.sort()
		for page in range(ceili(names.size() / 48.0)):
			var grid = GridContainer.new()
			grid.columns = 8
			root.add_child(grid)
			for index in range(page * 48, mini((page + 1) * 48, names.size())):
				var person = people[names[index]]
				var tile = VBoxContainer.new()
				tile.custom_minimum_size = Vector2(175, 132)
				grid.add_child(tile)
				var picture = TextureRect.new()
				picture.texture = Portraits.texture(person)
				picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				picture.custom_minimum_size = Vector2(175, 106)
				tile.add_child(picture)
				var caption = Label.new()
				caption.text = person.name
				caption.add_theme_font_size_override("font_size", 11)
				caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				tile.add_child(caption)
			await frame()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../../work/portrait-gallery-%d.png" % page)
			grid.queue_free()
			await frame()
	print("PORTRAITS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func textures_in(node: Node) -> Array:
	var result = []
	if node is TextureRect and node.focus_mode == Control.FOCUS_ALL: result.append(node)
	for child in node.get_children(): result.append_array(textures_in(child))
	return result

func text_in(node: Node) -> String:
	var result = node.text if node is Label else ""
	for child in node.get_children(): result += text_in(child)
	return result
