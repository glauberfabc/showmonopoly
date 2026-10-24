extends Reference
# Show Monopoly — regras v2 (ver docs/). Créditos inteiros; denominação e acumulado em centavos.
# aposta (bet) = créditos POR CARTELA. Valor-base da figura = aposta da cartela premiada. Custo da rodada = aposta × cartelas abertas.
const MAX_BET = 20
const INITIAL_BALLS = 30
const MAX_EXTRAS = 10
const BALL_COUNT = 90
const CARD_SIZE = 15
const CARD_COUNT = 4
const FULL_MASK = 32767
const MIN_EXTRA_PRICE = 1
# Sorteio assistido: chance-alvo de cada número das cartelas abertas sair nas 30 bolas (sem assistência seria 1/3).
const DRAW_ASSIST = 0.42
const Bonus = preload("res://scripts/bonus_rules.gd")
const Profile = preload("res://scripts/math_profile.gd")
var credits = 1000
var bet = 1
var denomination = 10
var jackpot = 500000
var cards = []
var open_cards = [true, true, true, true]
var marks = [0, 0, 0, 0]
var index_of = []
var drawn = []
var deck = []
var ball_weights = {}
var extras_bought = 0
var missed_balls = []
var phase = "ready"
var jackpot_won = false
var rng = RandomNumberGenerator.new()
var patterns = []
var pattern_masks = []
var paid = {}
var round_wins = 0
var wins = []
var win_log = []
var ball_events = []
var collections = [0, 0, 0]
var pending_bonus = [false, false, false]
var bonus = Bonus.new()
var resume_phase = "extras"
var last_extra_free = false
var last_extra_cost = 0
var color_chance = 0.10
const VAULT_MIN = 20
const VAULT_MAX = 50
var vault_targets = [20, 20, 20]
var free_chance = 0.10
var joker_chance = 0.08
var hold_percent = Profile.DEFAULT_HOLD
var extra_factor = Profile.extra_factor(Profile.DEFAULT_HOLD)
var stats = {"in": 0, "out": 0, "rounds": 0, "extras": 0}

func _init():
	rng.randomize()
	for color in range(3):
		vault_targets[color] = rng.randi_range(VAULT_MIN, VAULT_MAX)
	_build_patterns()
	_generate_cards()

func _build_patterns():
	patterns.append({"name": "Figura 01", "cells": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "pay": 1500})
	patterns.append({"name": "Figura 02", "cells": [0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14], "pay": 500})
	patterns.append({"name": "Figura 03", "cells": [0, 2, 4, 5, 6, 7, 8, 9, 10, 12, 14], "pay": 350})
	patterns.append({"name": "Figura 04", "cells": [0, 1, 2, 3, 4, 6, 8, 11, 12, 13], "pay": 200})
	patterns.append({"name": "Figura 05", "cells": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], "pay": 100})
	patterns.append({"name": "Figura 06", "cells": [0, 1, 2, 3, 4, 6, 8, 11, 13], "pay": 100})
	patterns.append({"name": "Figura 07", "cells": [0, 2, 4, 6, 8, 10, 12, 14], "pay": 50})
	patterns.append({"name": "Figura 08", "cells": [0, 4, 5, 6, 7, 8, 9, 12], "pay": 40})
	patterns.append({"name": "Figura 09", "cells": [2, 6, 8, 10, 11, 12, 13, 14], "pay": 10})
	patterns.append({"name": "Figura 10", "cells": [0, 4, 5, 9, 10, 14], "pay": 8})
	patterns.append({"name": "Figura 11", "cells": [2, 6, 8, 10, 14], "pay": 3})
	patterns.append({"name": "Figura 12", "cells": [0, 1, 2, 3, 4], "pay": 3})
	for pattern in patterns:
		var mask = 0
		for cell in pattern.cells:
			mask |= 1 << cell
		pattern_masks.append(mask)

