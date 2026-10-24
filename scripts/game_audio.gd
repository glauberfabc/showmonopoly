extends Node

const TRACK = preload("res://assets/audio/game-sounds-en-hash_12a703cb7803d40f9b24_e2d511ae.mp3")
const CUES = {
	"ball": [0.0, 0.125011],
	"cards": [51.436576, 0.208345],
	"bet": [51.103243, 0.083333],
	"start": [224.783469, 0.380272],
	"extra": [6.285556, 0.567029],
	"open": [50.399388, 0.453855],
	"close": [49.149388, 1.0],
	"slot_win": [79.933061, 4.0]
}
signal prize_started(pattern)
const PRIZES = [
	preload("res://assets/audio/ace-prizes/bingo.ogg"),
	preload("res://assets/audio/ace-prizes/1.ogg"),
	preload("res://assets/audio/ace-prizes/2.ogg"),
	preload("res://assets/audio/ace-prizes/3.ogg"),
	preload("res://assets/audio/ace-prizes/5.ogg"),
	preload("res://assets/audio/ace-prizes/4.ogg"),
	preload("res://assets/audio/ace-prizes/6.ogg"),
	preload("res://assets/audio/ace-prizes/11.ogg"),
	preload("res://assets/audio/ace-prizes/10.ogg"),
	preload("res://assets/audio/ace-prizes/7.ogg"),
	preload("res://assets/audio/ace-prizes/9.ogg"),
	preload("res://assets/audio/ace-prizes/8.ogg")
]
var prize_player

func play_prize(pattern):
	if not enabled or pattern < 0 or pattern >= PRIZES.size():
		return
	if prize_player == null:
		prize_player = AudioStreamPlayer.new()
		prize_player.volume_db = -4
		add_child(prize_player)
	prize_player.stop()
	prize_player.stream = PRIZES[pattern]
	prize_player.stream.loop = false
	prize_player.play()
	emit_signal("prize_started", pattern)

func stop_prize():
	if prize_player != null:
		prize_player.stop()

const VOICES = [
	preload("res://assets/audio/voice_super_big_win.mp3"),
	preload("res://assets/audio/voice_mega_big_win.mp3"),
	preload("res://assets/audio/voice_ultra_big_win.mp3")
]
const FILL_LOOP = preload("res://assets/audio/fill_loop.mp3")
const SFX = {
	"reel_start": preload("res://assets/audio/reel_start.mp3"),
	"reel_spin": preload("res://assets/audio/reel_spin.mp3"),
	"reel_stop1": preload("res://assets/audio/reel_stop1.mp3"),
	"reel_stop2": preload("res://assets/audio/reel_stop2.mp3"),
	"reel_stop3": preload("res://assets/audio/reel_stop3.mp3"),
	"reel_stop4": preload("res://assets/audio/reel_stop4.mp3"),
	"reel_stop5": preload("res://assets/audio/reel_stop5.mp3")
}
const THEME = preload("res://assets/audio/theme_free_spins.mp3")
var sfx_players = {}
var theme_player
var voice_player
var fill_player
var enabled = true
var voices = []
var cursor = 0
var coin_voices = []
var coin_cursor = 0

func play_voice(tier):
	if voice_player == null:
		voice_player = AudioStreamPlayer.new()
		voice_player.volume_db = -2
		add_child(voice_player)
	voice_player.stop()
	if not enabled:
		return
	voice_player.stream = VOICES[int(clamp(tier, 0, VOICES.size() - 1))]
	voice_player.play()

func set_fill_loop(active):
	if fill_player == null:
		fill_player = AudioStreamPlayer.new()
		fill_player.stream = FILL_LOOP
		fill_player.volume_db = -8
		add_child(fill_player)
	if active and enabled:
		if not fill_player.playing:
			fill_player.play()
	elif fill_player.playing:
		fill_player.stop()

func play_sfx(name, volume = -4.0):
	if not SFX.has(name):
		return
	if not sfx_players.has(name):
		var player = AudioStreamPlayer.new()
		player.stream = SFX[name]
		add_child(player)
		sfx_players[name] = player
	var p = sfx_players[name]
	p.volume_db = volume
	p.stop()
	if enabled:
		p.play()

func stop_sfx(name):
	if sfx_players.has(name):
		sfx_players[name].stop()

func play_theme(active):
	if theme_player == null:
		theme_player = AudioStreamPlayer.new()
		theme_player.stream = THEME
		theme_player.volume_db = -13
		add_child(theme_player)
	if active and enabled:
		if not theme_player.playing:
			theme_player.play()
	elif theme_player.playing:
		theme_player.stop()

func stop_voice():
	if voice_player != null:
		voice_player.stop()

func _ready():
	for i in range(4):
		var player = AudioStreamPlayer.new()
		player.stream = TRACK
		player.volume_db = -9
		add_child(player)
		var cutoff = Timer.new()
		cutoff.one_shot = true
		cutoff.connect("timeout", player, "stop")
		add_child(cutoff)
		voices.append([player, cutoff])
	# Dedicated voices keep fast ball ticks from cutting off coin impacts.
	for i in range(6):
		var player = AudioStreamPlayer.new()
		player.stream = TRACK
		player.volume_db = -7
		add_child(player)
		var cutoff = Timer.new()
		cutoff.one_shot = true
		cutoff.connect("timeout", player, "stop")
		add_child(cutoff)
		coin_voices.append([player, cutoff])

func play_coin():
	if not enabled:
		return
	var voice = coin_voices[coin_cursor]
	coin_cursor = (coin_cursor + 1) % coin_voices.size()
	voice[0].play(59.085556)
	voice[1].start(0.474172)

func play_cue(cue):
	if not enabled or not CUES.has(cue):
		return
	var voice = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice[0].play(CUES[cue][0])
	voice[1].start(CUES[cue][1])

func set_enabled(value):
	enabled = value
	if not value:
		stop_prize()
		stop_voice()
		set_fill_loop(false)
		play_theme(false)
	if not enabled:
		for voice in voices + coin_voices:
			voice[0].stop()
			voice[1].stop()
