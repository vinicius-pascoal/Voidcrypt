import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'models.dart';
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

  IconData _relicIcon(RelicType relic) {
    switch (relic) {
      case RelicType.longReach:
        return Icons.compare_arrows_rounded;
      case RelicType.criticalEdge:
        return Icons.bolt_rounded;
      case RelicType.vitalityCore:
        return Icons.favorite_rounded;
    }
  }

  Widget _rewardOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Escolha sua recompensa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Piso ${_controller.floor}: selecione uma reliquia passiva.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (
                        int i = 0;
                        i < _controller.pendingRewards.length;
                        i++
                      )
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 8,
                              right: i == _controller.pendingRewards.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: FilledButton(
                              onPressed: () => _controller.chooseReward(i),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _relicIcon(
                                      _controller.pendingRewards[i].relic,
                                    ),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _controller.pendingRewards[i].title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _controller.pendingRewards[i].description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
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
                  if (_controller.isAwaitingRewardChoice)
                    _rewardOverlay(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
