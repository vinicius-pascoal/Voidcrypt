import 'dart:math';

import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onAttack;
  final VoidCallback onWait;
  final int potions;
  final int bombs;
  final int temporalShields;
  final VoidCallback onUsePotion;
  final VoidCallback onUseBomb;
  final VoidCallback onUseTemporalShield;

  const ControlPanel({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onAttack,
    required this.onWait,
    required this.potions,
    required this.bombs,
    required this.temporalShields,
    required this.onUsePotion,
    required this.onUseBomb,
    required this.onUseTemporalShield,
  });

  Widget _itemButton({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFF162436),
            ),
            child: Icon(icon, size: size * 0.48),
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
          final itemSize = min(dpadSize, compact ? 44.0 : 48.0);

          Widget cluster() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _itemButton(
                      icon: Icons.medication_rounded,
                      count: potions,
                      onPressed: onUsePotion,
                      size: itemSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _itemButton(
                      icon: Icons.whatshot_rounded,
                      count: bombs,
                      onPressed: onUseBomb,
                      size: itemSize,
                    ),
                    SizedBox(width: horizontalGap),
                    _itemButton(
                      icon: Icons.shield_rounded,
                      count: temporalShields,
                      onPressed: onUseTemporalShield,
                      size: itemSize,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
