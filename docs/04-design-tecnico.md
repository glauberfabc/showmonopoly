# 04 · Design técnico

## Arquitetura
```
Main.tscn ──> scripts/show_main.gd     cena única: layout, desenho, fluxo da rodada, botões, ponte JS
                 ├─ scripts/board_rules.gd     regras puras (sem UI): cartelas, sorteio, figuras, extras, cancelamento, contadores
                 │     ├─ scripts/bonus_rules.gd   slot e acumulados
                 │     └─ scripts/math_profile.gd  retenção → fator (GERADO por tools/calibrate.gd)
                 ├─ scripts/menu_overlay.gd    calculadora + menu do operador (Control em tela cheia)
                 ├─ scripts/operator_config.gd configuração persistida e código do operador
                 ├─ scripts/ball_art.gd        texturas de esferas 3D geradas por código
                 ├─ scripts/game_audio.gd      sons (trechos de um MP3)
                 └─ assets/char_warp.shader, assets/logo_shine.shader
```
Código antigo (edição Potion Master) fica em `legacy/` com extensão `.gd_old` e não entra na exportação.

## Máquina de estados da rodada (`board_rules.gd`)
```
ready/finished ──start_round()──> drawing ──draw_initial()──> extras
extras ──buy_extra()──> extras | joker | bonus | finished (10ª extra)
extras ──finish_round() [CANCELAR EXTRA]──> finished   (preenche missed_balls)
joker ──choose_joker()──> extras | bonus | finished
bonus ──spin_bonus()… close_bonus()──> fase de retorno
```
Configuração (aposta, retenção, crédito, abrir/fechar/trocar) só em `ready`/`finished`.

## Apresentação (`show_main.gd`)
O jogo resolve a rodada de uma vez e **apresenta** depois: `shown` é o número de bolas reveladas; a cada `BALL_INTERVAL` revela-se a próxima (marca cartelas, dispara destaques/valores/sons, anima a bola no painel). `busy` vale até todas as bolas e uma cauda de tempo terminarem; então `settle()` abre bônus/Joker ou conclui.

Camadas (nós `Sprite` com `show_behind_parent`, desenhados antes do `_draw()` do nó raiz):
1. placa de fundo (uma ou duas peças, no modo 2 telas);
2. personagens esquerdo/direito com `char_warp.shader`;
3. logo com `logo_shine.shader` (soma de luz);
4. `_draw()`: faixa de prêmios, textos, cartelas, globo, bolas, contadores, modais;
5. botões (`Button`) e, por cima, `menu_overlay`.

## Coordenadas
Viewport lógico 1024 × 1636 (faixa de prêmios 100 px + arte 1024×1536). Coordenadas da arte são deslocadas por `STRIP` (100). No modo 2 telas, tudo com y ≥ `split_y()` (1097 na tela principal, 1275 no bônus) é deslocado também por `GAP` (44); botões usam `canvas_y()`. O viewport vira 1024 × 1680 via `SceneTree.set_screen_stretch`.

| Elemento | Retângulo na arte |
|---|---|
| Grade da cartela c | x = 89 (c par) ou 706; y = 667 (c<2) ou 908; células 46,2 × 43,5 |
| FECHAR/ABRIR | canto esquerdo da cartela (x0+4, y0+4, 70×42), x0 = 40/660, y0 = 614/856 |
| TROCAR | canto direito (x0+254) |
| 30 bolas | (86 + 59·(n%10), 1171 + 57·⌊n/10⌋) |
| 10 extras | (738 + 51·(i%5), 1203 + 65·⌊i/5⌋); chip COMPRAR EXTRA em y 1288 |
| − / + / JOGAR | (347,1382,72×83) / (609,1380,73×85) / (704,1355,288×124) |

## Persistência
`user://operator.cfg` (IndexedDB no navegador): retenção, crédito, monitor, som, contadores. Saldo e cartelas duram a sessão.

## Ponte JavaScript (automação)
`window.potionCommand(cmd)` aceita `play`, `extra`, `cards`, `minus`, `plus`, `rules`, `menu`, `sound`, `toggle:N`, `swap:N`, `calc:<teclas>`, `joker:N`, `spin`, `close`; o jogo chama `window.onPotionState(estado)` a cada atualização.

## Exportação
Preset **Web** (`export_presets.cfg`, modelo personalizado em `tools/web_templates`), shell `web/shell.html` (apenas o canvas), política de redimensionamento adaptativa; `docs/`, `legacy/`, `tests/`, `tools/` ficam fora do pacote.
