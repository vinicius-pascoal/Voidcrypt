import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/game_page.dart';
import '../game/models.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  GameDifficulty _selectedDifficulty = GameDifficulty.normal;
  PlayerClass _selectedPlayerClass = PlayerClass.slimeRogue;
  RunSnapshot? _savedSnapshot;
  bool _loadingSavedRun = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRun();
  }

  Future<void> _loadSavedRun() async {
    final snapshot = await GameController.loadSavedRun();
    if (!mounted) {
      return;
    }

    setState(() {
      _savedSnapshot = snapshot;
      _loadingSavedRun = false;
      if (snapshot != null) {
        _selectedDifficulty = snapshot.difficulty;
        _selectedPlayerClass = snapshot.playerClass;
      }
    });
  }

  String _difficultyLabel(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.normal:
        return 'Normal';
      case GameDifficulty.hard:
        return 'Hard';
      case GameDifficulty.nightmare:
        return 'Nightmare';
    }
  }

  String _playerClassLabel(PlayerClass playerClass) {
    switch (playerClass) {
      case PlayerClass.slimeRogue:
        return 'Slime Ladino';
      case PlayerClass.slimeGuardian:
        return 'Slime Guardiao';
      case PlayerClass.slimeSpitter:
        return 'Slime Acido';
      case PlayerClass.slimeMage:
        return 'Slime Mago';
    }
  }

  String _playerClassAbilityDescription(PlayerClass playerClass) {
    switch (playerClass) {
      case PlayerClass.slimeRogue:
        return 'Dash curto para atravessar espacos e reposicionar rapido.';
      case PlayerClass.slimeGuardian:
        return 'Casca defensiva que reduz pressao e recupera um pouco de vida.';
      case PlayerClass.slimeSpitter:
        return 'Disparo acido a distancia para enfraquecer alvos sem contato.';
      case PlayerClass.slimeMage:
        return 'Nova arcana em area para empurrar inimigos ao redor.';
    }
  }

  Future<void> _openGame({
    required bool forceNewRun,
    GameDifficulty? difficulty,
    PlayerClass? playerClass,
  }) async {
    final snapshot = forceNewRun ? null : _savedSnapshot;
    final runDifficulty = difficulty ?? _selectedDifficulty;
    final runPlayerClass = playerClass ?? _selectedPlayerClass;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GamePage(
            difficulty: runDifficulty,
            playerClass: runPlayerClass,
            resumeSnapshot: snapshot,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );

    await _loadSavedRun();
  }

  Future<void> _showNewGameSetupModal() async {
    GameDifficulty selectedDifficulty = _selectedDifficulty;
    PlayerClass selectedPlayerClass = _selectedPlayerClass;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final media = MediaQuery.of(context);
            final isShortHeight = media.size.height < 760;
            final textTheme = Theme.of(context).textTheme;

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isShortHeight ? 8 : 20,
              ),
              titlePadding: EdgeInsets.fromLTRB(
                20,
                isShortHeight ? 14 : 18,
                20,
                6,
              ),
              contentPadding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                isShortHeight ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                isShortHeight ? 10 : 12,
              ),
              title: const Text('Configurar Novo Jogo'),
              content: SizedBox(
                width: media.size.width > 560 ? 460 : media.size.width - 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dificuldade',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final difficulty in GameDifficulty.values)
                          ChoiceChip(
                            label: Text(_difficultyLabel(difficulty)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            selected: selectedDifficulty == difficulty,
                            onSelected: (_) {
                              setDialogState(() {
                                selectedDifficulty = difficulty;
                              });
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: isShortHeight ? 10 : 12),
                    Text(
                      'Classe Slime',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final playerClass in PlayerClass.values)
                          ChoiceChip(
                            label: Text(
                              _playerClassLabel(
                                playerClass,
                              ).replaceFirst('Slime ', ''),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            selected: selectedPlayerClass == playerClass,
                            onSelected: (_) {
                              setDialogState(() {
                                selectedPlayerClass = playerClass;
                              });
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: isShortHeight ? 8 : 10),
                    Container(
                      padding: EdgeInsets.all(isShortHeight ? 8 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B122C).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD7AA5E).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Habilidade (${_playerClassLabel(selectedPlayerClass)}): ${_playerClassAbilityDescription(selectedPlayerClass)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFFE8C2),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldStart != true || !mounted) {
      return;
    }

    setState(() {
      _selectedDifficulty = selectedDifficulty;
      _selectedPlayerClass = selectedPlayerClass;
    });

    await _openGame(
      forceNewRun: true,
      difficulty: selectedDifficulty,
      playerClass: selectedPlayerClass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedRun = _savedSnapshot != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF150B23), Color(0xFF231237), Color(0xFF341A4C)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 560;
              final cardHorizontalMargin = isCompactHeight ? 12.0 : 24.0;
              final cardVerticalMargin = isCompactHeight ? 10.0 : 18.0;
              final contentPadding = isCompactHeight ? 18.0 : 28.0;
              final titleSpacing = isCompactHeight ? 6.0 : 10.0;
              final sectionSpacing = isCompactHeight ? 14.0 : 22.0;
              final buttonHeight = isCompactHeight ? 46.0 : 54.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: cardHorizontalMargin,
                  vertical: cardVerticalMargin,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: contentPadding,
                        vertical: isCompactHeight ? 16 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25183A).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(
                            0xFFD7AA5E,
                          ).withValues(alpha: 0.82),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF000000,
                            ).withValues(alpha: 0.28),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'VOIDCRYPT',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontSize: isCompactHeight ? 34 : null,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isCompactHeight ? 2.0 : 2.4,
                                  color: const Color(0xFFFFE8C2),
                                ),
                          ),
                          SizedBox(height: titleSpacing),
                          Text(
                            'Explore salas geradas proceduralmente e sobreviva as sombras.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFFFFE8C2),
                                  height: isCompactHeight ? 1.2 : 1.35,
                                ),
                          ),
                          SizedBox(height: sectionSpacing),
                          if (_loadingSavedRun)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (hasSavedRun)
                            Container(
                              padding: EdgeInsets.all(
                                isCompactHeight ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B122C,
                                ).withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD7AA5E,
                                  ).withValues(alpha: 0.55),
                                ),
                              ),
                              child: Text(
                                'Run salva detectada: piso ${_savedSnapshot!.floor} (${_difficultyLabel(_savedSnapshot!.difficulty)} | ${_playerClassLabel(_savedSnapshot!.playerClass)}).',
                                style: const TextStyle(
                                  color: Color(0xFFE8D3AE),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          SizedBox(height: isCompactHeight ? 10 : 14),
                          if (hasSavedRun)
                            FilledButton.icon(
                              onPressed: _loadingSavedRun
                                  ? null
                                  : () => _openGame(forceNewRun: false),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Continuar Run'),
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(buttonHeight),
                              ),
                            ),
                          if (!hasSavedRun)
                            FilledButton.icon(
                              onPressed: _loadingSavedRun
                                  ? null
                                  : _showNewGameSetupModal,
                              icon: const Icon(Icons.rocket_launch_rounded),
                              label: const Text('Novo Jogo'),
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(buttonHeight),
                              ),
                            ),
                          if (hasSavedRun) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _loadingSavedRun
                                  ? null
                                  : _showNewGameSetupModal,
                              icon: const Icon(Icons.fiber_new_rounded),
                              label: const Text('Novo Jogo'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.fromHeight(
                                  isCompactHeight ? 44 : 48,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: isCompactHeight ? 8 : 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Como jogar'),
                                    content: const Text(
                                      'Use os controles a direita para mover, atacar e esperar turnos.\n\nColete loot para sobreviver e encontre a saida de cada piso.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Fechar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.help_outline_rounded),
                            label: const Text('Como jogar'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.fromHeight(
                                isCompactHeight ? 44 : 50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
