extends Control
# Show Monopoly — cena única. Todas as opções ficam dentro do jogo (ver docs/).
const Rules = preload("res://scripts/board_rules.gd")
const OperatorConfig = preload("res://scripts/operator_config.gd")
const BallArt = preload("res://scripts/ball_art.gd")
const MenuOverlay = preload("res://scripts/menu_overlay.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const GoldAmount = preload("res://scripts/gold_amount.gd")
var gold_amounts = {}
var gold_fonts = {}
const HOLD_COIN = preload("res://assets/hold-spin/coin.png")
const HOLD_JACKPOTS = [preload("res://assets/hold-spin/mini.png"), preload("res://assets/hold-spin/minor.png"), preload("res://assets/hold-spin/major.png")]
const BASE_ART = preload("res://assets/monopoly-base.png")
const BONUS_ART = preload("res://assets/monopoly-bonus.png")
const SYMBOL_ART = preload("res://assets/monopoly-symbols.png")
const WARP_SHADER = preload("res://assets/char_warp.shader")
const SHINE_SHADER = preload("res://assets/logo_shine.shader")
# cofres vermelho e azul um pouco menores, para parecerem apoiados no centro da mesa e não na beirada
const VAULT_SCALE = [0.25, 0.225, 0.225]
const SUPER_WIN_ART = preload("res://assets/super_big_win.png")
const BIGWIN_ART = [preload("res://assets/super_big_win.png"), preload("res://assets/mega_big_win.png"), preload("res://assets/ultra_big_win.png")]
const COIN_ART = preload("res://assets/coin_m.png")
const BUILD = "2026-10-13 · selos mega/ultra e moedas 3D"
const VAULT_STAGES = [
	[preload("res://assets/vault-stages/closed.png"), preload("res://assets/vault-stages/fill-1.png"), preload("res://assets/vault-stages/fill-2.png"), preload("res://assets/vault-stages/fill-3.png"), preload("res://assets/vault-stages/fill-4.png"), preload("res://assets/vault-stages/fill-5.png"), preload("res://assets/vault-stages/pressure-1.png"), preload("res://assets/vault-stages/pressure-2.png"), preload("res://assets/vault-stages/burst.png"), preload("res://assets/vault-stages/open.png")],
	[preload("res://assets/vault-stages/double/closed.png"), preload("res://assets/vault-stages/double/fill-1.png"), preload("res://assets/vault-stages/double/fill-2.png"), preload("res://assets/vault-stages/double/fill-3.png"), preload("res://assets/vault-stages/double/fill-4.png"), preload("res://assets/vault-stages/double/fill-5.png"), preload("res://assets/vault-stages/double/pressure.png"), preload("res://assets/vault-stages/double/cracked.png"), preload("res://assets/vault-stages/double/burst.png"), preload("res://assets/vault-stages/double/open.png")],
	[preload("res://assets/vault-stages/extra-spins/closed.png"), preload("res://assets/vault-stages/extra-spins/fill-1.png"), preload("res://assets/vault-stages/extra-spins/fill-2.png"), preload("res://assets/vault-stages/extra-spins/fill-3.png"), preload("res://assets/vault-stages/extra-spins/fill-4.png"), preload("res://assets/vault-stages/extra-spins/pressure.png"), preload("res://assets/vault-stages/extra-spins/fill-5.png"), preload("res://assets/vault-stages/extra-spins/cracked.png"), preload("res://assets/vault-stages/extra-spins/burst.png"), preload("res://assets/vault-stages/extra-spins/open.png")]
]
const STRIP = 100
const GAP = 44
const ART_H = 1536
const SPLIT_BASE = 600
const SPLIT_BONUS = 600
const BALL_INTERVAL = 0.11
const EXTRA_INTERVAL = 0.8

var game
var op
var audio
var overlay
var balls = {}
var fonts = {}
var controls = {}
var modal_buttons = []
var dual = false
var busy = false
var spin_time = 0.0
var spin_elapsed = 0.0
var reels_stopped = 0
const SPIN_TOTAL = 2.6
const REEL_STOPS = [1.0, 1.35, 1.7, 2.05, 2.4]
var elapsed = 0.0
var coin_bursts = []
var vault_sprites = []
var vault_charge = [0, 0, 0]
var vault_limits = [50, 50, 50]
var announced_prizes = {}
var vault_impact = [-100.0, -100.0, -100.0]
var vault_transition = -1.0
var vault_fill = [0.0, 0.0, 0.0]
var vault_particles = []
var vault_preview = false
const VAULT_BANG = 0.75
const VAULT_END = 2.9
var vault_burst_started = false
var modal_kind = ""
var preview_bonus = false
var status_message = "SHOW MONOPOLY · Escolha as cartelas e a aposta e jogue."
var bonus_intro = 0.0
var extra_slots = []
var pending_slot = -1
var joker_numbers = {}
var announced_win = 0
var jp_shown = [0.0, 0.0, 0.0]
var bigwin_t = -1.0
var bigwin_done = false
var bigwin_amount = 0
var bigwin_tier = 0
var bigwin_tick = 0.0
const BIGWIN_TIME = 7.4
const BIGWIN_TITLES = ["SUPER BIG WIN", "MEGA BIG WIN", "ULTRA BIG WIN"]
const BIGWIN_MULTIPLES = [10, 40, 100]
# apresentação do sorteio
var shown = 0
var reveal_start = 0
var reveal_time = 0.0
var reveal_rate = BALL_INTERVAL
var reveal_tail = 0.9
var win_shown = 0
var vis_set = {}
var ball_birth = {}
var flashes = {}
var pattern_flash = {}
var floaters = []
# camadas de fundo (Sprites atrás do desenho) e materiais
var plate_top
var plate_bottom
var warp_left
var warp_right
var logo_sprite
var sprites = []
var callback
var gold = Color("e6b85f")
var ink = Color("132b34")
var cream = Color("f6efda")
var colors = [Color("45b886"), Color("df6860"), Color("57a8db"), Color("b493d9")]
var vault_colors = [Color("2fc25e"), Color("e5413f"), Color("3478ea")]

# ---------------------------------------------------------------- utilidades
func font(size):
	size = int(size)
	if not fonts.has(size):
		var f = DynamicFont.new()
		f.font_data = load("res://assets/ui.ttf")
		f.size = size
		fonts[size] = f
	return fonts[size]

func money(cents):
	var value = abs(int(cents))
	var reais = str(int(value / 100))
	var grouped = ""
	while reais.length() > 3:
		grouped = "." + reais.substr(reais.length() - 3, 3) + grouped
		reais = reais.substr(0, reais.length() - 3)
	grouped = reais + grouped
	return "%sR$ %s,%02d" % ["-" if cents < 0 else "", grouped, value % 100]

func box(rect, color, border = Color("36525a"), radius = 16, width = 2):
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	draw_style_box(s, rect)

func text(value, rect, size = 24, color = Color("f6efda"), shadow = false):
	var f = font(size)
	var lines = str(value).split("\n")
	for i in range(lines.size()):
		var pos = Vector2(rect.position.x + (rect.size.x - f.get_string_size(lines[i]).x) / 2, rect.position.y + size + i * (size + 6))
		if shadow:
			draw_string(f, pos + Vector2(1.5, 2.0), lines[i], Color(0, 0, 0, 0.55))
		draw_string(f, pos, lines[i], color)

func total_height():
	return STRIP + ART_H + (GAP if dual else 0)

func split_y():
	if modal_kind == "bonus" and game.bonus.flags[1]:
		return 815
	return SPLIT_BONUS if modal_kind == "bonus" else SPLIT_BASE

func off_bottom():
	return STRIP + (GAP if dual else 0)

func canvas_y(y):
	return y + STRIP + (GAP if (dual and y >= split_y()) else 0)

func idle():
	return game._can_configure() and not busy and modal_kind == "" and not overlay.is_open()

# ---------------------------------------------------------------- inicialização
func _ready():
	op = OperatorConfig.new()
	op.load_settings()
	game = Rules.new()
	op.apply(game)
	for i in range(3):
		jp_shown[i] = float(game.bonus.levels.current[i])
	dual = op.monitor == "dual"
	audio = GameAudio.new()
	add_child(audio)
	audio.set_enabled(op.sound)
	balls = BallArt.build_set()
	_build_layers()
	_build_vaults()
	_build_controls()
	overlay = MenuOverlay.new()
	add_child(overlay)
	overlay.setup(self)
	if OS.has_feature("JavaScript"):
		callback = JavaScript.create_callback(self, "_browser_command")
		JavaScript.get_interface("window").potionCommand = callback
	apply_layout()
	refresh()

func _make_sprite():
	var s = Sprite.new()
	s.centered = false
	s.region_enabled = true
	s.show_behind_parent = true
	s.texture = BASE_ART
	add_child(s)
	sprites.append(s)
	return s

func _build_layers():
	plate_top = _make_sprite()
	plate_bottom = _make_sprite()
	warp_left = _make_sprite()
	warp_left.region_rect = Rect2(0, 12, 320, 410)
	warp_left.position = Vector2(0, STRIP + 12)
	var m = ShaderMaterial.new()
	m.shader = WARP_SHADER
	m.set_shader_param("box", Plane(0, 12, 320, 410))
	m.set_shader_param("center", Vector2(120, 215))
	m.set_shader_param("side", 1.0)
	m.set_shader_param("hand", Vector2(268, 112))
	m.set_shader_param("wrist", Vector2(232, 132))
	m.set_shader_param("phase", 0.0)
	warp_left.material = m
	warp_right = _make_sprite()
	warp_right.region_rect = Rect2(790, 12, 234, 410)
	warp_right.position = Vector2(790, STRIP + 12)
	var m2 = ShaderMaterial.new()
	m2.shader = WARP_SHADER
	m2.set_shader_param("box", Plane(790, 12, 234, 410))
	m2.set_shader_param("center", Vector2(915, 215))
	m2.set_shader_param("side", -1.0)
	m2.set_shader_param("hand", Vector2(985, 235))
	m2.set_shader_param("wrist", Vector2(960, 270))
	m2.set_shader_param("phase", 2.1)
	m2.set_shader_param("sway", 2.6)
	m2.set_shader_param("yaw", 4.0)
	m2.set_shader_param("wave", 0.03)
	warp_right.material = m2
	logo_sprite = _make_sprite()
	logo_sprite.region_rect = Rect2(226, 56, 576, 104)
	logo_sprite.position = Vector2(226, STRIP + 56)
	var m3 = ShaderMaterial.new()
	m3.shader = SHINE_SHADER
	logo_sprite.material = m3

func _build_vaults():
	# The supplied empty scene separates scenery from collectible vault sprites.
	var scene = Sprite.new()
	scene.texture = preload("res://assets/vault-stages/scene-reference.png")
	scene.centered = false
	scene.region_enabled = true
	scene.region_rect = Rect2(0, 94, 980, 576)
	scene.scale = Vector2(1024.0 / 980.0, 600.0 / 576.0)
	scene.position = Vector2(0, STRIP)
	scene.show_behind_parent = true
	add_child(scene)
	for color in range(3):
		var sprite = Sprite.new()
		sprite.texture = VAULT_STAGES[color][0]
		sprite.position = Vector2(190 + color * 322, STRIP + 452)
		sprite.scale = Vector2.ONE * VAULT_SCALE[color]
		sprite.show_behind_parent = true
		add_child(sprite)
		vault_sprites.append(sprite)

func _fill_target(color):
	return min(1.0, float(vault_charge[color]) / vault_limits[color])

func _animate_vaults(delta):
	for color in range(3):
		var sprite = vault_sprites[color]
		sprite.visible = modal_kind == "" or (modal_kind == "bonus" and not game.bonus.flags[1])
		var age = elapsed - vault_impact[color]
		# A collected ball compresses the safe, kicks it upward, then leaves a
		# springy wobble and a short pressure rattle. Each color has its own clock.
		var reacting = age >= 0.0 and age < 1.8
		var pressure = 1.0 + 0.55 * _fill_target(color)
		var bounce = sin(age * 22.0) * exp(-age * 3.0) * pressure if reacting else 0.0
		var rattle = sin(age * 76.0) * (1.0 - exp(-age * 28.0)) * exp(-age * 3.2) * pressure if reacting else 0.0
		var hop = sin(min(age / 0.34, 1.0) * PI) * 12.0 * pressure if reacting else 0.0
		vault_fill[color] = lerp(vault_fill[color], _fill_target(color), min(1.0, delta * 4.0))
		var stage = min(7, int(floor(_fill_target(color) * 8.0)))
		if vault_transition >= VAULT_BANG and game.bonus.flags[color]:
			stage = 8 if vault_transition < 1.6 else 9
		sprite.texture = VAULT_STAGES[color][stage]
		var size = VAULT_SCALE[color] * (1.0 + 0.035 * vault_fill[color])
		sprite.scale = Vector2(size * (1.0 - bounce * 0.065), size * (1.0 + bounce * 0.085))
		sprite.rotation = bounce * 0.035 + rattle * 0.014
		sprite.position = Vector2(190 + color * 322 + rattle * 4.5, STRIP + 452 - hop)

func _spawn_vault_money(color):
	var origin = Vector2(235 + color * 322, 468)
	for i in range(64):
		var angle = -PI / 2.0 + (_rnd(i, 11 + color) - 0.5) * 2.3
		var speed = 360.0 + _rnd(i, 12 + color) * 640.0
		vault_particles.append({
			"pos": origin + Vector2((_rnd(i, 13) - 0.5) * 120.0, (_rnd(i, 14) - 0.5) * 60.0),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"rot": _rnd(i, 15) * TAU, "spin": (_rnd(i, 16) - 0.5) * 14.0,
			"kind": 0 if i % 3 != 0 else 1,
			"born": elapsed + _rnd(i, 17) * 0.75,
			"floor": 560.0 + _rnd(i, 18) * 34.0,
			"bounces": 0, "color": color})

func _update_vault_particles(delta):
	for q in vault_particles:
		if elapsed < q.born:
			continue
		if q.bounces > 3:
			q.spin *= 0.9
			continue
		q.vel.y += 1250.0 * delta
		q.vel.x *= (1.0 - 0.6 * delta)
		q.pos += q.vel * delta
		q.rot += q.spin * delta
		if q.pos.y > q.floor and q.vel.y > 0.0:
			q.pos.y = q.floor
			q.vel.y *= -0.34
			q.vel.x *= 0.65
			q.spin *= 0.5
			q.bounces += 1
	while vault_particles.size() > 0 and elapsed - vault_particles[0].born > 3.4:
		vault_particles.pop_front()

func _set_art(texture):
	for s in sprites:
		s.texture = texture

func apply_layout():
	var split = split_y()
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1024, total_height()))
	plate_top.region_rect = Rect2(0, 0, 1024, split if dual else ART_H)
	plate_top.position = Vector2(0, STRIP)
	plate_bottom.visible = dual
	if dual:
		plate_bottom.region_rect = Rect2(0, split, 1024, ART_H - split)
		plate_bottom.position = Vector2(0, STRIP + split + GAP)
	if overlay != null:
		overlay.sync_size()

