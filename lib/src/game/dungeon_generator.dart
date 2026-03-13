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

    final roomCount = 6 + min(6, floor);
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
    }

    if (rooms.isEmpty) {
      final fallback = _Rect(2, 2, width - 4, height - 4);
      rooms.add(fallback);
    }

    for (final room in rooms) {
      _carveRoom(tiles, room);
    }

    _connectRoomsWithLoops(tiles, rooms, floor);

    final playerStart = rooms.first.center;
    final exit = rooms.last.center;
    tiles[exit.y][exit.x] = TileType.exit;

    final specialRooms = _buildSpecialRooms(
      rooms: rooms,
      floor: floor,
      playerStart: playerStart,
      exit: exit,
    );
    final specialRoomPositions = {
      for (final room in specialRooms) room.position,
    };

    final freeCells = _collectFreeCells(tiles)
      ..remove(playerStart)
      ..remove(exit)
      ..removeWhere((cell) => specialRoomPositions.contains(cell));

    freeCells.shuffle(_random);

    final hasBoss = floor >= 6 && floor % 3 == 0;
    final enemyCount = min(18, 3 + floor * 2 - (hasBoss ? 1 : 0));
    final enemies = <EnemyEntity>[];

    for (int i = 0; i < enemyCount && freeCells.isNotEmpty; i++) {
      final position = freeCells.removeLast();
      if (_distance(position, playerStart) < 5) {
        continue;
      }

      final type = _randomEnemyType(floor);
      final hp = type == EnemyType.tank ? 2 : 1;

      enemies.add(
        EnemyEntity(
          id: _nextEnemyId++,
          position: position,
          hp: hp,
          maxHp: hp,
          type: type,
        ),
      );
    }

    if (hasBoss && freeCells.isNotEmpty) {
      Point<int> bossPosition = freeCells.removeLast();
      int bestDistance = _distance(bossPosition, playerStart);

      for (final candidate in freeCells) {
        final distance = _distance(candidate, playerStart);
        if (distance > bestDistance) {
          bestDistance = distance;
          bossPosition = candidate;
        }
      }

      freeCells.remove(bossPosition);

      final bossHp = 4 + (floor ~/ 3);
      enemies.add(
        EnemyEntity(
          id: _nextEnemyId++,
          position: bossPosition,
          hp: bossHp,
          maxHp: bossHp,
          isBoss: true,
          type: EnemyType.boss,
        ),
      );
    }

    final lootCount = min(12, 2 + floor * 2);
    final loot = <LootDrop>[];

    for (int i = 0; i < lootCount && freeCells.isNotEmpty; i++) {
      final position = freeCells.removeLast();
      final rarityRoll = _random.nextInt(100);
      final rarity = rarityRoll < 68
          ? LootRarity.common
          : (rarityRoll < 93 ? LootRarity.rare : LootRarity.epic);
      final type = _random.nextInt(100) < 40
          ? LootType.essence
          : LootType.shard;
      loot.add(
        LootDrop(
          id: _nextLootId++,
          type: type,
          rarity: rarity,
          position: position,
        ),
      );
    }

    return FloorData(
      tiles: tiles,
      playerStart: playerStart,
      exit: exit,
      enemies: enemies,
      loot: loot,
      specialRooms: specialRooms,
    );
  }

  List<SpecialRoom> _buildSpecialRooms({
    required List<_Rect> rooms,
    required int floor,
    required Point<int> playerStart,
    required Point<int> exit,
  }) {
    if (rooms.length < 3) {
      return const [];
    }

    final candidates =
        rooms
            .map((room) => room.center)
            .where((center) => center != playerStart && center != exit)
            .toList(growable: true)
          ..shuffle(_random);

    final desiredRooms = min(4, max(2, 2 + (floor ~/ 4)));
    final selectedCount = min(desiredRooms, candidates.length);

    final types = <SpecialRoomType>[
      SpecialRoomType.treasure,
      SpecialRoomType.event,
      SpecialRoomType.trap,
      SpecialRoomType.altar,
    ];

    final selectedTypes = <SpecialRoomType>[];
    while (selectedTypes.length < selectedCount) {
      types.shuffle(_random);
      selectedTypes.addAll(types);
    }

    final roomsOut = <SpecialRoom>[];
    for (int i = 0; i < selectedCount; i++) {
      roomsOut.add(
        SpecialRoom(type: selectedTypes[i], position: candidates[i]),
      );
    }

    return roomsOut;
  }

  void _connectRoomsWithLoops(
    List<List<TileType>> tiles,
    List<_Rect> rooms,
    int floor,
  ) {
    if (rooms.length < 2) return;

    final connected = <int>{0};
    final edges = <_RoomEdge>{};

    while (connected.length < rooms.length) {
      int bestFrom = 0;
      int bestTo = 0;
      int bestScore = 1 << 30;

      for (final from in connected) {
        for (int to = 0; to < rooms.length; to++) {
          if (connected.contains(to)) continue;

          final score =
              _distance(rooms[from].center, rooms[to].center) +
              _random.nextInt(4);
          if (score < bestScore) {
            bestScore = score;
            bestFrom = from;
            bestTo = to;
          }
        }
      }

      _carveCorridor(tiles, rooms[bestFrom].center, rooms[bestTo].center);
      edges.add(_RoomEdge(bestFrom, bestTo));
      connected.add(bestTo);
    }

    final extraConnections = min(
      rooms.length,
      max(1, (rooms.length ~/ 3) + (floor ~/ 3)),
    );

    int added = 0;
    int attempts = 0;
    while (added < extraConnections && attempts < extraConnections * 8) {
      attempts += 1;

      final from = _random.nextInt(rooms.length);
      final near = List<int>.generate(rooms.length, (i) => i)
        ..remove(from)
        ..sort((a, b) {
          final da = _distance(rooms[from].center, rooms[a].center);
          final db = _distance(rooms[from].center, rooms[b].center);
          return da.compareTo(db);
        });

      final candidatePool = near.take(min(3, near.length)).toList();
      if (candidatePool.isEmpty) {
        continue;
      }

      final to = candidatePool[_random.nextInt(candidatePool.length)];
      final edge = _RoomEdge(from, to);
      if (edges.contains(edge)) {
        continue;
      }

      edges.add(edge);
      _carveCorridor(
        tiles,
        rooms[from].center,
        rooms[to].center,
        allowDetour: true,
      );
      added += 1;
    }
  }

  void _carveCorridor(
    List<List<TileType>> tiles,
    Point<int> from,
    Point<int> to, {
    bool allowDetour = false,
  }) {
    if (!allowDetour || _random.nextInt(100) < 60) {
      if (_random.nextBool()) {
        _carveHorizontal(tiles, from.x, to.x, from.y);
        _carveVertical(tiles, from.y, to.y, to.x);
      } else {
        _carveVertical(tiles, from.y, to.y, from.x);
        _carveHorizontal(tiles, from.x, to.x, to.y);
      }
      return;
    }

    final detourX = _clamp(
      ((from.x + to.x) ~/ 2) + (_random.nextInt(5) - 2),
      1,
      tiles[0].length - 2,
    );
    final detourY = _clamp(
      ((from.y + to.y) ~/ 2) + (_random.nextInt(5) - 2),
      1,
      tiles.length - 2,
    );

    _carveHorizontal(tiles, from.x, detourX, from.y);
    _carveVertical(tiles, from.y, detourY, detourX);
    _carveHorizontal(tiles, detourX, to.x, detourY);
    _carveVertical(tiles, detourY, to.y, to.x);
  }

  int _clamp(int value, int minValue, int maxValue) {
    return value < minValue ? minValue : (value > maxValue ? maxValue : value);
  }

  int _distance(Point<int> a, Point<int> b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  EnemyType _randomEnemyType(int floor) {
    final roll = _random.nextInt(100);

    if (floor <= 4) {
      return EnemyType.pursuer;
    }

    if (floor < 7) {
      if (roll < 72) return EnemyType.pursuer;
      return EnemyType.tank;
    }

    if (floor < 10) {
      if (roll < 52) return EnemyType.pursuer;
      if (roll < 78) return EnemyType.archer;
      return EnemyType.tank;
    }

    if (roll < 35) return EnemyType.pursuer;
    if (roll < 58) return EnemyType.archer;
    if (roll < 80) return EnemyType.tank;
    return EnemyType.summoner;
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

class _RoomEdge {
  final int a;
  final int b;

  const _RoomEdge(int x, int y) : a = x < y ? x : y, b = x < y ? y : x;

  @override
  bool operator ==(Object other) {
    return other is _RoomEdge && other.a == a && other.b == b;
  }

  @override
  int get hashCode => Object.hash(a, b);
}
