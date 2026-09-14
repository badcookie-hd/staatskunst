extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var sim = Simulation.new()
var checks = 0
var failures = 0

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("UPDATE FAIL: " + message)

func reset():
	sim.new_game(2026)
	sim.country(0).influence = 250

func _initialize():
	reset()
	var c = sim.country(0)
	check(sim.parties(0)[7].name == "Christen für Deutschland" and sim.parties(0)[7].fictional, "Explicit fictional CfD")
	check(sim.parties(0)[7].candidates.size() == 6, "Six invented politicians")
	check(c.law.name == "Grundgesetz" and c.democratic, "2026 Basic Law initialized")
	check(sim.reason(0, "law_dictatorship") != "" and sim.reason(0, "law_crisis") != "", "No immediate dictatorship from starting government")
	sim.act(0, "coalition_7")
	sim.act(0, "government_7")
	check(c.premier == "Jan Mertens" and int(c.ruling) == 7, "CfD takes government")
	check(sim.Politics.person(2026, c.code, c.cabinet.finance).name == "Clara Winter", "Fictional cabinet assigned")
	check(sim.reason(0, "law_crisis") != "", "New government needs time in office")
	sim.state.day = 15
	c.influence = 250
	check(sim.reason(0, "law_crisis") == "", "Crisis available after takeover and waiting")
	sim.act(0, "law_crisis")
	check(c.law.breached and int(c.law.stage) == 1 and c.democratic, "Crisis is explicit breach, not instant dictatorship")
	check(sim.reason(0, "law_centralize") != "", "Thirty-day cooldown enforced")
	sim.state.day = 45
	sim.act(0, "law_centralize")
	check(int(c.law.stage) == 2 and c.law.press == 35, "Rights eroded in second stage")
	sim.state.day = 75
	c.influence = 250
	check(sim.reason(0, "law_dictatorship") != "", "Low party support prevents final takeover")
	sim.shift_support(c, 7, 35)
	check(sim.reason(0, "law_dictatorship") == "", "All dictatorship prerequisites met")
	var before_repression = sim.Economy.ledger(c, 2026, 0).repression
	sim.act(0, "law_dictatorship")
	check(not c.democratic and int(c.law.stage) == 3 and c.head_name == "Jan Mertens", "Fictional dictatorship established")
	check(sim.reason(0, "campaign_0") != "" and sim.reason(0, "government_0") != "", "Elections and opposition takeover disabled")
	check(sim.Economy.ledger(c, 2026, 0).repression > before_repression, "Institutional breakdown has running costs")
	check(sim.save_game("user://law-test.json", 0) == OK, "Save dictatorship")
	var restored = Simulation.new()
	check(restored.read_game("user://law-test.json") == 0 and restored.country(0).law.breached and not restored.country(0).democratic, "Load dictatorship")
	c.influence = 250
	c.money = 1000
	sim.act(0, "democratize")
	check(c.democratic and c.law.rule_of_law == 100 and c.head_title == "Bundespräsident", "Democratic restoration restores rights and offices")
	reset()
	c = sim.country(0)
	sim.act(0, "coalition_4")
	sim.act(0, "government_4")
	sim.state.day = 15
	c.influence = 250
	check(c.premier == "Alice Weidel" and sim.reason(0, "law_crisis") == "", "AfD government can choose alternative path")
	sim.act(0, "law_crisis")
	sim.act(0, "law_defend")
	check(int(c.law.stage) == 0 and not c.law.breached, "Constitution can be defended")
	c.influence = 250
	sim.act(0, "law_crisis")
	sim.act(0, "government_0")
	check(int(c.law.stage) == 0, "New governing party cancels previous power path")
	reset()
	c = sim.country(0)
	c.econ.stock.energy = 0
	c.econ.stock.materials = 0
	c.econ.damage = 20
	var plan = sim.Economy.flow(c)
	var stocks = c.econ.stock.duplicate()
	sim.Economy.advance(c, 2026, 0, 1)
	for good in sim.Economy.GOODS:
		check(absf(c.econ.stock[good] - maxf(0, stocks[good] + (plan.production[good] - plan.consumed[good]) / 30)) < 0.0001, "Displayed production matches actual settlement: " + good)
		check(c.econ.stock[good] >= 0 and plan.consumed[good] <= plan.demand[good], "No invented consumption or negative stock")
	reset()
	c = sim.country(0)
	var before = sim.Economy.ledger(c, 2026, 0).balance
	sim.act(0, "social_up")
	check(sim.Economy.ledger(c, 2026, 0).balance < before, "Budget slider has real cash cost")
	sim.act(0, "trade", 1)
	check(sim.reason(0, "trade", 1) != "", "Duplicate contracts rejected")
	var cash_before = float(c.money)
	sim.advance(range(sim.count()))
	check(c.econ.trade_out > 0 and sim.country(1).econ.trade_in > 0, "Import and export payments recorded")
	check(absf(c.money - cash_before - c.econ.last_cash_change) < 0.00001, "Cash ledger reconciles actual money")
	check(absf(c.econ.last_cash_change - c.econ.last_operating + c.econ.trade_out - c.econ.trade_in - c.econ.last_borrowing) < 0.0001, "Daily income, trade and financing reconcile")
	check(absf(sim.income(0) - (sim.Economy.ledger(c, 2026, 0).balance - c.econ.trade_out * 30)) < 0.0001, "Displayed saldo includes actual imports")
	check(sim.reason(1, "cancel_trade_0") != "", "Other country cannot cancel player's contract")
	sim.act(0, "cancel_trade_0")
	check(sim.state.trades.is_empty() and c.trade == 0, "Cancel frees trade slot")
	sim.act(0, "industry")
	check(c.econ.transactions[0].amount == -220, "Project booked immediately in ledger")
	check(sim.save_game("user://economic-test.json", 0) == OK and restored.read_game("user://economic-test.json") == 0, "Economic journal round-trips")
	reset()
	c = sim.country(0)
	c.money = 0
	c.econ.social = 100
	c.econ.education = 100
	c.tax = 10
	sim.advance(range(sim.count()))
	check(c.econ.last_borrowing > 0 and c.money == 0, "Automatic deficit financing visible")
	sim.new_game(1936)
	check(sim.country(0).law.name != "Grundgesetz", "No anachronistic Basic Law in 1936")
	check(sim.parties(0)[7].fictional and not sim.parties(0)[7].legal, "1936 CfD explicitly alternative and initially unavailable")
	print("UPDATE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