func _shuffled_numbers():
	var numbers = range(1, BALL_COUNT + 1)
	for index in range(numbers.size() - 1, 0, -1):
		var other = rng.randi_range(0, index)
		var temporary = numbers[index]
		numbers[index] = numbers[other]
		numbers[other] = temporary
	return numbers

# Pesos de sorteio: números das cartelas abertas pesam W, os demais 1, com W escolhido para que cada
# número das cartelas saia nas 30 bolas com chance DRAW_ASSIST (aproximação de Poisson).
func _compute_weights():
	ball_weights = {}
	var in_cards = {}
	for c in range(CARD_COUNT):
		if open_cards[c]:
			for number in cards[c]:
				in_cards[number] = true
	var k = in_cards.size()
	var w = 1.0
	if k > 0 and k < BALL_COUNT:
		var rest = (INITIAL_BALLS - k * DRAW_ASSIST) / float(BALL_COUNT - k)
		rest = clamp(rest, 0.02, 0.98)
		w = max(1.0, -log(1.0 - DRAW_ASSIST) / -log(1.0 - rest))
	for n in range(1, BALL_COUNT + 1):
		ball_weights[n] = w if in_cards.has(n) else 1.0

func _assisted_deck():
	_compute_weights()
	var keyed = []
	for n in range(1, BALL_COUNT + 1):
		keyed.append([log(max(1e-12, rng.randf())) / ball_weights[n], n])
	keyed.sort_custom(self, "_key_desc")
	var order = []
	for item in keyed:
		order.append(item[1])
	return order

func _key_desc(a, b):
	return a[0] > b[0]

func _new_card():
	var numbers = _shuffled_numbers().slice(0, CARD_SIZE - 1)
	numbers.sort()
	var card = []
	for row in range(3):
		for col in range(5):
			card.append(numbers[col * 3 + row])
	return card

func _index_card(card):
	var map = {}
	for i in range(card.size()):
		map[card[i]] = i
	return map

func _generate_cards():
	cards.clear()
	index_of.clear()
	for _index in range(CARD_COUNT):
		var card = _new_card()
		cards.append(card)
		index_of.append(_index_card(card))

# ---------- configuração ----------
func _can_configure():
	return phase in ["ready", "finished"]

func open_count():
	var count = 0
	for state in open_cards:
		if state:
			count += 1
	return count

func unit():
	return bet

func slot_unit():
	return bet * CARD_COUNT

func stake():
	return bet * open_count()

func set_bet(value):
	if not _can_configure() or typeof(value) != TYPE_INT or value < 1 or value > MAX_BET:
		return false
	bet = value
	return true

func set_denomination(value):
	if not _can_configure() or typeof(value) != TYPE_INT or not value in [10, 25]:
		return false
	denomination = value
	return true

func set_hold(value):
	if not _can_configure() or typeof(value) != TYPE_INT or value < Profile.MIN_HOLD or value > Profile.MAX_HOLD:
		return false
	hold_percent = value
	extra_factor = Profile.extra_factor(value)
	return true

func _reset_board():
	_clear_round()
	phase = "ready"

func toggle_card(index):
	if not _can_configure() or index < 0 or index >= CARD_COUNT:
		return false
	if open_cards[index] and open_count() <= 1:
		return false
	open_cards[index] = not open_cards[index]
	_reset_board()
	return true

func swap_card(index):
	if not _can_configure() or index < 0 or index >= CARD_COUNT:
		return false
	cards[index] = _new_card()
	index_of[index] = _index_card(cards[index])
	_reset_board()
	return true

func change_cards():
	if not _can_configure():
		return false
	_generate_cards()
	_reset_board()
	return true

func _clear_round():
	drawn.clear()
	deck.clear()
	paid.clear()
	wins.clear()
	win_log.clear()
	ball_events.clear()
	marks = [0, 0, 0, 0]
	extras_bought = 0
	round_wins = 0
	jackpot_won = false
	pending_bonus = [false, false, false]
	last_extra_free = false
	last_extra_cost = 0

