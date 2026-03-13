import 'dart:math';

enum TileType { wall, floor, exit }

enum LootType { essence, shard }

enum RelicType { longReach, criticalEdge, vitalityCore }

enum EnemyType { pursuer, archer, tank, summoner, boss }

class EnemyEntity {
  final int id;
  final Point<int> position;
  final int hp;
  final int maxHp;
  final bool isBoss;
  final EnemyType type;
  final int aiState;

  const EnemyEntity({
    required this.id,
    required this.position,
    required this.hp,
    required this.maxHp,
    this.isBoss = false,
    this.type = EnemyType.pursuer,
    this.aiState = 0,
  });

  EnemyEntity copyWith({
    Point<int>? position,
    int? hp,
    int? maxHp,
    bool? isBoss,
    EnemyType? type,
    int? aiState,
  }) {
    return EnemyEntity(
      id: id,
      position: position ?? this.position,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      isBoss: isBoss ?? this.isBoss,
      type: type ?? this.type,
      aiState: aiState ?? this.aiState,
    );
  }
}

class RewardOption {
  final RelicType relic;
  final String title;
  final String description;

  const RewardOption({
    required this.relic,
    required this.title,
    required this.description,
  });
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
