> Atualização 11/10/2026: figuras do bingo usam aposta por cartela (sem fator 4); cofres têm limite independente sorteado uniformemente entre 20 e 50 coletas. Estimativas e calibrações históricas abaixo não validam esta versão. O preço da extra usa os novos valores de prêmio.

# 03 · Matemática, preço da extra e retenção

> **Aviso.** Valores de simulação própria, sem certificação. Servem para calibrar a demo e para o operador entender o que a retenção faz.

## 1. Probabilidades exatas da tabela (por cartela)
Uma figura com *k* casas está completa depois de *n* bolas com probabilidade `P(k,n) = Π_{i=0..k-1} (n−i)/(90−i)`. O retorno esperado por cartela, em múltiplos do valor-base, é `Σ pagamento × P(k,n)`:

| Figura | Paga | Casas | Retorno com 30 bolas | Retorno com 40 bolas |
|---|---:|---:|---:|---:|
| 01 | 1500× | 15 | 0,0000 | 0,0013 |
| 02 | 500× | 12 | 0,0002 | 0,0102 |
| 03 | 350× | 11 | 0,0005 | 0,0195 |
| 04 | 200× | 10 | 0,0011 | 0,0296 |
| 05 | 100× | 10 | 0,0005 | 0,0148 |
| 06 | 100× | 9 | 0,0020 | 0,0387 |
| 07 | 50× | 8 | 0,0038 | 0,0496 |
| 08 | 40× | 8 | 0,0030 | 0,0397 |
| 09 | 10× | 8 | 0,0008 | 0,0099 |
| 10 | 8× | 6 | 0,0076 | 0,0493 |
| 11 | 3× | 5 | 0,0097 | 0,0449 |
| 12 | 3× | 5 | 0,0097 | 0,0449 |
| **Total** | | | **3,89%** | **35,25%** |

Consequência: **as 30 bolas iniciais devolvem ~3,9% por cartela**; as 10 extras acrescentam até ~31,4 pontos. Chance de cartela cheia em 30 bolas: 3,4 × 10⁻⁹ (acumulado de Bingo, desprezível no RTP).

Com **valor-base = 4 × aposta por cartela** (DEC-02) e quatro cartelas abertas, o retorno é ≈15,5% do custo nas 30 bolas e ≈141% do custo com todas as extras — antes de pagar as extras e sem contar o Joker.

### 1.1 Sorteio assistido (REQ-SORT-01)
Na distribuição uniforme as figuras da tabela quase não saem nas 30 bolas (a de 3× é ≈1% por cartela). Por isso o baralho é sorteado com pesos: números das cartelas abertas recebem peso `W`, os demais 1, e `W` é calculado (aproximação de Poisson) para que cada número das cartelas tenha chance de 42% de sair nas 30 bolas. A ordem é gerada por amostragem sequencial proporcional aos pesos, de modo que a próxima bola tem probabilidade `peso ÷ soma dos pesos restantes` — exatamente o que o preço da extra usa. Resultado medido (84 mil rodadas): ≈66,7% das rodadas pagam alguma figura e 8,4% pagam bônus.

## 2. Preço da bola extra
Para o estado atual da rodada, `E` é a soma, sobre figuras de cartelas abertas ainda não pagas com **exatamente uma casa faltando**, de `pagamento × valor-base` agrupada por número faltante `n`:
```
total = Σ_n payout[n]            melhor = max_n payout[n]
E = ((1 − joker)·total/|baralho| + joker·melhor) / (1 − gratuita)      joker = 8%, gratuita = 10%      (total e |baralho| ponderados pelos pesos do sorteio)
preço = max(1, round(fator(retenção) × E))                            (créditos)
```
`E` é exatamente a esperança do ganho no próximo sorteio (incluindo o Joker, em que o jogador escolhe o melhor número, e a devolução da extra grátis), então a soma dos preços ao longo da rodada acompanha a soma dos ganhos esperados. O mínimo de 1 crédito distorce apostas pequenas (seção 4).

