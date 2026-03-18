# Voidcrypt

Voidcrypt e um roguelike tatico em turnos feito com Flutter, com geracao procedural, progressao de run, combate com stamina, inimigos com comportamentos distintos e foco em feedback visual.

## Visao geral

- Plataforma: Flutter (Android, iOS, Web, Desktop)
- Genero: roguelike dungeon crawler em turnos
- Tema visual: dark fantasy com UI roxo+dourado
- Estado atual: jogavel com sistemas principais de combate, progressao e metajogo

## Funcionalidades implementadas

### 1. Progressao de run

- Reliquias passivas por piso:
	- +1 alcance de ataque
	- +10% chance de critico
	- +1 HP maximo (com cura)
- Escolha de recompensa ao concluir piso
- Mini-chefes a cada 3 pisos (a partir do piso 6)

### 2. Combate mais profundo

- Inimigos com IA distinta:
	- Pursuer (perseguidor)
	- Archer (ataque a distancia em linha)
	- Tank (mais resistente e ritmo diferente de avancar)
	- Summoner (invoca reforcos)
	- Boss (versao mais perigosa)
- Sistema de stamina:
	- Ataque forte consome mais stamina
	- Esperar recupera stamina
- Telegraph de dano inimigo com marcacao no tabuleiro
- Knockback em golpes corpo a corpo/fortes quando possivel
- Visao inimiga limitada por distancia e linha de visao

### 3. Loot e economia

- Loja entre pisos para gastar shards
- Consumiveis:
	- Pocao
	- Bomba
	- Escudo temporal
- Raridades de loot (comum, raro, epico) com brilho/cor
- Feedback visual de compra na loja (sucesso/erro)

### 4. Geracao procedural avancada

- Salas especiais:
	- Tesouro
	- Evento
	- Armadilha
	- Altar
- Conectividade com loops e rotas alternativas
- Distribuicao de inimigos/loot escalonada por piso

### 5. Feedback visual

- Camera shake ao receber dano
- Hit stop curto em ataques com impacto
- Particulas em:
	- Coleta de loot
	- Morte de inimigos
- Onda de choque local para reforcar eventos de impacto

### 6. UX e qualidade de vida

- Menu de pausa com:
	- Retomar
	- Reiniciar
	- Sair
- HUD superior com HP, STA, Piso e Shards
- Layout responsivo para menu inicial e game over (sem overflow)

### 7. Menu e apresentacao

- Continuar automaticamente da ultima run salva
- Selecao de dificuldade:
	- Normal
	- Hard
	- Nightmare
- Tela de game over com resumo da run:
	- Dificuldade
	- Piso alcancado
	- Kills
	- Tempo
	- Loot coletado
	- Shards finais

## Controles

### Painel de controles (UI)

- Movimento: cima, baixo, esquerda, direita
- Acao:
	- Atacar
	- Esperar
- Itens:
	- Pocao
	- Bomba
	- Escudo temporal

### Gestos no tabuleiro

- Arrastar horizontal/vertical para mover o personagem

## Dificuldade

- Normal: baseline
- Hard: inimigos mais resistentes e dano recebido aumentado
- Nightmare: mais pressao no combate (inclui stamina base menor)

## Persistencia de run

- O jogo salva automaticamente o estado da run localmente.
- Ao abrir o menu inicial:
	- Se houver run salva, o botao principal vira Continuar Run.
	- Voce ainda pode iniciar Nova Run com a dificuldade selecionada.

## Estrutura principal do projeto

- `lib/src/game/game_controller.dart`: estado da partida, turnos, IA, combate, persistencia e game over
- `lib/src/game/dungeon_generator.dart`: geracao procedural de mapas/salas
- `lib/src/game/game_page.dart`: tela principal, HUD, overlays e fluxo visual
- `lib/src/game/widgets/game_board.dart`: render do tabuleiro, sprites e efeitos visuais
- `lib/src/game/widgets/control_panel.dart`: controles e uso de itens
- `lib/src/menu/main_menu_page.dart`: menu inicial, dificuldade e continuar run
- `lib/src/game/models.dart`: modelos e enums do dominio

## Como executar

### Requisitos

- Flutter SDK compativel com o projeto
- Dart SDK compativel com o `pubspec.yaml`

### Passos

```bash
flutter pub get
flutter run
```

### Analise estatica

```bash
flutter analyze
```

## Assets

- Personagem com sprites direcionais
- Sprites direcionais para os tipos de inimigo
- Tiles de piso e muro
- Icones e recursos visuais em `assets/`

### Creditos de assets

- Todos os assets visuais do jogo foram criados usando https://www.pixellab.ai.

## Status do projeto

O projeto ja possui um loop principal robusto de gameplay (geracao, combate, progressao, economia, pausa, persistencia e game over) e esta pronto para iteracoes de balanceamento e expansao de conteudo.
