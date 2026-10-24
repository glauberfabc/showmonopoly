# Show Monopoly — documentação spec-driven

A especificação vem primeiro: cada comportamento do jogo tem um identificador `REQ-*` em `02-requisitos.md`, um desenho em `04-design-tecnico.md`, e um teste (ou verificação visual) listado em `07-rastreabilidade.md`. Mudou uma regra? Altere o requisito, depois o código, depois o teste — nessa ordem.

| Arquivo | Conteúdo |
|---|---|
| `01-visao-e-decisoes.md` | Objetivo, escopo, decisões de projeto (DEC-*) e o que ainda precisa de confirmação |
| `02-requisitos.md` | Requisitos verificáveis (REQ-*) |
| `03-matematica-e-retencao.md` | Paytable, probabilidades exatas, modelo de preço da extra, calibração da retenção e resultados |
| `04-design-tecnico.md` | Arquitetura, arquivos, máquina de estados, coordenadas de tela, persistência |
| `05-ui-animacao.md` | Menu in-game, calculadora, menu do operador, 1 ou 2 telas, bolas 3D, logo e personagens |
| `06-plano-de-tarefas.md` | Tarefas, estado e itens em aberto |
| `07-rastreabilidade.md` | Matriz requisito → código → teste |

Fluxo de trabalho: editar `docs/` → editar `scripts/` → `tests/run.ps1 -Godot <caminho>` → exportar o preset **Web** → conferir no navegador.