func _button(key, caption, method, args = []):
	var b = Button.new()
	b.text = caption
	b.focus_mode = Control.FOCUS_NONE
	b.connect("pressed", self, method, args)
	add_child(b)
	controls[key] = b
	return b

func style(b, fill = Color(0, 0.14, 0.06, 0.86), border = Color(0.9, 0.72, 0.37, 0.95), radius = 14, size = 17):
	b.add_font_override("font", font(size))
	b.add_color_override("font_color", cream)
	b.add_color_override("font_color_disabled", Color(0.62, 0.7, 0.7, 0.7))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s = StyleBoxFlat.new()
		var c = fill
		if state == "hover":
			c = fill.lightened(0.2)
		elif state == "pressed":
			c = fill.darkened(0.25)
		elif state == "disabled":
			c = Color(0.1, 0.16, 0.16, 0.7)
		s.bg_color = c
		s.border_color = border if state != "disabled" else Color(0.35, 0.42, 0.42, 0.7)
		s.set_border_width_all(2)
		s.set_corner_radius_all(radius)
		b.add_stylebox_override(state, s)

func style_art(b, filled):
	if b.has_meta("surface"):
		b.get_meta("surface").visible = false
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.02, 0.24, 0.09, 1.0) if filled else Color(0, 0, 0, 0)
		s.set_corner_radius_all(22)
		if state in ["hover", "focus"] and not filled:
			s.border_color = gold
			s.set_border_width_all(2)
		b.add_stylebox_override(state, s)
	b.add_font_override("font", font(24))
	b.add_color_override("font_color", Color("fff1b0"))
	b.add_color_override("font_color_disabled", Color("b9c9a0"))

func style_3d(b, fill, size):
	b.add_font_override("font", font(size))
	b.add_color_override("font_color", Color("fff8d5"))
	b.add_color_override("font_color_shadow", Color("142415"))
	b.add_constant_override("shadow_offset_x", 1)
	b.add_constant_override("shadow_offset_y", 2)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_stylebox_override(state, StyleBoxEmpty.new())
	var surface
	if b.has_meta("surface"):
		surface = b.get_meta("surface")
	else:
		surface = ColorRect.new()
		surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surface.show_behind_parent = true
		var material = ShaderMaterial.new()
		material.shader = preload("res://assets/glossy_button.shader")
		surface.material = material
		b.add_child(surface)
		b.set_meta("surface", surface)
		b.connect("resized", self, "_sync_button_surface", [b])
	surface.material.set_shader_param("tint", fill)
	surface.visible = true
	_sync_button_surface(b)

func _sync_button_surface(b):
	if not b.has_meta("surface"):
		return
	var surface = b.get_meta("surface")
	surface.rect_size = b.rect_size
	surface.material.set_shader_param("extent", b.rect_size)

func _build_controls():
	_button("cards", "TROCAR TODAS", "change_cards")
	_button("rules", "REGRAS", "show_rules")
	_button("sound", "SOM", "toggle_sound")
	_button("menu", "MENU", "open_menu")
	_button("minus", "", "set_bet", [-1])
	_button("plus", "", "set_bet", [1])
	_button("play", "", "play")
	_button("extra", "", "buy_extra")
	for key in ["cards", "rules", "sound", "menu"]:
		style(controls[key])
	for key in ["minus", "plus", "play", "extra"]:
		style_art(controls[key], false)

func place(key, rect):
	var b = controls[key]
	b.rect_position = Vector2(rect.position.x, canvas_y(rect.position.y))
	b.rect_size = rect.size

func layout_controls():
	place("cards", Rect2(10, 0, 215, 36))
	place("rules", Rect2(672, 0, 106, 36))
	place("sound", Rect2(784, 0, 106, 36))
	place("menu", Rect2(895, 0, 119, 36))
	place("minus", Rect2(347, 1382, 72, 83))
	place("plus", Rect2(609, 1380, 73, 85))
	if game.phase == "extras" and not busy:
		place("play", Rect2(704, 1355, 288, 54))
		place("extra", Rect2(704, 1421, 288, 65))
	else:
		place("play", Rect2(704, 1355, 288, 124))

# ---------------------------------------------------------------- estado dos controles
func refresh():
	var base = modal_kind == ""
	for key in ["cards", "rules", "sound", "menu", "minus", "plus", "play", "extra"]:
		controls[key].visible = base
	if modal_kind == "bonus":
		_set_art(BASE_ART)
	else:
		_set_art(BASE_ART)
	apply_layout()
	layout_controls()
	var can = idle()
	for key in ["cards", "rules", "menu"]:
		controls[key].disabled = not can
	controls.sound.disabled = overlay.is_open()
	controls.minus.disabled = not can or game.bet <= 1
	controls.plus.disabled = not can or game.bet >= game.MAX_BET
	var extras_phase = game.phase == "extras"
	var play_ok = not busy and base and not overlay.is_open() and (extras_phase or (game._can_configure() and game.credits >= game.stake()))
	controls.play.disabled = not play_ok
	controls.play.text = "ESCOLHA O NÚMERO" if game.phase == "joker" else ("SORTEANDO" if busy else "")
	style_art(controls.play, controls.play.text != "")
	controls.extra.visible = base and extras_phase and not busy
	if extras_phase and not busy:
		controls.play.text = "CANCELAR EXTRA"
		controls.extra.text = "BOLA EXTRA · " + money(game.extra_quote() * game.denomination)
		style_3d(controls.play, Color("a93923"), 20)
		style_3d(controls.extra, Color("16952d"), 20)
	controls.extra.disabled = busy or not base or overlay.is_open() or not extras_phase or game.credits < game.extra_quote() or game.extras_bought >= game.MAX_EXTRAS
	controls.sound.text = "SOM ON" if op.sound else "SOM OFF"
	joker_numbers.clear()
	if game.phase == "joker":
		for n in game.joker_options():
			joker_numbers[n] = true
	publish_state()
	update()

