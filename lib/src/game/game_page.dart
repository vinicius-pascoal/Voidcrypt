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
                      hp: _controller.hp,
                      maxHp: _controller.maxHp,
                      floor: _controller.floor,
                      shards: _controller.shards,
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
