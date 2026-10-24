# Bônus de moedas dos cofres

O gatilho do jogo base continua com 20–50 bolas da mesma cor, escolhido por cofre. O movimento de impacto e os dez estágios de imagens foram preservados.

Cada grade começa vazia e tem 5 colunas × 3 linhas. As moedas descem durante o giro e ficam travadas. Somente casas vazias participam dos giros seguintes. Cada grade começa com três tentativas; receber uma moeda renova as tentativas daquela grade. Uma grade cheia encerra sua participação. O total das moedas é pago uma única vez quando todas as grades terminam, sem cobrar pelos giros do bônus.

- Verde: moedas com multiplicadores individuais 1×, 2×, 3× ou 5×. O valor mostrado já inclui o multiplicador.
- Vermelho: duas grades, com contadores independentes.
- Azul: quatro tentativas, inclusive na renovação, e chance progressivamente menor após 65% da grade ocupada.
- Combinações aplicam os modificadores simultaneamente.

Mini, Minor e Major usam as imagens fornecidas. O valor do acumulado é capturado quando a moeda cai, só pode aparecer uma vez por nível no bônus e volta ao inicial no pagamento final. A exploração do operador não altera esses saldos.

Parâmetros demonstrativos: chance básica de moeda de 12% por casa vazia/giro; azul reduz essa chance em até 65% conforme o preenchimento. Valores-base sorteados de [1,1,1,2,2,3,5,10] × unidade do bônus (4 × aposta), com fator 0,65 no vermelho e arredondamento para créditos inteiros. Multiplicadores verdes sorteados de [1,1,2,2,3,5]. Acumulados mantêm chance proporcional à aposta/inversa ao valor, reduzida pela metade no verde. Esses parâmetros concretizam as regras qualitativas do PDF; não representam validação do RTP de 90% nem das faixas de ganho médio citadas nele.

Arte de moeda sem valor fixo derivada por edição da imagem fornecida. Os valores em reais são desenhados conforme aposta, denominação e multiplicador reais. Os PNGs de Mini/Minor/Major são os originais fornecidos.
