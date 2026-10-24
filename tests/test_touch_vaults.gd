extends SceneTree
var failures = 0
func check(ok, label):
	if not ok:
		failures += 1
		printerr("FAIL " + label)
func _init():
	call_deferred("run")
func run():
	var s = load("res://Main.tscn").instance()
	root.add_child(s)
	s.set_process(false)
	s.audio.set_enabled(false)
	s._animate_vaults(0.1)
	for color in range(3):
		check(s.vault_sprites[color].texture.resource_path.ends_with("closed.png"), "initial vault closed and intact")
		check(s.vault_sprites[color].texture == s.VAULT_STAGES[color][0], "native artwork for each color")
		check(s.vault_sprites[color].material == null, "native colors without recoloring")
	s.dual = true
	s.game.color_chance = 0
	s.game.free_chance = 0
	s.game.joker_chance = 0
	s.game.cards = [range(1,16), range(31,46), range(46,61), range(61,76)]
	for c in range(4):
		s.game.index_of[c] = s.game._index_card(s.game.cards[c])
	s.game.drawn = [1,2,3,4] + range(20,30) + range(61,77)
	s.game.marks = [15,0,0,0]
	s.game.deck = [80,81,82,83,84,5]
	s.game.phase = "extras"
	s.shown = 30
	s.refresh()
	var touch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = s._slot_position(8) + Vector2(0, s.off_bottom())
	s._gui_input(touch)
	check(s.extra_slots == [8], "touch reserves requested socket")
	var balance = s.game.credits
	s._gui_input(touch)
	check(s.game.credits == balance and s.game.extras_bought == 1, "double tap blocked during reveal")
	s.busy = false
	s.buy_extra()
	check(s.extra_slots == [8,0], "button fills first free socket")
	s.busy = false
	balance = s.game.credits
	s.buy_extra(8)
	check(s.game.credits == balance and s.extra_slots == [8,0], "occupied socket never charges")
	s.game.joker_chance = 1
	s.buy_extra(6)
	check(s.pending_slot == 6 and s.game.phase == "joker", "Joker keeps requested socket")
	s.choose_joker(5)
	check(s.extra_slots == [8,0,6] and s.pending_slot == -1, "Joker lands in reserved socket")
	s.busy = false
	s.coin_bursts.clear()
	s.coin_bursts.append({"born":s.elapsed,"color":1,"sounded":false})
	s._process(0.1)
	check(s.vault_charge[1] == 1, "collect inflates matching vault")
	check(s.vault_charge[0] == 0 and s.vault_charge[2] == 0, "other colors do not fill")
	check(s.vault_sprites[1].texture.resource_path.ends_with("closed.png"), "one collection does not rush the fill stages")
	s._process(0.1)
	check(s.vault_charge[1] == 1, "no repeated inflation per frame")
	s._reset_presentation()
	check(s.vault_charge[1] == 1, "inflation persists across rounds")
	s.game.bonus.begin([false,true,false],4,10)
	s.game.phase = "bonus"
	s.settle()
	check(s.busy and s.modal_kind == "" and s.vault_transition == 0.0, "bonus waits for vault opening")
	s._process(s.VAULT_BANG + 0.01)
	check(s.vault_burst_started and s.modal_kind == "", "transition precedes slot")
	check(s.vault_particles.empty(), "no substitute explosion before user animation")
	s._animate_vaults(0.1)
	check(s.vault_sprites[1].texture.resource_path.ends_with("burst.png"), "trigger shows supplied rupture frame")
	s._process(s.VAULT_END)
	check(s.modal_kind == "bonus" and not s.busy and s.vault_charge[1] == 0, "slot opens and triggered vault resets")
	print("TOUCH / VAULT TESTS: %d failures" % failures)
	quit(1 if failures else 0)