func save_op():
	op.capture(game)
	op.sound = op.sound
	op.save_settings()

# ---------------------------------------------------------------- fluxo do jogo
func _begin_reveal(from_index, rate, tail):
	reveal_start = from_index
	shown = from_index
	reveal_time = 0.0
	reveal_rate = rate
	reveal_tail = tail
	busy = true

func play():
	if busy or modal_kind != "" or overlay.is_open():
		return
	if game.phase == "extras":
		var remaining = game.MAX_EXTRAS - game.extras_bought
		game.finish_round()
		audio.play_cue("close")
		if game.missed_balls.size() > 0:
			status_message = "Extra cancelada. As %d bolas que viriam ficam apagadas até a próxima rodada." % game.missed_balls.size()
		else:
			status_message = "Rodada encerrada."
		if game.round_wins > 0:
			status_message += " Ganho: " + money(game.round_wins * game.denomination) + "."
		save_op()
	elif game.start_round():
		game.draw_initial()
		_reset_presentation()
		_begin_reveal(0, BALL_INTERVAL, 1.0)
		audio.play_cue("start")
		status_message = "Sorteando as 30 bolas…"
	refresh()

func _reset_presentation():
	coin_bursts.clear()
	shown = 0
	win_shown = 0
	vis_set.clear()
	ball_birth.clear()
	flashes.clear()
	pattern_flash.clear()
	floaters.clear()
	announced_win = 0
	announced_prizes.clear()
	bigwin_t = -1.0
	bigwin_done = false
	if audio != null:
		audio.stop_voice()
		audio.stop_prize()
	extra_slots.clear()
	pending_slot = -1

func _slot_position(n):
	return Vector2(738 + (n % 5) * 51, 1203 + int(n / 5) * 65)

func _free_slots():
	var free = []
	for n in range(10):
		if not n in extra_slots and n != pending_slot:
			free.append(n)
	return free

# Button purchases always use the first free socket; touch supplies an exact index.
func _pick_slot():
	var free = _free_slots()
	return free[0] if not free.empty() else -1

func _slot_at(point):
	for slot in _free_slots():
		if _slot_position(slot).distance_to(point) <= 25.0:
			return slot
	return -1

func buy_extra(requested_slot = -1):
	if busy or modal_kind != "" or overlay.is_open():
		return
	var cost_before = game.extra_quote()
	var slot = _pick_slot() if requested_slot == -1 else requested_slot
	if not slot in _free_slots() or game.phase != "extras":
		return
	var number = game.buy_extra()
	if number > 0:
		extra_slots.append(slot)
		audio.play_cue("extra")
		var prefix = "EXTRA GRÁTIS! " if game.last_extra_free else ("Extra %d: %s. " % [game.extras_bought, money(game.last_extra_cost * game.denomination)])
		status_message = prefix + "Bola %02d a caminho…" % number
		_begin_reveal(game.drawn.size() - 1, EXTRA_INTERVAL, 0.7)
	elif number == 0:
		audio.play_cue("extra")
		pending_slot = slot
		status_message = "BOLA ZAZ! Toque em um número do quadro para completar a premiação."
		refresh()
		return
	else:
		status_message = "Saldo insuficiente para a extra de " + money(cost_before * game.denomination) + "."
	save_op()
	refresh()

func _reveal_ball(index):
	var number = game.drawn[index]
	vis_set[number] = true
	ball_birth[index] = elapsed
	audio.play_cue("ball")
	if game.ball_events[index].collected:
		coin_bursts.append({"born": elapsed + 0.45, "color": game.ball_events[index].color, "sounded": false, "charge": game.ball_events[index].get("charge", 1), "target": game.ball_events[index].get("target", 50)})
	var best_prize = -1
	for entry in game.win_log:
		if entry.ball == index:
			var key = "%d:%d" % [entry.card, entry.pattern]
			if announced_prizes.has(key):
				continue
			announced_prizes[key] = true
			best_prize = entry.pattern if best_prize < 0 else min(best_prize, entry.pattern)
			flashes[key] = elapsed
			pattern_flash[entry.pattern] = elapsed
			win_shown += entry.amount
			var x0 = 40 if entry.card % 2 == 0 else 660
			var y0 = 614 if entry.card < 2 else 856
			floaters.append({"text": "+" + money(entry.amount * game.denomination), "pos": Vector2(x0 + 164, y0 + 120 + (floaters.size() % 3) * 22), "born": elapsed})
	if best_prize >= 0:
		audio.play_prize(best_prize)

func settle():
	busy = false
	if game.phase == "bonus":
		busy = true
		vault_transition = 0.0
		vault_burst_started = false
		status_message = "Bônus do cofre ativado!"
	elif game.phase == "joker":
		status_message = "BOLA ZAZ! Toque em um número do quadro para completar a premiação."
	else:
		var win_text = ""
		if game.round_wins > 0:
			win_text = " Ganho: " + money(game.round_wins * game.denomination) + "."
		if game.phase == "finished":
			status_message = "Rodada concluída." + win_text
		elif game.extras_bought > 0:
			status_message = "Próxima extra: " + money(game.extra_quote() * game.denomination) + "." + win_text
		elif game.jackpot_won:
			status_message = "BINGO! Acumulado de " + money(game.jackpot) + " creditado." + win_text
		else:
			status_message = "30 bolas sorteadas." + win_text + " Extra: " + money(game.extra_quote() * game.denomination) + " ou cancele."
	save_op()
	refresh()

func _process(delta):
	for key in ["play", "extra", "spin"]:
		if controls.has(key) and is_instance_valid(controls[key]) and controls[key].has_meta("surface"):
			var b = controls[key]
			var mat = b.get_meta("surface").material
			mat.set_shader_param("pressed", 1.0 if b.pressed else 0.0)
			mat.set_shader_param("disabled", 1.0 if b.disabled else 0.0)
			mat.set_shader_param("hover", 1.0 if b.get_global_rect().has_point(get_global_mouse_position()) else 0.0)
	elapsed += delta
	for burst in coin_bursts:
		if elapsed >= burst.born and not burst.sounded:
			burst.sounded = true
			if not burst.get("explosion", false):
				vault_charge[burst.color] = burst.get("charge", vault_charge[burst.color] + 1)
				vault_limits[burst.color] = burst.get("target", game.vault_targets[burst.color])
				vault_impact[burst.color] = elapsed
	while coin_bursts.size() > 0 and elapsed - coin_bursts[0].born > 1.7:
		coin_bursts.pop_front()
	bonus_intro = max(0.0, bonus_intro - delta)
	_animate_shaders()
	_animate_vaults(delta)
	_update_vault_particles(delta)
	if vault_transition >= 0.0:
		vault_transition += delta
		if vault_transition >= VAULT_BANG and not vault_burst_started:
			vault_burst_started = true
			# Final supplied frames show rupture and the open door.
		if vault_transition >= VAULT_END:
			for color in range(3):
				if game.bonus.flags[color]:
					vault_charge[color] = 0
					vault_fill[color] = 0.0
					vault_limits[color] = game.vault_targets[color]
			vault_transition = -1.0
			busy = false
			vault_particles.clear()
			if vault_preview:
				vault_preview = false
				game.bonus.flags = [false, false, false]
			else:
				open_modal("bonus")
	elif busy:
		reveal_time += delta
		var target = game.drawn.size()
		var want = min(target, reveal_start + int(reveal_time / reveal_rate))
		while shown < want:
			_reveal_ball(shown)
			shown += 1
		if shown >= target and reveal_time >= (target - reveal_start) * reveal_rate + reveal_tail:
			settle()
	if spin_time > 0:
		spin_time -= delta
		spin_elapsed = SPIN_TOTAL - max(0.0, spin_time)
		while reels_stopped < 5 and spin_elapsed >= REEL_STOPS[reels_stopped]:
			reels_stopped += 1
			audio.play_sfx("reel_stop%d" % reels_stopped)
			for position in game.bonus.new_cells:
				if position % 5 == reels_stopped - 1:
					audio.play_coin()
					break
			if reels_stopped == 5:
				audio.stop_sfx("reel_spin")
		if spin_time <= 0:
			open_modal("bonus")
	_update_bigwin(delta)
	for i in range(3):
		var target = float(game.bonus.levels.current[i])
		if abs(target - jp_shown[i]) < 1.0:
			jp_shown[i] = target
		else:
			jp_shown[i] += (target - jp_shown[i]) * min(1.0, delta * 3.0)
	var filling = false
	for burst in coin_bursts:
		if not burst.get("explosion", false) and elapsed >= burst.born and elapsed - burst.born < 1.15:
			filling = true
	audio.set_fill_loop(filling and modal_kind == "")
	if not busy and spin_time <= 0 and game.round_wins > announced_win and modal_kind == "bonus":
		announced_win = game.round_wins
		audio.play_cue("slot_win")
	update()

func _update_bigwin(delta):
	if bigwin_t >= 0.0:
		bigwin_t += delta
		bigwin_tick -= delta
		if bigwin_tick <= 0.0 and bigwin_t < BIGWIN_TIME - 1.5:
			bigwin_tick = 0.16
			audio.play_coin()
		if bigwin_t >= BIGWIN_TIME:
			bigwin_t = -1.0
			audio.stop_voice()
	elif not bigwin_done and game.phase == "finished" and not busy and modal_kind == "" and spin_time <= 0 and not overlay.is_open():
		bigwin_done = true
		var multiple = float(game.round_wins) / max(1.0, float(game.stake()))
		if multiple >= BIGWIN_MULTIPLES[0]:
			bigwin_tier = 0
			for i in range(BIGWIN_MULTIPLES.size()):
				if multiple >= BIGWIN_MULTIPLES[i]:
					bigwin_tier = i
			bigwin_amount = game.round_wins
			bigwin_t = 0.0
			bigwin_tick = 0.0
			audio.play_voice(bigwin_tier)

func _animate_shaders():
	if warp_left == null:
		return
	warp_left.material.set_shader_param("t", elapsed)
	warp_right.material.set_shader_param("t", elapsed)
	logo_sprite.material.set_shader_param("t", elapsed)

func card_rect(c):
	return Rect2(40 if c % 2 == 0 else 660, 614 if c < 2 else 856, 328, 224)

