# Show Monopoly — Godot 3.6

Bingo demonstrativo com quatro cartelas, globo, três cofres e slot de bônus. Abra `project.godot` no Godot 3.6 e pressione F5, ou exporte o preset **Web**.

**A documentação spec-driven está em [`docs/`](docs/00-indice.md)** (requisitos `REQ-*`, matemática e retenção, design, UI, tarefas e rastreabilidade).

## O que há no jogo (tudo dentro da tela)
- Abrir/fechar cada cartela e trocar os números de cada uma (ou de todas). Custo = aposta por cartela × cartelas abertas.
- Premiação pela tabela de 12 figuras (1500×…3×), uma vez por figura e cartela, destaque e valor na tela.
- Bolas reveladas em sequência, em 3D colorido. Bola extra com preço antes da compra; **CANCELAR EXTRA** mostra com X as bolas que viriam, até o próximo JOGAR.
- **MENU → calculadora → `913731`** abre o menu do operador: retenção (4–20%), valor do crédito (R$ 0,10/0,25), monitor (vertical ou 2 telas), contabilidade.
- Logo com brilho animado; personagens com movimento de profundidade.

## Execução e verificação
- Local: `Jogar-no-navegador.ps1` (http://127.0.0.1:8765/) após exportar o preset **Web** (`web/shell.html` é o shell; a página contém só o jogo).
- Testes: `./tests/run.ps1 -Godot 'C:\caminho\Godot_v3.6-stable_win64.exe'`.
- Recalibrar a retenção: ver `docs/03-matematica-e-retencao.md` §5 (`tools/calibrate.gd`).

## Arquivos ativos
`scripts/show_main.gd` (cena), `board_rules.gd` (regras), `bonus_rules.gd` (slot), `math_profile.gd` (gerado), `menu_overlay.gd`, `operator_config.gd`, `ball_art.gd`, `game_audio.gd`; `assets/char_warp.shader`, `assets/logo_shine.shader`; artes `monopoly-base.png`, `monopoly-bonus.png`, `monopoly-symbols.png`. A edição anterior está em `legacy/`.

Créditos fictícios; RTP calibrado por simulação própria, **não certificado**.
