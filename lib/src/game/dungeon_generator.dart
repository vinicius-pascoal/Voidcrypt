import 'dart:math';

import 'models.dart';

class DungeonGenerator {
  final Random _random;
  int _nextEnemyId = 1;
  int _nextLootId = 1;

  DungeonGenerator({int? seed})
    : _random = seed == null ? Random() : Random(seed);

  FloorData generate({
    required int width,
    required int height,
    required int floor,
  }) {
    final tiles = List.generate(
      height,
      (_) => List.generate(width, (_) => TileType.wall),
    );

    final roomCount = 6 + min(5, floor);
    final rooms = <_Rect>[];

    for (
      int attempt = 0;
      attempt < 120 && rooms.length < roomCount;
      attempt++
    ) {
      final roomWidth = _random.nextInt(5) + 4;
      final roomHeight = _random.nextInt(4) + 4;
      final x = _random.nextInt(max(1, width - roomWidth - 2)) + 1;
      final y = _random.nextInt(max(1, height - roomHeight - 2)) + 1;

      final room = _Rect(x, y, roomWidth, roomHeight);
      final overlaps = rooms.any((r) => r.intersects(room.inflate(1)));

      if (overlaps) {
        continue;
      }

      rooms.add(room);
      _carveRoom(tiles, room);

      if (rooms.length > 1) {
        final previous = rooms[rooms.length - 2].center;
        final current = room.center;

        if (_random.nextBool()) {
          _carveHorizontal(tiles, previous.x, current.x, previous.y);
          _carveVertical(tiles, previous.y, current.y, current.x);
        } else {
          _carveVertical(tiles, previous.y, current.y, previous.x);
          _carveHorizontal(tiles, previous.x, current.x, current.y);
        }
      }
    }

    if (rooms.isEmpty) {
      final fallback = _Rect(2, 2, width - 4, height - 4);
      rooms.add(fallback);
      _carveRoom(tiles, fallback);
    }

    final playerStart = rooms.first.center;
    final exit = rooms.last.center;
    tiles[exit.y][exit.x] = TileType.exit;

    final freeCells = _collectFreeCells(tiles)
      ..remove(playerStart)
      ..remove(exit);

    freeCells.shuffle(_random);

    final enemyCount = min(18, 3 + floor * 2);
    final enemies = <EnemyEntity>[];

    for (int i = 0; i < enemyCount && freeCells.isNotEmpty; i++) {
      final position = freeCells.removeLast();
      if (_distance(position, playerStart) < 5) {
        continue;
      }

      enemies.add(EnemyEntity(id: _nextEnemyId++, position: position));
    }

    final lootCount = min(12, 2 + floor * 2);
    final loot = <LootDrop>[];

    for (int i = 0; i < lootCount && freeCells.isNotEmpty; i++) {
      final position = freeCells.removeLast();
      final type = _random.nextInt(100) < 40
          ? LootType.essence
          : LootType.shard;
      loot.add(LootDrop(id: _nextLootId++, type: type, position: position));
    }

    return FloorData(
      tiles: tiles,
      playerStart: playerStart,
      exit: exit,
      enemies: enemies,
      loot: loot,
    );
  }

  int _distance(Point<int> a, Point<int> b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  void _carveRoom(List<List<TileType>> tiles, _Rect room) {
    for (int y = room.y; y < room.y + room.height; y++) {
      for (int x = room.x; x < room.x + room.width; x++) {
        tiles[y][x] = TileType.floor;
      }
    }
  }

  void _carveHorizontal(List<List<TileType>> tiles, int x1, int x2, int y) {
    final from = min(x1, x2);
    final to = max(x1, x2);

    for (int x = from; x <= to; x++) {
      tiles[y][x] = TileType.floor;
    }
  }

  void _carveVertical(List<List<TileType>> tiles, int y1, int y2, int x) {
    final from = min(y1, y2);
    final to = max(y1, y2);

    for (int y = from; y <= to; y++) {
      tiles[y][x] = TileType.floor;
    }
  }

  List<Point<int>> _collectFreeCells(List<List<TileType>> tiles) {
    final cells = <Point<int>>[];

    for (int y = 0; y < tiles.length; y++) {
      for (int x = 0; x < tiles[y].length; x++) {
        if (tiles[y][x] == TileType.floor) {
          cells.add(Point<int>(x, y));
        }
      }
    }

    return cells;
  }
}

class _Rect {
  final int x;
  final int y;
  final int width;
  final int height;

  const _Rect(this.x, this.y, this.width, this.height);

  Point<int> get center => Point(x + width ~/ 2, y + height ~/ 2);

  _Rect inflate(int amount) {
    return _Rect(
      x - amount,
      y - amount,
      width + amount * 2,
      height + amount * 2,
    );
  }

  bool intersects(_Rect other) {
    return x < other.x + other.width &&
        x + width > other.x &&
        y < other.y + other.height &&
        y + height > other.y;
  }
}