func _gui_input(event):
	var pointer_down = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT)
	if pointer_down and bigwin_t > 0.8 and bigwin_t < BIGWIN_TIME - 0.6:
		bigwin_t = BIGWIN_TIME - 0.6
		audio.stop_voice()
		accept_event()
		return
	if pointer_down and idle() and modal_kind == "":
		var point = event.position - Vector2(0, off_bottom())
		for c in range(4):
			if card_rect(c).has_point(point):
				toggle_card(c)
				accept_event()
				return
	if pointer_down and game.phase == "extras" and modal_kind == "" and not busy and not overlay.is_open():
		var slot = _slot_at(event.position - Vector2(0, off_bottom()))
		if slot >= 0:
			buy_extra(slot)
			accept_event()
			return
	if pointer_down:
		if game.phase == "joker" and modal_kind == "" and not busy and not overlay.is_open():
			var p = event.position - Vector2(0, off_bottom())
			var prizes = _top_extra_prizes()
			var prect = _prize_rect(prizes.size())
			for i in range(prizes.size()):
				if p.distance_to(_prize_center(prect, prizes.size(), i)) <= 42.0:
					choose_joker(prizes[i][1])
					accept_event()
					return
			for c in range(4):
				if not game.open_cards[c]:
					continue
				var x = 89 if c % 2 == 0 else 706
				var y = 667 if c < 2 else 908
				if Rect2(x, y, 231, 130.5).has_point(p):
					var index = int((p.x - x) / 46.2) + 5 * int((p.y - y) / 43.5)
					var number = game.cards[c][clamp(index, 0, 14)]
					if joker_numbers.has(number):
						choose_joker(number)
						accept_event()
					return

# ---------------------------------------------------------------- modais
func open_modal(kind):
	if kind == "bonus" and modal_kind != "bonus":
		announced_win = game.round_wins
		bonus_intro = 1.8
		audio.play_theme(true)
	modal_kind = kind
	for b in modal_buttons:
		b.queue_free()
	modal_buttons.clear()
	if kind == "joker":
		var options = game.joker_options()
		for i in range(options.size()):
			var b = _modal_button("%02d" % options[i], Rect2(105 + i % 10 * 81, STRIP + 400 + int(i / 10) * 77, 70, 62), "choose_joker", [options[i]], 23)
			modal_buttons.append(b)
	elif kind == "bonus":
		var label = "VOLTAR" if game.bonus.spins_left == 0 else ("GIRANDO" if spin_time > 0 else "GIRAR")
		var b = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = label
		b.connect("pressed", self, "spin_bonus")
		add_child(b)
		style_3d(b, Color("16952d"), 34)
		b.disabled = spin_time > 0
		controls["spin"] = b
		modal_buttons.append(b)
	else:
		var b = _modal_button("VOLTAR", Rect2(277, STRIP + 1260, 470, 72), "close_modal", [], 27)
		modal_buttons.append(b)
	refresh()
	if kind == "bonus":
		var spin = controls["spin"]
		spin.rect_position = Vector2(704, canvas_y(1355))
		spin.rect_size = Vector2(288, 124)

func _modal_button(caption, rect, method, args, size):
	var b = Button.new()
	b.text = caption
	b.rect_position = rect.position
	b.rect_size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	style(b, Color("214851"), gold, 12, size)
	b.connect("pressed", self, method, args)
	add_child(b)
	return b

func close_modal():
	for b in modal_buttons:
		b.queue_free()
	modal_buttons.clear()
	controls.erase("spin")
	if modal_kind == "bonus":
		audio.play_theme(false)
		audio.stop_sfx("reel_spin")
	modal_kind = ""
	refresh()

func choose_joker(number):
	if game.choose_joker(number):
		var free = _free_slots()
		extra_slots.append(pending_slot if pending_slot >= 0 else (free[0] if not free.empty() else 0))
		pending_slot = -1
		if modal_kind != "":
			close_modal()
		audio.play_cue("extra")
		status_message = "Joker: bola %02d marcada em todas as cartelas." % number
		_begin_reveal(game.drawn.size() - 1, EXTRA_INTERVAL, 0.7)
		save_op()
		refresh()

func spin_bonus():
	if spin_time > 0:
		return
	if game.bonus.spins_left == 0:
		if preview_bonus:
			preview_bonus = false
		else:
			game.close_bonus()
		close_modal()
		settle_after_bonus()
		return
	if preview_bonus:
		game.bonus.spin()
	else:
		game.spin_bonus()
	spin_time = SPIN_TOTAL
	spin_elapsed = 0.0
	reels_stopped = 0
	controls["spin"].disabled = true
	audio.play_sfx("reel_start")
	audio.play_sfx("reel_spin", -7.0)
	refresh()

func settle_after_bonus():
	if game.phase in ["bonus", "joker"]:
		return
	if not preview_bonus:
		status_message = "Bônus concluído. Ganho da rodada: " + money(game.round_wins * game.denomination) + "."
	save_op()
	refresh()

# ---------------------------------------------------------------- ações dos botões
func change_cards():
	if idle() and game.change_cards():
		audio.play_cue("cards")
		_reset_presentation()
		status_message = "Números novos nas quatro cartelas."
		refresh()

func swap_card(index):
	if idle() and game.swap_card(index):
		audio.play_cue("cards")
		_reset_presentation()
		status_message = "Números novos na cartela %d." % (index + 1)
		refresh()

func toggle_card(index):
	if idle() and game.toggle_card(index):
		audio.play_cue("open" if game.open_cards[index] else "close")
		_reset_presentation()
		status_message = "Cartela %d %s · aposta total %s." % [index + 1, "aberta" if game.open_cards[index] else "fechada", money(game.stake() * game.denomination)]
		save_op()
		refresh()

func set_bet(delta):
	if not idle():
		return
	var previous = game.bet
	game.set_bet(game.bet + delta)
	if game.bet != previous:
		audio.play_cue("bet")
		status_message = "Aposta: %d crédito(s) por cartela · total %s." % [game.bet, money(game.stake() * game.denomination)]
	refresh()

func toggle_sound():
	op.sound = not op.sound
	audio.set_enabled(op.sound)
	op.save_settings()
	refresh()

func show_rules():
	if idle():
		open_modal("rules")

func open_menu():
	if idle():
		audio.play_cue("open")
		overlay.open_calculator()
		refresh()

func menu_closed():
	refresh()

func op_set_hold(value):
	if game.set_hold(int(value)):
		save_op()
		status_message = "Retenção %d%% (RTP-alvo %d%%) a partir da próxima rodada." % [game.hold_percent, 100 - game.hold_percent]
		refresh()

func op_set_denomination(value):
	if game.set_denomination(int(value)):
		save_op()
		status_message = "Crédito: " + money(game.denomination) + "."
		refresh()

func op_set_jackpot(tier, field, cents):
	game.bonus.set_level(tier, field, cents)
	save_op()
	status_message = "Acumulado %s ajustado." % ["MINI", "MINOR", "MAJOR"][tier]
	refresh()

func op_reset_jackpot(tier):
	game.bonus.reset_level(tier)
	save_op()
	refresh()

func op_set_monitor(mode):
	op.monitor = mode
	dual = mode == "dual"
	op.save_settings()
	refresh()

func op_preview():
	if not game._can_configure() or busy:
		return
	preview_bonus = true
	game.bonus.begin([true, true, true], game.slot_unit(), game.denomination, true)
	open_modal("bonus")

func op_reload_credits():
	if game.reset_demo():
		_reset_presentation()
		status_message = "Créditos recarregados."
		save_op()
		refresh()

func op_reset_stats():
	game.reset_stats()
	save_op()

# ---------------------------------------------------------------- desenho
func _draw():
	for amount in gold_amounts.values():
		amount.visible = false
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_draw_strip()
	if modal_kind == "bonus":
		_draw_bonus_view()
	else:
		_draw_base_view()
	if dual:
		_draw_bezel()
	if modal_kind in ["rules", "joker"]:
		draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
		_draw_modal()
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bigwin_t >= 0.0:
		_draw_bigwin()
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _rnd(i, salt):
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

