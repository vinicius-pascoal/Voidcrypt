import 'package:flutter/material.dart';

import '../game/game_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF25183A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD7AA5E).withValues(alpha: 0.82),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'VOIDCRYPT',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                        color: const Color(0xFFFFE8C2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Explore salas geradas proceduralmente e sobreviva as sombras.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFFFE8C2),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            transitionDuration: const Duration(
                              milliseconds: 550,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  return const GamePage();
                                },
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  final curved = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  );

                                  return FadeTransition(
                                    opacity: curved,
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Iniciar Jogo'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                  onPressed: () => Navigator.of(context).pop(),
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
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
