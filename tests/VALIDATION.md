# Validação — Show Monopoly v2 (08/10/2026)

- `tests/test_board.gd` (Godot 3.6 headless): 0 falhas — tabela de pagamentos, abrir/fechar/trocar cartelas, extras e cancelamento com bolas ocultas até JOGAR, perfil de retenção, chance dos acumulados proporcional à aposta, 150 rodadas aleatórias, calculadora, código 913731, operador, modos de monitor.
- Verificação visual no navegador (Chromium/WebGL): arte, bolas 3D, cartelas, extras, bolas canceladas com X, calculadora, menu do operador, modo 2 telas, brilho do logo e movimento dos personagens.
- Calibração: 110.000 rodadas, ver `docs/03-matematica-e-retencao.md` e `data/rtp-calibration.json`. Não certificada.
- Publicação na VPS: não realizada nesta rodada.
