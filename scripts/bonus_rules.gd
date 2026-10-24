extends Reference
# Hold & Spin demonstrativo. O gatilho de 20–50 coletas pertence ao jogo base.
const DEFAULT_INITIAL = [10000, 50000, 100000]
const DEFAULT_FINAL = [50000, 150000, 500000]
# Fração do valor apostado na rodada que alimenta cada acumulado (MINI, MINOR, MAJOR).
const GROWTH_RATE = [0.20, 0.10, 0.05]
const MIN_LEVEL = 1000
var levels = {"initial": DEFAULT_INITIAL.duplicate(), "current": DEFAULT_INITIAL.duplicate(), "final": DEFAULT_FINAL.duplicate()}
# Pesos demonstrativos de acumulados por moeda: escalam com a aposta e inversamente com o saldo.
# Não constituem uma meta de RTP; o verde aplica um fator adicional de 0,5.
const JACKPOT_SHARE = [0.15, 0.10, 0.10]
const MAX_JACKPOT_CHANCE = 0.25
var denomination = 10
var rng = RandomNumberGenerator.new()
var flags = [false, false, false]
var grid = []
var lives = []
var before_lives = []
var new_cells = []
var reserved = []
var spins_left = 0
var total = 0
var before_total = 0
var last_win = 0
var jackpot_name = ""
var stake = 4
var rows = 3
var preview = false

func _init():
	rng.randomize()

func max_lives():
	return 4 if flags[2] else 3

func begin(modifiers, unit, coin = 10, exploration = false):
	denomination = coin
	flags = modifiers.duplicate()
	stake = unit
	preview = exploration
	rows = 6 if flags[1] else 3
	grid.clear()
	lives.clear()
	new_cells.clear()
	reserved.clear()
	last_win = 0
	jackpot_name = ""
	for _row in range(rows):
		grid.append([null, null, null, null, null])
	for panel in range(int(rows / 3)):
		lives.append(max_lives())
		# A grade começa vazia; as moedas chegam de cima durante os giros.
	_recount()
	before_total = total
	before_lives = lives.duplicate()

func cash_coin():
	var values = [1, 1, 1, 2, 2, 3, 5, 10]
	var base = max(1, int(round(stake * values[rng.randi_range(0, 7)] * (0.65 if flags[1] else 1.0))))
	var multiplier = [1, 1, 2, 2, 3, 5][rng.randi_range(0, 5)] if flags[0] else 1
	return {"value": base * multiplier, "base": base, "multiplier": multiplier, "jackpot": -1}

func occupied(panel):
	var count = 0
	for row in range(panel * 3, panel * 3 + 3):
		for coin in grid[row]:
			if coin != null:
				count += 1
	return count

func coin_chance(panel):
	var fill = occupied(panel) / 15.0
	return 0.12 * (1.0 - clamp((fill - 0.65) / 0.35, 0.0, 1.0) * 0.65) if flags[2] else 0.12

func _recount():
	total = 0
	spins_left = 0
	for line in grid:
		for coin in line:
			if coin != null:
				total += coin.value
	for life in lives:
		spins_left = max(spins_left, life)

func jackpot_value(tier):
	return int(levels.current[tier])

# Sobe os acumulados a cada rodada: proporcional ao valor apostado, com peso extra para apostas
# maiores (aposta 1 sobe ~35% do normal, aposta 8 = 100%, aposta 20 ≈ 160%). Trava no valor final.
func grow(stake_cents, bet):
	var weight = clamp(sqrt(max(1.0, float(bet)) / 8.0), 0.35, 1.6)
	for tier in range(3):
		levels.current[tier] = min(float(levels.final[tier]), float(levels.current[tier]) + stake_cents * GROWTH_RATE[tier] * weight)

func set_level(tier, field, cents):
	cents = int(max(MIN_LEVEL, cents))
	if field == "initial":
		levels.initial[tier] = cents
		levels.final[tier] = max(levels.final[tier], cents)
		levels.current[tier] = max(levels.current[tier], cents)
	elif field == "final":
		levels.final[tier] = max(cents, levels.initial[tier])
		levels.current[tier] = min(levels.current[tier], levels.final[tier])
	else:
		levels.current[tier] = clamp(cents, levels.initial[tier], levels.final[tier])

func reset_level(tier):
	levels.current[tier] = levels.initial[tier]

func jackpot_chance(tier):
	var unit_cents = float(stake * denomination)
	return min(MAX_JACKPOT_CHANCE, JACKPOT_SHARE[tier] * unit_cents / max(1.0, float(levels.current[tier])))

func _new_coin():
	var roll = rng.randf()
	var cumulative = 0.0
	for tier in [2, 1, 0]:
		if tier in reserved:
			continue
		cumulative += jackpot_chance(tier) * (0.5 if flags[0] else 1.0)
		if roll < cumulative:
			reserved.append(tier)
			var value = int(jackpot_value(tier) / denomination)
			return {"value": value, "base": value, "multiplier": 1, "jackpot": tier}
	return cash_coin()

func spin():
	if spins_left <= 0:
		return -1
	var landings = []
	for panel in range(lives.size()):
		if lives[panel] <= 0:
			continue
		var chance = coin_chance(panel)
		for row in range(panel * 3, panel * 3 + 3):
			for col in range(5):
				if grid[row][col] == null and rng.randf() < chance:
					landings.append({"row": row, "col": col, "coin": _new_coin()})
	return resolve_spin(landings)

# Aplica somente moedas em casas vazias de grades ainda ativas.
func resolve_spin(landings):
	if spins_left <= 0:
		return -1
	before_total = total
	before_lives = lives.duplicate()
	new_cells.clear()
	last_win = 0
	for panel in range(lives.size()):
		if lives[panel] <= 0:
			continue
		lives[panel] -= 1
		var landed = false
		for item in landings:
			if item.row < panel * 3 or item.row >= panel * 3 + 3 or item.col < 0 or item.col >= 5:
				continue
			if grid[item.row][item.col] != null:
				continue
			grid[item.row][item.col] = item.coin.duplicate()
			new_cells.append(item.row * 5 + item.col)
			landed = true
		if landed:
			lives[panel] = max_lives()
		if occupied(panel) == 15:
			lives[panel] = 0
	_recount()
	if spins_left == 0:
		last_win = total
		var names = []
		for tier in reserved:
			names.append(["MINI", "MINOR", "MAJOR"][tier])
			if not preview:
				reset_level(tier)
		jackpot_name = PoolStringArray(names).join(" + ")
	return last_win
