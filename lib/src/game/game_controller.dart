import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dungeon_generator.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  static const String _savedRunKey = 'voidcrypt_saved_run_v1';
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
  Map<Point<int>, SpecialRoomType> specialRooms = {};
  final Set<Point<int>> _visitedSpecialRooms = <Point<int>>{};

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
  int hitStopTick = 0;
  int lootParticleTick = 0;
  int enemyDeathParticleTick = 0;
  List<Point<int>> lootParticlePositions = const [];
  List<Point<int>> enemyDeathParticlePositions = const [];

  int potions = 0;
  int bombs = 0;
  int temporalShields = 0;
  int shieldTurns = 0;

  int stamina = 4;
  int maxStamina = 4;
  int _facingDx = 0;
  int _facingDy = 1;

  String message = 'Explore as salas e encontre a saida.';

  final List<RelicType> activeRelics = [];
  List<RewardOption> pendingRewards = [];
  List<ShopItem> pendingShopItems = [];
  bool _shopPhaseActive = false;

  final RunSnapshot? _resumeSnapshot;
  final GameDifficulty difficulty;
  final PlayerClass playerClass;
  DateTime _runStartedAt = DateTime.now();
  int kills = 0;
  int lootCollected = 0;
  bool _isGameOver = false;
  int classAbilityCooldown = 0;
  RunSummary? lastRunSummary;

  Timer? _animationResetTimer;
  bool _busy = false;
  bool _isPersisting = false;

  bool get isBusy => _busy;
  bool get isAwaitingRewardChoice => pendingRewards.isNotEmpty;
  bool get isAwaitingShopChoice => _shopPhaseActive;
  bool get isGameOver => _isGameOver;
  int get facingDx => _facingDx;
  int get facingDy => _facingDy;
  bool get canUseClassAbility => classAbilityCooldown <= 0;

  GameController({
    this.difficulty = GameDifficulty.normal,
    this.playerClass = PlayerClass.slimeRogue,
    RunSnapshot? resumeSnapshot,
  }) : _resumeSnapshot = resumeSnapshot;

  static Future<void> clearSavedRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedRunKey);
  }

  static Future<RunSnapshot?> loadSavedRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRunKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _snapshotFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  String shopFeedbackMessage = '';
  bool shopFeedbackIsError = false;

  int get attackRange =>
      1 + activeRelics.where((r) => r == RelicType.longReach).length;

  double get critChance =>
      (0.10 * activeRelics.where((r) => r == RelicType.criticalEdge).length)
          .clamp(0.0, 0.6);

  int _baseMaxHpByDifficulty() {
    switch (difficulty) {
      case GameDifficulty.normal:
        return 5;
      case GameDifficulty.hard:
        return 4;
      case GameDifficulty.nightmare:
        return 4;
    }
  }

  int _baseMaxStaminaByDifficulty() {
    switch (difficulty) {
      case GameDifficulty.normal:
        return 4;
      case GameDifficulty.hard:
        return 4;
      case GameDifficulty.nightmare:
        return 3;
    }
  }

  int _enemyHpBonusByDifficulty() {
    switch (difficulty) {
      case GameDifficulty.normal:
        return 0;
      case GameDifficulty.hard:
        return 1;
      case GameDifficulty.nightmare:
        return 2;
    }
  }

  int _incomingDamageBonusByDifficulty() {
    switch (difficulty) {
      case GameDifficulty.normal:
        return 0;
      case GameDifficulty.hard:
        return 1;
      case GameDifficulty.nightmare:
        return 2;
    }
  }

  void _applyDifficultyToEnemies() {
    final hpBonus = _enemyHpBonusByDifficulty();
    if (hpBonus <= 0) {
      return;
    }

    enemies = [
      for (final enemy in enemies)
        enemy.copyWith(hp: enemy.hp + hpBonus, maxHp: enemy.maxHp + hpBonus),
    ];
  }

  void startNewRun() {
    maxHp = _baseMaxHpByDifficulty();
    hp = maxHp;
    steps = 0;
    floor = 1;
    shards = 0;
    potions = 0;
    bombs = 0;
    temporalShields = 0;
    shieldTurns = 0;
    maxStamina = _baseMaxStaminaByDifficulty();
    stamina = maxStamina;
    _facingDx = 0;
    _facingDy = 1;
    damageFlashTick = 0;
    hitStopTick = 0;
    classAbilityCooldown = 0;
    kills = 0;
    lootCollected = 0;
    _isGameOver = false;
    lastRunSummary = null;
    _runStartedAt = DateTime.now();
    activeRelics.clear();
    pendingRewards = [];
    pendingShopItems = [];
    shopFeedbackMessage = '';
    shopFeedbackIsError = false;
    _shopPhaseActive = false;
    telegraphedDamage = {};
    lootParticlePositions = const [];
    enemyDeathParticlePositions = const [];
    specialRooms = {};
    _visitedSpecialRooms.clear();
    _loadFloor(resetMessage: 'Run reiniciada. A cripta mudou de forma.');
  }

  void start() {
    if (_resumeSnapshot != null) {
      _restoreFromSnapshot(_resumeSnapshot);
      message = 'Run retomada no piso $floor.';
      notifyListeners();
      return;
    }
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
    _applyDifficultyToEnemies();
    previousEnemyPositions = {
      for (final enemy in enemies) enemy.id: enemy.position,
    };
    loot = List<LootDrop>.from(data.loot);
    specialRooms = {
      for (final room in data.specialRooms) room.position: room.type,
    };
    _visitedSpecialRooms.clear();
    exit = data.exit;
    mapVisualSeed = _random.nextInt(1 << 30);
    telegraphedDamage = {};
    lootParticlePositions = const [];
    enemyDeathParticlePositions = const [];

    message = resetMessage ?? 'Piso $floor gerado proceduralmente.';

    _queueAnimationReset();
    _buildTelegraphMap();
    notifyListeners();
  }

  bool isSpecialRoomVisited(Point<int> position) {
    return _visitedSpecialRooms.contains(position);
  }

  void _appendMessage(String suffix) {
    if (message.isEmpty) {
      message = suffix;
      return;
    }
    message = '$message $suffix';
  }

  void _handleSpecialRoomEntry(Point<int> position) {
    final roomType = specialRooms[position];
    if (roomType == null || _visitedSpecialRooms.contains(position)) {
      return;
    }

    _visitedSpecialRooms.add(position);

    switch (roomType) {
      case SpecialRoomType.treasure:
        final gain = 2 + _random.nextInt(3) + min<int>(2, floor ~/ 4);
        shards += gain;
        _appendMessage('Sala do Tesouro: +$gain shards.');
        break;
      case SpecialRoomType.event:
        final eventRoll = _random.nextInt(3);
        if (eventRoll == 0) {
          hp = min(maxHp, hp + 1);
          _appendMessage('Evento misterioso: voce recuperou 1 HP.');
        } else if (eventRoll == 1) {
          potions += 1;
          _appendMessage('Evento arcano: voce encontrou 1 pocao.');
        } else {
          final reduced = shieldTurns > 0 ? 1 : 0;
          final damage = max(0, 1 - reduced);
          if (damage > 0) {
            hp -= damage;
            damageFlashTick += 1;
            _appendMessage('Evento instavel: voce sofreu $damage de dano.');
          } else {
            _appendMessage('Evento instavel: o escudo bloqueou o dano.');
          }
        }
        break;
      case SpecialRoomType.trap:
        final rawDamage = 1 + _random.nextInt(2);
        final damage = max(0, rawDamage - (shieldTurns > 0 ? 1 : 0));
        if (damage > 0) {
          hp -= damage;
          damageFlashTick += 1;
          _appendMessage('Armadilha disparada: voce sofreu $damage de dano.');
        } else {
          _appendMessage(
            'Armadilha disparada, mas o escudo absorveu o impacto.',
          );
        }
        break;
      case SpecialRoomType.altar:
        if (hp > 1) {
          hp -= 1;
          maxStamina = min(7, maxStamina + 1);
          stamina = min(maxStamina, stamina + 1);
          damageFlashTick += 1;
          _appendMessage('Altar profano: -1 HP e +1 stamina maxima.');
        } else {
          maxHp += 1;
          hp = min(maxHp, hp + 1);
          _appendMessage('Altar benevolente: +1 HP maximo.');
        }
        break;
    }
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

  void _triggerHitStop() {
    hitStopTick += 1;
  }

  void _emitLootParticles(Point<int> position) {
    lootParticlePositions = [position];
    lootParticleTick += 1;
  }

  void _emitEnemyDeathParticles(List<Point<int>> positions) {
    if (positions.isEmpty) {
      return;
    }
    enemyDeathParticlePositions = List<Point<int>>.from(positions);
    enemyDeathParticleTick += 1;
  }

  void _setFacingDirection(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return;
    }
    _facingDx = dx.sign;
    _facingDy = dy.sign;
  }

  void _collectLootAtPlayer() {
    final lootIndex = _lootIndexAt(player);
    if (lootIndex == -1) {
      return;
    }

    final drop = loot.removeAt(lootIndex);
    _emitLootParticles(player);
    final rarityMultiplier = switch (drop.rarity) {
      LootRarity.common => 1,
      LootRarity.rare => 2,
      LootRarity.epic => 3,
    };

    lootCollected += 1;
    if (drop.type == LootType.essence) {
      final healAmount = rarityMultiplier;
      hp = min(maxHp, hp + healAmount);
      message = switch (drop.rarity) {
        LootRarity.common => 'Essencia comum: +1 HP.',
        LootRarity.rare => 'Essencia rara: +2 HP.',
        LootRarity.epic => 'Essencia epica: +3 HP.',
      };
      return;
    }

    final shardGain = rarityMultiplier;
    shards += shardGain;
    message = switch (drop.rarity) {
      LootRarity.common => 'Shard comum +1. Total: $shards.',
      LootRarity.rare => 'Shard raro +2. Total: $shards.',
      LootRarity.epic => 'Shard epico +3. Total: $shards.',
    };
  }

  Point<int>? _dashDestination(int dx, int dy) {
    var current = player;
    for (int i = 0; i < 2; i++) {
      final next = Point<int>(current.x + dx, current.y + dy);
      if (_isWall(next) || _enemyIndexAt(next) != -1) {
        break;
      }
      current = next;
    }

    if (current == player) {
      return null;
    }
    return current;
  }

  void useClassAbility() {
    if (_busy ||
        isGameOver ||
        isAwaitingRewardChoice ||
        isAwaitingShopChoice ||
        !canUseClassAbility) {
      return;
    }

    _busy = true;
    _captureAnimationOrigins();
    steps++;

    switch (playerClass) {
      case PlayerClass.slimeRogue:
        final destination = _dashDestination(_facingDx, _facingDy);
        if (destination == null) {
          message = 'Dash bloqueado.';
          _busy = false;
          notifyListeners();
          return;
        }
        player = destination;
        _triggerHitStop();
        classAbilityCooldown = 4;
        message = 'Dash de lodo executado!';
        _collectLootAtPlayer();
        _handleSpecialRoomEntry(player);
        break;
      case PlayerClass.slimeGuardian:
        shieldTurns = max(shieldTurns, 3);
        hp = min(maxHp, hp + 1);
        classAbilityCooldown = 5;
        message = 'Casca viscosa ativada: escudo e +1 HP.';
        break;
      case PlayerClass.slimeSpitter:
        var targetIndex = -1;
        for (int step = 1; step <= 3; step++) {
          final target = Point<int>(
            player.x + (_facingDx * step),
            player.y + (_facingDy * step),
          );
          if (_isWall(target)) {
            break;
          }
          final idx = _enemyIndexAt(target);
          if (idx != -1) {
            targetIndex = idx;
            break;
          }
        }

        if (targetIndex == -1) {
          message = 'Cuspe acido sem alvo.';
          _busy = false;
          notifyListeners();
          return;
        }

        final killed = _applyDamageToEnemy(targetIndex, 2);
        classAbilityCooldown = 4;
        _triggerHitStop();
        if (killed) {
          message = 'Cuspe acido dissolveu um inimigo!';
        } else {
          message = 'Cuspe acido acertou em cheio.';
        }
        break;
      case PlayerClass.slimeMage:
        final targets = <int>[];
        for (int i = 0; i < enemies.length; i++) {
          final enemy = enemies[i];
          final distance =
              (enemy.position.x - player.x).abs() +
              (enemy.position.y - player.y).abs();
          if (distance == 1) {
            targets.add(i);
          }
        }

        targets.sort((a, b) => b.compareTo(a));
        int killsByNova = 0;
        for (final i in targets) {
          if (i < enemies.length && _applyDamageToEnemy(i, 1)) {
            killsByNova += 1;
          }
        }

        classAbilityCooldown = 4;
        stamina = min(maxStamina, stamina + 1);
        _triggerHitStop();
        if (targets.isEmpty) {
          message = 'Nova Arcana sem alvos, mas sua energia foi renovada.';
        } else if (killsByNova > 0) {
          message = 'Nova Arcana vaporizou $killsByNova inimigos!';
        } else {
          message = 'Nova Arcana atingiu ${targets.length} alvo(s).';
        }
        break;
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

  void movePlayer(int dx, int dy) {
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }

    _setFacingDirection(dx, dy);

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
      _triggerHitStop();
      steps++;

      if (killed) {
        message = enemy.isBoss
            ? 'Golpe final no mini-chefe!'
            : (wasCritical
                  ? 'Critico! Espectro dissipado.'
                  : 'Voce golpeou um espectro.');
        previousEnemyPositions.remove(enemy.id);
        _buildTelegraphMap();
      } else {
        final knocked = _tryKnockback(enemyIndex, dx, dy);
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        final knockMsg = knocked ? ' Recuou!' : '';
        message = wasCritical
            ? 'Critico! Inimigo com $remaining HP.$knockMsg'
            : 'Inimigo ferido ($remaining HP).$knockMsg';
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
      _collectLootAtPlayer();
    } else {
      message = 'Voce avancou entre as salas.';
    }

    _handleSpecialRoomEntry(player);

    if (hp <= 0) {
      _afterTurn();
      _queueAnimationReset();
      notifyListeners();
      _busy = false;
      return;
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
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }

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
    Point<int> attackDir = const Point(0, 0);

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
          attackDir = dir;
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
      _triggerHitStop();

      if (killed) {
        message = enemy.isBoss
            ? 'Mini-chefe abatido!'
            : (wasCritical ? 'Critico devastador!' : 'Ataque forte certeiro.');
        previousEnemyPositions.remove(enemy.id);
        _buildTelegraphMap();
      } else {
        final knocked = _tryKnockback(targetIndex, attackDir.x, attackDir.y);
        final remaining = enemies.firstWhere((e) => e.id == enemy.id).hp;
        final knockMsg = knocked ? ' Recuau!' : '';
        message = wasCritical
            ? 'Critico! Inimigo com $remaining HP.$knockMsg'
            : 'Impacto forte! Inimigo com $remaining HP.$knockMsg';
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
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }

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

    _isGameOver = true;
    _busy = false;
    pendingRewards = [];
    pendingShopItems = [];
    _shopPhaseActive = false;
    telegraphedDamage = {};
    shieldTurns = 0;
    message = 'Voce caiu no Voidcrypt.';
    lastRunSummary = RunSummary(
      difficulty: difficulty,
      floor: floor,
      kills: kills,
      loot: lootCollected,
      shards: shards,
      steps: steps,
      duration: DateTime.now().difference(_runStartedAt),
    );
    unawaited(clearSavedRun());
  }

  bool _applyDamageToEnemy(
    int index,
    int damage, {
    List<Point<int>>? deathCollector,
  }) {
    final enemy = enemies[index];
    final remaining = enemy.hp - damage;

    if (remaining <= 0) {
      kills += 1;
      if (deathCollector != null) {
        deathCollector.add(enemy.position);
      } else {
        _emitEnemyDeathParticles([enemy.position]);
      }
      enemies.removeAt(index);
      return true;
    }

    enemies[index] = enemy.copyWith(hp: remaining);
    return false;
  }

  /// Tenta empurrar o inimigo em [index] 1 tile na direção (dx, dy).
  /// Retorna true se o knockback ocorreu (tile livre e não-parede).
  bool _tryKnockback(int index, int dx, int dy) {
    final enemy = enemies[index];
    final dest = Point<int>(enemy.position.x + dx, enemy.position.y + dy);
    if (_isWall(dest) || _enemyIndexAt(dest) != -1) return false;
    enemies[index] = enemy.copyWith(position: dest);
    return true;
  }

  void _openRewardSelection() {
    pendingRewards = _buildRandomRewardOptions();
    message = 'Escolha uma recompensa para o piso $floor.';
  }

  List<ShopItem> _buildShopItems() {
    return const [
      ShopItem(
        consumable: ConsumableType.potion,
        cost: 3,
        title: 'Pocao',
        description: 'Usar: recupera 2 HP.',
      ),
      ShopItem(
        consumable: ConsumableType.bomb,
        cost: 4,
        title: 'Bomba',
        description: 'Usar: dano em area adjacente.',
      ),
      ShopItem(
        consumable: ConsumableType.temporalShield,
        cost: 5,
        title: 'Escudo Temporal',
        description: 'Usar: reduz dano recebido por 2 turnos.',
      ),
    ];
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
    pendingShopItems = _buildShopItems();
    shopFeedbackMessage = '';
    shopFeedbackIsError = false;
    _shopPhaseActive = true;
    message = 'Reliquia recebida: ${chosen.title}. Visite a loja.';
    notifyListeners();
  }

  void buyShopItem(int index) {
    if (!isAwaitingShopChoice) return;
    if (index < 0 || index >= pendingShopItems.length) return;

    final item = pendingShopItems[index];
    if (shards < item.cost) {
      message = 'Shards insuficientes para ${item.title}.';
      shopFeedbackMessage = message;
      shopFeedbackIsError = true;
      notifyListeners();
      return;
    }

    shards -= item.cost;
    switch (item.consumable) {
      case ConsumableType.potion:
        potions += 1;
        break;
      case ConsumableType.bomb:
        bombs += 1;
        break;
      case ConsumableType.temporalShield:
        temporalShields += 1;
        break;
    }

    pendingShopItems.removeAt(index);
    message = '${item.title} comprada. Shards restantes: $shards.';
    shopFeedbackMessage = message;
    shopFeedbackIsError = false;
    notifyListeners();
  }

  void continueAfterShop() {
    if (!isAwaitingShopChoice) return;
    _shopPhaseActive = false;
    pendingShopItems = [];
    shopFeedbackMessage = '';
    shopFeedbackIsError = false;
    _loadFloor(resetMessage: 'Voce desceu para o piso $floor.');
  }

  void usePotion() {
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }
    if (potions <= 0) {
      message = 'Sem pocoes no inventario.';
      notifyListeners();
      return;
    }

    if (hp >= maxHp) {
      message = 'HP ja esta no maximo.';
      notifyListeners();
      return;
    }

    _busy = true;
    _captureAnimationOrigins();
    potions -= 1;
    hp = min(maxHp, hp + 2);
    steps++;
    message = 'Pocao usada. +2 HP.';
    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  void useBomb() {
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }
    if (bombs <= 0) {
      message = 'Sem bombas no inventario.';
      notifyListeners();
      return;
    }

    _busy = true;
    _captureAnimationOrigins();
    bombs -= 1;
    steps++;

    final targets = <int>[];
    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      final distance =
          (enemy.position.x - player.x).abs() +
          (enemy.position.y - player.y).abs();
      if (distance == 1) {
        targets.add(i);
      }
    }

    targets.sort((a, b) => b.compareTo(a));
    int kills = 0;
    final deathPositions = <Point<int>>[];
    for (final i in targets) {
      if (i < enemies.length &&
          _applyDamageToEnemy(i, 2, deathCollector: deathPositions)) {
        kills += 1;
      }
    }

    if (deathPositions.isNotEmpty) {
      _emitEnemyDeathParticles(deathPositions);
    }
    if (targets.isNotEmpty) {
      _triggerHitStop();
    }

    message = kills > 0
        ? 'Bomba explodiu e eliminou $kills inimigos.'
        : 'Bomba usada, mas sem alvos adjacentes.';

    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  void useTemporalShield() {
    if (_busy || isGameOver || isAwaitingRewardChoice || isAwaitingShopChoice) {
      return;
    }
    if (temporalShields <= 0) {
      message = 'Sem escudos temporais no inventario.';
      notifyListeners();
      return;
    }

    _busy = true;
    _captureAnimationOrigins();
    temporalShields -= 1;
    shieldTurns = max(shieldTurns, 2);
    steps++;
    message = 'Escudo temporal ativado por 2 turnos.';
    _enemyTurn();
    _afterTurn();
    _queueAnimationReset();
    notifyListeners();
    _busy = false;
  }

  bool _canEnemyMoveTo(Point<int> position, List<Point<int>> occupied) {
    if (_isWall(position)) return false;
    if (position == player) return false;
    if (position == exit) return false;
    if (occupied.contains(position)) return false;
    return true;
  }

  int _visionRangeFor(EnemyType type) {
    switch (type) {
      case EnemyType.pursuer:
        return 6;
      case EnemyType.archer:
        return 7;
      case EnemyType.tank:
        return 5;
      case EnemyType.summoner:
        return 6;
      case EnemyType.boss:
        return 8;
    }
  }

  bool _hasLineOfSightAnyDirection(Point<int> from, Point<int> to) {
    int x0 = from.x;
    int y0 = from.y;
    final int x1 = to.x;
    final int y1 = to.y;

    final int dx = (x1 - x0).abs();
    final int sx = x0 < x1 ? 1 : -1;
    final int dy = -(y1 - y0).abs();
    final int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (true) {
      if (x0 == x1 && y0 == y1) {
        return true;
      }

      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }

      if (x0 == x1 && y0 == y1) {
        return true;
      }

      if (_isWall(Point<int>(x0, y0))) {
        return false;
      }
    }
  }

  bool _enemyCanSeePlayer(EnemyEntity enemy) {
    final distance =
        (player.x - enemy.position.x).abs() +
        (player.y - enemy.position.y).abs();

    if (distance > _visionRangeFor(enemy.type)) {
      return false;
    }

    return _hasLineOfSightAnyDirection(enemy.position, player);
  }

  Point<int> _pickPatrolDestination(
    EnemyEntity enemy,
    List<Point<int>> occupied,
  ) {
    final candidates = <Point<int>>[
      Point<int>(enemy.position.x + 1, enemy.position.y),
      Point<int>(enemy.position.x - 1, enemy.position.y),
      Point<int>(enemy.position.x, enemy.position.y + 1),
      Point<int>(enemy.position.x, enemy.position.y - 1),
    ]..shuffle(_random);

    for (final candidate in candidates) {
      if (_canEnemyMoveTo(candidate, occupied)) {
        return candidate;
      }
    }

    return enemy.position;
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
        final hpBonus = _enemyHpBonusByDifficulty();
        final summoned = EnemyEntity(
          id: id,
          position: cell,
          hp: 1 + hpBonus,
          maxHp: 1 + hpBonus,
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

    final rawIncomingDamage = telegraphedDamage[player] ?? 0;
    final tunedDamage = rawIncomingDamage > 0
        ? rawIncomingDamage + _incomingDamageBonusByDifficulty()
        : 0;
    final incomingDamage = shieldTurns > 0
        ? max(0, tunedDamage - 1)
        : tunedDamage;
    bool playerWasHit = false;

    if (incomingDamage > 0) {
      hp -= incomingDamage;
      damageFlashTick += 1;
      playerWasHit = true;
    }

    telegraphedDamage = {};

    if (shieldTurns > 0) {
      shieldTurns -= 1;
    }
    if (classAbilityCooldown > 0) {
      classAbilityCooldown -= 1;
    }

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
      final canSeePlayer = _enemyCanSeePlayer(enemy);

      switch (enemy.type) {
        case EnemyType.pursuer:
        case EnemyType.boss:
          destination = canSeePlayer
              ? _pickChaseDestination(enemy, occupied)
              : _pickPatrolDestination(enemy, occupied);
          break;
        case EnemyType.archer:
          destination = canSeePlayer
              ? _pickArcherDestination(enemy, occupied)
              : _pickPatrolDestination(enemy, occupied);
          break;
        case EnemyType.tank:
          if (enemy.aiState > 0) {
            updated = updated.copyWith(aiState: enemy.aiState - 1);
          } else {
            destination = canSeePlayer
                ? _pickChaseDestination(enemy, occupied)
                : _pickPatrolDestination(enemy, occupied);
            updated = updated.copyWith(aiState: canSeePlayer ? 1 : 0);
          }
          break;
        case EnemyType.summoner:
          if (canSeePlayer && enemy.aiState >= 2) {
            final summon = _trySummon(enemy, occupied);
            if (summon != null) {
              spawned.add(summon);
            }
            updated = updated.copyWith(aiState: 0);
          } else {
            if (canSeePlayer) {
              updated = updated.copyWith(aiState: enemy.aiState + 1);
              destination = _pickArcherDestination(enemy, occupied);
            } else {
              updated = updated.copyWith(aiState: max(0, enemy.aiState - 1));
              destination = _pickPatrolDestination(enemy, occupied);
            }
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

  static Point<int> _pointFromJson(Map<String, dynamic> json) {
    return Point<int>((json['x'] as num).toInt(), (json['y'] as num).toInt());
  }

  static Map<String, dynamic> _pointToJson(Point<int> point) {
    return {'x': point.x, 'y': point.y};
  }

  static RewardOption _rewardFromJson(Map<String, dynamic> json) {
    return RewardOption(
      relic: RelicType.values[(json['relic'] as num).toInt()],
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  static ShopItem _shopItemFromJson(Map<String, dynamic> json) {
    return ShopItem(
      consumable: ConsumableType.values[(json['consumable'] as num).toInt()],
      cost: (json['cost'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  static RunSnapshot _snapshotFromJson(Map<String, dynamic> json) {
    final specialRooms = <Point<int>, SpecialRoomType>{};
    final rawSpecialRooms =
        (json['specialRooms'] as List<dynamic>? ?? const []);
    for (final raw in rawSpecialRooms) {
      final item = raw as Map<String, dynamic>;
      specialRooms[_pointFromJson(item)] =
          SpecialRoomType.values[(item['type'] as num).toInt()];
    }

    final visitedSpecial = <Point<int>>{};
    final rawVisited =
        (json['visitedSpecialRooms'] as List<dynamic>? ?? const []);
    for (final raw in rawVisited) {
      visitedSpecial.add(_pointFromJson(raw as Map<String, dynamic>));
    }

    return RunSnapshot(
      difficulty: GameDifficultyCodec.fromStorageKey(
        json['difficulty'] as String?,
      ),
      playerClass: PlayerClassCodec.fromStorageKey(
        json['playerClass'] as String?,
      ),
      map: [
        for (final row in (json['map'] as List<dynamic>))
          [for (final value in (row as List<dynamic>)) (value as num).toInt()],
      ],
      player: _pointFromJson(json['player'] as Map<String, dynamic>),
      exit: _pointFromJson(json['exit'] as Map<String, dynamic>),
      enemies: [
        for (final raw in (json['enemies'] as List<dynamic>? ?? const []))
          EnemyEntity(
            id: ((raw as Map<String, dynamic>)['id'] as num).toInt(),
            position: _pointFromJson(raw['position'] as Map<String, dynamic>),
            hp: (raw['hp'] as num).toInt(),
            maxHp: (raw['maxHp'] as num).toInt(),
            isBoss: raw['isBoss'] as bool? ?? false,
            type: EnemyType.values[(raw['type'] as num).toInt()],
            aiState: (raw['aiState'] as num?)?.toInt() ?? 0,
          ),
      ],
      loot: [
        for (final raw in (json['loot'] as List<dynamic>? ?? const []))
          LootDrop(
            id: ((raw as Map<String, dynamic>)['id'] as num).toInt(),
            type: LootType.values[(raw['type'] as num).toInt()],
            rarity: LootRarity.values[(raw['rarity'] as num).toInt()],
            position: _pointFromJson(raw['position'] as Map<String, dynamic>),
          ),
      ],
      specialRooms: specialRooms,
      visitedSpecialRooms: visitedSpecial,
      hp: (json['hp'] as num).toInt(),
      maxHp: (json['maxHp'] as num).toInt(),
      steps: (json['steps'] as num).toInt(),
      floor: (json['floor'] as num).toInt(),
      shards: (json['shards'] as num).toInt(),
      mapVisualSeed: (json['mapVisualSeed'] as num).toInt(),
      damageFlashTick: (json['damageFlashTick'] as num?)?.toInt() ?? 0,
      hitStopTick: (json['hitStopTick'] as num?)?.toInt() ?? 0,
      stamina: (json['stamina'] as num).toInt(),
      maxStamina: (json['maxStamina'] as num).toInt(),
      facingDx: (json['facingDx'] as num?)?.toInt() ?? 0,
      facingDy: (json['facingDy'] as num?)?.toInt() ?? 1,
      potions: (json['potions'] as num).toInt(),
      bombs: (json['bombs'] as num).toInt(),
      temporalShields: (json['temporalShields'] as num).toInt(),
      shieldTurns: (json['shieldTurns'] as num).toInt(),
      message: json['message'] as String? ?? '',
      activeRelics: [
        for (final raw in (json['activeRelics'] as List<dynamic>? ?? const []))
          RelicType.values[(raw as num).toInt()],
      ],
      pendingRewards: [
        for (final raw
            in (json['pendingRewards'] as List<dynamic>? ?? const []))
          _rewardFromJson(raw as Map<String, dynamic>),
      ],
      pendingShopItems: [
        for (final raw
            in (json['pendingShopItems'] as List<dynamic>? ?? const []))
          _shopItemFromJson(raw as Map<String, dynamic>),
      ],
      shopPhaseActive: json['shopPhaseActive'] as bool? ?? false,
      shopFeedbackMessage: json['shopFeedbackMessage'] as String? ?? '',
      shopFeedbackIsError: json['shopFeedbackIsError'] as bool? ?? false,
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      lootCollected: (json['lootCollected'] as num?)?.toInt() ?? 0,
      classAbilityCooldown:
          (json['classAbilityCooldown'] as num?)?.toInt() ?? 0,
      runStartedAtEpochMs:
          (json['runStartedAtEpochMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  RunSnapshot _buildSnapshot() {
    return RunSnapshot(
      difficulty: difficulty,
      playerClass: playerClass,
      map: [
        for (final row in map) [for (final tile in row) tile.index],
      ],
      player: player,
      exit: exit,
      enemies: List<EnemyEntity>.from(enemies),
      loot: List<LootDrop>.from(loot),
      specialRooms: Map<Point<int>, SpecialRoomType>.from(specialRooms),
      visitedSpecialRooms: Set<Point<int>>.from(_visitedSpecialRooms),
      hp: hp,
      maxHp: maxHp,
      steps: steps,
      floor: floor,
      shards: shards,
      mapVisualSeed: mapVisualSeed,
      damageFlashTick: damageFlashTick,
      hitStopTick: hitStopTick,
      stamina: stamina,
      maxStamina: maxStamina,
      facingDx: _facingDx,
      facingDy: _facingDy,
      potions: potions,
      bombs: bombs,
      temporalShields: temporalShields,
      shieldTurns: shieldTurns,
      message: message,
      activeRelics: List<RelicType>.from(activeRelics),
      pendingRewards: List<RewardOption>.from(pendingRewards),
      pendingShopItems: List<ShopItem>.from(pendingShopItems),
      shopPhaseActive: _shopPhaseActive,
      shopFeedbackMessage: shopFeedbackMessage,
      shopFeedbackIsError: shopFeedbackIsError,
      kills: kills,
      lootCollected: lootCollected,
      classAbilityCooldown: classAbilityCooldown,
      runStartedAtEpochMs: _runStartedAt.millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> _snapshotToJson(RunSnapshot snapshot) {
    return {
      'difficulty': snapshot.difficulty.storageKey,
      'playerClass': snapshot.playerClass.storageKey,
      'map': snapshot.map,
      'player': _pointToJson(snapshot.player),
      'exit': _pointToJson(snapshot.exit),
      'enemies': [
        for (final enemy in snapshot.enemies)
          {
            'id': enemy.id,
            'position': _pointToJson(enemy.position),
            'hp': enemy.hp,
            'maxHp': enemy.maxHp,
            'isBoss': enemy.isBoss,
            'type': enemy.type.index,
            'aiState': enemy.aiState,
          },
      ],
      'loot': [
        for (final drop in snapshot.loot)
          {
            'id': drop.id,
            'type': drop.type.index,
            'rarity': drop.rarity.index,
            'position': _pointToJson(drop.position),
          },
      ],
      'specialRooms': [
        for (final entry in snapshot.specialRooms.entries)
          {'x': entry.key.x, 'y': entry.key.y, 'type': entry.value.index},
      ],
      'visitedSpecialRooms': [
        for (final cell in snapshot.visitedSpecialRooms) _pointToJson(cell),
      ],
      'hp': snapshot.hp,
      'maxHp': snapshot.maxHp,
      'steps': snapshot.steps,
      'floor': snapshot.floor,
      'shards': snapshot.shards,
      'mapVisualSeed': snapshot.mapVisualSeed,
      'damageFlashTick': snapshot.damageFlashTick,
      'hitStopTick': snapshot.hitStopTick,
      'stamina': snapshot.stamina,
      'maxStamina': snapshot.maxStamina,
      'facingDx': snapshot.facingDx,
      'facingDy': snapshot.facingDy,
      'potions': snapshot.potions,
      'bombs': snapshot.bombs,
      'temporalShields': snapshot.temporalShields,
      'shieldTurns': snapshot.shieldTurns,
      'message': snapshot.message,
      'activeRelics': [for (final relic in snapshot.activeRelics) relic.index],
      'pendingRewards': [
        for (final reward in snapshot.pendingRewards)
          {
            'relic': reward.relic.index,
            'title': reward.title,
            'description': reward.description,
          },
      ],
      'pendingShopItems': [
        for (final item in snapshot.pendingShopItems)
          {
            'consumable': item.consumable.index,
            'cost': item.cost,
            'title': item.title,
            'description': item.description,
          },
      ],
      'shopPhaseActive': snapshot.shopPhaseActive,
      'shopFeedbackMessage': snapshot.shopFeedbackMessage,
      'shopFeedbackIsError': snapshot.shopFeedbackIsError,
      'kills': snapshot.kills,
      'lootCollected': snapshot.lootCollected,
      'classAbilityCooldown': snapshot.classAbilityCooldown,
      'runStartedAtEpochMs': snapshot.runStartedAtEpochMs,
    };
  }

  void _restoreFromSnapshot(RunSnapshot snapshot) {
    map = [
      for (final row in snapshot.map)
        [for (final tile in row) TileType.values[tile]],
    ];
    player = snapshot.player;
    exit = snapshot.exit;
    enemies = List<EnemyEntity>.from(snapshot.enemies);
    loot = List<LootDrop>.from(snapshot.loot);
    specialRooms = Map<Point<int>, SpecialRoomType>.from(snapshot.specialRooms);
    _visitedSpecialRooms
      ..clear()
      ..addAll(snapshot.visitedSpecialRooms);
    hp = snapshot.hp;
    maxHp = snapshot.maxHp;
    steps = snapshot.steps;
    floor = snapshot.floor;
    shards = snapshot.shards;
    mapVisualSeed = snapshot.mapVisualSeed;
    damageFlashTick = snapshot.damageFlashTick;
    hitStopTick = snapshot.hitStopTick;
    stamina = snapshot.stamina;
    maxStamina = snapshot.maxStamina;
    _facingDx = snapshot.facingDx;
    _facingDy = snapshot.facingDy;
    potions = snapshot.potions;
    bombs = snapshot.bombs;
    temporalShields = snapshot.temporalShields;
    shieldTurns = snapshot.shieldTurns;
    message = snapshot.message;
    activeRelics
      ..clear()
      ..addAll(snapshot.activeRelics);
    pendingRewards = List<RewardOption>.from(snapshot.pendingRewards);
    pendingShopItems = List<ShopItem>.from(snapshot.pendingShopItems);
    _shopPhaseActive = snapshot.shopPhaseActive;
    shopFeedbackMessage = snapshot.shopFeedbackMessage;
    shopFeedbackIsError = snapshot.shopFeedbackIsError;
    kills = snapshot.kills;
    lootCollected = snapshot.lootCollected;
    classAbilityCooldown = snapshot.classAbilityCooldown;
    _runStartedAt = DateTime.fromMillisecondsSinceEpoch(
      snapshot.runStartedAtEpochMs,
    );
    _isGameOver = false;
    lastRunSummary = null;
    lootParticlePositions = const [];
    enemyDeathParticlePositions = const [];
    previousPlayer = player;
    previousEnemyPositions = {
      for (final enemy in enemies) enemy.id: enemy.position,
    };
    _buildTelegraphMap();
  }

  Future<void> _persistRunIfNeeded() async {
    if (_isPersisting || _isGameOver) {
      return;
    }

    if (!(_hasMapData())) {
      return;
    }

    _isPersisting = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = _buildSnapshot();
      final encoded = jsonEncode(_snapshotToJson(snapshot));
      await prefs.setString(_savedRunKey, encoded);
    } catch (_) {
      // Falha de persistencia nao deve interromper a run.
    } finally {
      _isPersisting = false;
    }
  }

  bool _hasMapData() {
    try {
      return map.isNotEmpty && map[0].isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    unawaited(_persistRunIfNeeded());
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
