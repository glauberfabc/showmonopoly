extends Reference
# Configuração do operador (persistida). O código abaixo abre o menu pela calculadora.
# Atenção: o código está no cliente; serve a esta demonstração, não a um ambiente regulado.
const CODE = "913731"
const PATH = "user://operator.cfg"
var hold = 8
var denomination = 10
var monitor = "vertical"
var sound = true
var jackpots = null
var stats = {"in": 0, "out": 0, "rounds": 0, "extras": 0}

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return false
	hold = int(clamp(int(cfg.get_value("operator", "hold", 8)), 4, 20))
	denomination = int(cfg.get_value("operator", "denomination", 10))
	if not denomination in [10, 25]:
		denomination = 10
	monitor = str(cfg.get_value("operator", "monitor", "vertical"))
	if not monitor in ["vertical", "dual"]:
		monitor = "vertical"
	sound = bool(cfg.get_value("operator", "sound", true))
	for key in stats.keys():
		stats[key] = max(0, int(cfg.get_value("stats", key, 0)))
	if cfg.has_section("jackpot"):
		jackpots = {}
		for field in ["initial", "current", "final"]:
			var values = cfg.get_value("jackpot", field, [])
			if typeof(values) == TYPE_ARRAY and values.size() == 3:
				jackpots[field] = [float(values[0]), float(values[1]), float(values[2])]
		if jackpots.size() != 3:
			jackpots = null
	return true

func apply(game):
	game.set_hold(hold)
	game.set_denomination(denomination)
	game.stats = stats.duplicate()
	if jackpots != null:
		game.bonus.levels = {"initial": jackpots.initial.duplicate(), "current": jackpots.current.duplicate(), "final": jackpots.final.duplicate()}

func capture(game):
	hold = game.hold_percent
	denomination = game.denomination
	stats = game.stats.duplicate()
	jackpots = {"initial": game.bonus.levels.initial.duplicate(), "current": game.bonus.levels.current.duplicate(), "final": game.bonus.levels.final.duplicate()}

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("operator", "hold", hold)
	cfg.set_value("operator", "denomination", denomination)
	cfg.set_value("operator", "monitor", monitor)
	cfg.set_value("operator", "sound", sound)
	for key in stats.keys():
		cfg.set_value("stats", key, stats[key])
	if jackpots != null:
		for field in jackpots.keys():
			cfg.set_value("jackpot", field, jackpots[field])
	cfg.save(PATH)
