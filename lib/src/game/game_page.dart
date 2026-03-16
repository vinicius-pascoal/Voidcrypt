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
  static const Color _surfaceMain = Color(0xFF221635);
  static const Color _surfaceSoft = Color(0xFF2C1E46);
  static const Color _goldBorder = Color(0xFFD7AA5E);
  static const Color _goldText = Color(0xFFFFE8C2);

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldBorder.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _goldText),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _goldText)),
        ],
      ),
    );
  }

  Widget _topHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceMain,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldBorder.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip(
                  Icons.favorite_rounded,
                  'HP ${_controller.hp}/${_controller.maxHp}',
                ),
                _statChip(
                  Icons.local_fire_department_rounded,
                  'STA ${_controller.stamina}/${_controller.maxStamina}',
                ),
                _statChip(Icons.layers_rounded, 'Piso ${_controller.floor}'),
                _statChip(
                  Icons.diamond_rounded,
                  'Shards ${_controller.shards}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Voidcrypt',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: _goldText,
            ),
          ),
        ],
      ),
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

  Widget _shopFeedbackBanner() {
    final message = _controller.shopFeedbackMessage;
    final hasFeedback = message.isNotEmpty;
    final isSuccess = hasFeedback && !_controller.shopFeedbackIsError;
    final isError = hasFeedback && _controller.shopFeedbackIsError;

    if (!hasFeedback) {
      return const SizedBox(height: 54);
    }

    final bgColor = isSuccess
        ? const Color(0xFF284A36).withValues(alpha: 0.86)
        : const Color(0xFF5A2431).withValues(alpha: 0.9);
    final borderColor = isSuccess
        ? const Color(0xFF7AF2C0)
        : const Color(0xFFFF8FA7);
    final icon = isSuccess
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(message),
        constraints: const BoxConstraints(minHeight: 54),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.85)),
        ),
        child: Row(
          children: [
            Icon(icon, color: borderColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0D0817).withValues(alpha: 0.7),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surfaceMain,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _goldBorder.withValues(alpha: 0.9)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Escolha sua recompensa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _goldText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Piso ${_controller.floor}: selecione uma reliquia passiva.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: _goldText),
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
    final maxOverlayHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0D0817).withValues(alpha: 0.72),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 860,
              maxHeight: maxOverlayHeight,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surfaceMain,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _goldBorder.withValues(alpha: 0.9)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loja entre pisos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _goldText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shards disponiveis: ${_controller.shards}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _goldText),
                    ),
                    const SizedBox(height: 10),
                    _shopFeedbackBanner(),
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
                                      _controller
                                          .pendingShopItems[i]
                                          .description,
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
                  Column(
                    children: [
                      _topHud(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _surfaceMain,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: _goldBorder.withValues(alpha: 0.75),
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox.expand(
                                    child: GameBoard(controller: _controller),
                                  ),
                                ),
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
                                potions: _controller.potions,
                                bombs: _controller.bombs,
                                temporalShields: _controller.temporalShields,
                                onUsePotion: _controller.usePotion,
                                onUseBomb: _controller.useBomb,
                                onUseTemporalShield:
                                    _controller.useTemporalShield,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
