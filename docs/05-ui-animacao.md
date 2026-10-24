# 05 · Interface, menu e animações

## Tela principal (tudo dentro do jogo)
- **Faixa superior**: 12 figuras com valor; a figura que acabou de pagar pisca em branco/dourado por ~2,6 s.
- **Barra de botões** (sobre a arte): TROCAR TODAS · REGRAS · SOM · MENU.
- **Cada cartela**: FECHAR/ABRIR (esquerda) e TROCAR (direita) nos cantos do cabeçalho. Cartela fechada fica escurecida com "CARTELA FECHADA".
- **Painéis de bolas**: 30 bolas iniciais e 10 extras. A bola nova "salta" ao entrar. Slots vazios são encaixes escuros.
- **Extra**: o painel de extras é clicável e o chip "COMPRAR EXTRA · R$ …" mostra o preço antes da compra.
- **JOGAR** vira **CANCELAR EXTRA** enquanto há extras disponíveis.
- **Aposta**: − / + alteram a aposta por cartela; abaixo do número aparece "×N = total em R$".
- **Barra de status**: mensagem da rodada e **GANHO** acumulado conforme as bolas são reveladas.

### Bola extra cancelada (REQ-EXTRA-04/05)
Ao clicar CANCELAR EXTRA a rodada termina e as bolas restantes do baralho (até completar 10 extras) aparecem nos encaixes livres do painel de extras, em cores esmaecidas, com o número legível e um **X vermelho** por cima; o rótulo "BOLAS CANCELADAS" aparece sob o painel. Nada é pago ou cobrado. Elas permanecem — mesmo se o jogador fechar, abrir ou trocar cartelas — e **só desaparecem ao clicar em JOGAR**.

## Menu → calculadora → operador
1. **MENU** (disponível entre rodadas) abre uma calculadora com teclado na tela e teclado físico (0-9, + − × ÷, vírgula, Enter, Backspace, Delete, Esc).
2. Digitar **913731** (como últimos dígitos digitados, ou como entrada/resultado) abre o **MENU DO OPERADOR**:
   - **Retenção da casa** − / + (4%–20%), mostrando RTP-alvo e fator da extra; vale a partir da próxima rodada.
   - **Valor do crédito**: R$ 0,10 ou R$ 0,25.
   - **Monitor**: VERTICAL · 1 TELA ou 2 TELAS · CIMA/BAIXO (aplicado na hora).
   - **Contabilidade**: entradas, prêmios, RTP efetivo, rodadas, extras.
   - EXPLORAR BÔNUS (sem alterar saldo) · RECARREGAR CRÉDITOS · ZERAR CONTADORES · VOLTAR AO JOGO.
   Tudo é salvo automaticamente.

## Modo 2 telas
Superior (faixa de prêmios, logo, personagens, cofres, cartelas e globo — 1197 px lógicos) e inferior (bolas, extras, saldo, aposta, JOGAR — 439 px), separadas por uma faixa de 44 px que representa a moldura entre os monitores. No bônus a divisão sobe para y = 1275 (slots em cima; saldo e GIRAR embaixo). Os modais (regras, Joker, menu) cobrem as duas telas.

## Animações e efeitos
- **Logo** (`logo_shine.shader`, soma de luz): varredura diagonal a cada ~3,3 s, segunda faixa mais fina, pulsação suave e sete cintilações em estrela; atua só em tons quentes (dourado/vermelho), sem deformar letras.
- **Personagens** (`char_warp.shader`): em cada personagem, a imagem do recorte é amostrada com um deslocamento que combina **balanço** (mais forte na cabeça), **giro em torno do eixo vertical** (o centro do rosto se move mais que as bordas, como uma rotação), **respiração** e **aceno da mão**; uma máscara zera a deformação nas bordas do recorte e sobre a moldura dos acumulados, então o personagem se move "na frente" do cenário sem emendas.
  *Limite:* como o cenário e os personagens são uma única imagem, o fundo imediatamente ao redor se move junto, de forma sutil. Para independência total, forneça PNGs separados (cenário sem os personagens + um PNG transparente por personagem); o jogo passa a desenhar cada camada com parallax próprio.
- **Bolas 3D** (`ball_art.gd`): esferas geradas por código com luz difusa, brilho especular, luz de borda, reflexo inferior e disco claro para o número. Cinco cores para os números (1–18 amarelo, 19–36 laranja, 37–54 rosa, 55–72 turquesa, 73–90 lilás), três para as bolas coletadas dos cofres (verde, vermelho, azul, com aro dourado) e esferas das cores das cartelas como fichas de marcação.
- **Coletas**: bola colorida que acerta uma cartela voa em arco do globo ao cofre; o cofre pulsa enquanto há coleta.
- **Premiação**: borda dourada pulsante nas casas da figura, valor flutuante sobre a cartela e destaque na faixa.
