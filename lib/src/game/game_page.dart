import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'widgets/control_panel.dart';
import 'widgets/game_board.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController()..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.map.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statChip(
                              Icons.favorite_rounded,
                              'HP ${_controller.hp}/${_controller.maxHp}',
                            ),
                            _statChip(
                              Icons.layers_rounded,
                              'Piso ${_controller.floor}',
                            ),
                            _statChip(
                              Icons.diamond_rounded,
                              'Shards ${_controller.shards}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B121B),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio:
                                    GameController.visibleCols /
                                    GameController.visibleRows,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: GameBoard(controller: _controller),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: ControlPanel(
                      onUp: () => _controller.movePlayer(0, -1),
                      onDown: () => _controller.movePlayer(0, 1),
                      onLeft: () => _controller.movePlayer(-1, 0),
                      onRight: () => _controller.movePlayer(1, 0),
                      onAttack: _controller.attack,
                      onWait: _controller.waitTurn,
                      onRestart: _controller.startNewRun,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
