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

  Widget _floatingItemButton({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFF162436),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B6D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

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

  IconData _consumableIcon(ConsumableType consumable) {
    switch (consumable) {
      case ConsumableType.potion:
        return Icons.medication_rounded;
      case ConsumableType.bomb:
        return Icons.whatshot_rounded;
      case ConsumableType.temporalShield:
        return Icons.shield_rounded;
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

  Widget _shopOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF101B2A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Loja entre pisos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shards disponiveis: ${_controller.shards}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (
                        int i = 0;
                        i < _controller.pendingShopItems.length;
                        i++
                      )
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 8,
                              right:
                                  i == _controller.pendingShopItems.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: OutlinedButton(
                              onPressed: () => _controller.buyShopItem(i),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 10,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _consumableIcon(
                                      _controller
                                          .pendingShopItems[i]
                                          .consumable,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _controller.pendingShopItems[i].title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _controller.pendingShopItems[i].description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_controller.pendingShopItems[i].cost} shards',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _controller.continueAfterShop,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continuar para o proximo piso'),
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
                          stamina: _controller.stamina,
                          maxStamina: _controller.maxStamina,
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
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Row(
                      children: [
                        _floatingItemButton(
                          icon: Icons.medication_rounded,
                          count: _controller.potions,
                          onPressed: _controller.usePotion,
                        ),
                        const SizedBox(width: 8),
                        _floatingItemButton(
                          icon: Icons.whatshot_rounded,
                          count: _controller.bombs,
                          onPressed: _controller.useBomb,
                        ),
                        const SizedBox(width: 8),
                        _floatingItemButton(
                          icon: Icons.shield_rounded,
                          count: _controller.temporalShields,
                          onPressed: _controller.useTemporalShield,
                        ),
                      ],
                    ),
                  ),
                  if (_controller.isAwaitingRewardChoice)
                    _rewardOverlay(context),
                  if (_controller.isAwaitingShopChoice) _shopOverlay(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
