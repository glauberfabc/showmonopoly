extends Control
# Calculadora funcional que, ao receber o código do operador, abre o menu de configuração.
const OperatorConfig = preload("res://scripts/operator_config.gd")
const Profile = preload("res://scripts/math_profile.gd")
var host
var mode = ""
var buttons = []
var entry = "0"
var accumulator = 0.0
var pending = ""
var fresh = true
var typed = ""
var page = "main"
const TIERS = ["MINI", "MINOR", "MAJOR"]
const TIER_COLORS = [Color("43c46a"), Color("e5645f"), Color("5a9cf0")]
const FIELDS = [["initial", "INICIAL"], ["current", "ATUAL"], ["final", "FINAL"]]
var gold = Color("e6b85f")
var cream = Color("f6efda")

func setup(owner_node):
	host = owner_node
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	sync_size()

func sync_size():
	rect_position = Vector2.ZERO
	rect_size = host.rect_size

func is_open():
	return mode != ""

func _clear_buttons():
	for b in buttons:
		b.queue_free()
	buttons.clear()

func _button(caption, rect, method, args = [], size = 34, accent = false):
	var b = Button.new()
	b.text = caption
	b.rect_position = rect.position
	b.rect_size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.add_font_override("font", host.font(size))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s = StyleBoxFlat.new()
		var base = Color("214851")
		if accent:
			base = Color("246e54")
		if state == "hover":
			base = base.lightened(0.18)
		elif state == "pressed":
			base = base.darkened(0.25)
		elif state == "disabled":
			base = Color("23343c")
		s.bg_color = base
		s.border_color = gold if state != "disabled" else Color("486068")
		s.set_border_width_all(2)
		s.set_corner_radius_all(14)
		b.add_stylebox_override(state, s)
	b.add_color_override("font_color", cream)
	b.add_color_override("font_color_disabled", Color("7f9aa0"))
	b.connect("pressed", self, method, args)
	add_child(b)
	buttons.append(b)
	return b

# ---------- calculadora ----------
func open_calculator():
	_reset_calc()
	mode = "calc"
	sync_size()
	visible = true
	_build_calc()
	update()

func _reset_calc():
	typed = ""
	entry = "0"
	accumulator = 0.0
	pending = ""
	fresh = true

func _build_calc():
	_clear_buttons()
	var keys = [["C", "<", "/", "*"], ["7", "8", "9", "-"], ["4", "5", "6", "+"], ["1", "2", "3", "="], ["0", ".", "", ""]]
	var labels = {"C": "C", "<": "DEL", "/": "÷", "*": "×", "-": "−", "+": "+", "=": "=", ".": ","}
	var x0 = 142
	var y0 = 470
	for row in range(keys.size()):
		for col in range(4):
			var key = keys[row][col]
			if key == "":
				continue
			var rect = Rect2(x0 + col * 188, y0 + row * 150, 170, 134)
			if key == "=":
				rect = Rect2(x0 + col * 188, y0 + row * 150, 170, 284)
			elif key == "0":
				rect = Rect2(x0, y0 + row * 150, 358, 134)
			elif key == "." and row == 4:
				rect = Rect2(x0 + 2 * 188, y0 + row * 150, 170, 134)
			_button(labels.get(key, key), rect, "press", [key], 44, key == "=")
	_button("FECHAR", Rect2(342, 1290, 340, 86), "close", [], 30)

func press(key):
	if mode != "calc":
		return
	if entry == "Erro":
		_reset_calc()
	if key.length() == 1 and key >= "0" and key <= "9":
		if fresh:
			entry = key
			fresh = false
		elif entry.length() < 12:
			entry = key if entry == "0" else entry + key
		typed = (typed + key).right(max(0, (typed + key).length() - OperatorConfig.CODE.length()))
		if typed == OperatorConfig.CODE or entry == OperatorConfig.CODE:
			open_operator()
			return
	elif key == ".":
		if fresh:
			entry = "0."
			fresh = false
		elif not "." in entry and entry.length() < 12:
			entry += "."
	elif key == "C":
		_reset_calc()
	elif key == "<":
		typed = typed.substr(0, max(0, typed.length() - 1))
		if not fresh:
			entry = entry.substr(0, entry.length() - 1)
			if entry == "" or entry == "-":
				entry = "0"
				fresh = true
	elif key in ["+", "-", "*", "/"]:
		typed = ""
		if pending != "" and not fresh:
			_compute()
		else:
			accumulator = float(entry)
		pending = key
		fresh = true
	elif key == "=":
		typed = ""
		if pending != "":
			_compute()
			pending = ""
		fresh = true
		if entry == OperatorConfig.CODE:
			open_operator()
			return
	update()

func _compute():
	var value = float(entry)
	match pending:
		"+": accumulator += value
		"-": accumulator -= value
		"*": accumulator *= value
		"/":
			if value == 0.0:
				entry = "Erro"
				accumulator = 0.0
				pending = ""
				fresh = true
				return
			accumulator /= value
	entry = _format(accumulator)

