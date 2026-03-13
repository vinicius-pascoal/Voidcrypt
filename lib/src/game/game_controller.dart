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

  int hp = 5;
  int maxHp = 5;
  int steps = 0;
  int floor = 1;
  int shards = 0;
  int mapVisualSeed = 0;
  int damageFlashTick = 0;
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
    activeRelics.clear();
    pendingRewards = [];
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
    message = resetMessage ?? 'Piso $floor gerado proceduralmente.';

    _queueAnimationReset();
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
      } else {
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        message = wasCritical
            ? 'Critico! Mini-chefe ferido ($remaining HP).'
            : 'Inimigo ferido ($remaining HP).';
      }

      _enemyTurn();
      _afterTurn();
      if (killed) {
        previousEnemyPositions.remove(enemy.id);
      }
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

    _busy = true;
    _captureAnimationOrigins();

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

    if (targetIndex != -1) {
      final enemy = enemies[targetIndex];
      final wasCritical = _random.nextDouble() < critChance;
      final damage = wasCritical ? 2 : 1;
      final killed = _applyDamageToEnemy(targetIndex, damage);
      steps++;
      if (killed) {
        message = enemy.isBoss
            ? 'Mini-chefe abatido!'
            : (wasCritical ? 'Critico certeiro!' : 'Ataque certeiro.');
        previousEnemyPositions.remove(enemy.id);
      } else {
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        message = wasCritical
            ? 'Critico! Inimigo com $remaining HP.'
            : 'Inimigo com $remaining HP.';
      }
      _enemyTurn();
    } else {
      message = attackRange > 1
          ? 'Nenhum inimigo no alcance.'
          : 'Nenhum inimigo adjacente.';
      _enemyTurn();
    }

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
    message = 'Voce aguarda em silencio.';
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
    activeRelics.clear();
    pendingRewards = [];
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
    final options = _buildRandomRewardOptions();
    pendingRewards = options;
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

  void _enemyTurn() {
    if (enemies.isEmpty) return;

    final occupied = <Point<int>>[];
    bool playerHit = false;

    final moved = <EnemyEntity>[];

    for (final enemy in enemies) {
      final dx = player.x - enemy.position.x;
      final dy = player.y - enemy.position.y;

      if (dx.abs() + dy.abs() == 1) {
        playerHit = true;
        hp -= enemy.isBoss ? 2 : 1;
        moved.add(enemy);
        occupied.add(enemy.position);
        continue;
      }

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

      moved.add(enemy.copyWith(position: destination));
      occupied.add(destination);
    }

    enemies = moved;

    if (playerHit) {
      damageFlashTick += 1;
      message = hp > 0
          ? 'Voce sofreu dano.'
          : 'O vazio tomou sua ultima forca.';
    }
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
