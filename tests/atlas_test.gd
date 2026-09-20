extends SceneTree
const Atlas = preload("res://scripts/world_atlas.gd")
var game
var checks = 0
var failures = 0

func check(ok: bool, message: String):
	checks += 1
	if not ok: failures += 1; printerr("ATLAS FAIL: " + message)

func _initialize(): call_deferred("run")

func frame():
	await process_frame
	await process_frame

func shot(name_value: String):
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name_value + ".png")

func text_in(node: Node) -> String:
	var value = str(node.text) if node is Label or node is Button else ""
	for child in node.get_children(): value += "\n" + text_in(child)
	return value

func find_type(node: Node, type_name: String):
	if node.is_class(type_name): return node
	for child in node.get_children():
		var found = find_type(child, type_name)
		if found: return found
	return null

func run():
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.title_screen.hide()
	game.campaign_started = true
	game.session.solo(0, 2026)
	check(Atlas.countries().size() == 242 and game.map.world.size() == 242, "World polygons and political profiles cover all 242 regions")
	check(Atlas.search("USA")[0].code == "USA", "Search by ISO code")
	check(Atlas.search("Vatikan")[0].code == "VAT", "Microstate search")
	check(Atlas.search("NO SUCH COUNTRY").is_empty(), "No fabricated search results")
	var portraits = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_portraits.json"))
	for name_value in portraits:
		var entry = portraits[name_value]
		check(game.Portraits.texture({"name":name_value}) != null, "Offline atlas portrait loads: " + name_value)
		check(not entry.author.is_empty() and not entry.license.is_empty(), "Attribution retained: " + name_value)
		check(entry.source.begins_with("https://") and (entry.license_url.begins_with("https://") or entry.license_url.begins_with("http://")), "Image source and license link retained")
	for year in [1936, 2026]:
		game.session.solo(0, year)
		for entry in Atlas.countries().values():
			check(not game.map.reference(entry.code).is_empty(), "Geography exists: " + entry.code)
			game.open_reference(entry.code)
			check(game.detail_panel.visible and game.tab == 5, "Every country opens: " + entry.code)
			if not game.reference_code.is_empty():
				check(text_in(game.content).contains(entry.name), "Matching country profile: " + entry.code)
				check(game.reference_year == year, "Scenario-specific profile: " + entry.code)
			for person in entry.profiles[str(year)].leaders:
				check(not person.name.begins_with("Q") or not person.name.substr(1).is_valid_int(), "Human-readable person name")
				check(person.source.begins_with("https://www.wikidata.org/"), "Political source attribution")
			await process_frame
	game.session.solo(0, 2026)
	game.reference_code = ""
	game.panel_open = false
	game.refresh()
	await frame()
	game.map.fit_world()
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.map.transform_point(Vector2(-100,40))
	game.map._gui_input(click)
	await frame()
	check(game.reference_code == "USA" and text_in(game.content).contains("Donald Trump"), "Click USA opens dated political leadership")
	game.map.focus_reference("USA")
	await frame()
	await shot("screen-atlas-usa")
	for code in ["VAT", "MCO", "TUV", "NRU"]:
		game.map.focus_reference(code)
		var point = game.map.transform_point(game.map.reference(code).center)
		check(game.map.reference_code_at(point) == code, "Microstate has a usable map target: " + code)
		click.position = point
		game.map._gui_input(click)
		check(game.reference_code == code, "Microstate click opens matching profile: " + code)
	game.show_country_search()
	await frame()
	var query = find_type(game.country_search_window, "LineEdit")
	var results = find_type(game.country_search_window, "ItemList")
	query.text = "Japan"
	query.text_changed.emit(query.text)
	check(results.item_count == 1, "Search filters visible list")
	query.text_submitted.emit(query.text)
	await frame()
	check(game.reference_code == "JPN" and not game.country_search_window.visible, "Enter selects searched country")
	await shot("screen-atlas-japan")
	game.reference_code = ""
	game.panel_open = false
	game.refresh()
	for window_size in [Vector2i(1440,900), Vector2i(1152,720)]:
		root.size = window_size
		await frame()
		for zoom_value in [1.0, 4.0, 10.0, 24.0]:
			game.map.focus_country(0)
			game.map.zoom = zoom_value
			game.map.pan = -game.map.projection(game.map.center(0)) * game.map.map_scale() * zoom_value if zoom_value > 1 else Vector2.ZERO
			game.map.queue_redraw()
			await frame()
			if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
			var rects = game.map.label_rects
			var collisions = false
			for a in range(rects.size()):
				for b in range(a+1,rects.size()):
					if rects[a].intersects(rects[b]): collisions = true
			check(not collisions, "Country labels never overlap at tested viewport and zoom")
	root.size = Vector2i(1440,900)
	await frame()
	game.map.fit_world()
	await frame()
	await shot("screen-world")
	print("ATLAS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