func _format(value):
	if abs(value) < 1e12 and value == floor(value):
		return str(int(value))
	var text = ("%.8f" % value).rstrip("0").rstrip(".")
	return text.substr(0, 14)

func _input(event):
	if not visible or mode != "calc":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code = event.scancode
		var key = ""
		if code >= KEY_0 and code <= KEY_9:
			key = str(code - KEY_0)
		elif code >= KEY_KP_0 and code <= KEY_KP_9:
			key = str(code - KEY_KP_0)
		elif code == KEY_BACKSPACE:
			key = "<"
		elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_EQUAL:
			key = "="
		elif code == KEY_PLUS or code == KEY_KP_ADD:
			key = "+"
		elif code == KEY_MINUS or code == KEY_KP_SUBTRACT:
			key = "-"
		elif code == KEY_ASTERISK or code == KEY_KP_MULTIPLY:
			key = "*"
		elif code == KEY_SLASH or code == KEY_KP_DIVIDE:
			key = "/"
		elif code == KEY_PERIOD or code == KEY_COMMA or code == KEY_KP_PERIOD:
			key = "."
		elif code == KEY_DELETE:
			key = "C"
		elif code == KEY_ESCAPE:
			close()
			get_tree().set_input_as_handled()
			return
		if key != "":
			press(key)
			get_tree().set_input_as_handled()

# ---------- menu do operador ----------
func open_operator():
	mode = "operator"
	page = "main"
	sync_size()
	visible = true
	_build_operator()
	update()

func _build_operator():
	_clear_buttons()
	var op = host.op
	var game = host.game
	if page == "jackpot":
		_build_jackpot_page()
		return
	_button("−", Rect2(142, 330, 130, 96), "change_hold", [-1], 48)
	_button("+", Rect2(752, 330, 130, 96), "change_hold", [1], 48)
	_button("R$ 0,10", Rect2(142, 556, 350, 90), "set_denomination", [10], 34, op.denomination == 10)
	_button("R$ 0,25", Rect2(532, 556, 350, 90), "set_denomination", [25], 34, op.denomination == 25)
	_button("VERTICAL · 1 TELA", Rect2(142, 786, 350, 90), "set_monitor", ["vertical"], 28, op.monitor == "vertical")
	_button("2 TELAS · CIMA/BAIXO", Rect2(532, 786, 350, 90), "set_monitor", ["dual"], 28, op.monitor == "dual")
	_button("EXPLORAR BÔNUS", Rect2(142, 1130, 350, 84), "preview", [], 28)
	_button("RECARREGAR CRÉDITOS", Rect2(532, 1130, 350, 84), "reload_credits", [], 25)
	_button("ZERAR CONTADORES", Rect2(142, 1234, 350, 84), "reset_stats", [], 27)
	_button("VOLTAR AO JOGO", Rect2(532, 1234, 350, 84), "close", [], 28, true)
	_button("ACUMULADOS · MINI / MINOR / MAJOR", Rect2(142, 1334, 740, 66), "open_jackpots", [], 27)

func open_jackpots():
	page = "jackpot"
	_build_operator()
	update()

func close_jackpots():
	page = "main"
	_build_operator()
	update()

func _jackpot_row_y(tier, row):
	return 270 + tier * 322 + 58 + row * 78

func _build_jackpot_page():
	for tier in range(3):
		for row in range(3):
			var y = _jackpot_row_y(tier, row)
			var field = FIELDS[row][0]
			_button("−−", Rect2(300, y, 78, 66), "jp_change", [tier, field, -10000], 24)
			_button("−", Rect2(384, y, 66, 66), "jp_change", [tier, field, -1000], 30)
			_button("+", Rect2(662, y, 66, 66), "jp_change", [tier, field, 1000], 30)
			_button("++", Rect2(734, y, 78, 66), "jp_change", [tier, field, 10000], 24)
		_button("ZERAR", Rect2(796, _jackpot_row_y(tier, 1), 96, 66), "jp_reset", [tier], 20)
	_button("VOLTAR", Rect2(342, 1332, 340, 70), "close_jackpots", [], 30, true)

func jp_change(tier, field, delta):
	var current = int(host.game.bonus.levels[field][tier])
	host.op_set_jackpot(tier, field, current + delta)
	update()

func jp_reset(tier):
	host.op_reset_jackpot(tier)
	update()

func change_hold(delta):
	host.op_set_hold(host.game.hold_percent + delta)
	_build_operator()
	update()

func set_denomination(value):
	host.op_set_denomination(value)
	_build_operator()
	update()

func set_monitor(value):
	host.op_set_monitor(value)
	sync_size()
	_build_operator()
	update()

func preview():
	close()
	host.op_preview()

func reload_credits():
	host.op_reload_credits()
	update()

