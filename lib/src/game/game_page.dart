import 'dart:math';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'models.dart';
import '../menu/main_menu_page.dart';
import 'widgets/control_panel.dart';
import 'widgets/game_board.dart';

class GamePage extends StatefulWidget {
  final GameDifficulty difficulty;
  final PlayerClass playerClass;
  final RunSnapshot? resumeSnapshot;

  const GamePage({
    super.key,
    this.difficulty = GameDifficulty.normal,
    this.playerClass = PlayerClass.slimeRogue,
    this.resumeSnapshot,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameController _controller;
  bool _isPaused = false;
  static const Color _surfaceMain = Color(0xFF221635);
  static const Color _surfaceSoft = Color(0xFF2C1E46);
  static const Color _goldBorder = Color(0xFFD7AA5E);
  static const Color _goldText = Color(0xFFFFE8C2);

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _resumeFromPause() {
    setState(() {
      _isPaused = false;
    });
  }

  void _restartFromPause() {
    _controller.startNewRun();
    setState(() {
      _isPaused = false;
    });
  }

  void _exitFromPause() {
    setState(() {
      _isPaused = false;
    });

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainMenuPage()),
    );
  }

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
    final canPause =
        !_controller.isGameOver &&
        !_controller.isAwaitingRewardChoice &&
        !_controller.isAwaitingShopChoice;

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
                _statChip(
                  Icons.bubble_chart_rounded,
                  _playerClassLabel(_controller.playerClass),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canPause ? _togglePause : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Voidcrypt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _goldText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0D0817).withValues(alpha: 0.78),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Jogo Pausado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _goldText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _resumeFromPause,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Retomar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _restartFromPause,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reiniciar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _exitFromPause,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  String _playerClassAbilityLabel(PlayerClass playerClass) {
    switch (playerClass) {
      case PlayerClass.slimeRogue:
        return 'Dash';
      case PlayerClass.slimeGuardian:
        return 'Casca';
      case PlayerClass.slimeSpitter:
        return 'Cuspe';
      case PlayerClass.slimeMage:
        return 'Nova';
    }
  }

  IconData _playerClassAbilityIcon(PlayerClass playerClass) {
    switch (playerClass) {
      case PlayerClass.slimeRogue:
        return Icons.double_arrow_rounded;
      case PlayerClass.slimeGuardian:
        return Icons.shield_moon_rounded;
      case PlayerClass.slimeSpitter:
        return Icons.blur_circular_rounded;
      case PlayerClass.slimeMage:
        return Icons.auto_awesome_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFFE8D3AE))),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFF3DC),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _gameOverOverlay(BuildContext context) {
    final summary = _controller.lastRunSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0D0817).withValues(alpha: 0.82),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 520;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: constraints.maxHeight * 0.88,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(isCompactHeight ? 14 : 20),
                  decoration: BoxDecoration(
                    color: _surfaceMain,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _goldBorder.withValues(alpha: 0.9),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Game Over',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: isCompactHeight ? 30 : null,
                                fontWeight: FontWeight.w800,
                                color: _goldText,
                              ),
                        ),
                        SizedBox(height: isCompactHeight ? 8 : 12),
                        _summaryRow(
                          'Dificuldade',
                          _difficultyLabel(summary.difficulty),
                        ),
                        const SizedBox(height: 6),
                        _summaryRow('Piso alcancado', '${summary.floor}'),
                        const SizedBox(height: 6),
                        _summaryRow('Kills', '${summary.kills}'),
                        const SizedBox(height: 6),
                        _summaryRow('Tempo', _formatDuration(summary.duration)),
                        const SizedBox(height: 6),
                        _summaryRow('Loot coletado', '${summary.loot}'),
                        const SizedBox(height: 6),
                        _summaryRow('Shards finais', '${summary.shards}'),
                        SizedBox(height: isCompactHeight ? 12 : 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _controller.startNewRun,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Nova Run'),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size.fromHeight(
                                    isCompactHeight ? 42 : 48,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exitFromPause,
                                icon: const Icon(Icons.exit_to_app_rounded),
                                label: const Text('Voltar ao Menu'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.fromHeight(
                                    isCompactHeight ? 42 : 48,
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
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      difficulty: widget.resumeSnapshot?.difficulty ?? widget.difficulty,
      playerClass: widget.resumeSnapshot?.playerClass ?? widget.playerClass,
      resumeSnapshot: widget.resumeSnapshot,
    )..start();
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final cardWidth = ((totalWidth - 16) / 3).clamp(170.0, 280.0);

                  return Column(
                    children: [
                      Expanded(
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
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: _goldText),
                              ),
                              const SizedBox(height: 10),
                              _shopFeedbackBanner(),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (
                                    int i = 0;
                                    i < _controller.pendingShopItems.length;
                                    i++
                                  )
                                    SizedBox(
                                      width: cardWidth,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _controller.buyShopItem(i),
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
                                              _controller
                                                  .pendingShopItems[i]
                                                  .title,
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
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _controller.continueAfterShop,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Continuar para o proximo piso'),
                      ),
                    ],
                  );
                },
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
                  TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'damage-shake-${_controller.damageFlashTick}',
                    ),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final intensity = 1 - value;
                      final shakeX = sin(value * pi * 12) * intensity * 13;
                      final shakeY = cos(value * pi * 14) * intensity * 5.4;
                      return Transform.translate(
                        offset: Offset(shakeX, shakeY),
                        child: child,
                      );
                    },
                    child: IgnorePointer(
                      ignoring: _isPaused || _controller.isGameOver,
                      child: Column(
                        children: [
                          _topHud(),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(
                                      'hit-stop-board-${_controller.hitStopTick}',
                                    ),
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 110),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      final compress = (1 - value) * 0.028;
                                      return Transform.translate(
                                        offset: Offset(0, (1 - value) * 2.4),
                                        child: Transform.scale(
                                          scale: 1 - compress,
                                          alignment: Alignment.center,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _surfaceMain,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: _goldBorder.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: SizedBox.expand(
                                          child: GameBoard(
                                            controller: _controller,
                                          ),
                                        ),
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
                                    onUseClassAbility:
                                        _controller.useClassAbility,
                                    classAbilityEnabled:
                                        _controller.canUseClassAbility,
                                    classAbilityLabel: _playerClassAbilityLabel(
                                      _controller.playerClass,
                                    ),
                                    classAbilityIcon: _playerClassAbilityIcon(
                                      _controller.playerClass,
                                    ),
                                    classAbilityCooldown:
                                        _controller.classAbilityCooldown,
                                    potions: _controller.potions,
                                    bombs: _controller.bombs,
                                    temporalShields:
                                        _controller.temporalShields,
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
                    ),
                  ),
                  if (_controller.isAwaitingRewardChoice)
                    _rewardOverlay(context),
                  if (_controller.isAwaitingShopChoice) _shopOverlay(context),
                  if (_controller.isGameOver) _gameOverOverlay(context),
                  if (_isPaused) _pauseOverlay(context),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'damage-flash-${_controller.damageFlashTick}',
                        ),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final opacity = (1 - value) * 0.23;
                          return Container(
                            color: const Color(
                              0xFFFF425E,
                            ).withValues(alpha: opacity),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'hit-stop-flash-${_controller.hitStopTick}',
                        ),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 85),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          final opacity = (1 - value) * 0.16;
                          return Container(
                            color: Colors.white.withValues(alpha: opacity),
                          );
                        },
                      ),
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