# Moeda "M" em pseudo-3D: gira em torno do eixo vertical, mostra a borda com espessura, escurece de lado,
# tem sombra e brilho especular.
func _draw_coin(pos, r, spin, alpha, tilt = 0.0):
	var c = cos(spin)
	var sx = max(0.07, abs(c))
	var side = 1.0 if c >= 0.0 else -1.0
	var thick = r * 0.34 * abs(sin(spin))
	draw_set_transform(pos + Vector2(r * 0.16, r * 0.24), tilt, Vector2(sx, 1.0))
	draw_circle(Vector2.ZERO, r * 0.95, Color(0, 0, 0, 0.22 * alpha))
	for k in range(4, 0, -1):
		draw_set_transform(pos + Vector2(-side * thick * k / 4.0, 0).rotated(tilt), tilt, Vector2(sx, 1.0))
		var edge = 0.34 + 0.07 * k
		draw_texture_rect(COIN_ART, Rect2(-r, -r, r * 2.0, r * 2.0), false, Color(edge * 1.5, edge * 1.05, edge * 0.25, alpha))
	draw_set_transform(pos, tilt, Vector2(sx, 1.0))
	var shade = 0.62 + 0.38 * abs(c)
	draw_texture_rect(COIN_ART, Rect2(-r, -r, r * 2.0, r * 2.0), false, Color(shade, shade, shade, alpha))
	draw_circle(Vector2(-r * 0.38, -r * 0.42), r * 0.13, Color(1, 1, 0.9, 0.55 * abs(c) * alpha))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_bigwin():
	var t = bigwin_t
	var H = total_height()
	var fade_in = clamp(t / 0.4, 0.0, 1.0)
	var fade_out = clamp((BIGWIN_TIME - t) / 0.6, 0.0, 1.0)
	var fade = min(fade_in, fade_out)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(0, 0, 1024, H), Color(0, 0, 0, 0.76 * fade))
	var cx = 512.0
	var cy = STRIP + 470.0
	# raios de luz girando atrás do placar
	var tier_color = [Color(1.0, 0.82, 0.25), Color(1.0, 0.55, 0.15), Color(1.0, 0.35, 0.6)][bigwin_tier]
	for k in range(12):
		var a0 = t * 0.35 + k * TAU / 12.0
		var pts = PoolVector2Array([Vector2(cx, cy), Vector2(cx, cy) + Vector2(cos(a0), sin(a0)) * 900.0, Vector2(cx, cy) + Vector2(cos(a0 + 0.11), sin(a0 + 0.11)) * 900.0])
		draw_colored_polygon(pts, Color(tier_color.r, tier_color.g, tier_color.b, 0.13 * fade))
	draw_circle(Vector2(cx, cy), 250.0 + 14.0 * sin(t * 4.0), Color(tier_color.r, tier_color.g, tier_color.b, 0.12 * fade))
	# moedas caindo
	for i in range(46):
		var delay = _rnd(i, 1) * 2.4
		if t < delay:
			continue
		var speed = 520.0 + _rnd(i, 2) * 480.0
		var cycle = (H + 120.0) / speed
		var local = fposmod(t - delay, cycle)
		var x = 30.0 + _rnd(i, 3) * 964.0 + sin(t * 2.0 + i) * 18.0
		var y = -60.0 + local * speed
		var r = 18.0 + _rnd(i, 4) * 16.0
		_draw_coin(Vector2(x, y), r, t * (4.0 + _rnd(i, 5) * 6.0) + i, fade, sin(t * 1.5 + i) * 0.5)
	# faixa com o título (pulsa)
	var pulse = 1.0 + 0.045 * sin(t * 6.0) + 0.12 * max(0.0, 1.0 - t * 3.0)
	var title = BIGWIN_TITLES[bigwin_tier]
	var size = 100
	# selo do prêmio (SUPER / MEGA / ULTRA BIG WIN): nasce pequeno e cresce com leve ricochete, depois pulsa
	var art = BIGWIN_ART[bigwin_tier]
	var gk = clamp(t / 0.9, 0.0, 1.0)
	var grow = 1.0 - pow(1.0 - gk, 3.0) + 0.14 * sin(gk * PI) * (1.0 - gk) * 2.0
	var sc = (0.12 + 0.88 * grow) * (1.0 + 0.03 * sin(t * 5.0) * gk)
	var fit = min(500.0 / art.get_width(), 345.0 / art.get_height())
	var w = art.get_width() * fit * sc
	var h = art.get_height() * fit * sc
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_texture_rect(art, Rect2(cx - w / 2.0, cy - 96.0 - h, w, h), false, Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# placar com contagem
	var p = clamp((t - 0.3) / 3.2, 0.0, 1.0)
	var eased = 1.0 - pow(1.0 - p, 3.0)
	var shown_value = int(round(bigwin_amount * game.denomination * eased))
	box(Rect2(cx - 380, cy - 90, 760, 190), Color(0.17, 0.07, 0.02, 0.95 * fade), Color(tier_color.r, tier_color.g, tier_color.b, fade), 26, 6)
	box(Rect2(cx - 366, cy - 76, 732, 162), Color(0.1, 0.04, 0.01, 0.9 * fade), Color(0.8, 0.5, 0.15, 0.7 * fade), 20, 2)
	var digits = money(shown_value)
	text(digits, Rect2(cx - 360, cy - 78, 720, 120), 96, Color(0, 0, 0, 0.55 * fade))
	text(digits, Rect2(cx - 360, cy - 84, 720, 120), 96, Color(1.0, 0.94, 0.55, fade), true)
	text("×%d da aposta" % int(float(bigwin_amount) / max(1.0, float(game.stake()))), Rect2(cx - 360, cy + 52, 720, 34), 26, Color(1.0, 0.85, 0.5, fade * clamp(p * 3.0, 0.0, 1.0)))
	# brilhos
	for k in range(14):
		var sa = t * 1.5 + k * 1.7
		var sp = Vector2(cx + cos(sa * 0.9 + k) * (260 + 120 * _rnd(k, 7)), cy - 40 + sin(sa * 1.3 + k) * (130 + 70 * _rnd(k, 8)))
		var tw = 0.5 + 0.5 * sin(t * 7.0 + k * 2.3)
		var arm = 6.0 + 12.0 * tw
		draw_line(sp - Vector2(arm, 0), sp + Vector2(arm, 0), Color(1, 1, 0.8, fade * tw), 2.0)
		draw_line(sp - Vector2(0, arm), sp + Vector2(0, arm), Color(1, 1, 0.8, fade * tw), 2.0)

func _draw_bezel():
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var y = STRIP + split_y()
	draw_rect(Rect2(0, y, 1024, GAP), Color("07090d"))
	draw_rect(Rect2(0, y, 1024, 3), Color("3a4250"))
	draw_rect(Rect2(0, y + GAP - 3, 1024, 3), Color("3a4250"))
	text("▲ TELA SUPERIOR  ·  TELA INFERIOR ▼", Rect2(0, y + 10, 1024, 24), 17, Color("68768a"))

func _draw_strip():
	draw_rect(Rect2(0, 0, 1024, STRIP), Color("1a2445"))
	for i in range(game.patterns.size()):
		var tile_w = 1008.0 / game.patterns.size()
		var x = 8 + i * tile_w
		var age = elapsed - pattern_flash.get(i, -10.0)
		var glow = max(0.65 if pattern_flash.has(i) else 0.0, clamp(1.0 - age / 2.6, 0.0, 1.0))
		var won = pattern_flash.has(i)
		var border = Color("ffe98b") if won else Color("647d9f")
		border = border.linear_interpolate(Color.white, glow * (0.5 + 0.5 * sin(elapsed * 14.0)))
		box(Rect2(x, 4, 81, 91), Color("b08619") if won else Color("293e64"), border, 3, 3)
		if i < 2:
			text("BÔNUS", Rect2(x, 2, 81, 17), 13, gold)
		for n in range(15):
			draw_rect(Rect2(x + 7 + (n % 5) * 13.5, 23 + int(n / 5) * 12, 11, 10), Color("e0262d") if n in game.patterns[i].cells else Color("151a20"))
		text("×" + str(game.patterns[i].pay), Rect2(x, 62, 81, 29), 21, Color.white)

func _jackpot_values():
	for i in range(3):
		text(money(int(jp_shown[i])), Rect2(205 + i * 213, 254, 194, 44), 29, gold, true)

func _sparkle(center, size, phase):
	var k = 0.5 + 0.5 * sin(elapsed * 3.2 + phase)
	k = k * k * k
	if k < 0.05:
		return
	var s = size * k
	var c = Color(1, 0.96, 0.78, 0.95 * k)
	draw_line(center - Vector2(s, 0), center + Vector2(s, 0), c, 2.0)
	draw_line(center - Vector2(0, s), center + Vector2(0, s), c, 2.0)
	draw_line(center - Vector2(s, s) * 0.45, center + Vector2(s, s) * 0.45, Color(c.r, c.g, c.b, c.a * 0.6), 1.5)
	draw_line(center - Vector2(s, -s) * 0.45, center + Vector2(s, -s) * 0.45, Color(c.r, c.g, c.b, c.a * 0.6), 1.5)
	draw_circle(center, 2.0 + 2.0 * k, Color(1, 1, 1, 0.9 * k))

func _draw_logo_sparkles():
	var spots = [Vector2(262, 100), Vector2(344, 78), Vector2(430, 122), Vector2(522, 80), Vector2(618, 124), Vector2(716, 82), Vector2(776, 112)]
	for i in range(spots.size()):
		_sparkle(spots[i], 11 + (i % 3) * 3, i * 1.7)

func _draw_base_view():
	draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
	_jackpot_values()
	_draw_logo_sparkles()
	draw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
	for c in range(4):
		_draw_card(c)
	_draw_globe()
	_draw_floaters()
	draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
	_draw_vault_fx()
	draw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
	_draw_ball_panels()
	_draw_counters()
	_draw_extra_prizes()

# Painel "ESCOLHA UM NÚMERO": as maiores premiações que a bola extra pode pagar agora.
var prize_cache_key = ""
var prize_cache = []
const PRIZE_RINGS = [Color("f2b020"), Color("b45be0"), Color("e8452c"), Color("38a8e8")]

func _top_extra_prizes():
	var key = "%d:%d:%d" % [game.drawn.size(), game.extras_bought, int(game.phase == "joker")]
	if key != prize_cache_key:
		prize_cache_key = key
		var payouts = game._single_payouts()
		var list = []
		var allowed = game.joker_options()
		for number in payouts.keys():
			if number in allowed:
				list.append([payouts[number], number])
		list.sort_custom(self, "_prize_order")
		prize_cache = []
		for i in range(min(5, list.size())):
			prize_cache.append(list[i])
	return prize_cache

func _prize_order(a, b):
	if a[0] != b[0]:
		return a[0] > b[0]
	return a[1] < b[1]

func _prize_rect(count):
	var w = 130.0 * count + 120.0
	return Rect2(512 - w / 2, 1016, w, 156)

func _prize_center(rect, count, i):
	return Vector2(rect.position.x + rect.size.x / (count * 2.0) * (2 * i + 1), rect.position.y + 78)

func _draw_extra_prizes():
	if game.phase != "joker" or busy or modal_kind != "" or overlay.is_open():
		return
	var list = _top_extra_prizes()
	if list.empty():
		return
	var count = list.size()
	var rect = _prize_rect(count)
	box(Rect2(rect.position + Vector2(0, 5), rect.size), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 20, 0)
	box(rect, Color(0.17, 0.07, 0.36, 0.95), Color("8f5be0"), 20, 3)
	draw_rect(Rect2(rect.position.x + 24, rect.position.y + 40, rect.size.x - 48, 2), Color(1.0, 0.85, 0.5, 0.45))
	text("ESCOLHA UM NÚMERO", Rect2(rect.position.x, rect.position.y + 4, rect.size.x, 34), 27, Color("ffc933"), true)
	for i in range(count):
		var center = _prize_center(rect, count, i)
		var ring = PRIZE_RINGS[i % PRIZE_RINGS.size()]
		var pulse = 0.5 + 0.5 * sin(elapsed * 4.0 + i)
		draw_circle(center, 33.0 + 3.0 * pulse, Color(ring.r, ring.g, ring.b, 0.35 + 0.25 * pulse))
		draw_circle(center, 31.0, ring)
		draw_ball(center, 27.0, list[i][1], -1, 1.0, 1.0, false)
		text("%02d" % list[i][1], Rect2(center.x - 27, center.y - 17, 54, 26), 25, Color(0.08, 0.08, 0.1))
		if i == 0:
			box(Rect2(center.x - 34, rect.position.y + 36, 68, 18), Color("b01818"), Color.white, 4, 1)
			text("MAIOR", Rect2(center.x - 34, rect.position.y + 36, 68, 18), 12, Color.white)
		text("GANHE", Rect2(center.x - 40, center.y + 20, 80, 14), 12, Color.white)
		box(Rect2(center.x - 56, rect.position.y + 122, 112, 26), Color(0.1, 0.04, 0.24, 0.95), Color(ring.r, ring.g, ring.b, 0.6), 6, 1)
		text(money(list[i][0] * game.denomination), Rect2(center.x - 56, rect.position.y + 122, 112, 26), 19, Color("ffd24a"))

func near_cells(c):
	var visible_mask = 0
	for n in range(15):
		if vis_set.has(game.cards[c][n]):
			visible_mask |= 1 << n
	var result = {}
	for p in range(game.patterns.size()):
		if game.pattern_complete(p, visible_mask):
			continue
		for mask in game.masks_for_pattern(p):
			var missing = mask & ~visible_mask
			if missing == 0 or (missing & (missing - 1)) != 0:
				continue
			for n in range(15):
				if missing == (1 << n):
					result[n] = max(result.get(n, 0), game.patterns[p].pay)
	return result

func _draw_card(c):
	var x = 89 if c % 2 == 0 else 706
	var y = 667 if c < 2 else 908
	var open = game.open_cards[c]
	var near = near_cells(c) if open and game.phase != "ready" else {}
	for n in range(15):
		var r = Rect2(x + (n % 5) * 46.2, y + int(n / 5) * 43.5, 46.2, 43.5)
		var number = game.cards[c][n]
		var hit = open and vis_set.has(number)
		draw_rect(r, Color("f8e6c3") if open else Color("cdbd9d"))
		if hit:
			draw_rect(r, colors[c].lightened(0.35))
			draw_texture_rect(balls["c%d" % c], Rect2(r.position.x + 5.5, r.position.y + 3.5, 35, 36), false, Color(1, 1, 1, 0.96))
		if open and joker_numbers.has(number):
			var pulse = 0.5 + 0.5 * sin(elapsed * 7.0 + n)
			draw_rect(r, Color(1.0, 0.82, 0.25, 0.35 + 0.35 * pulse))
		if open and not near.has(n):
			text("%02d" % number, Rect2(r.position.x, r.position.y + 3, r.size.x, 35), 27, Color.white if hit else Color("261a0e"), hit)
		draw_rect(r, Color("6e4d29") if not joker_numbers.has(number) else Color("ffd34d"), false, 1.2 if not joker_numbers.has(number) else 2.5)
		if near.has(n) and not hit:
			var pulse = 0.5 + 0.5 * sin(elapsed * 8.0)
			draw_rect(r.grow(-1), Color(1.0, 0.79, 0.15, 0.20 + pulse * 0.55))
			draw_rect(r.grow(-1), Color(1.0, 0.9, 0.45, 0.5 + pulse * 0.5), false, 2.5)
			text("%02d" % number, Rect2(r.position.x, r.position.y - 2, r.size.x, 25), 22, Color("32200a"))
			text("×" + str(near[n]), Rect2(r.position.x, r.position.y + 24, r.size.x, 18), 12, Color("563300"))
	if not open:
		draw_rect(Rect2(x - 1, y - 1, 234, 133), Color(0.03, 0.05, 0.04, 0.82))
		text("CARTELA\nFECHADA", Rect2(x, y + 24, 232, 90), 30, Color("c9bd9a"))

func _draw_globe():
	var center = Vector2(512, 726)
	for i in range(16):
		var angle = i * 2.4 + elapsed * (11.0 if busy else 3.0)
		var pos = center + Vector2(cos(angle) * 92, sin(angle * 1.13) * 84) * (0.42 + 0.035 * i)
		var number = (i * 7) % 90 + 1
		draw_circle(pos + Vector2(2, 3), 17, Color(0, 0, 0, 0.25))
		draw_ball(pos, 19, number, -1, 1.0, 1.0)
	draw_texture_rect_region(BASE_ART, Rect2(374, 710, 282, 61), Rect2(374, 710, 282, 61))
	draw_texture_rect_region(BASE_ART, Rect2(473, 710, 84, 89), Rect2(473, 710, 84, 89))

func _draw_vault_fx():
	var center = Vector2(512, 726 + (GAP if dual else 0))
	for index in range(min(shown, game.ball_events.size())):
		var event = game.ball_events[index]
		if event.collected:
			var age = elapsed - ball_birth.get(index, elapsed)
			var t = clamp(age / 0.45, 0.0, 1.0)
			if t < 1.0:
				var eased = 1.0 - pow(1.0 - t, 3.0)
				var pos = center.linear_interpolate(Vector2(212 + event.color * 322, 343), eased)
				pos.y -= sin(t * PI) * 70.0
				draw_ball(pos, 22, event.number, event.color, 1.0, 1.0)
	for burst in coin_bursts:
		var age = elapsed - burst.born
		if age < 0.0:
			continue
		var origin = Vector2(212 + burst.color * 322, 337)
		for i in range(11):
			var t = age - (i % 3) * 0.035
			if t < 0.0 or t > 1.4:
				continue
			var vx = (i - 5) * 31.0
			var vy = -210.0 - (i * 37 % 100)
			var pos = origin + Vector2(vx * t, vy * t + 380.0 * t * t)
			var alpha = 1.0 - smoothstep(0.85, 1.4, t)
			var radius = 11.0 + (i % 3) * 2.5
			_draw_coin(pos, radius, t * 11.0 + i * 1.7, alpha, t * 2.5 + i)
			if t < 0.4:
				draw_line(pos - Vector2(vx, vy) * 0.045, pos - Vector2(vx, vy) * 0.015, Color(1.0, 0.87, 0.45, alpha * 0.4), 2.0)

	# Explosion animation is supplied separately by the user.

func _vault_point(color, lx, ly):
	var sprite = vault_sprites[color]
	return Vector2(sprite.position.x + (lx - 0.5) * 306.0 * sprite.scale.x, sprite.position.y - STRIP + (ly - 0.5) * 270.0 * sprite.scale.y)

func _draw_bill(pos, rot, w, h, alpha, squash = 1.0):
	var pts = PoolVector2Array()
	for corner in [Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]:
		pts.append(pos + Vector2(corner.x, corner.y * squash).rotated(rot))
	draw_colored_polygon(pts, Color(0.46, 0.74, 0.43, alpha))
	var band = PoolVector2Array()
	for corner in [Vector2(-w * 0.55, -h * 0.7), Vector2(w * 0.55, -h * 0.7), Vector2(w * 0.55, h * 0.7), Vector2(-w * 0.55, h * 0.7)]:
		band.append(pos + Vector2(corner.x, corner.y * squash).rotated(rot))
	draw_colored_polygon(band, Color(0.76, 0.9, 0.66, alpha))
	draw_circle(pos, h * 0.42, Color(0.3, 0.55, 0.3, alpha))
	pts.append(pts[0])
	draw_polyline(pts, Color(0.16, 0.34, 0.16, alpha), 1.6)

func _draw_money_coin(pos, r, spin, alpha):
	_draw_coin(pos, r * 1.15, spin, alpha, sin(spin * 0.7) * 0.4)

# Dinheiro tentando sair pelas frestas quando o cofre está quase estourando.
func _draw_vault_pressure():
	for color in range(3):
		if vault_transition >= VAULT_BANG and game.bonus.flags[color]:
			continue
		var fill = vault_fill[color]
		if fill < 0.38:
			continue
		var level = (fill - 0.38) / 0.62
		var count = 2 + int(level * 9.0)
		for i in range(count):
			var side = i % 3
			var t = 0.12 + _rnd(i, 20 + color) * 0.76
			var anchor
			var normal
			if side == 0:
				anchor = _vault_point(color, 0.23 + t * 0.58, 0.23)
				normal = Vector2(0, -1)
			elif side == 1:
				anchor = _vault_point(color, 0.81, 0.28 + t * 0.5)
				normal = Vector2(1, 0)
			else:
				anchor = _vault_point(color, 0.23, 0.28 + t * 0.5)
				normal = Vector2(-1, 0)
			var push = (6.0 + 22.0 * level) * (0.7 + 0.3 * sin(elapsed * 6.0 + i * 1.9 + color))
			var base = anchor + normal * push * 0.55
			var rot = normal.angle() + (_rnd(i, 21) - 0.5) * 1.1 + sin(elapsed * 9.0 + i) * 0.05
			if i % 4 == 3:
				_draw_money_coin(base, 10.0, elapsed * 3.0 + i, 1.0)
			else:
				_draw_bill(base, rot, 20.0, 10.5, 1.0)
		if level > 0.35:
			for k in range(int(3 + level * 6.0)):
				var phase = fposmod(elapsed * 1.7 + _rnd(k, 30 + color), 1.0)
				var sp = _vault_point(color, 0.23 + _rnd(k, 31) * 0.58, 0.23) + Vector2((_rnd(k, 32) - 0.5) * 18.0, -phase * 34.0)
				draw_circle(sp, 2.2 * (1.0 - phase), Color(1.0, 0.9, 0.45, (1.0 - phase) * min(1.0, level * 1.5)))

func _draw_vault_burst():
	if vault_transition >= VAULT_BANG:
		var t = vault_transition - VAULT_BANG
		for color in range(3):
			if not game.bonus.flags[color]:
				continue
			var door = Vector2(235 + color * 322, 462)
			if t < 0.6:
				var k = t / 0.6
				draw_arc(door, 30.0 + k * 360.0, 0, TAU, 48, Color(1.0, 0.92, 0.6, (1.0 - k) * 0.85), 14.0 * (1.0 - k) + 2.0)
				draw_arc(door, 20.0 + k * 230.0, 0, TAU, 40, Color(1.0, 0.7, 0.2, (1.0 - k) * 0.7), 8.0 * (1.0 - k) + 1.0)
				draw_circle(door, 150.0 * (1.0 - k * 0.7), Color(1.0, 0.95, 0.75, (1.0 - k) * 0.55))
			if t < 1.4:
				var glow = (1.0 - t / 1.4)
				for i in range(16):
					var a = -PI / 2.0 + (i - 7.5) * 0.19 + sin(elapsed * 2.0 + i) * 0.03
					var near = door + Vector2(cos(a), sin(a)) * 40.0
					var far = door + Vector2(cos(a), sin(a)) * (140.0 + 260.0 * glow)
					draw_line(near, far, Color(1.0, 0.88, 0.4, 0.35 * glow), 5.0 + (i % 3) * 3.0)
	for q in vault_particles:
		if elapsed < q.born:
			continue
		var life = elapsed - q.born
		var alpha = 1.0 - smoothstep(2.4, 3.3, life)
		if q.kind == 0:
			_draw_bill(q.pos, q.rot, 17.0, 9.0, alpha, 0.35 + 0.65 * abs(cos(q.rot * 0.7 + life * 3.0)))
		else:
			_draw_money_coin(q.pos, 10.0, q.rot * 1.3, alpha)

func _has_collected(color):
	for index in range(min(shown, game.ball_events.size())):
		var event = game.ball_events[index]
		if event.color == color and event.collected:
			return true
	return false

func _draw_floaters():
	var keep = []
	for item in floaters:
		var age = elapsed - item.born
		if age < 2.0:
			keep.append(item)
			var a = clamp(1.8 - age, 0.0, 1.0)
			var pos = item.pos + Vector2(0, -age * 26.0)
			box(Rect2(pos.x - 88, pos.y - 6, 176, 38), Color(0.05, 0.12, 0.02, 0.85 * a), Color(gold.r, gold.g, gold.b, a), 12, 2)
			text(item.text, Rect2(pos.x - 88, pos.y - 2, 176, 30), 22, Color(1, 0.93, 0.55, a))
	floaters = keep

func ball_texture(number, color):
	if color >= 0:
		return balls["v%d" % color]
	return balls["n%d" % BallArt.number_group(number)]

func draw_ball(center, radius, number, color = -1, factor = 1.0, alpha = 1.0, label = true):
	var r = radius * factor
	if color >= 0:
		_bonus_glow(center, r, color, alpha)
	draw_circle(center + Vector2(2, 4) * (radius / 23.0), r * 0.92, Color(0, 0, 0, 0.30 * alpha))
	draw_texture_rect(ball_texture(number, color), Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, alpha))
	if color >= 0:
		draw_arc(center, r + 1.5, 0, TAU, 28, Color(1.0, 0.86, 0.35, alpha), 2.5)
	if label and r > 8.0:
		var size = int(r * 0.78)
		text("%02d" % number, Rect2(center.x - r, center.y - 0.66 * size, r * 2.0, size), size, Color(0.1, 0.12, 0.16, alpha))

