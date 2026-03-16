import 'dart:math';

import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onAttack;
  final VoidCallback onWait;

  const ControlPanel({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onAttack,
    required this.onWait,
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

          Widget cluster() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
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
