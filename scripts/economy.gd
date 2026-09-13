extends RefCounted
const Politics = preload("res://scripts/politics.gd")
const GOODS = ["energy", "food", "materials"]
const PRICES = {"energy": 1.0, "food": 0.8, "materials": 1.4}

static func initialize(c: Dictionary):
	var scale_value = float(c.industry)
	c.econ = {"energy": scale_value * (1.3 if c.code in ["NOR", "SWE", "POL"] else 0.85), "farms": scale_value * (0.95 if c.code in ["FRA", "POL", "HUN"] else 0.7), "services": scale_value * 1.1, "workforce": scale_value * 2.8, "debt": scale_value * 12, "inflation": 2.0, "employment": 92.0, "damage": 0.0, "social": 50.0, "education": 50.0, "defense": 60.0, "corporate": 20.0, "vat": 15.0, "productivity": 1.0, "stock": {"energy": scale_value * 2, "food": scale_value * 2, "materials": scale_value * 2}, "history": []}

static func demand(c: Dictionary) -> Dictionary:
	return {"energy": c.industry * 0.75 + c.econ.services * 0.25 + c.army * 0.08, "food": c.econ.workforce * 0.24 + c.army * 0.03, "materials": c.army * c.quality * 0.13 + c.industry * 0.1}

static func supply(c: Dictionary) -> float:
	var needs = demand(c)
	var ratio = 1.0
	var production = {"energy": c.econ.energy, "food": c.econ.farms, "materials": c.industry * 0.55}
	for good in GOODS:
		var available_today = c.econ.stock[good] + production[good] * (1 - c.econ.damage / 100.0) / 30.0
		ratio = minf(ratio, available_today / maxf(0.01, needs[good] / 30.0))
	return clampf(ratio, 0.15, 1.0)

static func ledger(c: Dictionary, year: int, wars: int) -> Dictionary:
	var e = c.econ
	var available = supply(c)
	var output = available * (1.0 - e.damage / 100.0) * e.productivity * (0.6 + e.employment / 250.0) * (1 + Politics.bonus(c, year, "economy"))
	var gdp = (c.industry * 5 + e.services * 3 + e.farms * 1.5 + e.energy) * output
	var tax_efficiency = (0.85 + c.stability / 1000.0) * (1 + Politics.bonus(c, year, "finance"))
	var personal = gdp * 0.5 * c.tax / 100.0 * tax_efficiency
	var corporate = gdp * 0.25 * e.corporate / 100.0 * tax_efficiency
	var consumption = gdp * 0.5 * e.vat / 100.0 * tax_efficiency
	var admin = e.workforce * 0.25
	var social = e.workforce * e.social / 150.0
	var education = e.workforce * e.education / 300.0
	var military = c.army * c.quality * (0.12 + e.defense / 400.0)
	var war_cost = wars * (24 + c.army * 0.15)
	var rate = 2.0 + e.debt / maxf(1, gdp * 12) * 4 + maxf(0, e.inflation - 2) * 0.3
	var interest = e.debt * rate / 1200.0
	var revenue = personal + corporate + consumption
	var expenses = admin + social + education + military + war_cost + interest
	return {"gdp": gdp, "output": output, "supply": available, "personal": personal, "corporate": corporate, "consumption": consumption, "admin": admin, "social": social, "education": education, "military": military, "war": war_cost, "interest": interest, "rate": rate, "revenue": revenue, "expenses": expenses, "balance": revenue - expenses}

static func advance(c: Dictionary, year: int, wars: int, day: int):
	var e = c.econ
	var book = ledger(c, year, wars)
	var needs = demand(c)
	var production = {"energy": e.energy, "food": e.farms, "materials": c.industry * 0.55 * book.output}
	for good in GOODS: e.stock[good] = clampf(e.stock[good] + (production[good] * (1 - e.damage / 100.0) - needs[good]) / 30.0, 0, e.workforce * 6)
	c.money += book.balance / 30.0
	if c.money < 0:
		if e.debt - c.money <= book.gdp * 18:
			e.debt -= c.money
		else:
			c.stability = maxf(0, c.stability - 0.4)
			c.army = maxf(5, c.army - 0.1)
		c.money = 0
	var jobs = (c.industry * 1.2 + e.services + e.farms * 0.5 + e.energy * 0.25) * (1 - e.damage / 100.0)
	e.employment = lerpf(e.employment, clampf(jobs / e.workforce * 100, 45, 98), 0.015)
	e.inflation = lerpf(e.inflation, 2 + (1 - book.supply) * 18 + wars * 1.5 + maxf(0, c.tax - 30) * 0.1, 0.025)
	e.productivity = clampf(e.productivity + (e.education - 30) / 150000.0, 0.7, 1.8)
	e.damage = maxf(0, e.damage - (0.015 if wars == 0 else 0))
	c.stability = clampf(c.stability + (e.social - 50) / 2000.0 - maxf(0, e.inflation - 5) / 100.0, 0, 100)
	if day % 30 == 0:
		e.history.append({"day": day, "gdp": book.gdp, "balance": book.balance, "debt": e.debt, "inflation": e.inflation})
		if e.history.size() > 120: e.history.pop_front()
