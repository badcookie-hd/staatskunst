extends Control
const Session = preload("res://scripts/session.gd")
const WorldMap = preload("res://scripts/world_map.gd")
const GOLD = Color("ddbf7e")
const MUTED = Color("91a7ac")
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

func _ready():
	build_theme()
	session = Session.new()
	session.name = "Session"
	add_child(session)
	session.updated.connect(refresh)
	session.notice.connect(show_notice)
	build_ui()
	refresh()
	show_start()

func style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 6) -> StyleBoxFlat:
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
	t.set_stylebox("normal", "Button", style(Color("1e363e"), Color("354c50")))
	t.set_stylebox("hover", "Button", style(Color("2d4c53"), GOLD))
	t.set_stylebox("pressed", "Button", style(Color("40554e"), GOLD))
	t.set_stylebox("disabled", "Button", style(Color("162b32"), Color("253b41")))
	t.set_stylebox("focus", "Button", style(Color(0,0,0,0), GOLD))
	t.set_stylebox("panel", "AcceptDialog", style(Color("142b33"), Color("62766e")))
	t.set_stylebox("normal", "LineEdit", style(Color("0d2129"), Color("48636a")))
	t.set_color("font_color", "LineEdit", Color("e3e9e7"))
	t.set_stylebox("background", "ProgressBar", style(Color("142a32"), Color.TRANSPARENT, 3))
	t.set_stylebox("fill", "ProgressBar", style(Color("bfa66e"), Color.TRANSPARENT, 3))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	theme = t

func label(text_value: String, size_value: int = 15, color: Color = Color("e3e9e7")) -> Label:
	var l = Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size_value)
	l.add_theme_color_override("font_color", color)
	return l

func paragraph(parent: Node, value: String, color: Color = MUTED):
	var l = label(value, 14, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)

