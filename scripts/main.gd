extends Control
const Session = preload("res://scripts/session.gd")
const WorldMap = preload("res://scripts/world_map.gd")
const Trend = preload("res://scripts/trend.gd")
const Portraits = preload("res://scripts/portraits.gd")
const Settings = preload("res://scripts/settings.gd")
const Atlas = preload("res://scripts/world_atlas.gd")
const STEEL = preload("res://assets/steel-frame.svg")
const GOLD = Color("e2c28a")
const MUTED = Color("9eafc4")
var session
var map
var root_box: VBoxContainer
var content: VBoxContainer
var stats: HBoxContainer
var chronicle: VBoxContainer
var date_label: Label
var pause_button: Button
var status_label: Label
var nation_label: Label
var tab_buttons: Array = []
var tab = 0
var selected = 0
var modal: AcceptDialog
var network_window: AcceptDialog
var scroll: ScrollContainer
var map_caption: Label
var map_area: VBoxContainer
var detail_panel: PanelContainer
var setup_year = 1936
var setup_content: VBoxContainer
var preferences = Settings.new()
var title_screen: Control
var settings_window: AcceptDialog
var campaign_started = false
var panel_open = false
var reference_code = ""
var reference_year = 2026
var country_search_window: AcceptDialog
var map_mode_button: Button
var zoom_label: Label
var application_focused = true

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: application_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: application_focused = true

func has_open_window(node: Node) -> bool:
	for child in node.get_children():
		if child is Window and child.visible: return true
		if has_open_window(child): return true
	return false

func can_pan_map() -> bool:
	if not application_focused or not campaign_started: return false
	if is_instance_valid(title_screen) and title_screen.visible: return false
	var focus = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit: return false
	return not has_open_window(self)

func _ready():
	preferences.read()
	preferences.apply_display()
	build_theme()
	session = Session.new()
	session.name = "Session"
	add_child(session)
	session.updated.connect(refresh)
	session.notice.connect(show_notice)
	build_ui()
	refresh()
	show_main_menu()

func style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 2) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 11
	s.content_margin_bottom = 11
	return s

func build_theme():
	var t = Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", Color("e3e9e7"))
	t.set_color("font_color", "Button", Color("d8e5e2"))
	t.set_color("font_disabled_color", "Button", Color("60757c"))
	t.set_stylebox("normal", "Button", metal())
	t.set_stylebox("hover", "Button", metal(Color("e5d5af")))
	t.set_stylebox("pressed", "Button", metal(Color("a9b9c4")))
	t.set_stylebox("disabled", "Button", style(Color("202c33"), Color("34464e")))
	t.set_stylebox("focus", "Button", style(Color(0,0,0,0), GOLD))
	t.set_stylebox("panel", "AcceptDialog", metal())
	t.set_stylebox("panel", "ItemList", style(Color("17242c"), Color("465c66")))
	t.set_color("font_color", "ItemList", Color("e3e9e7"))
	t.set_stylebox("normal", "LineEdit", style(Color("191e1c"), Color("48636a")))
	t.set_color("font_color", "LineEdit", Color("e3e9e7"))
	t.set_stylebox("background", "ProgressBar", style(Color("262e2c"), Color.TRANSPARENT, 3))
	t.set_stylebox("fill", "ProgressBar", style(Color("bfa66e"), Color.TRANSPARENT, 3))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	theme = t

func metal(tint: Color = Color.WHITE) -> StyleBoxTexture:
	var box = StyleBoxTexture.new()
	box.texture = STEEL
	box.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 10)
		box.set_content_margin(side, 10 if side in [SIDE_LEFT, SIDE_RIGHT] else 7)
	return box

func label(text_value: String, size_value: int = 15, color: Color = Color("e3e9e7")) -> Label:
	var l = Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size_value)
	l.add_theme_color_override("font_color", color)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.tooltip_text = text_value
	return l

func paragraph(parent: Node, value: String, color: Color = MUTED):
	var l = label(value, 14, color)
	l.clip_text = false
	l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)