func start_round():
	if not _can_configure() or credits < stake():
		return false
	_clear_round()
	missed_balls.clear()
	credits -= stake()
	stats.in += stake()
	stats.rounds += 1
	bonus.grow(stake() * denomination, bet)
	deck = _assisted_deck()
	phase = "drawing"
	return true

# ---------- sorteio ----------
func matches(card):
	var count = 0
	for number in card:
		if number in drawn:
			count += 1
	return count

func _win(amount):
	credits += amount
	round_wins += amount
	stats.out += amount

func masks_for_pattern(p):
	if p == 11:
		return [31, 31 << 5, 31 << 10]
	return [pattern_masks[p]]

func pattern_complete(p, marked):
	for mask in masks_for_pattern(p):
		if (marked & mask) == mask:
			return true
	return false

func _pay_patterns(ball_index):
	for c in range(CARD_COUNT):
		if not open_cards[c]:
			continue
		for p in range(patterns.size()):
			var key = "%d:%d" % [c, p]
			if not paid.has(key) and pattern_complete(p, marks[c]):
				var amount = patterns[p].pay * unit()
				paid[key] = true
				_win(amount)
				wins.append("C%d · %s +%d" % [c + 1, patterns[p].name, amount])
				win_log.append({"ball": ball_index, "card": c, "pattern": p, "amount": amount})

func _collect(number):
	var color = -1
	var hit = false
	for c in range(CARD_COUNT):
		if open_cards[c] and index_of[c].has(number):
			hit = true
	if rng.randf() < color_chance:
		color = rng.randi_range(0, 2)
	var collected = color >= 0 and hit and not pending_bonus[color]
	if collected:
		collect_vault(color)
	ball_events.append({"number": number, "color": color, "collected": collected,
		"charge": collections[color] if color >= 0 else 0,
		"target": vault_targets[color] if color >= 0 else VAULT_MAX})

func collect_vault(color):
	if color < 0 or color >= 3 or pending_bonus[color]:
		return
	collections[color] += 1
	if collections[color] >= vault_targets[color]:
		pending_bonus[color] = true

func _accept(number):
	drawn.append(number)
	for c in range(CARD_COUNT):
		if open_cards[c] and index_of[c].has(number):
			marks[c] |= 1 << index_of[c][number]
	_collect(number)
	_pay_patterns(drawn.size() - 1)

func _open_pending_bonus(next_phase):
	if true in pending_bonus:
		resume_phase = next_phase
		bonus.begin(pending_bonus, slot_unit(), denomination)
		for color in range(3):
			if pending_bonus[color]:
				collections[color] = 0
				vault_targets[color] = rng.randi_range(VAULT_MIN, VAULT_MAX)
		pending_bonus = [false, false, false]
		phase = "bonus"
	else:
		phase = next_phase

func draw_next():
	if phase != "drawing" or drawn.size() >= INITIAL_BALLS or deck.empty():
		return -1
	var number = deck.pop_front()
	_accept(number)
	if drawn.size() == INITIAL_BALLS:
		for c in range(CARD_COUNT):
			if open_cards[c] and marks[c] == FULL_MASK:
				jackpot_won = true
				var amount = int(jackpot / denomination)
				_win(amount)
				wins.append("ACUMULADO BINGO +%d" % amount)
				break
		_open_pending_bonus(next_extra_phase())
	return number

func draw_initial():
	if phase != "drawing":
		return false
	for _index in range(INITIAL_BALLS - drawn.size()):
		if draw_next() < 0:
			return false
	return drawn.size() == INITIAL_BALLS

# ---------- bola extra ----------
# Valor esperado (em créditos) do próximo sorteio: figuras de uma só bola faltante, Joker (melhor número)
# e gratuidade. Preço = fator da retenção × valor esperado, arredondado, mínimo de 1 crédito.
func _single_payouts():
	var payouts = {}
	for c in range(CARD_COUNT):
		if not open_cards[c]:
			continue
		for p in range(patterns.size()):
			if paid.has("%d:%d" % [c, p]):
				continue
			for mask in masks_for_pattern(p):
				var rest = mask & ~marks[c]
				if rest == 0 or (rest & (rest - 1)) != 0:
					continue
				var cell = 0
				while (rest >> cell) & 1 == 0:
					cell += 1
				var number = cards[c][cell]
				payouts[number] = payouts.get(number, 0) + patterns[p].pay * unit()
	return payouts

