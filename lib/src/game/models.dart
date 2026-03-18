import 'dart:math';

enum GameDifficulty { normal, hard, nightmare }

extension GameDifficultyCodec on GameDifficulty {
  String get storageKey => name;

  static GameDifficulty fromStorageKey(String? raw) {
    return GameDifficulty.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => GameDifficulty.normal,
    );
  }
}

enum TileType { wall, floor, exit }

enum LootType { essence, shard }

enum LootRarity { common, rare, epic }

enum RelicType { longReach, criticalEdge, vitalityCore }

enum EnemyType { pursuer, archer, tank, summoner, boss }

enum ConsumableType { potion, bomb, temporalShield }

enum SpecialRoomType { treasure, event, trap, altar }

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
  final LootRarity rarity;
  final Point<int> position;

  const LootDrop({
    required this.id,
    required this.type,
    this.rarity = LootRarity.common,
    required this.position,
  });
}

class ShopItem {
  final ConsumableType consumable;
  final int cost;
  final String title;
  final String description;

  const ShopItem({
    required this.consumable,
    required this.cost,
    required this.title,
    required this.description,
  });
}

class SpecialRoom {
  final SpecialRoomType type;
  final Point<int> position;

  const SpecialRoom({required this.type, required this.position});
}

class FloorData {
  final List<List<TileType>> tiles;
  final Point<int> playerStart;
  final Point<int> exit;
  final List<EnemyEntity> enemies;
  final List<LootDrop> loot;
  final List<SpecialRoom> specialRooms;

  const FloorData({
    required this.tiles,
    required this.playerStart,
    required this.exit,
    required this.enemies,
    required this.loot,
    this.specialRooms = const [],
  });
}

class RunSummary {
  final GameDifficulty difficulty;
  final int floor;
  final int kills;
  final int loot;
  final int shards;
  final int steps;
  final Duration duration;

  const RunSummary({
    required this.difficulty,
    required this.floor,
    required this.kills,
    required this.loot,
    required this.shards,
    required this.steps,
    required this.duration,
  });
}

class RunSnapshot {
  final GameDifficulty difficulty;
  final List<List<int>> map;
  final Point<int> player;
  final Point<int> exit;
  final List<EnemyEntity> enemies;
  final List<LootDrop> loot;
  final Map<Point<int>, SpecialRoomType> specialRooms;
  final Set<Point<int>> visitedSpecialRooms;
  final int hp;
  final int maxHp;
  final int steps;
  final int floor;
  final int shards;
  final int mapVisualSeed;
  final int damageFlashTick;
  final int hitStopTick;
  final int stamina;
  final int maxStamina;
  final int facingDx;
  final int facingDy;
  final int potions;
  final int bombs;
  final int temporalShields;
  final int shieldTurns;
  final String message;
  final List<RelicType> activeRelics;
  final List<RewardOption> pendingRewards;
  final List<ShopItem> pendingShopItems;
  final bool shopPhaseActive;
  final String shopFeedbackMessage;
  final bool shopFeedbackIsError;
  final int kills;
  final int lootCollected;
  final int runStartedAtEpochMs;

  const RunSnapshot({
    required this.difficulty,
    required this.map,
    required this.player,
    required this.exit,
    required this.enemies,
    required this.loot,
    required this.specialRooms,
    required this.visitedSpecialRooms,
    required this.hp,
    required this.maxHp,
    required this.steps,
    required this.floor,
    required this.shards,
    required this.mapVisualSeed,
    required this.damageFlashTick,
    required this.hitStopTick,
    required this.stamina,
    required this.maxStamina,
    required this.facingDx,
    required this.facingDy,
    required this.potions,
    required this.bombs,
    required this.temporalShields,
    required this.shieldTurns,
    required this.message,
    required this.activeRelics,
    required this.pendingRewards,
    required this.pendingShopItems,
    required this.shopPhaseActive,
    required this.shopFeedbackMessage,
    required this.shopFeedbackIsError,
    required this.kills,
    required this.lootCollected,
    required this.runStartedAtEpochMs,
  });
}