## 3. Retenção → fator
O **fator** multiplica `E`. Retenção maior → fator maior → extra mais cara → RTP menor. `tools/calibrate.gd` simula a **estratégia de referência** (4 cartelas abertas, compra as 10 extras, Joker escolhe o melhor número, aposta 8 por cartela, 84.000 rodadas) e resolve, para cada retenção, o fator que dá `RTP = 100% − retenção`. Os fatores gerados estão em `scripts/math_profile.gd`:

| Retenção | 4% | 5% | 6% | 7% | **8%** | 9% | 10% | 11% | 12% | 13% | 14% | 15% | 16% | 17% | 18% | 19% | 20% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Fator | 1,046 | 1,057 | 1,070 | 1,080 | **1,089** | 1,102 | 1,110 | 1,122 | 1,135 | 1,149 | 1,163 | 1,178 | 1,193 | 1,208 | 1,223 | 1,239 | 1,254 |

Composição média da simulação (aposta 1, 4 cartelas): 66,7% das rodadas com prêmio, 8,4% com bônus pago, 10 extras compradas por rodada, 10,0% delas grátis. Probabilidades de prêmio (v2.1): bola colorida 10%, gatilho 10%, combinação 10%, extra grátis 10%, Joker 8%; ≈67% das rodadas pagam algo com o sorteio assistido (eram ≈26%), com maior variação. O RTP não muda: o preço da extra sobe (fator) para compensar.

## 4. Limites conhecidos (leia antes de usar os números)
1. **Erro estatístico**: com 84 mil rodadas a calibração tem incerteza de cerca de ±1,5 ponto percentual (as figuras de 350× a 1500× são raras). Uma amostra independente de 12 mil rodadas deu 95% (aposta 8) e 99% (aposta 20) para o alvo de 92%, dentro do esperado para esse tamanho.
2. **Aposta pequena**: com o mínimo de 1 crédito por extra, apostas de 1–3 créditos por cartela pagam preços acima do justo; com aposta 1 o RTP medido cai para ≈67% (alvo 92%). A calibração vale para apostas a partir de ≈6.
3. **Estratégia**: quem nunca compra extras recebe ≈15,5% em figuras (4 cartelas, 30 bolas) mais o bônus das 30 bolas (uma parte dos ≈19,5% medidos); quem compra todas, o alvo. Para retenções até 16% o fator é < 1 (cada extra custa menos que seu valor esperado, então comprar costuma compensar); acima disso o fator passa de 1 e o jogador paga um pouco mais que o valor esperado de cada bola.
4. O retorno dos acumulados Mini/Minor/Major está dentro do bônus e não foi medido separadamente.
5. Mudar tabela, probabilidades de bônus (`color_chance`, `trigger_chance`…), `free_chance`, `joker_chance` ou o valor-base **exige recalibrar**: rodar os passos de `tools/calibrate.gd`.

## 5. Como recalibrar
```
Godot --path . --no-window --script tools/calibrate.gd -- mode=sim rounds=30000 bet=8 seed=1 out=sim1.json
Godot --path . --no-window --script tools/calibrate.gd -- mode=sim rounds=30000 bet=8 seed=2 out=sim2.json
Godot --path . --no-window --script tools/calibrate.gd -- mode=solve in=sim1.json,sim2.json write=1
```
O último comando regrava `scripts/math_profile.gd`. Cada 17.000 rodadas levam ≈70 s em um núcleo.

## 6. Bônus (resumo)
Slot 5×3 (5×6 com o cofre vermelho; 3 giros, 5 com o azul); 3/4/5 iguais da esquerda pagam 1×/3×/7× o valor-base por linha (linha forçada em ~28% dos painéis; ver layout-e-extras.md); verde multiplica por 2/3/5/10 e habilita os acumulados, com chance `compartilhamento × valor-base ÷ valor do acumulado` (Mini 15%, Minor 10%, Major 10% do valor-base por giro verde, em média).
