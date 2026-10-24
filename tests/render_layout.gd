extends SceneTree

func _init():
	call_deferred("run")

func run():
	var s = load("res://Main.tscn").instance()
	root.add_child(s)
	s.audio.set_enabled(false)
	s.dual = true
	s.game.color_chance = 0
	s.game.cards = [range(1,16), range(16,31), range(31,46), range(46,61)]
	for c in range(4):
		s.game.index_of[c] = s.game._index_card(s.game.cards[c])
	s.game.drawn = [1,2,3,4,5,16,17,18,19] + range(61,82)
	s.game.deck = range(20,61) + range(82,91)
	s.game.ball_events.clear()
	for n in s.game.drawn:
		s.game.ball_events.append({"number":n,"color":-1,"collected":false})
		s.vis_set[n] = true
	s.shown = 30
	s.game.marks = [31,15,0,0]
	s.game.phase = "extras"
	s.game.round_wins = 12
	s.win_shown = 12
	s.pattern_flash[11] = s.elapsed
	s.status_message = "Falta uma bola para premiar. Escolha a extra ou cancele."
	s.refresh()
	yield(create_timer(0.6), "timeout")
	capture("layout-extras")
	for item in [["green",[true,false,false]], ["blue",[false,false,true]], ["red",[false,true,false]]]:
		s.preview_bonus = true
		s.game.bonus.begin(item[1],4,10)
		s.game.bonus.spin()
		s.open_modal("bonus")
		yield(create_timer(0.6), "timeout")
		capture("layout-bonus-" + item[0])
	print("LAYOUT RENDERS completed")
	quit()

func capture(name):
	var image = root.get_texture().get_data()
	image.flip_y()
	image.save_png("res://tests/" + name + ".png")
