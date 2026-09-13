extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var failures = 0
var checks = 0
var sim
const ALL_HUMANS = [0,1,2,3,4,5,6,7]

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func reset():
	sim = Simulation.new()
	sim.new_game()

func days(count: int):
	for i in range(count): sim.advance(ALL_HUMANS)

func _initialize():
	reset()
	check(sim.state.countries.size() == 8, "Eight countries")
	check(sim.reason(0, "war", 0) != "", "No self war")
	check(sim.reason(0, "war", 7) != "", "No non-neighbor war")
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
	check(sim.reason(0, "war", 3) != "", "One concurrent war per country")
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
	print("SIMULATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
