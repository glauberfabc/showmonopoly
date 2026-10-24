# 02 · Requisitos

Notação: **DEVE** = obrigatório. Cada item é verificável por teste automático (T) ou inspeção visual no navegador (V).

## Cartelas (CART)
- **REQ-CART-01** O jogo DEVE ter quatro cartelas 3×5. (T)
- **REQ-CART-02** Cada cartela DEVE ter 15 números distintos entre 1 e 90, ordenados por coluna. (T)
- **REQ-CART-03** O jogador DEVE poder fechar e abrir cada cartela (botão FECHAR/ABRIR no canto da cartela); ao menos uma permanece aberta; cartela fechada não participa do sorteio, não paga e não é cobrada. (T,V)
- **REQ-CART-04** O jogador DEVE poder trocar os números de uma cartela (TROCAR) ou das quatro (TROCAR TODAS), sem alterar as demais. (T,V)
- **REQ-CART-05** Abrir/fechar/trocar/aposta/retenção só DEVEM ser possíveis fora de uma rodada. (T)

## Aposta (APOS)
- **REQ-APOS-01** Aposta por cartela: inteiro de 1 a 20 créditos. (T)
- **REQ-APOS-02** Custo da rodada = aposta × cartelas abertas, debitado ao JOGAR; valor-base da figura = aposta da cartela premiada. (T)

## Premiação (PAY)
- **REQ-PAY-01** A tabela DEVE ter 12 figuras: 1500, 500, 350, 200, 100, 100, 50, 40, 10, 8, 3 e 3 (máscaras em `board_rules.gd`, mostradas na faixa superior e em REGRAS). (T,V)
- **REQ-PAY-02** Cada figura DEVE pagar múltiplo × valor-base, uma única vez por cartela e rodada, na posição exata (sem rotação); figuras diferentes somam. (T)
- **REQ-PAY-03** Nenhum pagamento pode se repetir ao reavaliar a mesma rodada. (T)
- **REQ-PAY-04** Cartela completa até a 30ª bola paga também o acumulado de Bingo (R$ 5.000,00), uma vez por rodada. (T)
- **REQ-PAY-05** Ao revelar uma bola que completa figura, DEVE haver destaque da figura na faixa e na cartela, valor flutuante e som. (V)

## Sorteio (SORT)
- **REQ-VAULT-01** Cada bola colorida coletada enche o cofre da cor: ele cresce (efeito barril/“gordinho”), a porta entorta e vibra cada vez mais, luz vaza pelas frestas e notas e moedas começam a sair pelas bordas. O enchimento é assintótico (nunca chega a 100% sozinho), pois o gatilho é aleatório; quando o bônus dispara o cofre treme forte, estoura (onda de choque e clarão), a porta abre e uma chuva de notas e moedas sai e quica. Duração do estouro ≈2,9 s antes do slot. Enquanto as moedas da bola caem no cofre toca o loop `wincounter_loop` do acervo (dá a sensação de enchimento), parando quando a queda termina. (V)
- **REQ-SLOT-AUDIO-01** No bônus de slot: música `FreespinThemeLoop1` em loop enquanto o slot está aberto; ao girar tocam `ReelStart2` (início) e `ReelSpin1` (giro); os 5 rolos param um a um (1,00 / 1,35 / 1,70 / 2,05 / 2,40 s) com `ReelStop1`…`ReelStop5`, e a música e o giro param ao sair do bônus. (V)
- **REQ-WIN-01** Prêmio alto da rodada (≥10× o custo da rodada = SUPER BIG WIN; ≥40× = MEGA BIG WIN; ≥100× = ULTRA BIG WIN, cada um com sua narração: VoiceoverSuperBigWin1, VoiceoverMegaBigWin1, VoiceoverUltraBigWin1 do acervo) dispara uma celebração: fundo escurecido, título pulsando, placar que conta até o valor, moedas caindo, raios e brilhos, com som de moedas. Dura 7,4 s; toque a dispensa e JOGAR inicia a próxima rodada. (V)
- **REQ-SORT-01** 30 bolas iniciais sem repetição de um universo de 90. (T)
- **REQ-SORT-02** As bolas DEVEM ser reveladas uma a uma (≈0,11 s cada), com cartelas, ganhos e coletas sincronizados com a bola exibida. (T,V)

## Bola extra (EXTRA)
- **REQ-SORT-01** Sorteio assistido: o baralho é uma permutação de 1–90 em que os números das cartelas **abertas** pesam mais que os demais, de modo que cada um saia nas 30 bolas com chance-alvo de 42% (sem assistência: 33%). Isso faz as figuras da tabela de prêmios saírem com muito mais frequência (≈67% das rodadas pagam alguma figura, contra ≈4% sem assistência). A assistência vale igual para qualquer número de cartelas abertas e o preço da extra usa os mesmos pesos, mantendo o RTP. (T)
- **REQ-EXTRA-01** Até 10 extras, na ordem do baralho já embaralhado. (T)
- **REQ-EXTRA-02** O preço exibido DEVE ser o debitado; extra grátis (10%) não debita; Joker (8%) deixa o jogador **tocar em qualquer número de uma cartela aberta** para completá-lo (sem lista/modal; a posição vazia da extra fica reservada com “?” até o toque). (T,V)
- **REQ-EXTRA-06** O jogador escolhe a posição: tocar um espaço vazio do painel de extras define onde a próxima bola extra será colocada (sem toque, vai ao espaço vazio mais próximo do ponteiro/primeiro livre); as bolas apagadas ocupam os espaços restantes (apagadas, sem X). (V)
- **REQ-EXTRA-03** Preço = fator da retenção × valor esperado da próxima bola (figuras a uma bola de completar, Joker e gratuidade), arredondado, mínimo 1 crédito. (T)
- **REQ-EXTRA-04** **Cancelar a extra** DEVE encerrar a rodada sem custo e **mostrar as bolas que viriam** (as próximas do baralho, até completar 10) no painel de extras, **apagada (sem X, com o número legível e aro vermelho)**, sem pagar nada. (T,V)
- **REQ-EXTRA-05** As bolas apagadas DEVEM permanecer visíveis (inclusive ao abrir/fechar/trocar cartelas) e **sumir somente ao clicar em JOGAR**. (T,V)

