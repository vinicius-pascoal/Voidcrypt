import 'dart:math';

import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  static const Color _runeButtonBase = Color(0xFF4A3F35);
  static const Color _runeButtonRaised = Color(0xFF5D4E41);
  static const Color _runeBorder = Color(0xFFC89B5A);
  static const Color _runeIcon = Color(0xFFFFF4E3);
  static const Color _panelSurface = Color(0xFF25183A);

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onAttack;
  final VoidCallback onWait;
  final VoidCallback onUseClassAbility;
  final bool classAbilityEnabled;
  final String classAbilityLabel;
  final IconData classAbilityIcon;
  final int classAbilityCooldown;
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
    required this.onUseClassAbility,
    required this.classAbilityEnabled,
    required this.classAbilityLabel,
    required this.classAbilityIcon,
    required this.classAbilityCooldown,
    required this.potions,
    required this.bombs,
    required this.temporalShields,
    required this.onUsePotion,
    required this.onUseBomb,
    required this.onUseTemporalShield,
  });

  ButtonStyle _runeButtonStyle(Color background) {
    return FilledButton.styleFrom(
      padding: EdgeInsets.zero,
      backgroundColor: background,
      foregroundColor: _runeIcon,
      elevation: 2,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _runeBorder, width: 1.1),
      ),
    );
  }

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
            style: _runeButtonStyle(_runeButtonRaised),
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
                color: _runeBorder,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A221D), width: 0.8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A221D),
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
        style: _runeButtonStyle(_runeButtonBase),
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
        style: _runeButtonStyle(_runeButtonRaised),
        child: Icon(icon, size: size * 0.44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panelSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _runeBorder.withValues(alpha: 0.72)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final verticalGap = compact ? 8.0 : 12.0;
          final controlWidth = min(
            constraints.maxWidth,
            compact ? 320.0 : 420.0,
          );
          final targetGap = compact ? 8.0 : 10.0;
          final horizontalGap = min(targetGap, max(2.0, controlWidth * 0.05));
          final maxButtonByWidth = (controlWidth - (horizontalGap * 2)) / 3;
          final reservedHeight = compact ? 128.0 : 148.0;
          final maxButtonByHeight = max(
            24.0,
            (constraints.maxHeight - reservedHeight) / 2,
          );
          final dpadSize = min(
            min(compact ? 54.0 : 68.0, maxButtonByHeight),
            max(24.0, maxButtonByWidth),
          );
          final itemSize = min(dpadSize, compact ? 42.0 : 48.0);
          final abilityHeight = compact ? 38.0 : 42.0;

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
                SizedBox(height: verticalGap),
                SizedBox(
                  height: abilityHeight,
                  width: controlWidth,
                  child: FilledButton.icon(
                    onPressed: classAbilityEnabled ? onUseClassAbility : null,
                    style: _runeButtonStyle(_runeButtonRaised),
                    icon: Icon(classAbilityIcon, size: compact ? 15 : 17),
                    label: Text(
                      classAbilityCooldown > 0
                          ? '$classAbilityLabel (${classAbilityCooldown}t)'
                          : classAbilityLabel,
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: verticalGap),
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
                SizedBox(height: compact ? 6 : 8),
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
                child: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: controlWidth, child: cluster()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
