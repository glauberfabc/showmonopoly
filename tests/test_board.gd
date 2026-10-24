extends SceneTree
# Suíte do Show Monopoly v2. Rodar: tests/run.ps1 (Windows) ou Godot --path . --no-window --script tests/test_board.gd
const Rules = preload("res://scripts/board_rules.gd")
const Profile = preload("res://scripts/math_profile.gd")
var failures = 0

func check(ok, message):
	if not ok:
		failures += 1
		printerr("FAIL " + message)

func plain():
	var g = Rules.new()
	g.color_chance = 0
	g.free_chance = 0
	g.joker_chance = 0
	return g

func _init():
	call_deferred("run")

func run():
	print("BEGIN rules v2")
	test_basics()
	test_cards_config()
	test_paytable()
	test_draw_assist()
	test_jackpot_levels()
	test_extras_and_cancel()
	test_extra_eligibility_transitions()
	test_hold_profile()
	test_bonus_jackpot_scaling()
	test_random_rounds()
	print("Rule checks finished; verifying scene")
	test_scene()

func test_basics():
	var g = plain()
	check(g.cards.size() == 4, "REQ-CART-01 quatro cartelas")
	for card in g.cards:
		var unique = {}
		for n in card:
			check(n >= 1 and n <= 90, "REQ-CART-02 universo de 90")
			unique[n] = true
		check(unique.size() == 15, "REQ-CART-02 15 números distintos")
	check(not g.set_bet(0) and not g.set_bet(21) and not g.set_bet(1.5), "REQ-APOS-01 limites da aposta")
	check(g.unit() == g.bet and g.stake() == g.bet * 4, "REQ-APOS-02 valor-base e custo")
	check(g.patterns.size() == 12, "REQ-PAY-01 doze figuras")

func test_cards_config():
	var g = plain()
	g.set_bet(5)
	check(g.toggle_card(1) and g.stake() == 15, "REQ-CART-03 fechar cartela reduz o custo")
	check(g.toggle_card(2) and g.toggle_card(3) and g.stake() == 5, "REQ-CART-03 fechar até restar uma")
	check(not g.toggle_card(0) and g.open_count() == 1, "REQ-CART-03 não fecha a última cartela")
	var before = g.cards[0].duplicate()
	var other = g.cards[1].duplicate()
	check(g.swap_card(0) and g.cards[1] == other, "REQ-CART-04 trocar números só da cartela escolhida")
	check(g.index_of[0].size() == 15, "REQ-CART-04 índice da cartela atualizado")
	g.toggle_card(1)
	g.credits = 1000
	g.start_round()
	check(g.credits == 1000 - g.stake(), "REQ-APOS-02 débito da rodada")
	check(not g.toggle_card(0) and not g.swap_card(0) and not g.change_cards() and not g.set_hold(10), "REQ-CART-05 configuração travada na rodada")
	g = plain()
	g.toggle_card(3)
	g.cards[0] = range(1, 16)
	g.cards[1] = range(16, 31)
	g.cards[2] = range(31, 46)
	g.cards[3] = range(1, 16)
	for i in range(4):
		g.index_of[i] = g._index_card(g.cards[i])
	g.start_round()
	g.deck = range(1, 91)
	g.draw_initial()
	var closed_paid = false
	for k in g.paid.keys():
		if k.begins_with("3:"):
			closed_paid = true
	check(not closed_paid, "REQ-CART-03 cartela fechada não paga")

