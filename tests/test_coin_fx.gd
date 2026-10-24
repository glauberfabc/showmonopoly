extends SceneTree

func _init():
	call_deferred("run")

func run():
	var scene = load("res://Main.tscn").instance()
	get_root().add_child(scene)
	scene.set_process(false)
	scene.audio.set_enabled(true)
	scene.game.drawn = [7]
	scene.game.ball_events = [{"number": 7, "color": 1, "collected": true}]
	scene.game.win_log.clear()
	scene._reveal_ball(0)
	assert(scene.coin_bursts.size() == 1)
	scene._process(0.46)
	assert(scene.audio.coin_cursor == 1)
	scene._process(0.1)
	assert(scene.audio.coin_cursor == 1) # no repeated sound on subsequent frames
	scene.audio.set_enabled(false)
	scene._reveal_ball(0)
	scene._process(0.46)
	assert(scene.audio.coin_cursor == 1) # mute also applies to the dedicated voices
	scene._process(2.0)
	assert(scene.coin_bursts.empty())
	scene._reveal_ball(0)
	scene._reset_presentation()
	assert(scene.coin_bursts.empty())
	print("COIN FX: collection, single sound, mute, cleanup and round reset passed")
	quit()
