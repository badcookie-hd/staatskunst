extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var checks = 0
var failures = 0
var sim = Simulation.new()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("SIM FAIL: " + message)

func reset(era: int = 2026):
	sim.new_game(era)
	sim.country(0).influence = 250

func _initialize():
	reset()
	var c = sim.country(0)
	check(sim.parties(0).size() == 8, "Germany has seven actual parties and fictional CfD")
	check(sim.parties(0)[0].name == "CDU" and sim.parties(0)[1].name == "CSU", "Christian parties")
	check(c.head_name == "Frank-Walter Steinmeier" and c.premier == "Friedrich Merz", "Separate offices")
	check(sim.Politics.person(2026, c.code, c.cabinet.finance).name == "Lars Klingbeil", "Initial German finance minister")
	check(sim.Politics.person(2026, c.code, c.cabinet.defense).name == "Boris Pistorius", "Initial German defense minister")
	check(sim.reason(0, "appoint_finance_0:0") != "", "Premier cannot double as minister")
	check(sim.reason(0, "appoint_finance_99:0") != "", "Unknown candidate denied")
	check(sim.reason(0, "appoint_invalid_0:1") != "", "Unknown office denied")
	check(sim.reason(0, "appoint_finance_4:0") != "", "Opposition appointment denied")
	check(sim.reason(0, "appoint_finance_1:1") == "", "Coalition appointment available")
	sim.act(0, "appoint_finance_1:1")
	check(c.cabinet.finance == "1:1", "Minister appointed")
	check(sim.reason(0, "appoint_finance_1:2") != "", "Office cooldown enforced")
	check(sim.reason(0, "appoint_economy_1:1") != "", "One person, one portfolio")
	sim.act(0, "coalition_1")
	check(c.cabinet.finance == "" and 1 not in c.coalition, "Coalition departure removes minister")
	check(sim.reason(0, "coalition_0") != "", "Governing party cannot leave")
	reset()
	c = sim.country(0)
	sim.act(0, "government_2")
	check(c.premier == "Lars Klingbeil" and c.head_name == "Frank-Walter Steinmeier", "Government change preserves president")
	check(sim.reason(0, "government_4") != "", "Opposition cannot seize premiership")
	sim.act(0, "campaign_6")
	check(c.support[6] > 9.66, "Dynamic seventh-party campaign")
	check(sim.reason(0, "campaign_99") != "" and sim.reason(0, "campaign_xyz") != "", "Invalid party campaign denied")
	var total = 0.0
	for value in c.support: total += value
	check(absf(total - 100) < 0.001, "Support normalized")
	reset(1936)
	c = sim.country(0)
	check(sim.parties(0)[1].name == "Zentrum" and not sim.parties(0)[1].legal, "Historical banned Zentrum")
	check(sim.reason(0, "campaign_1") != "" and sim.reason(0, "coalition_1") != "", "Dictatorship blocks banned parties")
	sim.act(0, "democratize")
	check(c.democratic and sim.reason(0, "campaign_1") == "", "Democratic alternative opens campaigns")
	c.money = 1000
	c.influence = 250
	sim.act(0, "restore_monarchy")
	check(c.head_name == "Wilhelm II." and c.head_title == "Kaiser", "Constitutional Kaiser alternative")
	reset()
	c = sim.country(0)
	var book = sim.Economy.ledger(c, 2026, 0)
	check(absf(book.revenue - book.expenses - book.balance) < 0.001, "Budget balances")
	var original_revenue = book.revenue
	sim.act(0, "tax_up")
	check(sim.Economy.ledger(c, 2026, 0).revenue > original_revenue, "Tax affects revenue")
	var gdp = sim.Economy.ledger(c, 2026, 0).gdp
	c.econ.stock.energy = 0
	c.econ.energy = 0
	check(sim.Economy.ledger(c, 2026, 0).gdp < gdp * 0.5, "Energy shortage reduces GDP")
	var weak_power = sim.power(0)
	c.econ.stock.energy = 1000
	check(sim.power(0) > weak_power * 2, "Supply affects military power")
	var money = c.money
	var debt = c.econ.debt
	sim.act(0, "loan")
	check(c.money == money + 200 and c.econ.debt == debt + 200, "Borrowing books equal cash and debt")
	sim.act(0, "repay")
	check(c.money == money and c.econ.debt == debt, "Repayment balanced")
	var interest = sim.Economy.ledger(c, 2026, 0).interest
	c.econ.debt *= 2
	check(sim.Economy.ledger(c, 2026, 0).interest > interest * 2, "Debt increases risk premium")
	reset()
	c = sim.country(0)
	c.money = 2000
	sim.act(0, "energy")
	sim.act(0, "farms")
	check(sim.reason(0, "industry") != "", "Two project slots")
	var energy = c.econ.energy
	for day in range(45): sim.advance(range(sim.count()))
	check(c.econ.energy == energy + 12 and c.projects.is_empty(), "Sector investment completes")
	check(c.econ.history.size() == 1, "Monthly economic history")
	reset()
	c = sim.country(0)
	sim.act(0, "trade", 1)
	var other = sim.country(1)
	var cash_total = c.money + other.money
	var goods_total = c.econ.stock.energy + other.econ.stock.energy
	sim.advance_trade()
	check(absf(c.money + other.money - cash_total) < 0.0001, "Trade conserves money")
	check(absf(c.econ.stock.energy + other.econ.stock.energy - goods_total) < 0.0001, "Trade conserves goods")
	check(sim.state.trades[0].delivered > 0, "Goods delivered")
	other.econ.stock.energy = 0
	var delivered = sim.state.trades[0].delivered
	sim.advance_trade()
	check(sim.state.trades[0].delivered == delivered, "No goods created when supplier empty")
	c.influence = 250
	sim.act(0, "war", 1)
	other.econ.stock.energy = 500
	sim.advance_trade()
	check(sim.state.trades[0].delivered == delivered, "War suspends trade")
	check(sim.state.wars.size() == 1 and sim.alive(1), "War not instant victory")
	for day in range(14): sim.advance(range(sim.count()))
	var w = sim.state.wars[0]
	check(w.history.size() == 2 and w.reports.size() >= 3, "Weekly reports and chart")
	check(w.loss_a > 0 and w.cost_a > 0 and c.econ.damage > 0, "Losses, costs and damage tracked")
	check(sim.save_game("user://test-v3.json", 0) == OK, "Save ongoing war")
	var restored = Simulation.new()
	check(restored.read_game("user://test-v3.json") == 0, "Load v3 snapshot")
	check(restored.country(0).cabinet == c.cabinet and restored.state.wars[0].reports[0].text == w.reports[0].text and restored.state.wars[0].reports.size() == w.reports.size(), "Cabinet and war reports persist")
	restored.country(0).influence = 250
	check(restored.reason(0, "appoint_finance_1:1") == "", "Coalition candidate remains available after JSON load")
	var file = FileAccess.open("user://bad-v3.json", FileAccess.WRITE)
	var bad = sim.state.duplicate(true)
	bad.countries[0].cabinet.finance = "999:3"
	file.store_string(JSON.stringify({"state": bad, "player": 0}))
	file.close()
	check(restored.read_game("user://bad-v3.json") == -1, "Reject invalid saved candidate")
	reset()
	c = sim.country(0)
	c.army = 400
	c.money = 10000
	for good in sim.Economy.GOODS: c.econ.stock[good] = 20000
	sim.country(6).army = 10
	sim.act(0, "war", 6)
	for day in range(80): sim.advance(range(sim.count()))
	check(int(sim.country(6).owner) == 0, "Overwhelming army wins over time")
	check(sim.state.war_archive.size() == 1 and sim.state.war_archive[0].winner == 0, "Victory archived")
	reset()
	sim.act(0, "war", 1)
	sim.state.wars[0].days = 30
	sim.country(0).influence = 200
	sim.act(0, "peace", 1)
	check(sim.state.wars.is_empty() and sim.state.war_archive[0].winner == -1, "Ceasefire archived")
	check(sim.reason(0, "war", 1) != "", "Truce enforced")
	for era in [1936, 2026]:
		reset(era)
		check(sim.count() == (16 if era == 1936 else 17), "Scenario count")
		for id in range(sim.count()):
			var nation = sim.country(id)
			check(sim.parties(id).size() >= 3 and not nation.premier.is_empty(), "Roster for %s / %d" % [nation.code, era])
			for person in sim.Politics.candidates(era, nation.code):
				check(not person.name.is_empty() and int(person.party) in range(sim.parties(id).size()), "Candidate identity and affiliation")
		for day in range(720): sim.advance(range(sim.count()))
		for id in range(sim.count()):
			var nation = sim.country(id)
			check(is_finite(sim.income(id)) and nation.money >= 0 and nation.econ.stock.energy >= 0, "Long-run economic bounds")
		check(sim.save_game("user://test-v3.json", sim.count() - 1) == OK and restored.read_game("user://test-v3.json") == sim.count() - 1, "Both scenario snapshots round-trip")
	reset(1936)
	for day in range(720): sim.advance([])
	for id in range(sim.count()):
		check(is_finite(sim.income(id)) and sim.country(id).projects.size() <= 2, "Autonomous AI campaign remains valid")
	print("SIMULATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
