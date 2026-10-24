extends SceneTree
const Bonus = preload("res://scripts/bonus_rules.gd")
var failed = 0

func check(ok, message):
	if not ok:
		failed += 1
		printerr("FAIL " + message)

func coin(value = 7):
	return {"value":value, "base":value, "multiplier":1, "jackpot":-1}

func _init():
	var b = Bonus.new()
	b.begin([false, true, false], 4)
	check(b.occupied(0) == 0 and b.occupied(1) == 0, "starts empty")
	check(b.lives == [3,3], "red gives two independent counters")
	check(b.resolve_spin([{ "row":0,"col":0,"coin":coin() }]) == 0, "no payment before completion")
	check(b.lives == [3,2] and b.total == 7, "only receiving board resets")
	b.resolve_spin([{ "row":0,"col":0,"coin":coin(999) }])
	check(b.grid[0][0].value == 7 and b.lives == [2,1], "locked coin cannot be replaced or renew counter")
	b.resolve_spin([])
	check(b.lives == [1,0], "empty board closes independently")
	var result = b.resolve_spin([{ "row":3,"col":0,"coin":coin(999) }])
	check(result == 7 and b.grid[3][0] == null, "finished board stays closed and sum paid once")
	check(b.resolve_spin([]) == -1 and b.spin() == -1, "finished bonus cannot pay again")
	b.begin([true,true,true], 4)
	check(b.lives == [4,4], "blue gives four attempts on both boards")
	var all = []
	for row in range(6):
		for col in range(5): all.append({"row":row,"col":col,"coin":coin()})
	check(b.resolve_spin(all) == 210 and b.spins_left == 0, "full boards finish and pay exact total")
	b.begin([true,false,true], 4)
	for _i in range(100):
		var c = b.cash_coin()
		check(c.multiplier in [1,2,3,5] and c.value == c.base * c.multiplier, "green multiplier included once")
	var empty_chance = b.coin_chance(0)
	for col in range(5):
		b.grid[0][col] = coin()
		b.grid[1][col] = coin()
	b.grid[2][0] = coin()
	check(b.coin_chance(0) < empty_chance, "blue chance decreases above 65 percent")
	b.begin([false,false,false], 4, 10, true)
	b.levels.current[0] = 25000
	b.reserved = [0]
	b.grid[0][0] = {"value":2500,"base":2500,"multiplier":1,"jackpot":0}
	b._recount()
	for _i in range(3): b.resolve_spin([])
	check(b.levels.current[0] == 25000, "preview does not reset real jackpot")
	for mask in range(1,8):
		b.begin([bool(mask & 1),bool(mask & 2),bool(mask & 4)],4)
		var turns = 0
		var paid = 0
		while b.spins_left > 0 and turns < 130:
			var snapshot = b.grid.duplicate(true)
			paid += b.spin()
			for row in range(b.rows):
				for col in range(5):
					if snapshot[row][col] != null: check(to_json(snapshot[row][col]) == to_json(b.grid[row][col]), "coin persists across spins")
			turns += 1
		check(b.spins_left == 0 and paid == b.total, "combination terminates and pays once")
	print("HOLD SPIN: ", failed, " failures")
	quit(1 if failed else 0)
