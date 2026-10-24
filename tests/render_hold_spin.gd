extends SceneTree
var failures = 0
func _init():
	call_deferred("run")

func run():
	var s = load("res://Main.tscn").instance()
	root.add_child(s)
	s.audio.set_enabled(false)
	s.dual = true
	s.preview_bonus = true
	s.set_process(false)
	s.game.phase = "extras"
	s.busy = true
	s.refresh()
	if s.controls.play.text == "CANCELAR EXTRA":
		failures += 1
	s.busy = false
	s.game.phase = "idle"
	for item in [["single",[true,false,false]], ["double",[true,true,true]]]:
		s.game.bonus.begin(item[1],4,10,true)
		s.open_modal("bonus")
		s.update()
		yield(VisualServer, "frame_post_draw")
		capture("hold-" + item[0] + "-empty")
		var landings = []
		for r in range(s.game.bonus.rows):
			for c in range(5):
				if (r * 5 + c) % 4 == 3: continue
				var coin = s.game.bonus.cash_coin()
				if c == 2: coin = {"value":1000,"base":1000,"multiplier":1,"jackpot":r % 3}
				landings.append({"row":r,"col":c,"coin":coin})
		s.game.bonus.resolve_spin(landings)
		s.spin_time = 1.9
		s.spin_elapsed = 0.7
		s.update()
		yield(VisualServer, "frame_post_draw")
		capture("hold-" + item[0] + "-falling")
		s.spin_time = 0
		s.update()
		yield(VisualServer, "frame_post_draw")
		capture("hold-" + item[0] + "-locked")
	print("HOLD UI: ", failures, " failures; six captures")
	quit(failures)

func capture(name):
	var image = root.get_texture().get_data()
	image.flip_y()
	image.save_png("res://tests/" + name + ".png")
