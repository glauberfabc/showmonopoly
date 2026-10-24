extends Reference
# PERFIL MATEMÁTICO — gerado por tools/calibrate.gd (84000 rodadas, aposta 1 por cartela, 4 cartelas). Não edite à mão.
# Retenção (%) -> fator do preço da bola extra (preço = fator × valor esperado da próxima bola).
const MIN_HOLD = 4
const MAX_HOLD = 20
const DEFAULT_HOLD = 8
const FACTORS = [1.046, 1.057, 1.07, 1.08, 1.089, 1.102, 1.11, 1.122, 1.135, 1.149, 1.163, 1.178, 1.193, 1.208, 1.223, 1.239, 1.254]

static func extra_factor(hold):
	var h = int(clamp(hold, MIN_HOLD, MAX_HOLD))
	return FACTORS[h - MIN_HOLD]

static func target_rtp(hold):
	return 100 - int(clamp(hold, MIN_HOLD, MAX_HOLD))
