import 'dart:math';

enum TileType { wall, floor, exit }

enum LootType { essence, shard }

class EnemyEntity {
  final int id;
  final Point<int> position;

  const EnemyEntity({required this.id, required this.position});

  EnemyEntity copyWith({Point<int>? position}) {
    return EnemyEntity(id: id, position: position ?? this.position);
  }
}

class LootDrop {
  final int id;
  final LootType type;
  final Point<int> position;

  const LootDrop({
    required this.id,
    required this.type,
    required this.position,
  });
}

class FloorData {
  final List<List<TileType>> tiles;
  final Point<int> playerStart;
  final Point<int> exit;
  final List<EnemyEntity> enemies;
  final List<LootDrop> loot;

  const FloorData({
    required this.tiles,
    required this.playerStart,
    required this.exit,
    required this.enemies,
    required this.loot,
  });
}