func extra_expected():
	var payouts = _single_payouts()
	var total = 0.0
	var best = 0
	for number in payouts.keys():
		var value = payouts[number]
		total += value * ball_weights.get(number, 1.0)
		best = max(best, value)
	var remaining = 0.0
	for number in deck:
		remaining += ball_weights.get(number, 1.0)
	remaining = max(1.0, remaining)
	var expected = (1.0 - joker_chance) * total / remaining + joker_chance * best
	return expected / max(0.01, 1.0 - free_chance)

func extra_value():
	return extra_expected() * extra_factor

func extra_quote():
	return int(max(MIN_EXTRA_PRICE, round(extra_value())))

func extra_eligible():
	# A primeira extra só é oferecida quando alguma figura está a uma bola de pagar. Depois que a compra
	# começou, o jogador pode seguir comprando até a 10ª bola (ou o fim do baralho), mesmo sem prêmio próximo.
	if extras_bought >= MAX_EXTRAS or deck.empty() or open_count() <= 0:
		return false
	return extras_bought > 0 or not _single_payouts().empty()

func next_extra_phase():
	return "extras" if extra_eligible() else "finished"

func buy_extra():
	var cost = extra_quote()
	if phase != "extras" or not extra_eligible() or credits < cost:
		return -1
	last_extra_free = rng.randf() < free_chance
	last_extra_cost = 0 if last_extra_free else cost
	credits -= last_extra_cost
	stats.in += last_extra_cost
	stats.extras += 1
	extras_bought += 1
	if rng.randf() < joker_chance:
		phase = "joker"
		return 0
	var number = deck.pop_front()
	_accept(number)
	_open_pending_bonus(next_extra_phase())
	return number

func joker_options():
	var options = []
	if phase != "joker":
		return options
	for c in range(CARD_COUNT):
		if not open_cards[c]:
			continue
		for number in cards[c]:
			if number in deck and not number in options:
				options.append(number)
	if options.empty():
		options = deck.duplicate()
	options.sort()
	return options

func best_joker_number():
	var options = joker_options()
	if options.empty():
		return -1
	var payouts = _single_payouts()
	var best = options[0]
	var best_value = payouts.get(best, 0)
	for number in options:
		if payouts.get(number, 0) > best_value:
			best = number
			best_value = payouts.get(number, 0)
	return best

func choose_joker(number):
	if phase != "joker" or not number in joker_options():
		return false
	deck.erase(number)
	_accept(number)
	_open_pending_bonus(next_extra_phase())
	return true

# ---------- bônus ----------
func spin_bonus():
	if phase != "bonus":
		return -1
	var amount = bonus.spin()
	if amount >= 0:
		_win(amount)
	return amount

func close_bonus():
	if phase != "bonus" or bonus.spins_left > 0:
		return false
	phase = resume_phase
	return true

# Cancelar a extra encerra a rodada e revela, com X, as bolas que ainda viriam (até o limite de dez).
func finish_round():
	if phase != "extras":
		return false
	var remaining = MAX_EXTRAS - extras_bought
	missed_balls = []
	if remaining > 0 and not deck.empty():
		missed_balls = deck.slice(0, min(remaining, deck.size()) - 1)
	phase = "finished"
	return true

func reset_demo():
	if not _can_configure():
		return false
	credits = 1000
	collections = [0, 0, 0]
	for color in range(3):
		vault_targets[color] = rng.randi_range(VAULT_MIN, VAULT_MAX)
	missed_balls.clear()
	_generate_cards()
	_reset_board()
	return true

func reset_stats():
	stats = {"in": 0, "out": 0, "rounds": 0, "extras": 0}

func observed_rtp():
	if stats.in <= 0:
		return 0.0
	return float(stats.out) / float(stats.in)