# Destaque das bolas dos cofres: halo pulsante, raios girando, brilhos em órbita e reflexo branco.
func _bonus_glow(center, r, color, alpha):
	var base = vault_colors[color].lightened(0.35)
	var pulse = 0.5 + 0.5 * sin(elapsed * 6.0 + color)
	for i in range(5):
		var k = float(i) / 5.0
		draw_circle(center, r * (2.1 - k * 0.9) + pulse * 4.0, Color(base.r, base.g, base.b, (0.05 + 0.05 * k) * alpha))
	for i in range(8):
		var a = elapsed * 1.6 + i * TAU / 8.0
		var len_outer = r * (2.2 + 0.5 * sin(elapsed * 5.0 + i * 1.3))
		draw_line(center + Vector2(cos(a), sin(a)) * r * 1.05, center + Vector2(cos(a), sin(a)) * len_outer, Color(1.0, 0.95, 0.7, 0.55 * alpha), 2.5)
	for i in range(4):
		var o = -elapsed * 2.4 + i * TAU / 4.0
		var q = center + Vector2(cos(o), sin(o)) * r * 1.55
		var tw = 0.5 + 0.5 * sin(elapsed * 9.0 + i * 2.0)
		draw_line(q - Vector2(5, 0) * (0.6 + tw), q + Vector2(5, 0) * (0.6 + tw), Color(1, 1, 1, 0.9 * alpha), 2.0)
		draw_line(q - Vector2(0, 5) * (0.6 + tw), q + Vector2(0, 5) * (0.6 + tw), Color(1, 1, 1, 0.9 * alpha), 2.0)
	draw_arc(center, r + 2.0, 0, TAU, 32, Color(1.0, 0.9, 0.45, (0.65 + 0.35 * pulse) * alpha), 3.0)