## Retenção (RET)
- **REQ-RET-01** Retenção configurável de 4% a 20% (inteiros). (T)
- **REQ-RET-02** O fator de preço da extra DEVE crescer com a retenção; vale a partir da próxima rodada. (T)
- **REQ-RET-03** RTP-alvo = 100% − retenção, na estratégia de referência de `03`. (T, simulação)

## Bônus (BONUS)
- **REQ-BONUS-01** A chance de Mini/Minor/Major no giro verde DEVE ser proporcional ao valor-base (retorno acompanha a aposta). (T)
- **REQ-BONUS-02** Cofres, coletas, gatilhos e slot mantêm as regras anteriores (10% bola colorida, 10% gatilho, 10% combinação). Bolas coloridas (bônus) têm brilho próprio: halo pulsante, raios girando e faíscas, além do aro. (T,V)

## Menu e calculadora (MENU)
- **REQ-MENU-01** O botão MENU (fora de rodada) DEVE abrir uma calculadora. (T,V)
- **REQ-MENU-02** A calculadora DEVE funcionar (+ − × ÷ , C DEL =, teclado físico), com "Erro" em divisão por zero. (T)
- **REQ-MENU-03** Digitar `913731` (últimos seis dígitos digitados, ou resultado/entrada igual) DEVE abrir o menu do operador. (T,V)
- **REQ-MENU-04** VOLTAR AO JOGO / FECHAR DEVEM fechar o menu. (T)

## Operador (OPER)
- **REQ-OPER-01** Ajustar retenção (− / +). (T)
- **REQ-OPER-02** Cadastrar valor do crédito: R$ 0,10 ou R$ 0,25. (T)
- **REQ-OPER-03** Escolher monitor: VERTICAL ou 2 TELAS. (T)
- **REQ-OPER-04** Explorar bônus (sem alterar saldo), recarregar créditos, zerar contadores. (V)
- **REQ-OPER-05** Contabilidade: entradas, prêmios, RTP efetivo, rodadas, extras. (T)
- **REQ-OPER-06** Configurações e contadores DEVEM persistir entre sessões (`user://operator.cfg`). (V)

## Monitor (MON)
- **REQ-MON-01** Vertical: uma tela 1024×1636 lógicos. (T,V)
- **REQ-MON-02** 2 telas: parte superior (faixa de prêmios, logo, personagens, cofres, cartelas, globo) e inferior (bolas sorteadas/extras, saldo, aposta, JOGAR) separadas por faixa de 44 px; botões acompanham. (T,V)

## Interface (UI) e visual (VIS)
- **REQ-UI-01** Nenhum controle fora do canvas; a página só carrega o jogo. (V)
- **REQ-VIS-01** O logo DEVE brilhar continuamente (varredura de luz, pulsação, cintilações). (V)
- **REQ-VIS-02** Os dois personagens DEVEM se mover com respiração, giro e aceno, dando sensação de profundidade independente do cenário. (V)
- **REQ-VIS-03** As bolas (globo, painéis, voo aos cofres, marcadores das cartelas) DEVEM ser esferas 3D coloridas com luz, brilho e disco do número. (V)

## Acumulados progressivos (Mini / Minor / Major)

- **REQ-JP-01** Cada nível tem três valores configuráveis no menu do operador: Inicial, Atual e Final.
- **REQ-JP-02** O valor Atual é o exibido na tela. Ao cair o acumulado, ele volta ao Inicial.
- **REQ-JP-03** O Atual sobe aos poucos a cada rodada e para de subir ao chegar no Final.
- **REQ-JP-04** O crescimento é proporcional à aposta: taxa 20% / 10% / 5% do valor apostado × peso sqrt(aposta/8) limitado a 0,35–1,6 (aposta 1 ≈ 35%, aposta 8 = 100%, aposta 20 ≈ 160%).
- **REQ-JP-05** A chance de acerto é JACKPOT_SHARE × unidade / valor Atual, mantendo o pagamento esperado constante (RTP inalterado). Valores persistem em `user://operator.cfg`.

- **REQ-EXTRA-07** Na bola Coringa (símbolo "?"), o painel "ESCOLHA UM NÚMERO" sobrepõe a parte inferior central da tela e lista até 5 números que completam premiações, do maior para o menor valor (R$ = figura × aposta). Tocar na bola do painel marca o número automaticamente em todas as cartelas; o toque direto na cartela continua como alternativa. O painel some durante sorteio, menu e janelas.
