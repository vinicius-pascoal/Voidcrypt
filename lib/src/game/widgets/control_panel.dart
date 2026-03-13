import 'dart:math';

import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int stamina;
  final int maxStamina;
  final int floor;
  final int shards;

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onAttack;
  final VoidCallback onWait;
  final VoidCallback onRestart;

  const ControlPanel({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.stamina,
    required this.maxStamina,
    required this.floor,
    required this.shards,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onAttack,
    required this.onWait,
    required this.onRestart,
  });

  Widget _directionButton(
    IconData icon,
    VoidCallback onPressed, {
    double size = 64,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF1C2633),
        ),
        child: Icon(icon, size: size * 0.5),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }

  Widget _iconControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF1C2633),
        ),
        child: Icon(icon, size: size * 0.44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final veryCompact = constraints.maxHeight < 430;
          final controlWidth = min(
            constraints.maxWidth,
            compact ? 320.0 : 420.0,
          );
          final targetGap = compact ? 8.0 : 10.0;
          final horizontalGap = min(targetGap, max(2.0, controlWidth * 0.05));
          final maxButtonByWidth = (controlWidth - (horizontalGap * 2)) / 3;
          final dpadSize = min(
            compact ? 54.0 : 68.0,
            max(24.0, maxButtonByWidth),
          );
          final showRestartLabel = controlWidth >= 170;
          final restartButtonWidth = showRestartLabel
              ? min(controlWidth, max(120.0, dpadSize * 2.2))
              : dpadSize;

          Widget cluster() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: restartButtonWidth,
                  height: compact ? 40 : 44,
                  child: showRestartLabel
                      ? OutlinedButton.icon(
                          onPressed: onRestart,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reiniciar'),
                        )
                      : OutlinedButton(
                          onPressed: onRestart,
                          child: const Icon(Icons.restart_alt_rounded),
                        ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconControlButton(
                      icon: Icons.gavel_rounded,
                      onPressed: onAttack,
                      size: dpadSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _directionButton(
                      Icons.keyboard_arrow_up_rounded,
                      onUp,
                      size: dpadSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _iconControlButton(
                      icon: Icons.hourglass_bottom_rounded,
                      onPressed: onWait,
                      size: dpadSize,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _directionButton(
                      Icons.keyboard_arrow_left_rounded,
                      onLeft,
                      size: dpadSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _directionButton(
                      Icons.keyboard_arrow_down_rounded,
                      onDown,
                      size: dpadSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _directionButton(
                      Icons.keyboard_arrow_right_rounded,
                      onRight,
                      size: dpadSize,
                    ),
                  ],
                ),
              ],
            );
          }

          final title = Text(
            'Voidcrypt',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip(Icons.favorite_rounded, 'HP $hp/$maxHp'),
              _statChip(
                Icons.local_fire_department_rounded,
                'STA $stamina/$maxStamina',
              ),
              _statChip(Icons.layers_rounded, 'Piso $floor'),
              _statChip(Icons.diamond_rounded, 'Shards $shards'),
            ],
          );

          if (veryCompact) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    stats,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(width: controlWidth, child: cluster()),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 10),
              stats,
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: controlWidth, child: cluster()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