func draw_ghost(center, radius, number):
	draw_circle(center + Vector2(2, 4), radius * 0.92, Color(0, 0, 0, 0.30))
	draw_texture_rect(ball_texture(number, -1), Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(0.82, 0.82, 0.86, 0.78))
	var size = int(radius * 0.78)
	text("%02d" % number, Rect2(center.x - radius, center.y - 0.66 * size, radius * 2.0, size), size, Color(0.08, 0.1, 0.14, 0.95))
	draw_arc(center, radius, 0, TAU, 28, Color(0.88, 0.2, 0.2, 0.85), 2.0)

func _socket(pos, radius):
	draw_circle(pos, radius + 1.5, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(pos, radius, Color(0.05, 0.16, 0.1, 0.9))
	draw_arc(pos, radius, 0, TAU, 28, Color(0.55, 0.45, 0.2, 0.55), 2.0)

func _draw_ball_panels():
	for n in range(40):
		var pos = Vector2(86 + (n % 10) * 59, 1171 + int(n / 10) * 57) if n < 30 else Vector2(738 + ((n - 30) % 5) * 51, 1203 + int((n - 30) / 5) * 65)
		var radius = 23.0 if n < 30 else 21.0
		if n < 30:
			if n < shown and n < game.drawn.size():
				_draw_drawn(n, pos, radius)
			else:
				_socket(pos, radius)
		else:
			var slot = n - 30
			var k = extra_slots.find(slot)
			var free_rank = _free_slots().find(slot)
			if k >= 0 and 30 + k < game.drawn.size() and 30 + k < shown:
				_draw_drawn(30 + k, pos, radius)
			elif slot == pending_slot and game.phase == "joker":
				_socket(pos, radius)
				text("?", Rect2(pos.x - radius, pos.y - 16, radius * 2, 30), 26, Color(1, 0.85, 0.3, 0.5 + 0.5 * sin(elapsed * 6.0)))
			elif k < 0 and game.phase == "finished" and free_rank >= 0 and free_rank < game.missed_balls.size():
				draw_ghost(pos, radius, game.missed_balls[free_rank])
			else:
				_socket(pos, radius)
				if game.phase == "extras" and k < 0 and not busy:
					draw_arc(pos, radius - 3, 0, TAU, 24, Color(1, 0.85, 0.35, 0.25 + 0.25 * sin(elapsed * 4.0 + n)), 2.0)

func _draw_drawn(index, pos, radius):
	var event = game.ball_events[index]
	var age = elapsed - ball_birth.get(index, -10.0)
	var factor = 1.0
	if age < 0.3:
		var k = age / 0.3
		factor = 1.0 + 0.45 * sin(k * PI) * (1.0 - k) + (k - 1.0) * 0.6 * (1.0 - k)
		factor = clamp(factor, 0.2, 1.4)
	draw_ball(pos, radius, game.drawn[index], event.color if event.collected else -1, factor)

func _draw_counters():
	if game.phase == "extras" and not busy:
		box(Rect2(698, 1350, 300, 143), Color("073520"), gold, 25, 3)
	text(money(game.credits * game.denomination), Rect2(76, 1410, 238, 54), 31, gold, true)
	text(str(game.bet), Rect2(427, 1394, 171, 53), 40, gold, true)
	text("×%d = %s" % [game.open_count(), money(game.stake() * game.denomination)], Rect2(427, 1442, 171, 22), 17, Color("fff1b0"))
	var meter = win_shown if busy else game.round_wins
	if meter > 0:
		box(Rect2(357, 1309, 338, 65), Color("082f22"), gold, 12, 3)
		text("GANHOS NA RODADA", Rect2(367, 1313, 318, 23), 17, cream)
		text(money(meter * game.denomination), Rect2(367, 1334, 318, 34), 27, Color("ffe07a"), true)
	box(Rect2(70, 1494, 900, 25), Color(0, 0.1, 0.02, 0.95), Color(0, 0, 0, 0), 3)
	text(status_message, Rect2(75, 1494, 890, 25), 15, cream)

# ---------------------------------------------------------------- bônus
func _draw_bonus_view():
	draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
	_jackpot_values()
	_draw_logo_sparkles()
	if not game.bonus.flags[1]:
		_draw_vault_fx()
	draw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
	var b = game.bonus
	var double_grid = b.flags[1]
	var start = 320 if double_grid else 607
	if double_grid:
		draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
		box(Rect2(42, 320, 940, 495), Color("230a0b"), gold, 20, 6)
		draw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
		box(Rect2(42, 815, 940, 502), Color("230a0b"), gold, 20, 6)
		draw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
	else:
		box(Rect2(42, 607, 940, 710), Color("230a0b"), gold, 20, 6)
	box(Rect2(66, start + 7, 892, 65), Color("4b125b"), gold, 14, 3)
	text("SUPER BÔNUS!" if double_grid or b.flags.count(true) > 1 else "BÔNUS DOS COFRES", Rect2(80, start + 11, 864, 36), 32, gold, true)
	var features = []
	if b.flags[1]: features.append("TELA DUPLA")
	if b.flags[0]: features.append("MULTIPLIER ×2 · ×3 · ×5")
	if b.flags[2]: features.append("EXTRA SPINS")
	text(PoolStringArray(features).join(" + "), Rect2(80, start + 46, 864, 23), 18, cream)
	for panel in range(b.lives.size()):
		var offset = STRIP if double_grid and panel == 0 else off_bottom()
		draw_set_transform(Vector2(0, offset), 0, Vector2.ONE)
		var y = 430 + panel * 428 if double_grid else 728
		var rect = Rect2(70, y, 884, 360 if double_grid else 490)
		box(Rect2(70, y - 35, 182, 30), Color("9c2011"), gold, 8, 2)
		text("TELA " + str(panel + 1), Rect2(72, y - 34, 178, 28), 20, gold)
		box(Rect2(268, y - 35, 686, 30), Color("102a70"), gold, 8, 2)
		var life = b.before_lives[panel] if spin_time > 0 else b.lives[panel]
		text(str(life) + " GIROS RESTANTES" if life > 0 else "TELA CONCLUÍDA", Rect2(272, y - 34, 678, 28), 21, gold)
		box(rect.grow(4), Color("090f12"), gold, 9, 4)
		var cw = rect.size.x / 5.0
		var ch = rect.size.y / 3.0
		for row in range(3):
			for col in range(5):
				var r = panel * 3 + row
				var cell = Rect2(rect.position + Vector2(col * cw, row * ch), Vector2(cw, ch))
				draw_rect(cell, Color("987230"), false, 1.5)
				var coin = b.grid[r][col]
				var arriving = r * 5 + col in b.new_cells
				var rolling = spin_time > 0 and spin_elapsed < REEL_STOPS[col] and b.before_lives[panel] > 0 and (coin == null or arriving)
				if rolling:
					var descent = fmod(spin_elapsed * 2.6 + row * 0.31 + col * 0.17, 1.0)
					var is_landing = coin != null and spin_elapsed >= REEL_STOPS[col] - 0.42
					if is_landing:
						descent = clamp((spin_elapsed - REEL_STOPS[col] + 0.42) / 0.42, 0.0, 1.0)
					var flying_size = Vector2(min(cw - 8, ch * (1.55 if double_grid else 1.0)), ch - 3)
					var falling = Rect2(cell.position + (cell.size - flying_size) * 0.5 + Vector2(0, (descent - 1.0) * ch), flying_size)
					var art = HOLD_JACKPOTS[coin.jackpot] if is_landing and coin.jackpot >= 0 else HOLD_COIN
					_draw_falling_coin(art, falling, cell)
					continue
				if coin == null:
					var center = cell.position + cell.size * 0.5
					var ink = Color("343545") if rolling else Color("191f2a")
					var bob = sin(elapsed * 18 + col + row) * 5 if rolling else 0.0
					box(Rect2(center.x - 24, center.y - 18 + bob, 48, 29), ink, ink, 5)
					draw_line(center + Vector2(-32, 13 + bob), center + Vector2(32, 13 + bob), ink, 7, true)
					continue
				var size = Vector2(min(cw - 8, ch * 1.55), ch - 3)
				if not double_grid: size = Vector2(min(cw - 8, ch - 4), min(cw - 8, ch - 4))
				var dest = Rect2(cell.position + (cell.size - size) * 0.5, size)
				if coin.jackpot >= 0:
					draw_texture_rect(HOLD_JACKPOTS[coin.jackpot], dest, false)
				else:
					draw_texture_rect(HOLD_COIN, dest, false)
					_draw_coin_amount(r * 5 + col, money(coin.value * game.denomination), dest, offset)
				if coin.multiplier > 1:
					var badge = cell.position + Vector2(cw - 24, 18)
					draw_circle(badge, 19, gold)
					draw_circle(badge, 16, Color("075526"))
					text("×" + str(coin.multiplier), Rect2(badge - Vector2(18, 14), Vector2(36, 28)), 21, cream)
	draw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
	box(Rect2(70, 1234, 884, 65), Color("073c28"), gold, 12, 3)
	var displayed = b.before_total if spin_time > 0 else b.total
	text(("GANHO TOTAL: " if b.spins_left == 0 and spin_time <= 0 else "MOEDAS ACUMULADAS: ") + money(displayed * game.denomination), Rect2(80, 1236, 864, 33), 28, gold)
	text("Novas moedas renovam os giros da própria tela. Moedas conquistadas ficam travadas.", Rect2(80, 1272, 864, 22), 17, cream)
	var credits = game.credits - (b.last_win if spin_time > 0 and not preview_bonus else 0)
	text(money(credits * game.denomination), Rect2(77, 1410, 237, 52), 30, gold)
	text(str(game.bet), Rect2(427, 1394, 170, 55), 40, gold)
	text("EXPLORAÇÃO: SEM ALTERAR SALDO" if preview_bonus else "MOEDAS PAGAS AO FINAL DO BÔNUS · GIROS GRATUITOS", Rect2(100, 1500, 824, 30), 19, cream)

func _draw_coin_amount(id, caption, dest, offset):
	if overlay != null and overlay.is_open():
		return
	var type_size = 40
	while type_size > 14 and font(type_size).get_string_size(caption).x > dest.size.x * 0.84 - 8:
		type_size -= 1
	if not gold_fonts.has(type_size):
		var face = DynamicFont.new()
		face.font_data = font(type_size).font_data
		face.size = type_size
		face.outline_size = 3
		face.outline_color = Color("a21807")
		gold_fonts[type_size] = face
	if not gold_amounts.has(id):
		var amount = GoldAmount.new()
		add_child(amount)
		gold_amounts[id] = amount
	var width = font(type_size).get_string_size(caption).x
	var at = dest.position + Vector2((dest.size.x - width) * 0.5, dest.size.y * 0.65 - type_size * 0.5)
	gold_amounts[id].set_amount(caption, gold_fonts[type_size], at + Vector2(0, offset))

func _draw_falling_coin(art, dest, cell):
	# Recorta o movimento vertical na casa: não passa sobre moedas já travadas.
	var visible = dest.clip(cell)
	if visible.size.x <= 0 or visible.size.y <= 0:
		return
	var factor = art.get_size() / dest.size
	var source = Rect2((visible.position - dest.position) * factor, visible.size * factor)
	draw_texture_rect_region(art, visible, source)

func _draw_sprite(index, dest):
	# Separate bounds prevent neighboring symbols from leaking into enlarged reels.
	var regions = [Rect2(20, 200, 316, 278), Rect2(344, 128, 285, 325), Rect2(645, 204, 280, 274), Rect2(946, 143, 295, 332), Rect2(25, 535, 308, 265), Rect2(339, 535, 280, 251)]
	if index % regions.size() == 5:
		var q = min(dest.size.x, dest.size.y) * 0.92
		draw_texture_rect(COIN_ART, Rect2(dest.position + (dest.size - Vector2(q, q)) * 0.5, Vector2(q, q)), false)
		return
	var region = regions[index % regions.size()]
	var scale = SYMBOL_ART.get_width() / 1280.0
	var source = Rect2(region.position * scale, region.size * scale)
	var fit = min(dest.size.x / source.size.x, dest.size.y / source.size.y)
	var size = source.size * fit
	dest = Rect2(dest.position + (dest.size - size) * 0.5, size)
	draw_texture_rect_region(SYMBOL_ART, dest, source)

# ---------------------------------------------------------------- modais desenhados
func _draw_modal():
	draw_rect(Rect2(0, -STRIP, 1024, total_height()), Color(0, 0.05, 0.03, 0.95))
	if modal_kind == "rules":
		box(Rect2(50, 40, 924, 1380), Color("063524"), gold, 20)
		text("SHOW MONOPOLY · REGRAS", Rect2(80, 66, 864, 55), 38, gold)
		text("4 cartelas 3×5 · 90 números · 30 bolas iniciais · até 10 extras\nAposta por cartela (1–20 créditos); abra ou feche cartelas.\nCusto = aposta × cartelas abertas. Prêmio = figura × aposta da cartela premiada.\nExtra: preço mostrado antes da compra; grátis 10% · Joker 8%.\nCancelar a extra mostra, apagadas, as bolas que viriam.\nBola colorida 10% · cada cofre abre após 20–50 coletas da sua cor.", Rect2(80, 142, 864, 260), 23, cream)
		text("versão " + BUILD, Rect2(80, 1380, 864, 30), 18, Color(0.7, 0.8, 0.7, 0.8))
		text("PREMIAÇÃO · múltiplos do valor-base", Rect2(70, 430, 884, 40), 25, gold)
		for i in range(game.patterns.size()):
			var x = 85 + (i % 4) * 219
			var y = 480 + int(i / 4) * 172
			text("×" + str(game.patterns[i].pay), Rect2(x, y, 194, 32), 26, gold)
			for n in range(15):
				box(Rect2(x + 24 + n % 5 * 29, y + 42 + int(n / 5) * 26, 25, 22), Color("d43333") if n in game.patterns[i].cells else Color("142923"), ink, 2)
		text("Cada figura paga uma vez por cartela; figuras diferentes somam.\nBÔNUS na faixa identifica prêmios; não abre os cofres.\nNo bônus, moedas descem e travam. Uma nova moeda renova os giros.\nVerde: multiplicadores · Vermelho: duas telas · Azul: 4 giros.\nO total das moedas é pago ao final. Créditos fictícios.", Rect2(75, 1010, 874, 175), 21, cream)
	elif modal_kind == "joker":
		box(Rect2(50, 40, 924, 1380), Color("122f39"), gold, 28)
		text("BOLA ZAZ · JOKER", Rect2(80, 66, 864, 60), 42, gold)
		text("Escolha um número ainda não marcado.\nEle será removido do globo e contará como esta extra.\nO mesmo número marca todas as cartelas.", Rect2(90, 156, 844, 140), 25)

# ---------------------------------------------------------------- bônus: sprites
func _sprite_unused():
	pass

# ---------------------------------------------------------------- automação (navegador)
func _browser_command(args):
	if args.empty():
		return
	var cmd = str(args[0])
	if cmd.begins_with("joker:") and modal_kind == "joker":
		choose_joker(int(cmd.substr(6)))
		return
	if cmd == "forcejoker":
		game.joker_chance = 1.0
		return
	if cmd == "previewbonus":
		op_preview()
		return
	if cmd.begins_with("vault:"):
		var level = int(cmd.substr(6))
		vault_charge = [level, level, level]
		return
	if cmd == "vaultburst":
		game.bonus.flags = [true, false, true]
		vault_preview = true
		vault_transition = 0.0
		vault_burst_started = false
		busy = false
		return
	if cmd.begins_with("bigwin:"):
		var multiple = int(cmd.substr(7))
		bigwin_amount = multiple * game.stake()
		bigwin_tier = 0
		for i in range(BIGWIN_MULTIPLES.size()):
			if multiple >= BIGWIN_MULTIPLES[i]:
				bigwin_tier = i
		bigwin_t = 0.0
		audio.play_voice(bigwin_tier)
		return
	if cmd == "spin" and modal_kind == "bonus":
		spin_bonus()
		return
	if cmd == "close" and modal_kind != "":
		close_modal()
		return
	if cmd == "sound":
		toggle_sound()
		return
	if cmd.begins_with("calc:"):
		if not overlay.is_open():
			open_menu()
		for ch in cmd.substr(5):
			overlay.press(ch)
		return
	if cmd.begins_with("toggle:"):
		toggle_card(int(cmd.substr(7)))
		return
	if cmd.begins_with("swap:"):
		swap_card(int(cmd.substr(5)))
		return
	if modal_kind != "" or busy or overlay.is_open():
		return
	match cmd:
		"play": play()
		"extra": buy_extra()
		"cards": change_cards()
		"minus": set_bet(-1)
		"plus": set_bet(1)
		"rules": show_rules()
		"menu": open_menu()

func publish_state():
	if not OS.has_feature("JavaScript"):
		return
	var state = {"phase": game.phase, "modal": modal_kind, "busy": busy, "cards": game.cards, "open": game.open_cards, "drawn": game.drawn, "shown": shown, "missed": game.missed_balls, "credits": game.credits, "bet": game.bet, "stake": game.stake(), "denomination": game.denomination, "hold": game.hold_percent, "monitor": op.monitor, "extras": game.extras_bought, "extra_cost": game.extra_quote(), "status": status_message, "round_wins": game.round_wins, "menu": overlay.mode, "stats": game.stats}
	JavaScript.eval("window.onPotionState && window.onPotionState(" + JSON.print(state) + ");", true)
