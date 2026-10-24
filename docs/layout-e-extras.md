# Layout e elegibilidade de extras — 09/10/2026

Slots: separação em y=600 também no bônus, cofres acima e uma/duas grades abaixo. Nove linhas por grade, contagem consecutiva da esquerda para a direita; 3/4/5 símbolos pagam 3×/8×/20× o valor-base, antes do multiplicador verde. Linhas distintas somam e o traçado dourado cobre somente os símbolos pagos. Frequência de símbolos, giros e acumulados preservados. Estes parâmetros aumentam o retorno do bônus e invalidam qualquer calibração histórica de RTP; o jogo permanece demonstrativo.

Correção da Figura 12: a linha horizontal de 3× aceita qualquer uma das três linhas da cartela. Pagamento único por figura/cartela/rodada preservado; proximidade e preço das extras consideram as três alternativas. Testes cobrem cada linha isolada e pagamento sem repetição.

- Valores e máscaras da tabela mantidos por confirmação do usuário. A referência nova orienta apenas o destaque dourado.
- Modo de duas telas: separador antes das cartelas; cofres, acumulados e paytable acima; quatro cartelas, globo, bolas e controles abaixo. Coordenadas de clique do Joker acompanham o deslocamento.
- Figuras pagas permanecem douradas até a próxima rodada. A antecipação usa somente números já revelados, sem antecipar o resultado interno do sorteio. Pisca apenas a célula que falta e exibe o maior multiplicador que ela completa.
- Campo de ganhos da rodada acima da aposta, visível somente com premiação maior que zero.
- Extras: disponíveis apenas com alguma figura ainda não paga a uma bola de completar em cartela aberta. A elegibilidade é recalculada após a bola extra e o Joker; o bônus conserva a fase correta para o retorno. Limite de dez mantido.
- Área JOGAR dividida em cancelar e comprar extra somente na fase de extras. Superfícies com gradiente, relevo dourado e estados de interação.
- Verde/azul: uma grade 5×3 ampliada. Vermelho (inclusive combinado): duas grades maiores sobre os cofres.

Validação: 150 rodadas, bloqueio de extra sem proximidade, transição após prêmio/Joker, cartela fechada, coordenadas inferiores, célula faltante e renderização dos três bônus. Capturas em tests/layout-*.png.

Matemática: os multiplicadores e o preço condicional não mudaram. A elegibilidade altera a distribuição das rodadas; a calibração histórica de math_profile.gd não constitui validação de RTP para esta regra nova.

Atualização de 10/10: toque em espaço vazio compra a extra naquela posição; o botão usa o primeiro espaço livre. O Joker conserva a posição escolhida. Cofres acumulam crescimento visual por bola da mesma cor e abrem antes da transição ao bônus, sem alterar seu gatilho RNG. Validação automatizada em tests/test_touch_vaults.gd, incluindo bloqueio de compra duplicada durante animação; monitor touch físico não testado.

Atualização 11/10/2026 (bônus de slot): 3/4/5 símbolos agora pagam 1×/3×/7× o valor-base e uma linha é forçada em ~28% dos painéis (3 símbolos 75%, 4 símbolos 20%, 5 símbolos 5%). Simulação: chance de ao menos uma linha por giro sobe de ~21% para ~43%, com retorno médio por giro praticamente igual (≈1,02× vs ≈1,04× o valor-base). O símbolo FICHA do slot passou a ser a moeda "M" do jogo. Big win: o selo SUPER BIG WIN cresce no lugar do texto e as moedas que caem são a moeda "M".

Atualização 12/10/2026: (1) cofres vermelho e azul reduzidos ~10% (VAULT_SCALE) para parecerem apoiados na mesa. (2) A compra de bola extra não encerra mais quando não há figura próxima: segue até o limite de 10 extras ou o fim das bolas, com preço mínimo (1 crédito) sem prêmio possível; o preço continua = fator × valor esperado e sobe conforme surgem figuras maiores faltando uma bola.

Correção 12/10/2026 (noite): a primeira bola extra só é oferecida quando alguma figura está a uma bola de pagar (regra original). Depois que o jogador comprou a primeira, ele pode continuar comprando até a 10ª bola ou o fim do baralho, mesmo sem prêmio próximo (preço mínimo nesse caso). Substitui o item (2) da atualização anterior.

Atualização 13/10/2026: selos MEGA e ULTRA BIG WIN (assets/mega_big_win.png, ultra_big_win.png) usam a mesma animação de crescimento do SUPER. Moedas "M" pseudo-3D (giro com espessura de borda, sombra e brilho) nos big wins e nas moedas que saltam dos cofres ao receber a bola colorida.