func button(parent: Node, value: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = value
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func panel(parent: Node, color: Color = Color("202d35")) -> VBoxContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", metal() if color == Color("202d35") else style(color, Color("69716c")))
	parent.add_child(p)
	var box = VBoxContainer.new()
	p.add_child(box)
	return box

func clear(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func build_ui():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 4)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 3)
	margin.add_child(root_box)
	var header = HBoxContainer.new()
	root_box.add_child(header)
	var brand = label("S T A A T S K U N S T", 18, GOLD)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	date_label = label("", 16)
	date_label.custom_minimum_size.x = 180
	header.add_child(date_label)
	pause_button = button(header, "▶ Fortsetzen", func(): session.toggle_pause())
	pause_button.custom_minimum_size.x = 125
	for speed in [1, 3, 5]: button(header, "%d×" % speed, func(): session.set_speed(speed)).custom_minimum_size.x = 45
	button(header, "Menü", show_menu).custom_minimum_size.x = 85
	stats = HBoxContainer.new()
	root_box.add_child(stats)
	var nav = HBoxContainer.new()
	root_box.add_child(nav)
	var names = ["Übersicht", "Parteien", "Kabinett", "Wirtschaft", "Krieg", "Diplomatie", "Verfassung"]
	for i in range(names.size()):
		var b = button(nav, names[i], func(): tab = i; panel_open = true; scroll.scroll_vertical = 0; refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 34
		tab_buttons.append(b)
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(body)
	map_area = VBoxContainer.new()
	map_area.add_theme_constant_override("separation", 3)
	map_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(map_area)
	var map_header = HBoxContainer.new()
	map_area.add_child(map_header)
	nation_label = label("", 12, GOLD)
	nation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_header.add_child(nation_label)
	map_caption = label("", 10, MUTED)
	map_caption.custom_minimum_size.x = 100
	map_header.add_child(map_caption)
	map = WorldMap.new()
	map.sim = session.sim
	map.settings = preferences
	map.keyboard_pan_allowed = can_pan_map
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(300, 260)
	map.selected.connect(func(id): reference_code = ""; selected = id; tab = 5; panel_open = true; refresh())
	map.reference_selected.connect(open_reference)
	map_area.add_child(map)
	var controls = HBoxContainer.new()
	map_area.add_child(controls)
	controls.add_theme_constant_override("separation", 4)
	for entry in [["Welt", func(): map.fit_world()], ["Mein Land", func(): map.focus_country(session.player_id)], ["Ländersuche", show_country_search]]:
		var b = button(controls, entry[0], entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.x = {"Welt":55, "Mein Land":88, "Ländersuche":112}[entry[0]]
	button(controls, "−", func(): map.zoom_at(map.size / 2, -1)).custom_minimum_size.x = 32
	zoom_label = label("1.0×", 12, GOLD)
	zoom_label.custom_minimum_size.x = 43
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(zoom_label)
	button(controls, "+", func(): map.zoom_at(map.size / 2, 1)).custom_minimum_size.x = 32
	map.draw.connect(func(): zoom_label.text = "%.1f×" % map.zoom)
	map_mode_button = button(controls, "Politisch", func():
		map.mode = "diplomatic" if map.mode == "political" else "political"
		map_mode_button.text = "Beziehungen" if map.mode == "diplomatic" else "Politisch"
		map.queue_redraw())
	map_mode_button.custom_minimum_size.x = 128
	map_mode_button.tooltip_text = "Kartenmodus wechseln · Politisch: Länderfarben · Beziehungen: eigene Gebiete gold, andere Kampagnenländer grün, übrige Welt grau"
	chronicle = VBoxContainer.new()
	map_area.add_child(chronicle)
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size.x = 550
	detail_panel.add_theme_stylebox_override("panel", metal())
	body.add_child(detail_panel)
	var side_box = VBoxContainer.new()
	detail_panel.add_child(side_box)
	button(side_box, "Akte schließen  ×", func(): panel_open = false; refresh())
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	status_label = label("WASD: Bewegen · Umschalt: Schneller · Mausrad: Zoom · Rechts/Mitte ziehen: Verschieben", 12, GOLD)
	root_box.add_child(status_label)

func refresh():
	if stats == null: return
	var sim = session.sim
	selected = clampi(selected, 0, sim.count() - 1)
	var c = sim.country(session.player_id)
	clear(stats)
	metric("STAATSMITTEL", "%.0f M" % c.money, "%+.1f M / Monat" % sim.income(session.player_id))
	metric("POLITISCHER EINFLUSS", "%.0f" % c.influence, "Für Gesetze und Entscheidungen")
	metric("STABILITÄT", "%.0f %%" % c.stability, "Freie Wahlen" if c.democratic else "Autoritäre Regierung")
	metric("MONATS-BIP", "%.0f M" % sim.Economy.ledger(c, sim.year(), sim.war_count(session.player_id)).gdp, "%.1f %% Inflation · %.0f %% Beschäftigung" % [c.econ.inflation, c.econ.employment])
	metric("STREITKRÄFTE", "%.0f Tsd." % c.army, "Stärke %.0f · Versorgung %.0f %%" % [sim.power(session.player_id), sim.Economy.supply(c) * 100])
	date_label.text = "%s   ·   %d×" % [date_text(int(sim.state.day)), session.speed]
	pause_button.text = "Ⅱ Pause" if session.running else "▶ Fortsetzen"
	pause_button.disabled = not session.is_host() or int(sim.state.winner) >= 0
	nation_label.text = "%s  /  %s" % [c.name.to_upper(), "LAN · %d Spieler" % session.players.size() if session.online else "EINZELSPIELER"]
	map_caption.text = "%d  /  %d STAATEN" % [sim.year(), sim.count()]
	map.selected_id = selected
	map.selected_reference = reference_code if tab == 5 else ""
	map.player_id = session.player_id
	map.ensure_cache()
	map.queue_redraw()
	map_area.visible = true
	detail_panel.visible = panel_open
	for i in range(tab_buttons.size()): tab_buttons[i].modulate = GOLD if tab == i else Color.WHITE
	clear(content)
	if int(sim.state.winner) >= 0:
		content.add_child(label("PARTIE ABGESCHLOSSEN", 19, GOLD))
		paragraph(content, "%s hat gewonnen. Starte im Menü eine neue Partie." % sim.country(int(sim.state.winner)).name)
	elif not sim.alive(session.player_id):
		content.add_child(label("REGIERUNG GESTÜRZT", 19, GOLD))
		paragraph(content, "Dein Land wurde eingegliedert. Du kannst die Welt weiter beobachten oder eine neue Partie starten.")
	match tab:
		0: state_tab(c)
		1: politics_tab(c)
		2: cabinet_tab(c)
		3: economy_tab(c)
		4: war_tab(c)
		5:
			if reference_code.is_empty(): foreign_tab(c)
			else: reference_tab()
		6: constitution_tab(c)
	clear(chronicle)
	for entry in sim.state.log.slice(0, 1):
		var l = label("%s   %s" % [date_text(int(entry.day)), entry.text], 12, MUTED)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chronicle.add_child(l)

func metric(title: String, value: String, detail: String):
	var box = panel(stats)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.get_parent().tooltip_text = title + " · " + value + "\n" + detail
	var row = HBoxContainer.new()
	box.add_child(row)
	var caption = label(title, 10, Color("b5b9b0"))
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var number = label(value, 18, Color("ece4ca"))
	number.clip_text = false
	number.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	row.add_child(number)

func date_text(day: int) -> String:
	return "%02d.%02d.%d" % [day % 30 + 1, (day / 30) % 12 + 1, session.sim.year() + day / 360]

func heading(title: String, sub: String):
	content.add_child(label(title, 23, GOLD))
	paragraph(content, sub)

func bar(parent: Node, value: float):
	var p = ProgressBar.new()
	p.custom_minimum_size.y = 7
	p.show_percentage = false
	p.value = value
	parent.add_child(p)

func state_tab(c: Dictionary):
	banner(content, 115)
	heading("Die Staatsführung", "%s · %s\n%s · %s" % [c.head_title, c.head_name, c.premier_title, c.premier])
	leader_pictures(content, c)
	paragraph(content, "Regierung: " + session.sim.parties(session.player_id)[int(c.ruling)].name, GOLD)
	var goal = panel(content, Color("203a3e"))
	goal.add_child(label("DEIN WEG ZUM SIEG", 11, GOLD))
	paragraph(goal, "Wohlstand: ab Tag 365 mindestens 100 Industrie und 75 % Stabilität. Oder: fünf Länder kontrollieren.")
	bar(goal, c.industry)
	paragraph(goal, "%.0f / 100 Industrie   ·   %d / 5 Länder" % [c.industry, session.sim.territories(session.player_id)])
	if int(c.event) >= 0:
		var titles = ["Streik im Industriegebiet", "Die Energiefrage", "Eine neue Generation"] if session.sim.year() == 1936 else ["Automatisierung der Industrie", "Energiewende", "Digitale Bildung"]
		var bodies = ["Arbeitende fordern sichere Arbeitsplätze und Investitionen.", "Die Städte verlangen eine verlässliche öffentliche Versorgung.", "Studierende fordern moderne Schulen und berufliche Perspektiven."] if session.sim.year() == 1936 else ["Neue Technologien verändern die Arbeitswelt. Beschäftigte fordern Weiterbildung.", "Netzausbau und erneuerbare Energie benötigen staatliche Investitionen.", "Schulen und Hochschulen benötigen moderne digitale Infrastruktur."]
		var event_box = panel(content)
		event_box.add_child(label(titles[int(c.event)], 18, GOLD))
		paragraph(event_box, bodies[int(c.event)] + " Entscheidung binnen %d Tagen, sonst wird vertagt." % (30 - int(session.sim.state.day) + int(c.event_day)))
		add_action("event_0", event_box, "Investieren · 60 M", "+7 Stabilität, +2 Industrie")
		add_action("event_1", event_box, "Entscheidung vertagen", "+20 Einfluss, −5 Stabilität")
	else:
		paragraph(content, "Keine dringende Kabinettsvorlage. Neue Ereignisse erscheinen alle 75 Tage.")
	content.add_child(label("LAUFENDE PROJEKTE", 11, GOLD))
	projects(c)
	add_action("welfare")

func grid(parent: Node, columns: int = 2) -> GridContainer:
	var g = GridContainer.new()
	g.columns = mini(columns, 2)
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	parent.add_child(g)
	return g

func card(parent: Node) -> VBoxContainer:
	var box = panel(parent)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box

func politics_tab(c: Dictionary):
	var sim = session.sim
	heading("Parlament & Parteien", "Nächste Modellwahl in %d Tagen. Koalitionsanteil: %.1f %% · %s" % [180 - int(sim.state.day) % 180, sim.Politics.coalition_support(c), "freie Wahlen" if c.democratic else "autoritäre Herrschaft"])
	paragraph(content, "Reale Parteien und die fiktive CfD. Unterstützung und Koalitionen sind Spielwerte, keine Umfragen. Historisch verbotene Parteien werden durch eine Verfassungsreform als Alternativpfad verfügbar.")
	if not c.democratic: add_action("democratize")
	if sim.year() == 1936 and c.code == "DEU": add_action("restore_monarchy")
	var g = grid(content, 2)
	var order = range(sim.parties(session.player_id).size())
	if c.code == "DEU":
		order.erase(7)
		order.push_front(7)
	for i in order:
		var party = sim.parties(session.player_id)[i]
		var box = card(g)
		if party.get("fictional", false):
			var emblem = TextureRect.new()
			emblem.texture = load("res://assets/cfd-emblem.svg")
			emblem.custom_minimum_size = Vector2(48, 48)
			emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			emblem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(emblem)
			paragraph(box, "CfD · FIKTIVE SPIELPARTEI", GOLD)
			paragraph(box, party.description)
		paragraph(box, "%s   ·   %.1f %%" % [party.name, c.support[i]], Color(party.color))
		var faces = GridContainer.new()
		faces.columns = 2
		faces.add_theme_constant_override("h_separation", 10)
		box.add_child(faces)
		for person in party.candidates:
			var tile = VBoxContainer.new()
			tile.custom_minimum_size.x = 92
			faces.add_child(tile)
			portrait(tile, person, 82)
			var caption = label(person.name, 12)
			caption.custom_minimum_size.x = 92
			caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caption.clip_text = false
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(caption)
			if Portraits.credit(person).get("kind", "") == "illustration": tile.add_child(label("KI-Illustration", 10, MUTED))
		bar(box, c.support[i])
		paragraph(box, ("REGIERUNGSFÜHRUNG" if int(c.ruling) == i else "KOALITION" if i in c.coalition else "OPPOSITION") + (" · verboten / Exil" if not party.legal and not c.democratic else ""), GOLD)
		add_action("campaign_%d" % i, box, "Wahlkampf · 25 Einfluss", "+9 Unterstützung vor Normalisierung · 15 Tage Abklingzeit")
		if i != int(c.ruling):
			add_action("coalition_%d" % i, box, "Koalition verlassen" if i in c.coalition else "In Koalition aufnehmen", "30 Einfluss · Koalitionswechsel räumt betroffene Ministerämter")
			add_action("government_%d" % i, box, "Regierung führen lassen", "80 Einfluss · benötigt Koalitionsmehrheit und freie Wahlen")

func cabinet_tab(c: Dictionary):
	var sim = session.sim
	heading("Dein Kabinett", "Du bestimmst die Besetzung. Koalitionsparteien stellen die Kandidaten für vier Ressorts.")
	var leaders = grid(content)
	for pair in [[c.head_title, c.head_name], [c.premier_title, c.premier]]:
		var box = card(leaders)
		box.add_child(label(pair[0].to_upper(), 11, GOLD))
		var leader = find_person(c, pair[1])
		portrait(box, leader, 100)
		var leader_name = label(pair[1], 18)
		leader_name.clip_text = false
		leader_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		leader_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(leader_name)
	paragraph(content, "Startpersonal nach Epoche. Die vier Ressorts bilden ein Spielkabinett; Besetzung, Koalitionen und Fachboni sind vereinfacht. Fachprofil = Spielrolle, keine Bewertung realer Fähigkeiten.")
	var g = grid(content)
	for role in sim.Politics.ROLES:
		var person = sim.Politics.person(sim.year(), c.code, c.cabinet[role])
		var box = card(g)
		box.add_theme_constant_override("separation", 5)
		box.add_child(label(sim.Politics.ROLES[role].to_upper(), 11, GOLD))
		var title = "Vakant" if person.is_empty() else person.name
		var initials = "—"
		if not person.is_empty(): initials = person.name.left(1) + person.name.get_slice(" ", person.name.get_slice_count(" ") - 1).left(1)
		if not person.is_empty(): portrait(box, person, 130)
		else: box.add_child(label(initials, 26, Color("76bdbe")))
		paragraph(box, title, Color.WHITE)
		if not person.is_empty(): paragraph(box, sim.parties(session.player_id)[int(person.party)].name + " · Profil: " + sim.Politics.ROLES[person.focus])
		var effects = {"finance": "Steuereffizienz", "economy": "Wirtschaftsleistung", "defense": "effektive Armeestärke", "foreign": "Wirkung von Staatsbesuchen"}
		paragraph(box, "+%.0f %% %s" % [sim.Politics.bonus(c, sim.year(), role) * 100, effects[role]], GOLD)
		button(box, "Minister ernennen …", func(): choose_minister(role))

func choose_minister(role: String):
	var sim = session.sim
	var c = sim.country(session.player_id)
	var dialog = AcceptDialog.new()
	dialog.title = "Ernennung · " + sim.Politics.ROLES[role]
	dialog.get_ok_button().text = "Zurück"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	var list_scroll = ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(620, 460)
	dialog.add_child(list_scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(box)
	paragraph(box, "20 Einfluss je Ernennung. Passendes Profil: +12 %, sonst +4 %. Jede Person kann ein Amt besetzen. Weitere Kandidaten durch Koalitionsverhandlungen unter Parteien freischalten.")
	for p in sim.Politics.candidates(sim.year(), c.code):
		var action = "appoint_%s_%s" % [role, p.id]
		var error = sim.reason(session.player_id, action)
		var row = HBoxContainer.new()
		box.add_child(row)
		portrait(row, p, 60)
		var b = button(row, "%s · %s" % [p.name, sim.parties(session.player_id)[int(p.party)].name], func(): session.command(action); dialog.queue_free())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not error.is_empty()
		b.tooltip_text = error if not error.is_empty() else "Profil: " + sim.Politics.ROLES[p.focus]
	dialog.popup_centered()

func economy_tab(c: Dictionary):
	var sim = session.sim
	var e = c.econ
	var book = sim.budget(session.player_id)
	heading("Wirtschaft & Staatshaushalt", "Modellwerte in M und Gütereinheiten. Produktion, Vorräte, Arbeitsplätze, Steuern und Schulden werden täglich miteinander verrechnet.")
	var summary = grid(content, 3)
	for item in [["LAUFENDER MONATSSALDO", "%+.1f M" % book.net], ["STAATSSCHULDEN", "%.0f M · %.2f %% Zins" % [e.debt, book.rate]], ["VERSORGUNG", "%.0f %% · %.1f %% Schäden" % [book.supply * 100, e.damage]]]:
		var box = card(summary)
		box.add_child(label(item[0], 11, MUTED))
		box.add_child(label(item[1], 21, GOLD))
	var columns = grid(content)
	var revenue = card(columns)
	revenue.add_child(label("EINNAHMEN / MONAT", 12, GOLD))
	for item in [["Einkommensteuer", book.personal], ["Unternehmenssteuer", book.corporate], ["Verbrauchsteuer", book.consumption], ["Exporte (letzte Lieferrate)", book.exports], ["Gesamt", book.revenue + book.exports]]: ledger_row(revenue, item[0], item[1])
	var expenses = card(columns)
	expenses.add_child(label("AUSGABEN / MONAT", 12, GOLD))
	for item in [["Verwaltung", book.admin], ["Soziales", book.social], ["Bildung", book.education], ["Verteidigung", book.military], ["Kriegskosten", book.war], ["Zinsen", book.interest], ["Repressionsapparat", book.repression], ["Importe (letzte Lieferrate)", book.imports], ["Gesamt", book.expenses + book.imports]]: ledger_row(expenses, item[0], item[1])
	paragraph(content, "Letzter Tagesabschluss: Kasse %+.2f M · davon automatische Kredite %+.2f M. Laufender Monatssaldo enthält die letzte tatsächliche Handelsrate; einmalige Projekte und Kredite stehen im Kontobuch." % [e.last_cash_change, e.last_borrowing], GOLD)
	var charts = grid(content)
	for key in ["gdp", "balance"]:
		var chart = Trend.new()
		chart.caption = "MONATS-BIP" if key == "gdp" else "HAUSHALTSSALDO / MONAT"
		chart.values = e.history.map(func(point): return point[key])
		charts.add_child(chart)
	content.add_child(label("VERSORGUNG & PRODUKTION", 14, GOLD))
	var resources = grid(content, 3)
	var demand = sim.Economy.demand(c)
	var flow = sim.Economy.flow(c)
	for good in sim.Economy.GOODS:
		var box = card(resources)
		box.add_child(label({"energy": "ENERGIE", "food": "NAHRUNG", "materials": "MATERIAL"}[good], 11, MUTED))
		box.add_child(label("%.0f Einheiten" % e.stock[good], 22, GOLD))
		paragraph(box, "Produktion %.1f / Monat\nBedarf %.1f / Monat\nBilanz %+.1f / Monat\nUngedeckt %.1f / Monat" % [flow.production[good], demand[good], flow.production[good] - demand[good], flow.shortfall[good]])
		var deficit = demand[good] - flow.production[good]
		paragraph(box, "Engpass in etwa %.0f Tagen" % (e.stock[good] / deficit * 30) if deficit > 0.01 else "Produktion deckt den Bedarf", GOLD)
	paragraph(content, "Fehlende Vorräte senken Produktion und Armeestärke. Kriegsschäden drücken die Leistung. Handelsverträge unter Diplomatie liefern nur, wenn der Partner Überschüsse hat und du zahlen kannst. Importe und Exporte sind im Saldo enthalten, basierend auf der letzten tatsächlichen Lieferung.")
	content.add_child(label("STEUERN & BUDGETS", 14, GOLD))
	var controls = grid(content, 3)
	var income_box = card(controls)
	income_box.add_child(label("Einkommensteuer · %d %%" % c.tax, 15, GOLD))
	add_action("tax_up", income_box)
	add_action("tax_down", income_box)
	for key in ["corporate", "vat", "social", "education", "defense"]:
		var box = card(controls)
		var names = {"corporate": "Unternehmenssteuer", "vat": "Verbrauchsteuer", "social": "Sozialbudget", "education": "Bildungsbudget", "defense": "Verteidigungsbudget"}
		paragraph(box, "%s · %.0f %s" % [names[key], e[key], "%" if key in ["corporate", "vat"] else "/ 100"], GOLD)
		var explanations = {"corporate": "Besteuert Unternehmensgewinne.", "vat": "Besteuert Konsum im Modell.", "social": "Höheres Budget stabilisiert die Gesellschaft.", "education": "Steigert die Produktivität über Zeit.", "defense": "Erhöht Unterhalt und effektive Armeestärke."}
		paragraph(box, explanations[key])
		add_action(key + "_up", box)
		add_action(key + "_down", box)
	var debt = grid(content)
	add_action("loan", card(debt))
	add_action("repay", card(debt))
	content.add_child(label("INVESTITIONEN · ZWEI PROJEKTPLÄTZE", 14, GOLD))
	projects(c)
	paragraph(content, "Kapazitäten: Industrie %.0f · Energie %.0f · Landwirtschaft %.0f · Dienstleistungen %.0f" % [c.industry, e.energy, e.farms, e.services])
	var investments = grid(content, 3)
	for action in ["industry", "energy", "farms", "services", "research", "recruit"]: add_action(action, card(investments))
	for contract_index in range(sim.state.trades.size()):
		var contract = sim.state.trades[contract_index]
		if int(contract.a) == session.player_id:
			paragraph(content, "%s → %s · geliefert %.1f · bezahlt %.1f M%s" % [sim.country(int(contract.b)).name, {"energy": "Energie", "food": "Nahrung", "materials": "Material"}[contract.good], contract.delivered, contract.spent, " · wegen Krieg ausgesetzt" if sim.at_war(int(contract.a), int(contract.b)) else ""])

			add_action("cancel_trade_%d" % contract_index, content, "Vertrag kündigen", "Kostenlos · Handelsplatz freigeben")
	content.add_child(label("KONTOBUCH · LETZTE BUCHUNGEN", 14, GOLD))
	if e.transactions.is_empty(): paragraph(content, "Noch keine Buchungen. Die Zeit ist pausiert; Entscheidungen buchen sofort, der Haushalt täglich.")
	for entry in e.transactions.slice(0, 12):
		paragraph(content, "%s · %s · %+.2f M%s" % [date_text(int(entry.day)), entry.text, entry.amount, " · Schulden %+.2f M" % entry.debt if absf(entry.debt) > 0.001 else ""])

func ledger_row(parent: Node, title: String, value: float):
	var row = HBoxContainer.new()
	parent.add_child(row)
	var text_label = label(title, 14, MUTED)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	var amount = label("%.1f M" % value, 14)
	amount.clip_text = false
	amount.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	row.add_child(amount)

func war_tab(_c: Dictionary):
	var sim = session.sim
	heading("Kriegsraum", "Strategischer Verlauf ohne Front- oder Einheitensteuerung. Größe, Qualität, Versorgung und Staatsführung bestimmen die wirksame Stärke.")
	if sim.state.wars.is_empty(): paragraph(content, "Aktuell herrscht Frieden. Wähle einen Staat auf der Karte und öffne Diplomatie, um Beziehungen oder eine Kriegserklärung vorzubereiten.")
	for w in sim.state.wars + sim.state.war_archive.slice(0, 3):
		var box = panel(content)
		paragraph(box, "%s ↔ %s" % [sim.country(int(w.a)).name, sim.country(int(w.b)).name], GOLD)
		paragraph(box, "BEENDET" if w.has("ended") else "AKTIV · TAG %d" % w.days, GOLD)
		bar(box, (w.progress + 100) / 2)
		paragraph(box, "Fortschritt %+.1f / 100\n+100: Angreifer siegt · −100: Verteidiger siegt" % w.progress)
		paragraph(box, "Verluste: %.2f / %.2f Tsd.\nZusätzliche Kriegskosten: %.1f / %.1f M\nStärke jetzt: %.0f / %.0f" % [w.loss_a, w.loss_b, w.cost_a, w.cost_b, sim.power(int(w.a)), sim.power(int(w.b))])
		var chart = Trend.new()
		chart.caption = "KRIEGSFORTSCHRITT / WOCHEN"
		chart.values = w.history.map(func(point): return point.progress)
		box.add_child(chart)
		if not w.has("ended"):
			var pa = sim.power(int(w.a))
			var pb = sim.power(int(w.b))
			var rate = (pa - pb) / maxf(1, pa + pb) * 4
			paragraph(box, "Patt: Kräfte annähernd ausgeglichen." if absf(rate) < 0.05 else "Bei unveränderter Stärke: noch ungefähr %.0f Tage. Versorgung und Politik können den Verlauf ändern." % ((100 - w.progress * signf(rate)) / absf(rate)))
		for entry in w.reports.slice(0, 6): paragraph(box, "%s · %s" % [date_text(int(entry.day)), entry.text])

func projects(c: Dictionary):
	if c.projects.is_empty(): paragraph(content, "2 freie Projektplätze. Investiere unter Wirtschaft.")
	for p in c.projects:
		var days = int(p.finish) - int(session.sim.state.day)
		paragraph(content, "%s · noch %d Tage" % [session.sim.ACTIONS[p.kind][0], days], GOLD)

func foreign_tab(_c: Dictionary):
	var sim = session.sim
	var target = int(sim.country(selected).owner)
	var c = sim.country(target)
	heading(c.name, "%s · %s\n%s · %s" % [c.head_title, c.head_name, c.premier_title, c.premier])
	leader_pictures(content, c)
	paragraph(content, "Regierung: " + sim.parties(target)[int(c.ruling)].name, GOLD)
	paragraph(content, "Stärke %.0f  ·  %.0f Tsd. Soldaten\nQualität %.2f  ·  Stabilität %.0f %%\nBeziehungen %+d" % [sim.power(target), c.army, c.quality, c.stability, sim.relation(session.player_id, target)])
	for w in sim.state.wars:
		if int(w.a) == target or int(w.b) == target or int(w.a) == session.player_id or int(w.b) == session.player_id:
			var box = panel(content)
			box.add_child(label("%s ↔ %s" % [sim.country(int(w.a)).name, sim.country(int(w.b)).name], 14, GOLD))
			bar(box, (w.progress + 100) / 2)
			paragraph(box, "Tag %d · Angreiferfortschritt %+.1f / 100\n+100: Angreifer siegt. −100: Verteidiger siegt." % [w.days, w.progress])
	for action in ["trade", "import_food", "import_materials", "diplomacy", "war", "peace"]: add_action(action)
	paragraph(content, "Stärke = Größe × Qualität × Stabilität × Versorgung × Verteidigungsbudget × Kabinettsfaktor. Die stärkere Armee setzt sich über Zeit durch. Bei Gleichstand bleibt der Krieg stehen.")
	content.add_child(label("PARTEIEN & PERSONAL", 16, GOLD))
	for party in sim.Politics.roster(sim.year(), c.code).get("parties", []):
		var box = panel(content)
		paragraph(box, party.name, GOLD)
		for person in party.candidates:
			var row = HBoxContainer.new()
			box.add_child(row)
			portrait(row, person, 48)
			var name_label = label(person.name, 15)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_label)

func open_reference(code: String):
	if Atlas.country(code).is_empty(): return
	for i in range(session.sim.count()):
		if session.sim.country(i).code == code or (session.sim.year() == 1936 and code in ["CZE", "SVK"] and session.sim.country(i).code == "CSK"):
			reference_code = ""
			selected = i
			tab = 5
			panel_open = true
			refresh()
			return
	reference_code = code
	reference_year = session.sim.year()
	tab = 5
	panel_open = true
	scroll.scroll_vertical = 0
	refresh()

func show_country_search():
	if is_instance_valid(country_search_window): country_search_window.queue_free()
	country_search_window = AcceptDialog.new()
	country_search_window.title = "Weltatlas · Ländersuche"
	country_search_window.get_ok_button().text = "Schließen"
	add_child(country_search_window)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(610, 430)
	country_search_window.add_child(box)
	var query = LineEdit.new()
	query.placeholder_text = "Land oder Kürzel eingeben · z. B. USA, Japan, Vatikan"
	box.add_child(query)
	var results = ItemList.new()
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(results)
	var populate = func(text_value):
		results.clear()
		for entry in Atlas.search(text_value):
			var index = results.add_item(entry.name + "   ·   " + entry.code)
			results.set_item_metadata(index, entry.code)
		if results.item_count > 0: results.select(0)
	var choose = func(index):
		var code = results.get_item_metadata(index)
		open_reference(code)
		map.focus_reference(code)
		country_search_window.hide()
	query.text_changed.connect(populate)
	query.text_submitted.connect(func(_text):
		if results.item_count > 0: choose.call(results.get_selected_items()[0]))
	results.item_clicked.connect(func(index, _position, _mouse): choose.call(index))
	populate.call("")
	country_search_window.popup_centered()
	query.grab_focus()

func reference_tab():
	var entry = Atlas.country(reference_code)
	if entry.is_empty(): return
	var profile = entry.profiles[str(reference_year)]
	heading(entry.name, "WELTATLAS · POLITISCHE LÄNDERAKTE")
	var years = HBoxContainer.new()
	content.add_child(years)
	for year in [1936, 2026]:
		var option = button(years, str(year), func(): reference_year = year; refresh())
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.modulate = GOLD if reference_year == year else Color.WHITE
	paragraph(content, "Staatsführung am 01.01.%d · Datierter Quellenstand, keine simulierte Regierung." % reference_year, GOLD)
	if profile.has("reference_government"): paragraph(content, "Staatsführung des Bezugsstaats: " + profile.reference_government, GOLD)
	if reference_year == 1936 and profile.name != entry.name: paragraph(content, "Historischer Bezugsstaat: " + profile.name)
	if profile.leaders.is_empty():
		paragraph(content, "Für diesen Stichtag ist kein ausreichend datierter Amtsinhaber im Atlas erfasst. Für damalige Kolonien, Nachfolgestaaten oder unbewohnte Gebiete wird keine heutige Regierung als historische Regierung ausgegeben.")
		if reference_year == 1936: button(content, "Politische Länderakte 2026 ansehen", func(): reference_year = 2026; refresh())
	var unique_leaders: Dictionary = {}
	for person in profile.leaders:
		if unique_leaders.has(person.qid): unique_leaders[person.qid].role += " / " + person.role
		else: unique_leaders[person.qid] = person.duplicate(true)
	for person in unique_leaders.values():
		var box = panel(content, Color("28363e"))
		paragraph(box, person.role, GOLD)
		var row = HBoxContainer.new()
		box.add_child(row)
		if Portraits.texture(person) != null: portrait(row, person, 88)
		else:
			var monogram = label(person.name.substr(0, 1), 36, GOLD)
			monogram.custom_minimum_size = Vector2(72, 88)
			monogram.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			monogram.tooltip_text = "Kein frei verwendbares Foto im Atlas vorhanden."
			row.add_child(monogram)
		var text_box = VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_box)
		paragraph(text_box, person.name, Color("eef3f1"))
		paragraph(text_box, person.title)
		paragraph(text_box, "Amtsbeginn: " + person.since)
		if Portraits.texture(person) == null: paragraph(text_box, "Foto nicht verfügbar")
		if not person.parties.is_empty(): paragraph(box, "Parteizugehörigkeit laut Quelle: " + ", ".join(person.parties))
		button(box, "Person und Quellen öffnen ↗", func(): OS.shell_open(person.person_source))
		button(box, "Amtsangaben prüfen ↗", func(): OS.shell_open(person.get("authority_source", person.source)))
	content.add_child(label("GEOGRAFISCHES PROFIL", 15, GOLD))
	var continents = {"Asia":"Asien","Europe":"Europa","Africa":"Afrika","North America":"Nordamerika","South America":"Südamerika","Oceania":"Ozeanien","Antarctica":"Antarktika"}
	paragraph(content, continents.get(entry.continent, entry.continent) + " · " + entry.code)
	paragraph(content, "Heutige Referenzdaten; keine Werte der Wirtschaftssimulation.")
	if not entry.capital.is_empty(): paragraph(content, "Hauptstadt / Verwaltungssitz: " + ", ".join(entry.capital))
	if not entry.currency.is_empty(): paragraph(content, "Währung: " + ", ".join(entry.currency))
	if entry.population > 0: paragraph(content, "Bevölkerung: %.2f Mio. · Schätzung %d" % [entry.population / 1000000.0, entry.population_year])
	if entry.type == "Dependency": paragraph(content, "Abhängiges Gebiet · Bezugsstaat: " + entry.sovereign)
	paragraph(content, "Dieses Gebiet ist als Länderakte zugänglich. Krieg, Haushalt und Regierungswechsel stehen weiterhin für die Kampagnenländer zur Verfügung. Weltgrenzen sind moderne Referenzgrenzen, auch in der 1936-Ansicht.")
	button(content, "Länderquelle öffnen ↗", func(): OS.shell_open("https://www.wikidata.org/wiki/" + entry.qid))

func add_action(action: String, parent: Node = null, title: String = "", detail: String = ""):
	if parent == null: parent = content
	if title.is_empty():
		title = session.sim.ACTIONS[action][0]
		detail = session.sim.ACTIONS[action][1]
	var target = int(session.sim.country(selected).owner)
	var preview = budget_preview(action)
	if not preview.is_empty(): detail += "\n" + preview
	var b = button(parent, title, func():
		if action == "war": confirm_war(target)
		elif action.begins_with("law_") and action != "law_defend": confirm_law(action)
		else: session.command(action, target))
	var error = session.sim.reason(session.player_id, action, target)
	b.disabled = error != ""
	b.tooltip_text = error if error != "" else detail
	paragraph(parent, detail if error.is_empty() else error, MUTED)

func confirm_war(target: int):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Kriegserklärung"
	dialog.dialog_text = "Krieg gegen %s erklären?\n70 Einfluss, −12 Stabilität und laufende Kriegskosten (mindestens 24 M / Monat).\nEigene Stärke: %.0f · Gegner: %.0f\nDer Krieg läuft automatisch, bis ein Staat gewinnt oder ein Waffenstillstand gilt." % [session.sim.country(target).name, session.sim.power(session.player_id), session.sim.power(target)]
	dialog.confirmed.connect(func(): session.command("war", target); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(610, 200))

func show_notice(value: String):
	if status_label: status_label.text = value

func show_start():
	if is_instance_valid(title_screen): title_screen.hide()
	if is_instance_valid(modal): modal.queue_free()
	modal = AcceptDialog.new()
	modal.title = "Neue Partie · Szenario wählen"
	modal.get_ok_button().text = "Zurück"
	modal.confirmed.connect(func():
		if not campaign_started: show_main_menu())
	modal.canceled.connect(func():
		if not campaign_started: show_main_menu())
	add_child(modal)
	var setup_scroll = ScrollContainer.new()
	setup_scroll.custom_minimum_size = Vector2(750, 570)
	setup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(setup_scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_scroll.add_child(box)
	box.add_child(label("Zwei Epochen. Dein politischer Kurs.", 28, GOLD))
	var years = HBoxContainer.new()
	box.add_child(years)
	for value in [1936, 2026]:
		var b = button(years, "1936 · Europa am Scheideweg" if value == 1936 else "2026 · Europa der Gegenwart", func(): setup_year = value; refresh_setup())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_content = VBoxContainer.new()
	box.add_child(setup_content)
	refresh_setup()
	modal.popup_centered()

func refresh_setup():
	clear(setup_content)
	var scenario = session.sim.Scenarios.get_scenario(setup_year)
	setup_content.add_child(label("%d — %s" % [setup_year, scenario.title], 22, GOLD))
	paragraph(setup_content, scenario.description)
	setup_content.add_child(label("STAAT WÄHLEN UND PARTIE STARTEN", 11, GOLD))
	var grid = GridContainer.new()
	grid.columns = 3
	setup_content.add_child(grid)
	for i in range(scenario.countries.size()):
		var entry = scenario.countries[i]
		var b = button(grid, entry.name, func(): session.solo(i, setup_year); selected = i; campaign_started = true; panel_open = false; refresh(); modal.hide(); map.fit_world())
		b.custom_minimum_size.x = 230
		b.tooltip_text = "Industrie %d · Armee %d · Qualität %.2f · %s" % [entry.industry, entry.army, entry.quality, "Freie Wahlen" if entry.democratic else "Autoritäre Regierung"]
	paragraph(setup_content, "Globale Referenzkarte mit 242 Ländern und Gebieten und europäischen Kampagnenländern. Historische Grenzen sind schematisch; Wirtschaft, Militär und politische Anteile sind Spielwerte. Personen und Parteien beziehen sich auf den Szenariostart am 1. Januar; spätere Regierungswechsel folgen der Simulation. Der Verlauf ist frei, keine festgelegte Geschichtswiederholung.")
	paragraph(setup_content, "Mit ▶ oder Leertaste starten. WASD: Karte bewegen; Umschalt: schneller; Mausrad: Zoom; Rechts/Mitte ziehen: verschieben. Welt und Mein Land wechseln die Ansicht. Außerhalb der Kampagnenländer zeigt die Weltkarte moderne Referenzgrenzen, auch im Szenario 1936.")

func show_menu():
	if session.is_host() and session.running: session.toggle_pause()
	var menu = AcceptDialog.new()
	menu.title = "Staatskunst · Menü"
	menu.get_ok_button().text = "Zurück"
	add_child(menu)
	menu.confirmed.connect(menu.queue_free)
	var menu_scroll = ScrollContainer.new()
	menu_scroll.custom_minimum_size = Vector2(490, 470)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(menu_scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.add_child(box)
	button(box, "Partie speichern", func():
		if not session.is_host(): show_notice("Nur der Host kann speichern."); return
		var error = session.sim.save_game("user://campaign-v4.json", session.player_id)
		show_notice("Partie gespeichert." if error == OK else "Speichern fehlgeschlagen: %s" % error_string(error)))
	var load_button = button(box, "Gespeicherte Partie laden", func():
		var id = session.sim.read_game("user://campaign-v4.json")
		if id < 0: show_notice("Kein gültiger Spielstand gefunden."); return
		session.player_id = id
		session.running = false
		selected = id
		refresh()
		menu.hide()
		show_notice("Partie geladen und pausiert."))
	load_button.disabled = session.online
	var new_button = button(box, "Neue Partie", func(): menu.hide(); show_start())
	new_button.disabled = session.online
	button(box, "LAN / Direkte IP", func(): menu.hide(); show_network())
	button(box, "Spielanleitung", func(): menu.hide(); show_help())
	button(box, "Einstellungen", func(): menu.hide(); show_settings())
	button(box, "Zum Hauptmenü", func(): menu.hide(); show_main_menu())
	button(box, "Über die Politikerbilder", func(): menu.hide(); show_portrait_info())
	paragraph(box, "Staatskunst 0.8.1 · Godot 4.5\nReale Staaten · Szenarien 1936 und 2026\nKartengrundlage: Natural Earth (Public Domain)\nLokaler Spielstand: " + OS.get_user_data_dir())
	button(box, "Spiel beenden", func(): get_tree().quit())
	menu.popup_centered()

func show_portrait_info():
	var dialog = AcceptDialog.new()
	dialog.title = "Über die Politikerbilder"
	dialog.get_ok_button().text = "Schließen"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(540, 300)
	dialog.add_child(box)
	paragraph(box, "Porträts anklicken für eine große Ansicht mit Quelle und Lizenz.")
	paragraph(box, "307 reale Personen: Wikimedia-Fotos. Manuel Giménez Fernández: gekennzeichnete KI-Illustration ohne gesicherte historische Ähnlichkeit. Sechs CfD-Politiker: erfundene Figuren mit eigenen Illustrationen.")
	paragraph(box, "Der Weltatlas ergänzt weitere Politikerfotos. Nachweise: WORLD-PORTRAIT-CREDITS.md. Nicht verfügbare Fotos sind in der jeweiligen Akte gekennzeichnet.")
	paragraph(box, "Sämtliche Bilder sind offline enthalten. Fotos behalten ihre jeweiligen Lizenzen. Nachweise: PORTRAIT-CREDITS.md im Download.")
	dialog.popup_centered()

func show_network():
	network_window = AcceptDialog.new()
	network_window.title = "LAN / Direkte IP"
	network_window.get_ok_button().text = "Zurück"
	add_child(network_window)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(540, 340)
	network_window.add_child(box)
	paragraph(box, "Bis zu 8 Spieler. Der Host simuliert die Welt und steuert die Zeit. Gäste erhalten jeweils einen freien unabhängigen Staat.")
	var host_button = button(box, "Aktuelle Partie hosten · UDP 24560", func():
		var result = session.host_game()
		if result == OK: network_window.hide()
		else: show_notice("Host konnte nicht starten: " + error_string(result)))
	host_button.disabled = session.online
	var address = LineEdit.new()
	address.placeholder_text = "IP des Hosts, z. B. 192.168.1.20"
	box.add_child(address)
	var join_button = button(box, "Per IP beitreten", func():
		var result = session.join_game(address.text)
		if result == OK: network_window.hide()
		else: show_notice("Verbindung konnte nicht starten: " + error_string(result)))
	join_button.disabled = session.online
	paragraph(box, "LAN: lokale IPv4 des Hosts eingeben. Über Internet: öffentliche IP des Hosts und UDP-Port 24560 im Router auf dessen Rechner weiterleiten. Kein Matchmaking, kein Konto, kein zentraler Server.")
	var leave_button = button(box, "Verbindung trennen", func(): session.disconnect_session(); network_window.hide())
	leave_button.disabled = not session.online
	network_window.popup_centered()

func show_help():
	var help = AcceptDialog.new()
	help.title = "So spielst du Staatskunst"
	help.dialog_text = "STAAT: Ziele, Ereignisse und laufende Projekte.\nPARTEIEN: Wahlkampf, Koalitionen und Regierungswechsel.\nKABINETT: Minister aus den Koalitionsparteien ernennen.\nWIRTSCHAFT: Sektoren, Vorräte, Steuern, Budgets und Schulden.\nKRIEG: Verlauf, Verluste, Versorgung und Wochenberichte.\nAUSLAND: Land auf der Karte auswählen; handeln oder Krieg erklären.\n\nEin Tag dauert bei 1× eine Sekunde. Leertaste pausiert.\nEin Modellmonat hat 30 Tage, ein Modelljahr 360 Tage.\nProjekte: maximal zwei gleichzeitig. Entscheidungen: 15 Tage Abklingzeit.\nRegelmäßige Wahlen: alle 180 Tage. Ereignisse: alle 75 Tage.\nKriegsfortschritt folgt relativer Stärke inklusive Versorgung und Budget.\nEin Sieg gliedert alle Gebiete des Verlierers ein.\n\nSIEG: 5 Länder oder ab Tag 365 mindestens 100 Industrie / 75 Stabilität.\nSPEICHERN: Menü → Partie speichern. Nur der Host kann speichern.\nBei Host-Trennung kannst du den Stand alleine weiterspielen."
	add_child(help)
	help.confirmed.connect(help.queue_free)
	help.popup_centered(Vector2i(720, 450))

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(title_screen) and title_screen.visible:
			if campaign_started: title_screen.hide()
		else: show_menu()
		return
	if is_instance_valid(title_screen) and title_screen.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if get_viewport().gui_get_focus_owner() is LineEdit: return
		session.toggle_pause()

func show_main_menu():
	if session.is_host() and session.running: session.toggle_pause()
	if is_instance_valid(title_screen):
		remove_child(title_screen)
		title_screen.queue_free()
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(title_screen)
	var backdrop = TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/strategy-room.png"): backdrop.texture = load("res://assets/strategy-room.png")
	title_screen.add_child(backdrop)
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.035, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(shade)
	var layout = MarginContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: layout.add_theme_constant_override("margin_" + edge, 32)
	title_screen.add_child(layout)
	var row = HBoxContainer.new()
	layout.add_child(row)
	var menu = VBoxContainer.new()
	menu.custom_minimum_size.x = 420
	menu.add_theme_constant_override("separation", 8)
	row.add_child(menu)
	menu.add_child(label("P O L I T I S C H E   G L O B A L S T R A T E G I E", 11, GOLD))
	menu.add_child(label("STAATSKUNST", 48, Color("e8d9b1")))
	paragraph(menu, "Entscheidungen verändern die Welt.\n1936 / 2026", Color("b7b8a5"))
	var gap = Control.new()
	gap.custom_minimum_size.y = 20
	menu.add_child(gap)
	var resume = button(menu, "Partie fortsetzen", func(): title_screen.hide())
	resume.disabled = not campaign_started
	button(menu, "Neue Kampagne", show_start).disabled = session.online
	var load_button = button(menu, "Spielstand laden", load_from_title)
	load_button.disabled = session.online or not FileAccess.file_exists("user://campaign-v4.json")
	button(menu, "LAN / Direkte IP", func(): campaign_started = true; title_screen.hide(); show_network())
	button(menu, "Einstellungen", show_settings)
	button(menu, "Spielanleitung", show_help)
	button(menu, "Bildquellen & Mitwirkende", show_portrait_info)
	button(menu, "Spiel beenden", func(): get_tree().quit())
	for child in menu.get_children():
		if child is Button:
			for state in ["normal", "hover", "pressed", "disabled"]:
				var button_style = child.get_theme_stylebox(state).duplicate()
				button_style.content_margin_top = 7
				button_style.content_margin_bottom = 7
				child.add_theme_stylebox_override(state, button_style)
	var bottom_gap = Control.new()
	bottom_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_child(bottom_gap)
	paragraph(menu, "VERSION 0.8.1 · GODOT\nWeltkarte: Natural Earth · Eigene Spielgrafik\n16 / 17 europäische Kampagnenländer", Color("b7b8a5"))
	var space = Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)

func load_from_title():
	var id = session.sim.read_game("user://campaign-v4.json")
	if id < 0:
		var error = AcceptDialog.new()
		error.dialog_text = "Der Spielstand konnte nicht geladen werden."
		add_child(error)
		error.confirmed.connect(error.queue_free)
		error.popup_centered()
		return
	session.player_id = id
	session.running = false
	selected = id
	campaign_started = true
	title_screen.hide()
	refresh()

func show_settings():
	if session.is_host() and session.running: session.toggle_pause()
	if is_instance_valid(settings_window): settings_window.queue_free()
	settings_window = AcceptDialog.new()
	settings_window.title = "Einstellungen"
	settings_window.get_ok_button().text = "Fertig"
	settings_window.confirmed.connect(settings_window.queue_free)
	settings_window.canceled.connect(settings_window.queue_free)
	add_child(settings_window)
	var pages = TabContainer.new()
	pages.custom_minimum_size = Vector2(650, 390)
	settings_window.add_child(pages)
	var graphics = settings_page(pages, "Grafik")
	setting_toggle(graphics, "Vollbild", "fullscreen")
	setting_toggle(graphics, "VSync", "vsync")
	paragraph(graphics, "Bildratenlimit")
	var fps = OptionButton.new()
	for value in [30, 60, 120, 0]: fps.add_item("Unbegrenzt" if value == 0 else "%d FPS" % value, value)
	fps.select([30, 60, 120, 0].find(preferences.fps_limit))
	fps.item_selected.connect(func(index): preferences.fps_limit = fps.get_item_id(index); save_settings())
	graphics.add_child(fps)
	paragraph(graphics, "VSync synchronisiert die Darstellung mit deinem Bildschirm. Das FPS-Limit begrenzt zusätzlich die Bildrate. Einstellungen werden sofort angewendet und gespeichert.")
	var cartography = settings_page(pages, "Karte")
	setting_toggle(cartography, "Ländernamen anzeigen", "labels")
	setting_toggle(cartography, "Gradnetz anzeigen", "map_grid")
	setting_toggle(cartography, "Minikarte anzeigen", "minimap")
	setting_toggle(cartography, "Kriegsanimationen", "animations")
	paragraph(cartography, "Zoomgeschwindigkeit")
	var slider = HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 2.0
	slider.step = 0.1
	slider.value = preferences.zoom_speed
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect(func(value): preferences.zoom_speed = value; save_settings())
	cartography.add_child(slider)
	var controls = settings_page(pages, "Steuerung")
	paragraph(controls, "WASD · Karte bewegen (W Norden, A Westen, S Süden, D Osten)\nUmschalt halten · Doppelte Bewegungsgeschwindigkeit\nMausrad · Karte zoomen\nRechte oder mittlere Maustaste ziehen · Karte verschieben\nLinksklick · Kampagnenland auswählen\nWelt · Ganze Welt einpassen\nMein Land · Auf deine Regierung zoomen\nAkte schließen · Karte vergrößern\nLeertaste · Zeit pausieren / fortsetzen\nEscape · Spielmenü öffnen")
	paragraph(controls, "Die Weltkarte zeigt 242 Länder und Gebiete. Spielbar sind die Länder der jeweiligen Kampagne. Außerhalb davon werden moderne Referenzgrenzen dargestellt, auch 1936.")
	settings_window.popup_centered()

func settings_page(pages: TabContainer, caption: String) -> VBoxContainer:
	var viewport = ScrollContainer.new()
	viewport.name = caption
	viewport.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pages.add_child(viewport)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport.add_child(box)
	return box

func setting_toggle(parent: Node, caption: String, key: String):
	var toggle = CheckButton.new()
	toggle.text = caption
	toggle.button_pressed = preferences.get(key)
	toggle.toggled.connect(func(value): preferences.set(key, value); save_settings())
	parent.add_child(toggle)

func save_settings():
	preferences.apply_display()
	map.queue_redraw()
	var result = preferences.save()
	if result != OK: show_notice("Einstellungen konnten nicht gespeichert werden: " + error_string(result))

func banner(parent: Node, height: int = 150):
	var picture = TextureRect.new()
	picture.texture = load("res://assets/parliament.png")
	picture.custom_minimum_size.y = height
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	parent.add_child(picture)

func leader_pictures(parent: Node, c: Dictionary):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	for person_name in [c.head_name, c.premier]: portrait(row, find_person(c, person_name), 72)

func portrait(parent: Node, person: Dictionary, edge: int = 110):
	var picture = TextureRect.new()
	picture.texture = Portraits.texture(person)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(edge, edge)
	picture.tooltip_text = person.get("name", "") + (" · KI-Illustration" if Portraits.credit(person).get("kind", "") == "illustration" else "") + " · Anklicken: Porträt und Bildquelle"
	picture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	picture.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			show_portrait(person)
			picture.accept_event())
	picture.focus_mode = Control.FOCUS_ALL
	picture.gui_input.connect(func(event):
		if event.is_action_pressed("ui_accept"): show_portrait(person); picture.accept_event())
	parent.add_child(picture)
	return picture

func show_portrait(person: Dictionary):
	var dialog = AcceptDialog.new()
	dialog.title = person.get("name", "Porträt")
	dialog.get_ok_button().text = "Schließen"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(480, 0)
	dialog.add_child(box)
	var picture = TextureRect.new()
	picture.texture = Portraits.texture(person)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(280, 280)
	box.add_child(picture)
	paragraph(box, person.get("name", ""), GOLD)
	if person.get("fictional", false):
		paragraph(box, "Fiktive Spielfigur der Christen für Deutschland. KI-generiertes Porträt für Staatskunst.")
	else:
		var source = Portraits.credit(person)
		paragraph(box, ("Illustration: " if source.get("kind", "") == "illustration" else "Foto: ") + source.get("author", "Nicht verfügbar"))
		paragraph(box, "Lizenz: " + source.get("license", "—"))
		if not source.get("attribution", "").is_empty(): paragraph(box, source.attribution)
		paragraph(box, source.get("note", "Wikimedia-Vorschaubild unverändert übernommen; Anzeige skaliert. Aufnahmen können aus einem anderen Jahr als dem Szenariostart stammen."))
		if source.has("source"): button(box, "Bildquelle und vollständige Lizenz öffnen ↗", func(): OS.shell_open(source.source))
		if not source.get("license_url", "").is_empty(): button(box, "Lizenzbedingungen öffnen ↗", func(): OS.shell_open(source.license_url))
	dialog.popup_centered()

func find_person(c: Dictionary, person_name: String) -> Dictionary:
	for person in session.sim.Politics.candidates(session.sim.year(), c.code):
		if person.name == person_name: return person
	return {"name": person_name}

func budget_preview(action: String) -> String:
	var sim = session.sim
	var c = sim.country(session.player_id).duplicate(true)
	var before = sim.Economy.ledger(c, sim.year(), sim.war_count(session.player_id)).balance
	var key = action.get_slice("_", 0)
	if action in ["tax_up", "tax_down"]:
		c.tax += 5 if action.ends_with("up") else -5
		c.stability = clampf(c.stability + (-5 if action.ends_with("up") else 4), 0, 100)
	elif key in ["social", "education", "defense", "corporate", "vat"]:
		c.econ[key] += (5 if key in ["corporate", "vat"] else 10) * (1 if action.ends_with("up") else -1)
	else: return ""
	var after = sim.Economy.ledger(c, sim.year(), sim.war_count(session.player_id)).balance
	return "Haushaltswirkung sofort: %+.1f M / Monat" % (after - before)

func constitution_tab(c: Dictionary):
	var sim = session.sim
	var law = c.law
	banner(content, 150)
	heading(law.name + " & Staatsordnung", "Amtierende Regierung: %s · %s" % [sim.parties(session.player_id)[int(c.ruling)].name, c.premier])
	var info = grid(content, 3)
	for entry in [["RECHTSSTAAT", law.rule_of_law], ["PRESSEFREIHEIT", law.press], ["WIDERSTAND", law.resistance]]:
		var box = card(info)
		box.add_child(label(entry[0], 11, GOLD))
		box.add_child(label("%.0f / 100" % entry[1], 24))
		bar(box, entry[1])
	paragraph(content, "Staatsform: " + ("Demokratie" if c.democratic else "Diktatur / autoritäre Regierung") + (" · Verfassungsbruch" if law.breached else ""), GOLD)
	if c.code == "DEU" and sim.year() == 2026:
		var articles = grid(content)
		for entry in [["Art. 1 & 20", "Menschenwürde, Demokratie, Sozialstaat und Bindung staatlicher Gewalt an Recht und Verfassung."], ["Art. 5", "Meinungs- und Pressefreiheit. Staatliche Zensur ist untersagt."], ["Art. 21 & 38", "Parteien wirken an politischer Willensbildung mit; die Bundestagswahl ist frei und gleich."], ["Art. 79", "Änderungen benötigen Zweidrittelmehrheiten in Bundestag und Bundesrat. Die in Art. 1 und 20 geschützten Grundsätze sind einer Änderung entzogen."]]:
			var box = card(articles)
			box.add_child(label(entry[0], 17, GOLD))
			paragraph(box, entry[1])
		paragraph(content, "Kurzfassung der Grundgesetz-Grundsätze. Unterstützung im Spiel ist keine echte Sitz- oder Bundesratsmehrheit. Die folgenden Machtaktionen sind ein fiktiver Verfassungsbruch, keine rechtmäßige Änderung des Grundgesetzes.")
	else:
		paragraph(content, "Abstrakte Verfassungsregeln dieser Epoche. Das Grundgesetz von 1949 gilt im 1936-Szenario nicht. Pressefreiheit, Rechtsstaat und freie Wahlen werden als Spielwerte dargestellt.")
	content.add_child(label("ALTERNATIVER MACHTPFAD", 15, GOLD))
	paragraph(content, "Zuerst eine andere Partei an die Regierung bringen: zum Beispiel AfD oder die fiktive CfD. Danach sind bewusste autoritäre Entscheidungen möglich. Keine Partei löst diesen Verlauf automatisch aus. Widerstand, Stabilitätsverluste, zusätzliche Kosten und schlechtere Kreditbedingungen sind die Folgen.")
	var stages = grid(content, 3)
	for entry in [["crisis", "1 · Verfassungskrise", "Neue Regierungspartei, Koalitionsmehrheit, 15 Tage im Amt. 100 Einfluss. −8 Stabilität, Rechtsstaat sinkt auf 65."], ["centralize", "2 · Machtzentralisierung", "30 Tage nach Krisenbeginn. 100 Einfluss. −10 Stabilität, Rechtsstaat und Pressefreiheit sinken auf 35."], ["dictatorship", "3 · Diktatur", "Weitere 30 Tage, mindestens 30 % Unterstützung der Regierungspartei. 150 Einfluss. −12 Stabilität, freie Wahlen enden."]]:
		var box = card(stages)
		box.add_child(label(entry[1], 16, GOLD))
		paragraph(box, entry[2])
		add_action("law_" + entry[0], box, sim.Constitution.TITLES[entry[0]], "Bewusster alternativer Spielpfad")
	if c.democratic: add_action("law_defend", content, "Verfassung verteidigen · 60 Einfluss", "Krise beenden, Grundrechte wiederherstellen, +5 Stabilität")
	else: add_action("democratize")
	paragraph(content, "Eine andere gewählte Regierung beendet den laufenden Machtpfad. Nach Errichtung einer Diktatur bleiben Wirtschafts-, Kabinetts- und Außenpolitik spielbar; Wahlkampf ist gesperrt.")

func confirm_law(action: String):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Staatsordnung verändern"
	dialog.dialog_text = "Diesen alternativen Spielpfad bewusst fortsetzen?\nDie Aktion verletzt die demokratische Verfassungsordnung.\nWiderstand, Stabilitätsverlust und wirtschaftliche Kosten folgen.\nKosten: %.0f Einfluss." % session.sim.Constitution.COSTS[action.trim_prefix("law_")]
	dialog.confirmed.connect(func(): session.command(action); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(650, 220))
