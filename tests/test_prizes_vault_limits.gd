extends SceneTree
const Rules = preload("res://scripts/board_rules.gd")
var failures = 0
var heard = []
func check(ok, label):
	if not ok:
		failures += 1
		printerr("FAIL " + label)
func _init():
	call_deferred("run")
func heard_prize(pattern):
	heard.append(pattern)
func run():
	var g = Rules.new()
	g.color_chance = 0
	g.bet = 1
	g.marks = [31,0,0,0]
	g._pay_patterns(4)
	check(g.round_wins == 3 and g.round_wins * g.denomination == 30, "one line pays R$0.30 with four open cards")
	g._pay_patterns(5)
	check(g.round_wins == 3, "same figure is never paid twice")
	g.marks[1] = 31
	g._pay_patterns(6)
	check(g.round_wins == 6, "two winning cards pay R$0.60")
	check(g.slot_unit() == 4, "slot base preserved")
	for limit in range(20,51):
		g = Rules.new()
		g.vault_targets = [limit,50,20]
		g.collections[1] = 19
		for n in range(1,limit + 1):
			g.collect_vault(0)
			check(g.pending_bonus[0] == (n == limit), "vault opens exactly at selected limit %d, collection %d" % [limit,n])
			if n == 10:
				g._clear_round()
				check(g.collections[0] == 10, "collections persist across rounds")
		check(not g.pending_bonus[1] and g.collections[1] == 19, "other vault cannot open early")
		g.collect_vault(0)
		check(g.collections[0] == limit, "pending vault stops collecting")
		g._open_pending_bonus("finished")
		check(g.bonus.flags == [true,false,false] and g.collections == [0,19,0], "only triggered vault resets")
		check(g.vault_targets[0] >= 20 and g.vault_targets[0] <= 50, "new cycle limit remains bounded")
	g = Rules.new()
	g.vault_targets = [20,50,20]
	for i in range(20):
		g.collect_vault(0)
		g.collect_vault(2)
	g._open_pending_bonus("finished")
	check(g.bonus.flags == [true,false,true], "two completed vaults combine")
	var limits = {}
	for i in range(100):
		g = Rules.new()
		for limit in g.vault_targets:
			check(limit >= 20 and limit <= 50, "initial limits bounded")
			limits[limit] = true
	check(limits.size() > 10, "limits vary between cycles")
	var s = load("res://Main.tscn").instance()
	root.add_child(s)
	s.set_process(false)
	AudioServer.set_bus_mute(0, true)
	s.audio.set_enabled(true)
	s.audio.connect("prize_started", self, "heard_prize")
	var sound_names = ["bingo","1","2","3","5","4","6","11","10","7","9","8"]
	var lengths = [23.46,11.94,10.92,7.71,6.92,4.49,3.71,1.25,1.59,3.40,2.56,1.04]
	for p in range(12):
		s._reset_presentation()
		s.game.drawn = [1]
		s.game.ball_events = [{"color":-1,"collected":false}]
		s.game.win_log = [{"ball":0,"card":0,"pattern":p,"amount":3}]
		var before = heard.size()
		s._reveal_ball(0)
		check(heard.size() == before + 1 and heard.back() == p, "correct sound for paid pattern %d" % p)
		check(s.audio.prize_player.stream.resource_path.ends_with("/%s.ogg" % sound_names[p]), "requested Ace Base asset")
		check(abs(s.audio.prize_player.stream.get_length() - lengths[p]) < 0.03, "requested audio duration")
		s._reveal_ball(0)
		check(heard.size() == before + 1, "duplicate reveal cannot replay prize")
	# Completing the full card with the 31st ball selects bingo, even with lesser new figures.
	s._reset_presentation()
	s.game = Rules.new()
	s.game.color_chance = 0
	s.game.free_chance = 0
	s.game.joker_chance = 0
	s.game.credits = 100000
	s.game.cards[0] = range(1,16)
	s.game.index_of[0] = s.game._index_card(s.game.cards[0])
	s.game.open_cards = [true,false,false,false]
	s.game.marks = [32767 ^ (1 << 14),0,0,0]
	s.game.drawn = range(1,15) + range(31,47)
	for n in s.game.drawn:
		s.game.ball_events.append({"color":-1,"collected":false})
	s.game.deck = [15,80]
	s.game.phase = "extras"
	check(s.game.buy_extra() == 15, "extra completes full card")
	s._reveal_ball(30)
	check(heard.back() == 0, "extra bingo plays 23.46-second bingo sound")
	var count = heard.size()
	s.settle()
	s.game.drawn.append(80)
	s.game.ball_events.append({"color":-1,"collected":false})
	s._reveal_ball(31)
	s.settle()
	check(heard.size() == count, "losing extra and settle do not replay prior win")
	s._reset_presentation()
	s.game.phase = "ready"
	s.game.open_cards = [true,true,true,true]
	s.busy = false
	s.modal_kind = ""
	s.dual = true
	s.refresh()
	check(not s.controls.has("toggle0") and not s.controls.has("swap0"), "card buttons removed")
	for touch in [true,false]:
		var event = InputEventScreenTouch.new() if touch else InputEventMouseButton.new()
		if not touch:
			event.button_index = BUTTON_LEFT
		event.pressed = true
		event.position = s.card_rect(0).position + Vector2(100,100 + s.off_bottom())
		s._gui_input(event)
		check(s.game.open_cards[0] == (not touch), "touch closes and mouse reopens card")
		s.game.phase = "drawing"
		s._gui_input(event)
		check(s.game.open_cards[0] == (not touch), "card locked during round")
		s.game.phase = "ready"
	for color in range(3):
		check(s.VAULT_STAGES[color].size() == 10, "ten authored stages per vault")
	s.vault_limits = [50,50,50]
	s.vault_charge = [1,25,49]
	s._animate_vaults(0.1)
	check(s.vault_sprites[0].texture == s.VAULT_STAGES[0][0], "first ball does not fill vault")
	check(s.vault_sprites[1].texture == s.VAULT_STAGES[1][4], "halfway fill")
	check(s.vault_sprites[2].texture == s.VAULT_STAGES[2][7], "pressure before trigger")
	s.game.bonus.flags = [false,false,true]
	s.vault_transition = 0.9
	s._animate_vaults(0.1)
	check(s.vault_sprites[2].texture == s.VAULT_STAGES[2][8], "burst only after trigger")
	s.vault_transition = 1.8
	s._animate_vaults(0.1)
	check(s.vault_sprites[2].texture == s.VAULT_STAGES[2][9], "open door follows burst")
	print("PRIZE / VAULT LIMIT TESTS: %d failures" % failures)
	quit(1 if failures else 0)
