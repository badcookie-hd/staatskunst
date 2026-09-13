extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var failures = 0
var checks = 0
var sim

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func reset():
	sim = Simulation.new()
	sim.new_game()
	# Stable unit-test fixture, separate from scenario balance data.
	sim.country(0).merge({"money":310.0,"industry":35.0,"stability":68.0,"army":48.0,"quality":1.0,"ruling":0,"support":[30.0,27.0,25.0,18.0],"democratic":true},true)
	sim.country(1).merge({"money":318.0,"industry":42.0,"stability":68.0,"army":59.0,"quality":1.15,"ruling":1},true)

func days(count: int):
	for i in range(count): sim.advance(range(sim.count()))

func _initialize():
	reset()
	check(sim.state.countries.size() == 16, "Sixteen countries in 1936")
	check(sim.reason(0, "war", 0) != "", "No self war")
	check(sim.reason(0, "war", 12) != "", "No non-neighbor war")
	check(sim.reason(-1, "industry") != "", "Invalid actor rejected")
	check(sim.reason(0, "cheat") != "", "Unknown action rejected")
	check(sim.reason(0, "campaign_99") != "", "Unknown party rejected")
	var before = sim.country(0).money
	var projected = sim.income(0)
	days(1)
	check(is_equal_approx(sim.country(0).money - before, projected / 30.0), "Budget includes ruling party")
	sim.act(0, "industry")
	check(sim.country(0).projects.size() == 1, "Project queued")
	check(sim.reason(0, "industry") != "", "Cannot overspend or spam")
	days(44)
	check(sim.country(0).industry == 35, "Construction takes time")
	days(1)
	check(sim.country(0).industry == 43, "Construction completes")
	reset()
	sim.country(0).money = 2000
	sim.act(0, "industry")
	sim.act(0, "research")
	check(sim.reason(0, "recruit") != "", "Two project limit")
	days(60)
	check(is_equal_approx(sim.country(0).quality, 1.25), "Research quality increase")
	reset()
	sim.act(0, "campaign_3")
	check(sim.country(0).support[3] > 18, "Campaign changes support")
	check(sim.reason(0, "campaign_2") != "", "Shared campaign cooldown")
	var total = 0.0
	for value in sim.country(0).support: total += value
	check(absf(total - 100) < 0.001, "Support normalized")
	sim.country(0).support = [5.0, 10.0, 75.0, 10.0]
	days(180)
	check(int(sim.country(0).ruling) == 2, "Election changes government")
	reset()
	sim.country(0).money = 5000
	sim.country(0).army = 200
	sim.country(0).quality = 2
	sim.act(0, "war", 1)
	check(sim.state.wars.size() == 1, "War starts")
	days(1)
	check(sim.alive(1), "War not instant")
	check(sim.state.wars[0].progress > 0, "Stronger attacker advances")
	check(sim.reason(0, "war", 6) != "", "One concurrent war per country")
	days(80)
	check(int(sim.country(1).owner) == 0, "Stronger army wins over time")
	check(sim.state.wars.is_empty(), "Completed war removed")
	check(sim.reason(1, "industry") != "", "Defeated state cannot act")
	reset()
	sim.country(1).army = 250
	sim.country(1).money = 5000
	sim.act(0, "war", 1)
	days(90)
	check(int(sim.country(0).owner) == 1, "Stronger defender wins")
	reset()
	sim.country(0).army = 100
	sim.country(1).army = 100
	sim.country(1).quality = 1
	sim.country(1).ruling = 0
	sim.country(1).stability = 56
	sim.act(0, "war", 1)
	days(31)
	check(absf(sim.state.wars[0].progress) < 0.001, "Equal armies stalemate")
	check(sim.reason(0, "peace", 1) == "", "Stalemate allows peace")
	sim.act(0, "peace", 1)
	check(sim.state.wars.is_empty(), "Armistice ends war")
	sim.country(0).influence = 200
	check(sim.reason(0, "war", 1) != "", "Truce prevents immediate war")
	reset()
	sim.country(0).money = 0
	sim.country(0).army = 5000
	days(1)
	check(sim.country(0).money >= 0 and sim.country(0).army < 5000, "Bankruptcy reduces army")
	reset()
	days(75)
	check(sim.country(0).event >= 0, "Scheduled event")
	sim.act(0, "event_1")
	check(sim.country(0).event == -1, "Event resolved")
	reset()
	check(sim.save_game("user://test-save.json", 3) == OK, "Save succeeds")
	sim.country(0).money = 1
	check(sim.read_game("user://test-save.json") == 3, "Saved player restored")
	check(sim.country(0).money == 310, "State restored")
	var file = FileAccess.open("user://bad-save.json", FileAccess.WRITE)
	var bad = sim.state.duplicate(true)
	bad.countries[0].projects = [{"kind": "bad", "finish": 1}]
	file.store_string(JSON.stringify({"state": bad, "player": 0}))
	file.close()
	check(sim.read_game("user://bad-save.json") == -1, "Malformed save rejected")
	check(sim.country(0).money == 310, "Bad load preserves current state")
	reset()
	sim.country(0).industry = 100
	sim.country(0).stability = 90
	sim.state.day = 364
	days(1)
	check(int(sim.state.winner) == 0, "Prosperity victory")
	check(sim.reason(0, "industry") != "", "Completed games reject actions")
	reset()
	for i in range(5): sim.country(i).owner = 0
	days(1)
	check(int(sim.state.winner) == 0, "Territorial victory")
	reset()
	for i in range(1800): sim.advance([])
	for c in sim.state.countries:
		check(is_finite(c.money) and c.money >= 0 and c.stability >= 0 and c.stability <= 100, "Long simulation invariants " + c.name)
	for scenario_year in [1936,2026]:
		sim.new_game(scenario_year)
		check(sim.year() == scenario_year, "Scenario selected %d" % scenario_year)
		check(sim.count() == (16 if scenario_year == 1936 else 17), "Scenario country count")
		check(sim.country(0).name == ("Deutsches Reich" if scenario_year == 1936 else "Deutschland"), "Era-specific German name")
		check(sim.country(7).name == ("Tschechoslowakei" if scenario_year == 1936 else "Tschechien"), "Era-specific Czech state")
		check(sim.country(0).democratic == (scenario_year == 2026), "Regime differs")
		check(sim.borders(0,1) and sim.borders(2,1), "Land and maritime access")
		check(not sim.borders(0,12), "No Germany-Portugal border")
		for c in sim.Scenarios.get_scenario(scenario_year).countries:
			for n in c.neighbors:
				check(float(c.id) in sim.Scenarios.get_scenario(scenario_year).countries[int(n)].neighbors, "Symmetric borders")
		check(sim.save_game("user://scenario-test.json", sim.count()-1) == OK, "Scenario save")
		sim.new_game(2026 if scenario_year == 1936 else 1936)
		check(sim.read_game("user://scenario-test.json") == sim.count()-1 and sim.year() == scenario_year, "Scenario restored across eras")
		days(75)
		check(sim.country(0).event >= 0, "Events in both eras")
	sim.new_game(1936)
	check(sim.reason(0,"campaign_0") != "", "Dictatorship blocks free campaigns")
	sim.country(0).support = [90.0,4.0,3.0,3.0]
	days(180)
	check(int(sim.country(0).ruling) == 3, "Dictatorship has no automatic election")
	sim.country(0).money = 1000
	sim.country(0).influence = 200
	sim.act(0,"democratize")
	check(sim.country(0).democratic, "Constitution enables democracy")
	check(sim.reason(0,"campaign_0") == "", "Campaign unlocked by reform")
	days(180)
	check(int(sim.country(0).ruling) == 0, "Reformed state elects government")
	var historic_polygons = sim.Scenarios.get_scenario(1936).countries[0].polygons
	var modern_polygons = sim.Scenarios.get_scenario(2026).countries[0].polygons
	check(historic_polygons != modern_polygons and historic_polygons.size() == 2, "Historical Germany includes separate East Prussia")
	sim.new_game(2026)
	check(sim.country(0).quality > 2 and sim.ACTIONS.industry[0] == "Digitale Infrastruktur", "Modern technology and decisions")
	print("SIMULATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
