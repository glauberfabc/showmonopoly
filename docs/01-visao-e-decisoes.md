# 01 · Visão, escopo e decisões

## Objetivo
Bingo eletrônico de demonstração (Godot 3.6, exportado para Web) com quatro cartelas 3×5, universo de 90 números, 30 bolas iniciais e até 10 bolas extras, três cofres bônus e slot de bônus. **Todas as opções ficam dentro do jogo**: o painel HTML lateral foi removido; a página só contém a tela do jogo.

## Escopo desta versão (v2)
1. Abrir/fechar cada cartela e trocar os números de cada cartela (ou de todas).
2. Bola extra com preço calculado; **cancelar** a extra mostra as bolas que viriam, com X, até o próximo JOGAR.
3. Premiação exatamente pela tabela de 12 figuras, paga uma vez por figura e cartela, figuras diferentes somam.
4. Menu → calculadora funcional → código `913731` → menu do operador (retenção, valor do crédito, tipo de monitor, contabilidade).
5. Monitor vertical (1 tela) ou **2 telas** (superior = show; inferior = bolas e apostas).
6. Logo com brilho animado; personagens com profundidade independente do cenário; bolas coloridas 3D.

Fora de escopo: dinheiro real, depósitos/saques, certificação de RTP, servidor.

## Decisões (DEC)
| ID | Decisão | Motivo |
|---|---|---|
| DEC-01 | **Aposta = créditos por cartela** (1–20). Custo da rodada = aposta × cartelas abertas. | Abrir/fechar cartelas só faz sentido se o custo acompanhar. |
| DEC-02 | **Prêmio por cartela = figura × aposta daquela cartela.** | Atualizado em 11/10/2026: aposta 1, denominação R$ 0,10 e linha ×3 pagam R$ 0,30 por cartela premiada. Custo da rodada continua aposta × cartelas abertas. Base do slot permanece 4 × aposta. |
| DEC-03 | A **retenção** atua no **preço da bola extra** (fator calibrado por simulação). | Com a tabela confirmada, as 30 bolas devolvem só ~3,9% por cartela; o retorno vem das extras. Ver `03`. |
| DEC-04 | Acumulados Mini/Minor/Major mantêm os valores em reais da referência, mas a **chance** de cada um é proporcional ao valor-base. | Antes a chance fixa tornava o retorno esperado absurdo para apostas pequenas. |
| DEC-05 | O código `913731` é conferido no cliente. | Serve à demonstração; um ambiente regulado exige autenticação de servidor. |
| DEC-06 | Modo 2 telas: um único canvas dividido (superior 1197 px, faixa de 44 px, inferior 439 px). | Uma instância do jogo, sem sincronização entre janelas. Proporções configuráveis (`SPLIT_BASE`, `GAP`). |
| DEC-07 | Personagens e logo animados por **shader sobre a arte de fundo** (sem recortes separados). | A arte entregue é uma placa única. Veja limites em `05`. |

## Para confirmar com você
- DEC-01/02 (custo por cartela e valor-base 4×).
- Proporção/tamanho físico dos dois monitores (hoje: superior 1024×1197, inferior 1024×439 lógicos).
- Faixa de retenção oferecida (hoje 4% a 20%) e retenção inicial (8%).
- Se quiser os personagens realmente "soltos" do cenário, enviar PNGs separados (veja `05`).
