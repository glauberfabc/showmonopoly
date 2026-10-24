# Acervo de sons e efeitos dos cofres

Atualização Dragon: 86 trechos do primeiro HAR e 107 arquivos do HAR “dragon mais legal som”, totalizando 592 entradas. O segundo grupo aparece como Dragon Mais Legal; WebM é remuxado para OGG sem recompressão, com somente a faixa de áudio. Todos os 107 arquivos foram decodificados com ffmpeg sem erros. Os extratores podem ser executados novamente sem duplicar entradas. Para publicar apenas o acervo, usar `tools/vps_manage.py deploy --host 2.25.190.121 --replace --audio-only`.

A página `sounds.html` oferece busca, filtro por origem, reprodução exclusiva, volume e parada. O catálogo tem 399 entradas em 12 categorias, incluindo Ace Base, Triple Bonus, Potion Master, Show Ball e Pachinko. Os sprites do Potion Master usam os intervalos originais; os Ogg dos PCKs são reconstruídos a partir dos pacotes e posições de amostra originais.

Para reconstruir: `python tools/build_audio_library.py`. As capturas HAR permanecem locais; somente áudios, catálogo e página entram na publicação. A exportação Godot não remove esses arquivos.

A pipoqueira usa velocidade angular 11 durante o sorteio e 3 em repouso (antes 5 e 0,8). Cada bola coletada agenda um efeito no cofre correspondente: trajetória de 0,45 segundo com desaceleração, 11 moedas com impulso, rotação, gravidade e desaparecimento gradual. O som `insert_coin` tem seis vozes dedicadas para não ser cortado pelo som das bolas. O efeito continua na entrada do bônus e respeita a opção de som.

Validação: 150 rodadas automatizadas sem falhas; exportação Web sem erros; reprodução no navegador de Potion Master, Triple Bonus e Ace Base; verificação de duração e existência de todos os áudios em `tests/audio-library-verification.json`.