func test_jackpot_levels():
	var b = Rules.Bonus.new()
	check(b.levels.current == b.levels.initial, "REQ-JP-01 atual começa no inicial")
	var start = float(b.levels.current[0])
	b.grow(3200, 8)
	var normal = b.levels.current[0] - start
	check(normal > 0.0, "REQ-JP-02 sobe a cada rodada")
	var s1 = float(b.levels.current[0])
	b.grow(3200 / 8, 1)
	var low = b.levels.current[0] - s1
	b.reset_level(0)
	var s2 = float(b.levels.current[0])
	b.grow(3200 * 20 / 8, 20)
	var high = b.levels.current[0] - s2
	check(low < normal / 8.0 and high > normal * 2.5, "REQ-JP-02 aposta maior sobe mais rápido, menor bem devagar")
	for i in range(200000):
		if b.levels.current[0] >= b.levels.final[0]:
			break
		b.grow(3200, 8)
	b.grow(3200, 20)
	check(b.levels.current[0] == b.levels.final[0], "REQ-JP-03 trava no valor final")
	b.set_level(0, "final", 5000)
	check(b.levels.final[0] >= b.levels.initial[0] and b.levels.current[0] <= b.levels.final[0], "REQ-JP-04 final nunca abaixo do inicial; atual dentro da faixa")
	b.set_level(0, "initial", 30000)
	check(b.levels.current[0] >= 30000 and b.levels.final[0] >= 30000, "REQ-JP-04 subir o inicial arrasta atual e final")
	b.set_level(1, "current", 999999999)
	check(b.levels.current[1] == b.levels.final[1], "REQ-JP-04 atual limitado ao final")
	b.begin([true, false, false], 4, 10)
	var low_chance = b.jackpot_chance(0)
	b.set_level(0, "current", b.levels.final[0])
	check(b.jackpot_chance(0) <= low_chance, "REQ-JP-05 chance acompanha o valor atual (retorno esperado constante)")
	b.reset_level(2)
	check(b.levels.current[2] == b.levels.initial[2], "REQ-JP-01 ao cair volta ao inicial")

func test_draw_assist():
	var g = plain()
	g.rng.seed = 77
	var hits = 0.0
	var total = 0.0
	for r in range(400):
		g.start_round()
		var sorted = g.deck.duplicate()
		sorted.sort()
		check(sorted == range(1, 91), "REQ-SORT-01 baralho é permutação de 1..90")
		var in_cards = {}
		for c in range(4):
			for n in g.cards[c]:
				in_cards[n] = true
		for i in range(30):
			total += 1.0
			if in_cards.has(g.deck[i]):
				hits += 1.0
		g.phase = "ready"
	var share = hits / total
	var k = 60.0
	var expected_share = 0.42 * 60.0 / 30.0
	check(share > 0.55 and share < expected_share + 0.1, "REQ-SORT-01 sorteio assistido favorece números das cartelas (%.2f)" % share)

func test_paytable():
	for row in range(3):
		var line_game = plain()
		line_game.open_cards = [true, false, false, false]
		line_game.cards[0] = range(1, 16)
		line_game.marks[0] = 15 << (row * 5)
		check(line_game._single_payouts().get(row * 5 + 5, 0) == 3 * line_game.unit(), "linha %d: falta uma bola" % row)
		line_game.marks[0] = 31 << (row * 5)
		line_game._pay_patterns(4)
		check(line_game.round_wins == 3 * line_game.unit(), "linha %d: paga 3x" % row)
		line_game._pay_patterns(5)
		check(line_game.win_log.size() == 1, "linha %d: sem pagamento duplicado" % row)
	var g = plain()
	g.set_denomination(25)
	g.start_round()
	g.cards = [range(1, 16), range(31, 46), range(46, 61), range(61, 76)]
	for i in range(4):
		g.index_of[i] = g._index_card(g.cards[i])
	g.deck = range(1, 91)
	g.draw_initial()
	check(g.jackpot_won, "REQ-PAY-04 acumulado de bingo nas 30 bolas")
	var figures = 1500 + 500 + 350 + 200 + 100 + 100 + 50 + 40 + 10 + 8 + 3 + 3
	check(g.round_wins == figures * g.unit() + int(500000 / 25), "REQ-PAY-02 todas as figuras uma vez cada + acumulado: %d" % g.round_wins)
	check(g.win_log.size() == 12, "REQ-PAY-02 doze pagamentos registrados")
	var balance = g.credits
	g._pay_patterns(29)
	check(g.credits == balance, "REQ-PAY-03 sem pagamento repetido")
	# uma figura isolada: primeira linha = Figura 12 (3x)
	g = plain()
	g.bet = 7
	g.start_round()
	g.cards = [[1, 2, 3, 4, 5, 40, 41, 42, 43, 44, 50, 51, 52, 53, 54], range(60, 75), range(75, 90), range(61, 76)]
	for i in range(4):
		g.index_of[i] = g._index_card(g.cards[i])
	g.deck = [1, 2, 3, 4, 5] + range(10, 90)
	for _i in range(5):
		g.draw_next()
	check(g.round_wins == 3 * g.unit() and g.wins.size() == 1, "REQ-PAY-02 Figura 12 paga 3 x valor-base")
	var expected_stats = g.stats.out
	check(expected_stats == g.round_wins, "REQ-OPER-05 contador de prêmios")