func button(parent: Node, value: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = value
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func panel(parent: Node, color: Color = Color("142a32")) -> VBoxContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color, Color("2b4248")))
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
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	margin.add_child(root_box)
	var header = HBoxContainer.new()
	root_box.add_child(header)
	var brand = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(label("S T A A T S K U N S T", 26, GOLD))
	brand.add_child(label("MACHT IST EINE FRAGE DER ENTSCHEIDUNG", 10, MUTED))
	date_label = label("", 17)
	header.add_child(date_label)
	pause_button = button(header, "▶ Fortsetzen", func(): session.toggle_pause())
	for speed in [1, 3, 5]: button(header, "%d×" % speed, func(): session.set_speed(speed))
	button(header, "Menü", show_menu)
	stats = HBoxContainer.new()
	root_box.add_child(stats)
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(body)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var map_header = HBoxContainer.new()
	left.add_child(map_header)
	nation_label = label("", 16)
	nation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_header.add_child(nation_label)
	map_header.add_child(label("POLITISCHE KARTE  /  8 STAATEN", 11, MUTED))
	map = WorldMap.new()
	map.sim = session.sim
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(520, 320)
	map.selected.connect(func(id): selected = id; refresh())
	left.add_child(map)
	var key = HBoxContainer.new()
	left.add_child(key)
	key.add_child(label("◎ Dein Staatsgebiet     ━ Ausgewählter Staat     ┄ Aktiver Krieg", 12, MUTED))
	var journal = panel(left)
	journal.add_child(label("LAGEBERICHT", 11, GOLD))
	chronicle = VBoxContainer.new()
	journal.add_child(chronicle)
	var side = PanelContainer.new()
	side.custom_minimum_size.x = 400
	side.add_theme_stylebox_override("panel", style(Color("142a32"), Color("30464a")))
	body.add_child(side)
	var side_box = VBoxContainer.new()
	side.add_child(side_box)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	side_box.add_child(tabs)
	var names = ["Staat", "Politik", "Wirtschaft", "Ausland"]
	for i in range(4):
		var b = button(tabs, names[i], func(): tab = i; scroll.scroll_vertical = 0; refresh())
		b.add_theme_font_size_override("font_size", 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_buttons.append(b)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	status_label = label("Wähle ein Land und gestalte seine Zukunft. Leertaste: Pause.", 13, GOLD)
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	root_box.add_child(status_label)

func refresh():
	if stats == null: return
	var sim = session.sim
	var c = sim.country(session.player_id)
	clear(stats)
	metric("STAATSMITTEL", "%.0f M" % c.money, "%+.1f M / Monat" % sim.income(session.player_id))
	metric("POLITISCHER EINFLUSS", "%.0f" % c.influence, "Für Gesetze und Entscheidungen")
	metric("STABILITÄT", "%.0f %%" % c.stability, sim.PARTIES[int(c.ruling)] + " regieren")
	metric("INDUSTRIE", "%.0f" % c.industry, "%d %% Steuern · %d Handelsverträge" % [c.tax, c.trade])
	metric("STREITKRÄFTE", "%.0f Tsd." % c.army, "Qualität %.2f · Stärke %.0f" % [c.quality, sim.power(session.player_id)])
	date_label.text = "%s   ·   %d×" % [date_text(int(sim.state.day)), session.speed]
	pause_button.text = "Ⅱ Pause" if session.running else "▶ Fortsetzen"
	pause_button.disabled = not session.is_host() or int(sim.state.winner) >= 0
	nation_label.text = "%s  /  %s" % [c.name.to_upper(), "LAN · %d Spieler" % session.players.size() if session.online else "EINZELSPIELER"]
	map.selected_id = selected
	map.player_id = session.player_id
	map.queue_redraw()
	for i in range(4): tab_buttons[i].modulate = GOLD if tab == i else Color.WHITE
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
		2: economy_tab(c)
		3: foreign_tab(c)
	clear(chronicle)
	for entry in sim.state.log.slice(0, 3):
		var l = label("%s   %s" % [date_text(int(entry.day)), entry.text], 12, MUTED)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chronicle.add_child(l)

func metric(title: String, value: String, detail: String):
	var box = panel(stats)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(label(title, 10, MUTED))
	box.add_child(label(value, 25, GOLD))
	box.add_child(label(detail, 11, MUTED))

func date_text(day: int) -> String:
	return "%02d.%02d.%d" % [day % 30 + 1, (day / 30) % 12 + 1, 1936 + day / 360]

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
	heading("Das Kabinett", "Dein Kurs für %s. Jede Entscheidung verändert das politische Gleichgewicht." % c.name)
	var goal = panel(content, Color("203a3e"))
	goal.add_child(label("DEIN WEG ZUM SIEG", 11, GOLD))
	paragraph(goal, "Wohlstand: ab Tag 365 mindestens 100 Industrie und 75 % Stabilität. Oder: fünf der acht Länder kontrollieren.")
	bar(goal, c.industry)
	paragraph(goal, "%.0f / 100 Industrie   ·   %d / 5 Länder" % [c.industry, session.sim.territories(session.player_id)])
	if int(c.event) >= 0:
		var titles = ["Streik im Industriegebiet", "Die Energiefrage", "Eine neue Generation"]
		var bodies = ["Gewerkschaften fordern sichere Arbeitsplätze und Investitionen.", "Die Städte verlangen eine verlässliche öffentliche Versorgung.", "Studierende fordern moderne Schulen und berufliche Perspektiven."]
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

func politics_tab(c: Dictionary):
	heading("Parteien & Parlament", "Nächste Wahl in %d Tagen. Die stärkste Partei übernimmt automatisch die Regierung." % (180 - int(session.sim.state.day) % 180))
	var bonuses = ["+16 % Industrie als zusätzliche Monatseinnahmen", "+Stabilität, kostet 6 M pro Monat", "+0,25 politischer Einfluss pro Tag", "+0,75 Tsd. Soldaten / Monat, −Stabilität"]
	for i in range(4):
		var box = panel(content)
		box.add_child(label("%s   %.1f %% %s" % [session.sim.PARTIES[i], c.support[i], "• Regierung" if int(c.ruling) == i else ""], 15, GOLD if int(c.ruling) == i else Color("dce7e4")))
		bar(box, c.support[i])
		paragraph(box, bonuses[i])
		add_action("campaign_%d" % i, box, "Wahlkampf · 25 Einfluss", "+9 Unterstützung, übrige Parteien verlieren Anteile")

func economy_tab(c: Dictionary):
	heading("Wirtschaft & Aufbau", "Projekte belegen jeweils einen von zwei Plätzen. Einnahmen, Unterhalt und Steuern werden täglich abgerechnet.")
	projects(c)
	for action in ["industry", "research", "recruit", "tax_up", "tax_down"]: add_action(action)

func projects(c: Dictionary):
	if c.projects.is_empty(): paragraph(content, "2 freie Projektplätze. Investiere unter Wirtschaft.")
	for p in c.projects:
		var days = int(p.finish) - int(session.sim.state.day)
		paragraph(content, "%s · noch %d Tage" % [session.sim.ACTIONS[p.kind][0], days], GOLD)

func foreign_tab(_c: Dictionary):
	var sim = session.sim
	var target = int(sim.country(selected).owner)
	var c = sim.country(target)
	heading(c.name, "Klicke auf der Karte auf einen Staat, um Handel, Diplomatie oder einen Krieg vorzubereiten.")
	paragraph(content, "Stärke %.0f  ·  %.0f Tsd. Soldaten\nQualität %.2f  ·  Stabilität %.0f %%\nBeziehungen %+d" % [sim.power(target), c.army, c.quality, c.stability, sim.relation(session.player_id, target)])
	for w in sim.state.wars:
		if int(w.a) == target or int(w.b) == target or int(w.a) == session.player_id or int(w.b) == session.player_id:
			var box = panel(content)
			box.add_child(label("%s ↔ %s" % [sim.country(int(w.a)).name, sim.country(int(w.b)).name], 14, GOLD))
			bar(box, (w.progress + 100) / 2)
			paragraph(box, "Tag %d · Angreiferfortschritt %+.1f / 100\n+100: Angreifer siegt. −100: Verteidiger siegt." % [w.days, w.progress])
	for action in ["trade", "diplomacy", "war", "peace"]: add_action(action)
	paragraph(content, "Stärke = Größe × Qualität × Stabilitätsfaktor. Die stärkere Armee setzt sich über Zeit durch. Bei Gleichstand bleibt der Krieg stehen.")

func add_action(action: String, parent: Node = null, title: String = "", detail: String = ""):
	if parent == null: parent = content
	if title.is_empty():
		title = session.sim.ACTIONS[action][0]
		detail = session.sim.ACTIONS[action][1]
	var target = int(session.sim.country(selected).owner)
	var b = button(parent, title, func():
		if action == "war": confirm_war(target)
		else: session.command(action, target))
	var error = session.sim.reason(session.player_id, action, target)
	b.disabled = error != ""
	b.tooltip_text = error if error != "" else detail
	paragraph(parent, detail if error.is_empty() else error, MUTED)

func confirm_war(target: int):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Kriegserklärung"
	dialog.dialog_text = "Krieg gegen %s erklären?\n70 Einfluss, −12 Stabilität und 24 M Kriegsunterhalt / Monat.\nEigene Stärke: %.0f · Gegner: %.0f\nDer Krieg läuft automatisch, bis ein Staat gewinnt oder ein Waffenstillstand gilt." % [session.sim.country(target).name, session.sim.power(session.player_id), session.sim.power(target)]
	dialog.confirmed.connect(func(): session.command("war", target); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(610, 200))

func show_notice(value: String):
	if status_label: status_label.text = value

func show_start():
	modal = AcceptDialog.new()
	modal.title = "Willkommen bei Staatskunst"
	modal.get_ok_button().text = "Kabinett öffnen"
	add_child(modal)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(570, 470)
	modal.add_child(box)
	box.add_child(label("Eine Welt. Dein politischer Kurs.", 28, GOLD))
	paragraph(box, "1936, auf einem fiktiven Kontinent. Führe deinen Staat durch Wahlen, Wirtschaftskrisen und internationale Konflikte.")
	box.add_child(label("WÄHLE DEINEN STAAT", 11, GOLD))
	var grid = GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	for i in range(8):
		var b = button(grid, session.sim.NAMES[i], func(): session.solo(i); selected = i; refresh(); modal.hide())
		b.custom_minimum_size.x = 275
	paragraph(box, "1. Baue Industrie aus und halte den Haushalt im Plus.\n2. Fördere Parteien; alle 180 Tage wird gewählt.\n3. Nutze Diplomatie oder überlegene Streitkräfte.\n4. Gewinne durch Wohlstand oder fünf kontrollierte Länder.")
	paragraph(box, "Die Zeit ist pausiert. Mit ▶ oder Leertaste starten. Alle Armeen handeln automatisch. LAN / direkte IP findest du im Menü.")
	modal.popup_centered()

func show_menu():
	if session.is_host() and session.running: session.toggle_pause()
	var menu = AcceptDialog.new()
	menu.title = "Staatskunst · Menü"
	menu.get_ok_button().text = "Zurück"
	add_child(menu)
	menu.confirmed.connect(menu.queue_free)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(470, 430)
	menu.add_child(box)
	button(box, "Partie speichern", func():
		if not session.is_host(): show_notice("Nur der Host kann speichern."); return
		var error = session.sim.save_game("user://campaign.json", session.player_id)
		show_notice("Partie gespeichert." if error == OK else "Speichern fehlgeschlagen: %s" % error_string(error)))
	var load_button = button(box, "Gespeicherte Partie laden", func():
		var id = session.sim.read_game("user://campaign.json")
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
	paragraph(box, "Staatskunst 0.1.0 · Godot 4.5\nEin eigenständiges Strategiespiel mit fiktiven Staaten.\nLokaler Spielstand: " + OS.get_user_data_dir())
	button(box, "Spiel beenden", func(): get_tree().quit())
	menu.popup_centered()

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
	help.dialog_text = "STAAT: Ziele, Ereignisse und laufende Projekte.\nPOLITIK: Wahlkampf verändert die nächste Regierung.\nWIRTSCHAFT: Industrie, Qualität, Rekrutierung und Steuern.\nAUSLAND: Land auf der Karte auswählen; handeln oder Krieg erklären.\n\nEin Tag dauert bei 1× eine Sekunde. Leertaste pausiert.\nEin Modellmonat hat 30 Tage, ein Modelljahr 360 Tage.\nProjekte: maximal zwei gleichzeitig. Entscheidungen: 15 Tage Abklingzeit.\nRegelmäßige Wahlen: alle 180 Tage. Ereignisse: alle 75 Tage.\nKriegsfortschritt hängt allein von relativer Stärke ab.\nEin Sieg gliedert alle Gebiete des Verlierers ein.\n\nSIEG: 5 Länder oder ab Tag 365 mindestens 100 Industrie / 75 Stabilität.\nSPEICHERN: Menü → Partie speichern. Nur der Host kann speichern.\nBei Host-Trennung kannst du den Stand alleine weiterspielen."
	add_child(help)
	help.confirmed.connect(help.queue_free)
	help.popup_centered(Vector2i(720, 450))

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if get_viewport().gui_get_focus_owner() is LineEdit: return
		session.toggle_pause()
