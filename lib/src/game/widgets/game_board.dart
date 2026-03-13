import 'dart:math';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../models.dart';

class GameBoard extends StatelessWidget {
  final GameController controller;

  static const List<String> _wallTileAssets = [
    'assets/tiles/tiles_muro/Tile_03.png',
    'assets/tiles/tiles_muro/Tile_04.png',
    'assets/tiles/tiles_muro/Tile_05.png',
    'assets/tiles/tiles_muro/Tile_06.png',
    'assets/tiles/tiles_muro/Tile_07.png',
    'assets/tiles/tiles_muro/Tile_09.png',
    'assets/tiles/tiles_muro/Tile_11.png',
    'assets/tiles/tiles_muro/Tile_13.png',
    'assets/tiles/tiles_muro/Tile_19.png',
    'assets/tiles/tiles_muro/Tile_23.png',
    'assets/tiles/tiles_muro/Tile_24.png',
    'assets/tiles/tiles_muro/Tile_26.png',
    'assets/tiles/tiles_muro/Tile_27.png',
    'assets/tiles/tiles_muro/Tile_28.png',
    'assets/tiles/tiles_muro/Tile_33.png',
    'assets/tiles/tiles_muro/Tile_37.png',
    'assets/tiles/tiles_muro/Tile_44.png',
    'assets/tiles/tiles_muro/Tile_48.png',
    'assets/tiles/tiles_muro/Tile_49.png',
    'assets/tiles/tiles_muro/Tile_51.png',
    'assets/tiles/tiles_muro/Tile_52.png',
    'assets/tiles/tiles_muro/Tile_53.png',
    'assets/tiles/tiles_muro/Tile_57.png',
    'assets/tiles/tiles_muro/Tile_58.png',
    'assets/tiles/tiles_muro/Tile_59.png',
    'assets/tiles/tiles_muro/Tile_60.png',
    'assets/tiles/tiles_muro/Tile_61.png',
    'assets/tiles/tiles_muro/Tile_65.png',
    'assets/tiles/tiles_muro/Tile_75.png',
    'assets/tiles/tiles_muro/Tile_77.png',
    'assets/tiles/tiles_muro/Tile_79.png',
    'assets/tiles/tiles_muro/Tile_80.png',
    'assets/tiles/tiles_muro/Tile_81.png',
    'assets/tiles/tiles_muro/Tile_86.png',
    'assets/tiles/tiles_muro/Tile_87.png',
    'assets/tiles/tiles_muro/Tile_88.png',
    'assets/tiles/tiles_muro/Tile_89.png',
    'assets/tiles/tiles_muro/Tile_91.png',
    'assets/tiles/tiles_muro/Tile_92.png',
    'assets/tiles/tiles_muro/Tile_93.png',
    'assets/tiles/tiles_muro/Tile_97.png',
    'assets/tiles/tiles_muro/Tile_98.png',
    'assets/tiles/tiles_muro/Tile_99.png',
    'assets/tiles/tiles_muro/Tile_101.png',
    'assets/tiles/tiles_muro/Tile_102.png',
    'assets/tiles/tiles_muro/Tile_105.png',
  ];

  static const List<String> _floorTileAssets = [
    'assets/tiles/tiles_piso/Tile_20.png',
    'assets/tiles/tiles_piso/Tile_21.png',
    'assets/tiles/tiles_piso/Tile_22.png',
    'assets/tiles/tiles_piso/Tile_34.png',
    'assets/tiles/tiles_piso/Tile_35.png',
    'assets/tiles/tiles_piso/Tile_36.png',
    'assets/tiles/tiles_piso/Tile_39.png',
    'assets/tiles/tiles_piso/Tile_46.png',
    'assets/tiles/tiles_piso/Tile_47.png',
    'assets/tiles/tiles_piso/Tile_72.png',
    'assets/tiles/tiles_piso/Tile_73.png',
    'assets/tiles/tiles_piso/Tile_74.png',
    'assets/tiles/tiles_piso/Tile_76.png',
    'assets/tiles/tiles_piso/Tile_82.png',
    'assets/tiles/tiles_piso/Tile_83.png',
    'assets/tiles/tiles_piso/Tile_84.png',
    'assets/tiles/tiles_piso/Tile_94.png',
    'assets/tiles/tiles_piso/Tile_95.png',
    'assets/tiles/tiles_piso/Tile_108.png',
  ];

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

  String _tileAssetPath(TileType tile, int x, int y) {
    final isWall = tile == TileType.wall;
    final list = isWall ? _wallTileAssets : _floorTileAssets;
    final salt = isWall ? 0x9E3779B9 : 0x7F4A7C15;

    final hash =
        ((x * 73856093) ^ (y * 19349663) ^ controller.mapVisualSeed ^ salt) &
        0x7fffffff;

    return list[hash % list.length];
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

  bool _isInside(int x, int y) {
    return y >= 0 &&
        y < controller.map.length &&
        x >= 0 &&
        x < controller.map[0].length;
  }

  bool _wallTouchesFloor(int x, int y) {
    final neighbors = <Point<int>>[
      Point<int>(x + 1, y),
      Point<int>(x - 1, y),
      Point<int>(x, y + 1),
      Point<int>(x, y - 1),
    ];

    for (final n in neighbors) {
      if (!_isInside(n.x, n.y)) continue;
      final tile = controller.map[n.y][n.x];
      if (tile == TileType.floor || tile == TileType.exit) {
        return true;
      }
    }

    return false;
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
            final visibleWall =
                tile != TileType.wall || _wallTouchesFloor(mapX, mapY);
            final tileAsset = visibleWall
                ? _tileAssetPath(tile, mapX, mapY)
                : null;

            children.add(
              Positioned(
                left: col * cellWidth,
                top: row * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: Padding(
                  padding: const EdgeInsets.all(0.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: visibleWall
                          ? _tileColor(tile)
                          : Colors.transparent,
                      border: visibleWall
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            )
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (tileAsset != null)
                          Positioned.fill(
                            child: Image.asset(
                              tileAsset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) {
                                return ColoredBox(color: _tileColor(tile));
                              },
                            ),
                          ),
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
