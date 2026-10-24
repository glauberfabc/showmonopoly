extends SceneTree
func _init():
	call_deferred("run")
func run():
	var s = load("res://Main.tscn").instance()
	root.add_child(s)
	s.audio.set_enabled(false)
	s.dual = true
	s.refresh()
	yield(create_timer(0.3), "timeout")
	capture("vaults-zero-gain")
	s.vault_limits = [40,40,40]
	s.vault_charge = [35,25,15]
	yield(create_timer(0.4), "timeout")
	capture("vaults-inflated")
	for color in range(3):
		s.set_process(false)
		s.vault_impact = [-100,-100,-100]
		s.vault_impact[color] = s.elapsed - 0.10
		s._animate_vaults(0.016)
		s.update()
		yield(VisualServer, "frame_post_draw")
		capture("vaults-impact-%d" % color)
		s.set_process(true)
		yield(create_timer(1.8), "timeout")
	s.game.bonus.begin([true,false,false],4,10)
	s.game.phase = "bonus"
	s.settle()
	yield(create_timer(0.9), "timeout")
	capture("vaults-burst")
	yield(create_timer(0.9), "timeout")
	capture("vaults-opening")
	yield(create_timer(s.VAULT_END), "timeout")
	capture("vaults-bonus")
	print("VAULT RENDERS completed")
	quit()
func capture(name):
	var img = root.get_texture().get_data()
	img.flip_y()
	img.save_png("res://tests/" + name + ".png")