func test_extras_and_cancel():
	var g = plain()
	g.start_round()
	g.cards = [range(31, 46), range(46, 61), range(61, 76), range(76, 91)]
	for i in range(4):
		g.index_of[i] = g._index_card(g.cards[i])
	g.deck = range(1, 91)
	g.draw_initial()
	check(g.phase == "finished" and g.drawn.size() == 30, "REQ-EXTRA-06 sem figura próxima não oferece a primeira extra")
	check(g.buy_extra() == -1, "REQ-EXTRA-06 compra bloqueada sem figura próxima")
	# First row lacks 35; draws 31..33 cannot complete it yet.
	g.cards[0] = [1, 2, 3, 4, 35, 31, 32, 33, 34, 36, 37, 38, 39, 40, 41]
	g.index_of[0] = g._index_card(g.cards[0])
	g.marks[0] = 15
	g.phase = "extras"
	check(g.extra_eligible(), "REQ-EXTRA-06 falta uma bola libera extras")
	for i in range(3):
		var cost = g.extra_quote()
		var balance = g.credits
		var winnings = g.round_wins
		check(g.buy_extra() == 31 + i, "REQ-EXTRA-01 sequência do baralho")
		check(g.credits == balance - cost + g.round_wins - winnings, "REQ-EXTRA-02 débito exato do preço mostrado")
	var next_numbers = g.deck.slice(0, 6)
	var before_credits = g.credits
	check(g.finish_round(), "REQ-EXTRA-04 cancelar encerra a rodada")
	check(g.missed_balls == next_numbers, "REQ-EXTRA-04 bolas canceladas = as próximas do baralho")
	check(g.missed_balls.size() == 7 and g.credits == before_credits, "REQ-EXTRA-04 sete bolas, sem prêmio nem custo")
	check(not (g.missed_balls[0] in g.drawn), "REQ-EXTRA-04 bolas canceladas não foram sorteadas")
	g.toggle_card(1)
	check(g.missed_balls == next_numbers, "REQ-EXTRA-05 visualização persiste ao configurar")
	g.change_cards()
	check(g.missed_balls == next_numbers, "REQ-EXTRA-05 persiste ao trocar números")
	g.start_round()
	check(g.missed_balls.empty(), "REQ-EXTRA-05 some ao jogar novamente")
	# preço ancorado no valor esperado
	g = plain()
	g.bet = 10
	g.start_round()
	g.cards = [[1, 2, 3, 4, 91, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], range(31, 46), range(46, 61), range(61, 76)]
	g.cards[0] = [1, 2, 3, 4, 85, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	for i in range(4):
		g.index_of[i] = g._index_card(g.cards[i])
	g.deck = [1, 2, 3, 4] + range(16, 85) + [5] + range(86, 91)
	g.deck = range(1, 91)
	g.deck.erase(85)
	g.deck.append(85)
	g.drawn = [1, 2, 3, 4]
	g.marks = [15, 0, 0, 0]
	g.deck = range(86, 91) + [85] + range(31, 85)
	g.phase = "extras"
	var value = g.extra_value()
	check(value > 0 and g.extra_quote() >= 1, "REQ-EXTRA-03 preço positivo com figura quase completa")
	check(g.extra_quote() == int(max(1, round(g.extra_expected() * g.extra_factor))), "REQ-EXTRA-03 preço = fator × valor esperado")
	g.free_chance = 0.0
	var best = g.best_joker_number()
	check(best == -1, "Joker só existe na fase joker")
	g.phase = "joker"
	check(g.best_joker_number() in g.joker_options(), "Joker sugerido é opção válida")

func test_extra_eligibility_transitions():
	for joker in [false, true]:
		var g = plain()
		g.cards = [range(1,16), range(31,46), range(46,61), range(61,76)]
		for c in range(4):
			g.index_of[c] = g._index_card(g.cards[c])
		g.marks = [15,0,0,0]
		g.drawn = [1,2,3,4]
		g.deck = [5,80,81]
		g.phase = "extras"
		g.joker_chance = 1.0 if joker else 0.0
		check(g.extra_eligible(), "REQ-EXTRA-07 próxima figura detectada")
		var number = g.buy_extra()
		if joker:
			check(number == 0 and g.phase == "joker", "REQ-EXTRA-07 Joker oferecido")
			g.choose_joker(5)
		check(g.phase == "extras" and g.extra_eligible(), "REQ-EXTRA-07 continua vendendo extras mesmo sem prêmio próximo")
		check(g.extra_quote() == g.MIN_EXTRA_PRICE, "REQ-EXTRA-07 sem prêmio próximo o preço é o mínimo")
		g.extras_bought = g.MAX_EXTRAS
		check(not g.extra_eligible() and g.buy_extra() == -1, "REQ-EXTRA-07 rejeita compra no limite de extras")
	var g = plain()
	g.marks = [15,0,0,0]
	g.open_cards = [false, false, false, false]
	g.deck = range(1,91)
	check(not g.extra_eligible(), "REQ-EXTRA-07 sem cartela aberta não libera extra")

func test_hold_profile():
	var g = plain()
	check(g.set_hold(4) and g.set_hold(20) and not g.set_hold(3) and not g.set_hold(21), "REQ-RET-01 retenção 4% a 20%")
	var previous = 0.0
	for h in range(Profile.MIN_HOLD, Profile.MAX_HOLD + 1):
		var f = Profile.extra_factor(h)
		check(f > previous, "REQ-RET-02 fator cresce com a retenção (%d%%)" % h)
		previous = f
	g.set_hold(12)
	check(abs(g.extra_factor - Profile.extra_factor(12)) < 0.0001, "REQ-RET-02 jogo usa o fator da retenção")
	check(Profile.target_rtp(8) == 92, "REQ-RET-03 RTP-alvo = 100 - retenção")

func test_bonus_jackpot_scaling():
	var b = Rules.Bonus.new()
	b.begin([false, true, false], 4, 10)
	b.begin([true, false, false], 4, 10)
	var small = b.jackpot_chance(0)
	b.begin([true, false, false], 40, 10)
	var large = b.jackpot_chance(0)
	check(abs(large / small - 10.0) < 0.001, "REQ-BONUS-01 chance do acumulado proporcional à aposta")
	check(small * 50000 / 40.0 > 0.0, "REQ-BONUS-01 retorno esperado positivo")

func test_random_rounds():
	var g = Rules.new()
	g.credits = 10000000
	for i in range(150):
		g.bet = 1 + i % 20
		g.change_cards()
		if i % 5 == 0:
			g.toggle_card(i % 4)
		check(g.start_round(), "rodada inicia")
		var wallet = g.credits
		g.draw_initial()
		var guard = 0
		while g.phase != "finished" and guard < 100:
			guard += 1
			match g.phase:
				"bonus":
					if g.bonus.spins_left > 0:
						g.spin_bonus()
					else:
						g.close_bonus()
				"joker":
					g.choose_joker(g.best_joker_number())
				"extras":
					if i % 3 == 0 and g.extras_bought >= 2:
						g.finish_round()
					else:
						g.buy_extra()
		check(g.phase == "finished", "rodada termina")
		check(g.drawn.size() <= 40 and g.extras_bought <= 10, "limite de 40 bolas")
		check(g.missed_balls.size() == 0 or g.missed_balls.size() + g.extras_bought == 10, "bolas canceladas completam dez")
		var seen = {}
		for n in g.drawn:
			check(not seen.has(n), "sem bola repetida")
			seen[n] = true
		for n in g.missed_balls:
			check(not seen.has(n), "bola cancelada não repete sorteada")
	check(g.stats.rounds == 150 and g.stats["in"] > 0, "REQ-OPER-05 contadores atualizados")

func test_scene():
	var scene = load("res://Main.tscn").instance()
	root.add_child(scene)
	call_deferred("scene_checks", scene)

func scene_checks(s):
	check(s.controls.has("play") and not s.controls.has("toggle0") and not s.controls.has("swap0"), "REQ-UI-01 controles criados uma vez")
	check(s.overlay != null and not s.overlay.is_open(), "REQ-MENU-01 menu fechado ao iniciar")
	s.game.credits = 100000
	s.play()
	check(s.busy, "REQ-SORT-02 sorteio apresentado")
	for i in range(100):
		s._process(0.1)
	check(not s.busy and s.shown == 30, "REQ-SORT-02 30 bolas reveladas em sequência")
	if s.game.phase == "extras":
		s.play()
		check(s.game.phase == "finished" and s.game.missed_balls.size() == 10, "REQ-EXTRA-04 cancelar na cena")
	# Geometry and anticipation use visible draws, never unrevealed results.
	s.dual = true
	s.modal_kind = ""
	s.apply_layout()
	s.layout_controls()
	check(s.card_rect(0).position.y + s.off_bottom() > s.STRIP + s.SPLIT_BASE + s.GAP, "REQ-MON-03 cartelas ficam na tela inferior")
	s.vis_set.clear()
	for n in range(4):
		s.vis_set[s.game.cards[0][n]] = true
	var near = s.near_cells(0)
	check(near.has(4) and near.size() == 1, "REQ-UI-02 só a célula faltante da linha sinaliza")
	s.vis_set[s.game.cards[0][4]] = true
	check(not s.near_cells(0).has(4), "REQ-UI-02 célula deixa de piscar após completar")
	# menu
	s.busy = false
	s.modal_kind = ""
	s.game.phase = "ready"
	s.refresh()
	s.open_menu()
	check(s.overlay.mode == "calc", "REQ-MENU-01 MENU abre a calculadora")
	s.overlay.press("2")
	s.overlay.press("+")
	s.overlay.press("3")
	s.overlay.press("=")
	check(s.overlay.entry == "5", "REQ-MENU-02 calculadora soma")
	s.overlay.press("C")
	s.overlay.press("9")
	s.overlay.press("/")
	s.overlay.press("0")
	s.overlay.press("=")
	check(s.overlay.entry == "Erro", "REQ-MENU-02 divisão por zero")
	s.overlay.press("C")
	for ch in "913731":
		s.overlay.press(ch)
	check(s.overlay.mode == "operator", "REQ-MENU-03 código 913731 abre o menu do operador")
	s.op_set_hold(15)
	check(s.game.hold_percent == 15, "REQ-OPER-01 retenção ajustável")
	s.op_set_denomination(25)
	check(s.game.denomination == 25, "REQ-OPER-02 crédito R$ 0,25")
	s.op_set_denomination(10)
	check(s.game.denomination == 10, "REQ-OPER-02 crédito R$ 0,10")
	s.op_set_monitor("dual")
	check(s.dual and s.total_height() == 1680, "REQ-MON-02 modo 2 telas")
	s.op_set_monitor("vertical")
	check(not s.dual and s.total_height() == 1636, "REQ-MON-01 modo vertical")
	s.overlay.close()
	check(not s.overlay.is_open(), "REQ-MENU-04 voltar ao jogo")
	s.overlay.open_calculator()
	for ch in "5913731":
		s.overlay.press(ch)
	check(s.overlay.mode == "operator", "REQ-MENU-03 código aceito após outros dígitos")
	s.overlay.close()
	print("BOARD TESTS: %d failures; 150 random rounds + paytable, cancel reveal, menu, monitor modes" % failures)
	quit(1 if failures > 0 else 0)
