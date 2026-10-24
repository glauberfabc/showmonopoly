extends SceneTree
# Calibra o fator de preço da bola extra para cada retenção (docs/03-matematica-e-retencao.md).
# Estratégia de referência: quatro cartelas abertas, compra todas as extras, Joker escolhe o melhor número.
#
# 1) Simular (pode ser repetido com sementes diferentes e rodar em paralelo):
#    Godot --path . --no-window --script tools/calibrate.gd -- mode=sim rounds=30000 bet=8 seed=1 out=/tmp/sim1.json
# 2) Resolver e gerar scripts/math_profile.gd:
#    Godot --path . --no-window --script tools/calibrate.gd -- mode=solve in=/tmp/sim1.json,/tmp/sim2.json write=1
const Rules = preload("res://scripts/board_rules.gd")
const Profile = preload("res://scripts/math_profile.gd")

func arg(name, default):
	for a in OS.get_cmdline_args():
		if a.begins_with(name + "="):
			return a.substr(name.length() + 1)
	return str(default)

func simulate(rounds, bet, seed_value, cards_open):
	var g = Rules.new()
	g.rng.seed = seed_value
	g.bonus.rng.seed = seed_value + 1
	g.credits = 1000000000
	g.bet = bet
	g.color_chance = float(arg("color", g.color_chance))
	g.free_chance = float(arg("free", g.free_chance))
	g.joker_chance = float(arg("joker", g.joker_chance))
	for i in range(4):
		g.open_cards[i] = i < cards_open
	var data = {"rounds": rounds, "bet": bet, "cards": cards_open, "stake": 0, "patterns": 0, "bonus": 0, "buckets": {}, "extras": 0, "free": 0, "win_rounds": 0, "bonus_rounds": 0}
	for _r in range(rounds):
		g.change_cards()
		g.start_round()
		data.stake += g.stake()
		g.draw_initial()
		var round_bonus = 0
		var guard = 0
		while g.phase != "finished" and guard < 200:
			guard += 1
			match g.phase:
				"bonus":
					if g.bonus.spins_left > 0:
						round_bonus += g.spin_bonus()
					else:
						g.close_bonus()
				"joker":
					g.choose_joker(g.best_joker_number())
				"extras":
					var v = g.extra_expected()
					g.buy_extra()
					data.extras += 1
					if g.last_extra_free:
						data.free += 1
					else:
						var key = str(int(round(v * 50.0)))
						data.buckets[key] = data.buckets.get(key, 0) + 1
		if g.round_wins > 0:
			data.win_rounds += 1
		if round_bonus > 0:
			data.bonus_rounds += 1
		for entry in g.win_log:
			data.patterns += entry.amount
		data.bonus += round_bonus
	return data

func merge(files):
	var total = {"rounds": 0, "stake": 0, "patterns": 0, "bonus": 0, "buckets": {}, "extras": 0, "free": 0, "win_rounds": 0, "bonus_rounds": 0}
	for path in files:
		var file = File.new()
		if file.open(path, File.READ) != OK:
			printerr("cannot open " + path)
			continue
		var parsed = JSON.parse(file.get_as_text()).result
		file.close()
		for key in ["rounds", "stake", "patterns", "bonus", "extras", "free", "win_rounds", "bonus_rounds"]:
			total[key] += int(parsed[key])
		total["bet"] = int(parsed["bet"])
		for bucket in parsed.buckets.keys():
			total.buckets[bucket] = total.buckets.get(bucket, 0) + int(parsed.buckets[bucket])
	return total

func rtp(data, factor):
	var cost = 0
	for bucket in data.buckets.keys():
		var v = float(bucket) / 50.0
		cost += data.buckets[bucket] * max(Rules.MIN_EXTRA_PRICE, int(round(v * factor)))
	return float(data.patterns + data.bonus) / float(data.stake + cost)

func solve(data, target):
	var low = 0.02
	var high = 4.0
	for _i in range(40):
		var mid = (low + high) / 2.0
		if rtp(data, mid) > target:
			low = mid
		else:
			high = mid
	return (low + high) / 2.0

func _init():
	if arg("mode", "sim") == "sim":
		var rounds = int(arg("rounds", 20000))
		var started = OS.get_ticks_msec()
		var data = simulate(rounds, int(arg("bet", 8)), int(arg("seed", 20261008)), int(arg("cards", 4)))
		var file = File.new()
		file.open(arg("out", "user://sim.json"), File.WRITE)
		file.store_string(JSON.print(data))
		file.close()
		print("simulated ", rounds, " rounds in ", OS.get_ticks_msec() - started, " ms")
		quit()
		return
	var data = merge(arg("in", "").split(","))
	var rounds = data.rounds
	print("rounds ", rounds, " bet ", data.bet, " patterns/stake ", float(data.patterns) / data.stake, " bonus/stake ", float(data.bonus) / data.stake, " extras/round ", float(data.extras) / rounds, " free ", float(data.free) / max(1, data.extras), " rodadas com prêmio ", float(data.win_rounds) / rounds, " rodadas com bônus pago ", float(data.bonus_rounds) / rounds)
	var factors = []
	for hold in range(Profile.MIN_HOLD, Profile.MAX_HOLD + 1):
		var factor = stepify(solve(data, (100.0 - hold) / 100.0), 0.001)
		factors.append(factor)
		print("retenção ", hold, "% -> RTP-alvo ", 100 - hold, "% fator ", factor, " RTP medido ", stepify(rtp(data, factor) * 100.0, 0.01), "%")
	if arg("write", 0) == "1":
		var text = "extends Reference\n# PERFIL MATEMÁTICO — gerado por tools/calibrate.gd (%d rodadas, aposta %d por cartela, 4 cartelas). Não edite à mão.\n# Retenção (%%) -> fator do preço da bola extra (preço = fator × valor esperado da próxima bola).\nconst MIN_HOLD = %d\nconst MAX_HOLD = %d\nconst DEFAULT_HOLD = 8\nconst FACTORS = %s\n\nstatic func extra_factor(hold):\n\tvar h = int(clamp(hold, MIN_HOLD, MAX_HOLD))\n\treturn FACTORS[h - MIN_HOLD]\n\nstatic func target_rtp(hold):\n\treturn 100 - int(clamp(hold, MIN_HOLD, MAX_HOLD))\n" % [rounds, data.bet, Profile.MIN_HOLD, Profile.MAX_HOLD, str(factors)]
		var out = File.new()
		out.open(arg("target", "res://scripts/math_profile.gd"), File.WRITE)
		out.store_string(text)
		out.close()
		print("written")
	quit()
