import 'dart:math';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../models.dart';

class GameBoard extends StatelessWidget {
  final GameController controller;

  const GameBoard({super.key, required this.controller});

  Color _tileColor(TileType tile) {
    switch (tile) {
      case TileType.wall:
        return const Color(0xFF2B3340);
      case TileType.floor:
        return const Color(0xFF111A24);
      case TileType.exit:
        return const Color(0xFF15382E);
    }
  }

  IconData _lootIcon(LootType type) {
    switch (type) {
      case LootType.essence:
        return Icons.favorite_rounded;
      case LootType.shard:
        return Icons.diamond_rounded;
    }
  }

  Color _lootColor(LootType type) {
    switch (type) {
      case LootType.essence:
        return const Color(0xFFFF7A9C);
      case LootType.shard:
        return const Color(0xFF6FD5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = controller.viewportOrigin();
    final startCol = origin.dx.toInt();
    final startRow = origin.dy.toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / GameController.visibleCols;
        final cellHeight = constraints.maxHeight / GameController.visibleRows;
        final iconSize = min(cellWidth, cellHeight) * 0.52;

        final lootByPosition = {
          for (final drop in controller.loot) drop.position: drop,
        };

        final children = <Widget>[];

        for (int row = 0; row < GameController.visibleRows; row++) {
          for (int col = 0; col < GameController.visibleCols; col++) {
            final mapX = startCol + col;
            final mapY = startRow + row;
            final pos = Point(mapX, mapY);
            final tile = controller.map[mapY][mapX];
            final loot = lootByPosition[pos];

            children.add(
              Positioned(
                left: col * cellWidth,
                top: row * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: _tileColor(tile),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (tile == TileType.exit)
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: iconSize,
                            color: const Color(0xFF72F0B5),
                          ),
                        if (loot != null)
                          Icon(
                            _lootIcon(loot.type),
                            size: iconSize * 0.66,
                            color: _lootColor(loot.type),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }

        final playerLeft = (controller.player.x - startCol) * cellWidth;
        final playerTop = (controller.player.y - startRow) * cellHeight;

        children.add(
          AnimatedPositioned(
            key: const ValueKey('player-entity'),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            left: playerLeft,
            top: playerTop,
            width: cellWidth,
            height: cellHeight,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Center(
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF69A8FF),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: iconSize * 0.68,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );

        for (final enemy in controller.enemies) {
          final left = (enemy.position.x - startCol) * cellWidth;
          final top = (enemy.position.y - startRow) * cellHeight;

          children.add(
            AnimatedPositioned(
              key: ValueKey('enemy-${enemy.id}'),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              width: cellWidth,
              height: cellHeight,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC24BFF),
                    ),
                    child: Icon(
                      Icons.blur_on_rounded,
                      size: iconSize * 0.72,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            controller.movePlayer(velocity > 0 ? 1 : -1, 0);
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            controller.movePlayer(0, velocity > 0 ? 1 : -1);
          },
          child: Stack(children: children),
        );
      },
    );
  }
}
