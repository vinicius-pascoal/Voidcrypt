import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'dungeon_generator.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  static const int visibleCols = 12;
  static const int visibleRows = 7;
  static const int mapWidth = 36;
  static const int mapHeight = 22;

  final Random _random = Random();
  final DungeonGenerator _generator = DungeonGenerator();

  late List<List<TileType>> map;
  Point<int> player = const Point(1, 1);
  Point<int> exit = const Point(1, 1);

  List<EnemyEntity> enemies = [];
  List<LootDrop> loot = [];

  Point<int>? previousPlayer;
  Map<int, Point<int>> previousEnemyPositions = {};
  Map<Point<int>, int> telegraphedDamage = {};

  int hp = 5;
  int maxHp = 5;
  int steps = 0;
  int floor = 1;
  int shards = 0;
  int mapVisualSeed = 0;
  int damageFlashTick = 0;

  int stamina = 4;
  int maxStamina = 4;

  String message = 'Explore as salas e encontre a saida.';

  final List<RelicType> activeRelics = [];
  List<RewardOption> pendingRewards = [];

  Timer? _animationResetTimer;
  bool _busy = false;

  bool get isBusy => _busy;
  bool get isAwaitingRewardChoice => pendingRewards.isNotEmpty;

  int get attackRange =>
      1 + activeRelics.where((r) => r == RelicType.longReach).length;

  double get critChance =>
      (0.10 * activeRelics.where((r) => r == RelicType.criticalEdge).length)
          .clamp(0.0, 0.6);

  void startNewRun() {
    hp = 5;
    maxHp = 5;
    steps = 0;
    floor = 1;
    shards = 0;
    stamina = maxStamina;
    activeRelics.clear();
    pendingRewards = [];
    telegraphedDamage = {};
    _loadFloor(resetMessage: 'Run reiniciada. A cripta mudou de forma.');
  }

  void start() {
    _loadFloor(resetMessage: 'Entre em Voidcrypt.');
  }

  void _loadFloor({String? resetMessage}) {
    final data = _generator.generate(
      width: mapWidth,
      height: mapHeight,
      floor: floor,
    );

    map = data.tiles;
    player = data.playerStart;
    previousPlayer = player;
    enemies = List<EnemyEntity>.from(data.enemies);
    previousEnemyPositions = {
      for (final enemy in enemies) enemy.id: enemy.position,
    };
    loot = List<LootDrop>.from(data.loot);
    exit = data.exit;
    mapVisualSeed = _random.nextInt(1 << 30);
    telegraphedDamage = {};

    message = resetMessage ?? 'Piso $floor gerado proceduralmente.';

    _queueAnimationReset();
    _buildTelegraphMap();
    notifyListeners();
  }

  bool _isInside(Point<int> p) {
    return p.y >= 0 && p.y < map.length && p.x >= 0 && p.x < map[0].length;
  }

  bool _isWall(Point<int> p) {
    return !_isInside(p) || map[p.y][p.x] == TileType.wall;
  }

  int _enemyIndexAt(Point<int> p) {
    return enemies.indexWhere((enemy) => enemy.position == p);
  }

  int _lootIndexAt(Point<int> p) {
    return loot.indexWhere((drop) => drop.position == p);
  }

  void _captureAnimationOrigins() {
    previousPlayer = player;
    previousEnemyPositions = {
      for (final enemy in enemies) enemy.id: enemy.position,
    };
  }

  void _queueAnimationReset() {
    _animationResetTimer?.cancel();
    _animationResetTimer = Timer(const Duration(milliseconds: 180), () {
      previousPlayer = player;
      previousEnemyPositions = {
        for (final enemy in enemies) enemy.id: enemy.position,
      };
      notifyListeners();
    });
  }

  void _recoverStamina(int amount) {
    stamina = min(maxStamina, stamina + amount);
  }

  void movePlayer(int dx, int dy) {
    if (_busy || isAwaitingRewardChoice) return;

    final next = Point(player.x + dx, player.y + dy);

    if (_isWall(next)) {
      message = 'Uma parede bloqueia seu caminho.';
      notifyListeners();
      return;
    }

    _busy = true;
    _captureAnimationOrigins();

    final enemyIndex = _enemyIndexAt(next);
    if (enemyIndex != -1) {
      final enemy = enemies[enemyIndex];
      final wasCritical = _random.nextDouble() < critChance;
      final damage = wasCritical ? 2 : 1;
      final killed = _applyDamageToEnemy(enemyIndex, damage);
      steps++;

      if (killed) {
        message = enemy.isBoss
            ? 'Golpe final no mini-chefe!'
            : (wasCritical
                  ? 'Critico! Espectro dissipado.'
                  : 'Voce golpeou um espectro.');
        previousEnemyPositions.remove(enemy.id);
      } else {
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        message = wasCritical
            ? 'Critico! Inimigo com $remaining HP.'
            : 'Inimigo ferido ($remaining HP).';
      }

      _recoverStamina(1);
      _enemyTurn();
      _afterTurn();
      _queueAnimationReset();
      notifyListeners();
      _busy = false;
      return;
    }

    player = next;
    steps++;

    final lootIndex = _lootIndexAt(player);
    if (lootIndex != -1) {
      final drop = loot.removeAt(lootIndex);
      if (drop.type == LootType.essence) {
        hp = min(maxHp, hp + 1);
        message = 'Essencia coletada. +1 HP.';
      } else {
        shards += 1;
        message = 'Fragmento encontrado. Shards: $shards.';
      }
    } else {
      message = 'Voce avancou entre as salas.';
    }

    _recoverStamina(1);

    if (player == exit) {
      floor += 1;
      hp = min(maxHp, hp + 1);
      _openRewardSelection();
      _busy = false;
      notifyListeners();
      return;
    }

    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  void attack() {
    if (_busy || isAwaitingRewardChoice) return;

    if (stamina < 2) {
      message = 'Stamina insuficiente para ataque forte.';
      notifyListeners();
      return;
    }

    _busy = true;
    _captureAnimationOrigins();

    stamina = max(0, stamina - 2);

    final dirs = <Point<int>>[
      const Point(0, -1),
      const Point(1, 0),
      const Point(0, 1),
      const Point(-1, 0),
    ];

    int targetIndex = -1;

    for (final dir in dirs) {
      for (int step = 1; step <= attackRange; step++) {
        final target = Point(
          player.x + (dir.x * step),
          player.y + (dir.y * step),
        );
        if (_isWall(target)) {
          break;
        }

        targetIndex = _enemyIndexAt(target);
        if (targetIndex != -1) {
          break;
        }
      }

      if (targetIndex != -1) {
        break;
      }
    }

    steps++;

    if (targetIndex != -1) {
      final enemy = enemies[targetIndex];
      final wasCritical = _random.nextDouble() < critChance;
      final damage = wasCritical ? 3 : 2;
      final killed = _applyDamageToEnemy(targetIndex, damage);

      if (killed) {
        message = enemy.isBoss
            ? 'Mini-chefe abatido!'
            : (wasCritical ? 'Critico devastador!' : 'Ataque forte certeiro.');
        previousEnemyPositions.remove(enemy.id);
      } else {
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        message = wasCritical
            ? 'Critico! Inimigo com $remaining HP.'
            : 'Impacto forte! Inimigo com $remaining HP.';
      }
    } else {
      message = 'Ataque forte no vazio.';
    }

    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  void waitTurn() {
    if (_busy || isAwaitingRewardChoice) return;

    _busy = true;
    _captureAnimationOrigins();
    steps++;
    _recoverStamina(2);
    message = 'Voce aguarda e recupera stamina.';
    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  void _afterTurn() {
    if (hp > 0) {
      return;
    }

    floor = 1;
    hp = maxHp;
    steps = 0;
    shards = 0;
    stamina = maxStamina;
    activeRelics.clear();
    pendingRewards = [];
    telegraphedDamage = {};
    _loadFloor(resetMessage: 'Voce caiu. A cripta reiniciou.');
  }

  bool _applyDamageToEnemy(int index, int damage) {
    final enemy = enemies[index];
    final remaining = enemy.hp - damage;

    if (remaining <= 0) {
      enemies.removeAt(index);
      return true;
    }

    enemies[index] = enemy.copyWith(hp: remaining);
    return false;
  }

  void _openRewardSelection() {
    pendingRewards = _buildRandomRewardOptions();
    message = 'Escolha uma recompensa para o piso $floor.';
  }

  List<RewardOption> _buildRandomRewardOptions() {
    final candidates = <RewardOption>[
      const RewardOption(
        relic: RelicType.longReach,
        title: 'Lanca Estendida',
        description: '+1 alcance de ataque.',
      ),
      const RewardOption(
        relic: RelicType.criticalEdge,
        title: 'Lamina Voraz',
        description: '+10% chance de critico.',
      ),
      const RewardOption(
        relic: RelicType.vitalityCore,
        title: 'Nucleo Vital',
        description: '+1 HP maximo e cura 1 HP.',
      ),
    ]..shuffle(_random);

    return candidates.take(2).toList(growable: false);
  }

  void chooseReward(int index) {
    if (!isAwaitingRewardChoice) return;
    if (index < 0 || index >= pendingRewards.length) return;

    final chosen = pendingRewards[index];
    activeRelics.add(chosen.relic);

    if (chosen.relic == RelicType.vitalityCore) {
      maxHp += 1;
      hp = min(maxHp, hp + 1);
    }

    pendingRewards = [];
    _loadFloor(resetMessage: 'Reliquia recebida: ${chosen.title}.');
  }

  bool _canEnemyMoveTo(Point<int> position, List<Point<int>> occupied) {
    if (_isWall(position)) return false;
    if (position == player) return false;
    if (position == exit) return false;
    if (occupied.contains(position)) return false;
    return true;
  }

  Point<int> _pickChaseDestination(
    EnemyEntity enemy,
    List<Point<int>> occupied,
  ) {
    final dx = player.x - enemy.position.x;
    final dy = player.y - enemy.position.y;

    Point<int> destination = enemy.position;
    final candidates = <Point<int>>[];

    if (dx.abs() >= dy.abs()) {
      if (dx != 0) {
        candidates.add(Point(enemy.position.x + dx.sign, enemy.position.y));
      }
      if (dy != 0) {
        candidates.add(Point(enemy.position.x, enemy.position.y + dy.sign));
      }
    } else {
      if (dy != 0) {
        candidates.add(Point(enemy.position.x, enemy.position.y + dy.sign));
      }
      if (dx != 0) {
        candidates.add(Point(enemy.position.x + dx.sign, enemy.position.y));
      }
    }

    final fallback = <Point<int>>[
      Point(enemy.position.x + 1, enemy.position.y),
      Point(enemy.position.x - 1, enemy.position.y),
      Point(enemy.position.x, enemy.position.y + 1),
      Point(enemy.position.x, enemy.position.y - 1),
    ]..shuffle(_random);

    candidates.addAll(fallback);

    for (final candidate in candidates) {
      if (_canEnemyMoveTo(candidate, occupied)) {
        destination = candidate;
        break;
      }
    }

    return destination;
  }

  bool _hasLineOfSight(Point<int> from, Point<int> to, {int range = 4}) {
    if (from.x != to.x && from.y != to.y) {
      return false;
    }

    if ((from.x - to.x).abs() + (from.y - to.y).abs() > range) {
      return false;
    }

    final dx = (to.x - from.x).sign;
    final dy = (to.y - from.y).sign;

    var x = from.x + dx;
    var y = from.y + dy;

    while (x != to.x || y != to.y) {
      if (_isWall(Point<int>(x, y))) {
        return false;
      }
      x += dx;
      y += dy;
    }

    return true;
  }

  Point<int> _pickArcherDestination(
    EnemyEntity enemy,
    List<Point<int>> occupied,
  ) {
    final distance =
        (player.x - enemy.position.x).abs() +
        (player.y - enemy.position.y).abs();

    if (_hasLineOfSight(enemy.position, player, range: 4)) {
      if (distance <= 2) {
        final retreat = Point<int>(
          enemy.position.x - (player.x - enemy.position.x).sign,
          enemy.position.y - (player.y - enemy.position.y).sign,
        );
        if (_canEnemyMoveTo(retreat, occupied)) {
          return retreat;
        }
      }
      return enemy.position;
    }

    return _pickChaseDestination(enemy, occupied);
  }

  EnemyEntity? _trySummon(EnemyEntity summoner, List<Point<int>> occupied) {
    final candidates = <Point<int>>[
      Point<int>(summoner.position.x + 1, summoner.position.y),
      Point<int>(summoner.position.x - 1, summoner.position.y),
      Point<int>(summoner.position.x, summoner.position.y + 1),
      Point<int>(summoner.position.x, summoner.position.y - 1),
    ]..shuffle(_random);

    for (final cell in candidates) {
      if (_canEnemyMoveTo(cell, occupied)) {
        final id = enemies.fold<int>(0, (m, e) => max(m, e.id)) + 1;
        final summoned = EnemyEntity(
          id: id,
          position: cell,
          hp: 1,
          maxHp: 1,
          type: EnemyType.pursuer,
        );
        occupied.add(cell);
        message = 'Um invocador chamou reforcos.';
        return summoned;
      }
    }

    return null;
  }

  void _enemyTurn() {
    if (enemies.isEmpty && telegraphedDamage.isEmpty) return;

    final incomingDamage = telegraphedDamage[player] ?? 0;
    bool playerWasHit = false;

    if (incomingDamage > 0) {
      hp -= incomingDamage;
      damageFlashTick += 1;
      playerWasHit = true;
    }

    telegraphedDamage = {};

    if (enemies.isEmpty) {
      if (playerWasHit) {
        message = hp > 0
            ? 'Voce sofreu $incomingDamage de dano.'
            : 'O vazio tomou sua ultima forca.';
      }
      return;
    }

    final occupied = <Point<int>>[];
    final moved = <EnemyEntity>[];
    final spawned = <EnemyEntity>[];

    for (final enemy in enemies) {
      EnemyEntity updated = enemy;
      Point<int> destination = enemy.position;

      switch (enemy.type) {
        case EnemyType.pursuer:
        case EnemyType.boss:
          destination = _pickChaseDestination(enemy, occupied);
          break;
        case EnemyType.archer:
          destination = _pickArcherDestination(enemy, occupied);
          break;
        case EnemyType.tank:
          if (enemy.aiState > 0) {
            updated = updated.copyWith(aiState: enemy.aiState - 1);
          } else {
            destination = _pickChaseDestination(enemy, occupied);
            updated = updated.copyWith(aiState: 1);
          }
          break;
        case EnemyType.summoner:
          if (enemy.aiState >= 2) {
            final summon = _trySummon(enemy, occupied);
            if (summon != null) {
              spawned.add(summon);
            }
            updated = updated.copyWith(aiState: 0);
          } else {
            updated = updated.copyWith(aiState: enemy.aiState + 1);
            destination = _pickArcherDestination(enemy, occupied);
          }
          break;
      }

      if (destination != enemy.position &&
          _canEnemyMoveTo(destination, occupied)) {
        updated = updated.copyWith(position: destination);
      }

      moved.add(updated);
      occupied.add(updated.position);
    }

    enemies = [...moved, ...spawned];

    _buildTelegraphMap();

    if (playerWasHit) {
      message = hp > 0
          ? 'Voce sofreu $incomingDamage de dano.'
          : 'O vazio tomou sua ultima forca.';
    }
  }

  void _buildTelegraphMap() {
    final next = <Point<int>, int>{};

    void add(Point<int> p, int damage) {
      if (_isWall(p)) return;
      next[p] = (next[p] ?? 0) + damage;
    }

    for (final enemy in enemies) {
      switch (enemy.type) {
        case EnemyType.pursuer:
          add(Point<int>(enemy.position.x + 1, enemy.position.y), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y), 1);
          add(Point<int>(enemy.position.x, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x, enemy.position.y - 1), 1);
          break;
        case EnemyType.tank:
          add(Point<int>(enemy.position.x + 1, enemy.position.y), 2);
          add(Point<int>(enemy.position.x - 1, enemy.position.y), 2);
          add(Point<int>(enemy.position.x, enemy.position.y + 1), 2);
          add(Point<int>(enemy.position.x, enemy.position.y - 1), 2);
          break;
        case EnemyType.archer:
          for (final dir in const [
            Point<int>(1, 0),
            Point<int>(-1, 0),
            Point<int>(0, 1),
            Point<int>(0, -1),
          ]) {
            for (int step = 1; step <= 4; step++) {
              final p = Point<int>(
                enemy.position.x + (dir.x * step),
                enemy.position.y + (dir.y * step),
              );
              if (_isWall(p)) break;
              add(p, 1);
            }
          }
          break;
        case EnemyType.summoner:
          add(Point<int>(enemy.position.x + 1, enemy.position.y), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y), 1);
          add(Point<int>(enemy.position.x, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x, enemy.position.y - 1), 1);
          add(Point<int>(enemy.position.x + 1, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x + 1, enemy.position.y - 1), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y - 1), 1);
          break;
        case EnemyType.boss:
          add(Point<int>(enemy.position.x + 1, enemy.position.y), 2);
          add(Point<int>(enemy.position.x - 1, enemy.position.y), 2);
          add(Point<int>(enemy.position.x, enemy.position.y + 1), 2);
          add(Point<int>(enemy.position.x, enemy.position.y - 1), 2);
          add(Point<int>(enemy.position.x + 1, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y + 1), 1);
          add(Point<int>(enemy.position.x + 1, enemy.position.y - 1), 1);
          add(Point<int>(enemy.position.x - 1, enemy.position.y - 1), 1);
          break;
      }
    }

    telegraphedDamage = next;
  }

  Offset viewportOrigin() {
    final maxStartCol = max(0, map[0].length - visibleCols);
    final maxStartRow = max(0, map.length - visibleRows);

    final startCol = min(max(0, player.x - (visibleCols ~/ 2)), maxStartCol);
    final startRow = min(max(0, player.y - (visibleRows ~/ 2)), maxStartRow);

    return Offset(startCol.toDouble(), startRow.toDouble());
  }

  @override
  void dispose() {
    _animationResetTimer?.cancel();
    super.dispose();
  }
}