func reset_stats():
	host.op_reset_stats()
	update()

func close():
	_clear_buttons()
	mode = ""
	visible = false
	host.menu_closed()

# ---------- desenho ----------
func _text(value, rect, size, color = cream, left = false):
	var f = host.font(size)
	var lines = str(value).split("\n")
	for i in range(lines.size()):
		var w = f.get_string_size(lines[i]).x
		var x = rect.position.x if left else rect.position.x + (rect.size.x - w) / 2
		draw_string(f, Vector2(x, rect.position.y + size + i * (size + 8)), lines[i], color)

func _panel(rect):
	var s = StyleBoxFlat.new()
	s.bg_color = Color("0b2c22")
	s.border_color = gold
	s.set_border_width_all(3)
	s.set_corner_radius_all(26)
	draw_style_box(s, rect)

func _field(rect):
	var s = StyleBoxFlat.new()
	s.bg_color = Color("06180f")
	s.border_color = Color("56727a")
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	draw_style_box(s, rect)

func _draw():
	if mode == "":
		return
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.0, 0.035, 0.02, 0.96))
	_panel(Rect2(92, 120, 840, 1300))
	if mode == "calc":
		_text("CALCULADORA", Rect2(92, 150, 840, 60), 44, gold)
		_field(Rect2(142, 250, 740, 170))
		var shown = entry.replace(".", ",")
		if pending != "":
			_text(_format(accumulator).replace(".", ",") + " " + {"+": "+", "-": "−", "*": "×", "/": "÷"}[pending], Rect2(160, 262, 704, 30), 24, Color("a8c1c2"), true)
		var size = 76 if shown.length() <= 9 else 54
		var f = host.font(size)
		draw_string(f, Vector2(862 - f.get_string_size(shown).x, 392), shown, cream)
	elif page == "jackpot":
		var game = host.game
		_text("ACUMULADOS", Rect2(92, 150, 840, 60), 44, gold)
		_text("Inicial: valor para onde volta quando cai · Atual: o que aparece na tela · Final: teto (para de subir).", Rect2(112, 214, 800, 22), 17, Color("b6cbce"))
		for tier in range(3):
			var top = 270 + tier * 322
			_text(TIERS[tier], Rect2(142, top, 740, 44), 34, TIER_COLORS[tier], true)
			for row in range(3):
				var y = _jackpot_row_y(tier, row)
				_text(FIELDS[row][1], Rect2(142, y + 16, 150, 30), 22, Color("a8c1c2"), true)
				_field(Rect2(458, y, 196, 66))
				_text(host.money(int(game.bonus.levels[FIELDS[row][0]][tier])), Rect2(458, y + 14, 196, 40), 28, gold if row == 1 else cream)
	else:
		var game = host.game
		var op = host.op
		_text("MENU DO OPERADOR", Rect2(92, 150, 840, 60), 44, gold)
		_text("RETENÇÃO DA CASA", Rect2(142, 262, 740, 36), 26, Color("a8c1c2"), true)
		_field(Rect2(292, 330, 440, 96))
		_text("%d %%" % game.hold_percent, Rect2(292, 346, 440, 60), 54, gold)
		_text("RTP-alvo %d%% · fator da extra %s · vale a partir da próxima rodada" % [Profile.target_rtp(game.hold_percent), ("%.3f" % game.extra_factor).replace(".", ",")], Rect2(142, 440, 740, 28), 21, Color("b6cbce"), true)
		_text("VALOR DO CRÉDITO", Rect2(142, 492, 740, 36), 26, Color("a8c1c2"), true)
		_text("Aplicado a saldos, apostas e prêmios exibidos em reais.", Rect2(142, 662, 740, 28), 21, Color("b6cbce"), true)
		_text("MONITOR", Rect2(142, 722, 740, 36), 26, Color("a8c1c2"), true)
		_text("2 TELAS divide a imagem em superior (show) e inferior (apostas e bolas).", Rect2(142, 892, 740, 28), 21, Color("b6cbce"), true)
		_text("CONTABILIDADE (desde o último zeramento)", Rect2(142, 944, 740, 36), 26, Color("a8c1c2"), true)
		_field(Rect2(142, 990, 740, 118))
		var coin = game.denomination
		_text("Entradas %s   ·   Prêmios %s" % [host.money(game.stats["in"] * coin), host.money(game.stats["out"] * coin)], Rect2(160, 1002, 704, 30), 24, cream, true)
		_text("RTP efetivo %s   ·   Rodadas %d   ·   Extras %d" % [("%.1f%%" % (game.observed_rtp() * 100.0)).replace(".", ",") if game.stats["in"] > 0 else "—", game.stats["rounds"], game.stats["extras"]], Rect2(160, 1050, 704, 30), 24, cream, true)
		_text("Mudanças são salvas automaticamente.", Rect2(142, 1398, 740, 20), 17, Color("b6cbce"), true)
