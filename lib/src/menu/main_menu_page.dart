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

  Future<void> _openGame({required bool forceNewRun}) async {
    final snapshot = forceNewRun ? null : _savedSnapshot;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GamePage(
            difficulty: _selectedDifficulty,
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
                          Container(
                            padding: EdgeInsets.all(isCompactHeight ? 10 : 12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Dificuldade',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: const Color(0xFFFFE8C2),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<GameDifficulty>(
                                  segments: const [
                                    ButtonSegment(
                                      value: GameDifficulty.normal,
                                      label: Text('Normal'),
                                    ),
                                    ButtonSegment(
                                      value: GameDifficulty.hard,
                                      label: Text('Hard'),
                                    ),
                                    ButtonSegment(
                                      value: GameDifficulty.nightmare,
                                      label: Text('Nightmare'),
                                    ),
                                  ],
                                  selected: {_selectedDifficulty},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _selectedDifficulty = selection.first;
                                    });
                                  },
                                ),
                                if (hasSavedRun) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Run salva detectada: piso ${_savedSnapshot!.floor} (${_difficultyLabel(_savedSnapshot!.difficulty)}).',
                                    style: const TextStyle(
                                      color: Color(0xFFE8D3AE),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isCompactHeight ? 10 : 14),
                          FilledButton.icon(
                            onPressed: _loadingSavedRun
                                ? null
                                : () => _openGame(forceNewRun: false),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              hasSavedRun ? 'Continuar Run' : 'Iniciar Jogo',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(buttonHeight),
                            ),
                          ),
                          if (hasSavedRun) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _loadingSavedRun
                                  ? null
                                  : () => _openGame(forceNewRun: true),
                              icon: const Icon(Icons.fiber_new_rounded),
                              label: const Text('Nova Run'),
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
