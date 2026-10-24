# 07 · Rastreabilidade

| Requisito | Código | Verificação |
|---|---|---|
| CART-01/02 | `board_rules.gd` `_new_card`, `_generate_cards` | `test_basics` |
| CART-03 | `toggle_card`, `show_main.gd` `toggle_card`, `_draw_card` | `test_cards_config`; visual |
| CART-04 | `swap_card`, `change_cards` | `test_cards_config`; visual |
| CART-05 | `_can_configure` | `test_cards_config` |
| APOS-01/02 | `set_bet`, `unit`, `stake`, `start_round` | `test_basics`, `test_cards_config` |
| PAY-01/02/03/04 | `_build_patterns`, `_pay_patterns`, `draw_next` | `test_paytable` |
| PAY-05 | `_reveal_ball`, `_draw_strip`, `_draw_floaters`, `_draw_card` | visual |
| SORT-01/02 | `draw_initial`; `_process`, `_reveal_ball` | `test_extras_and_cancel`, `scene_checks` |
| EXTRA-01…03 | `buy_extra`, `extra_expected`, `extra_quote` | `test_extras_and_cancel` |
| EXTRA-04/05 | `finish_round`, `missed_balls`, `draw_ghost` | `test_extras_and_cancel`, `scene_checks`; visual |
| RET-01…03 | `set_hold`, `math_profile.gd`, `tools/calibrate.gd` | `test_hold_profile`; simulação (`03`) |
| BONUS-01/02 | `bonus_rules.gd` `jackpot_chance` | `test_bonus_jackpot_scaling`, `test_random_rounds` |
| MENU-01…04 | `menu_overlay.gd` | `scene_checks`; visual |
| OPER-01…03 | `op_set_hold`, `op_set_denomination`, `op_set_monitor` | `scene_checks` |
| OPER-04…06 | `op_preview`, `op_reload_credits`, `op_reset_stats`, `operator_config.gd` | visual |
| OPER-05 | `stats`, `observed_rtp` | `test_paytable`, `test_random_rounds` |
| MON-01/02 | `apply_layout`, `canvas_y`, `_draw_bezel` | `scene_checks`; visual |
| EXTRA-06, EXTRA-02 (Joker por toque) | `_pick_slot`, `extra_slots`, `_gui_input`, `joker_numbers` | `scene_checks`; visual |
| BONUS-02 (brilho) | `_bonus_glow` | visual |
| SORT-01 | `_compute_weights`, `_assisted_deck`, `extra_expected` | `test_draw_assist` |
| WIN-01 | `_update_bigwin`, `_draw_bigwin` | visual (comando `bigwin:N`) |
| VAULT-01 | `_animate_vaults`, `_draw_vault_pressure`, `_draw_vault_burst`, `vault_swell.shader` | `tests/test_touch_vaults.gd`; visual (comandos `vault:N`, `vaultburst`) |
| UI-01 | `web/shell.html` | visual |
| VIS-01/02/03 | `logo_shine.shader`, `char_warp.shader`, `ball_art.gd` | visual (capturas no navegador) |
| JP-01..05 | `bonus_rules.gd` (`levels`, `grow`, `set_level`, `reset_level`, `jackpot_chance`), `operator_config.gd`, `menu_overlay.gd` (página ACUMULADOS) | `test_jackpot_levels` |
| EXTRA-07 | `show_main.gd` (`_top_extra_prizes`, `_draw_extra_prizes`) | visual (captura no navegador) |
