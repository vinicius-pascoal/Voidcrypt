import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const VoidcryptApp());
}

class VoidcryptApp extends StatelessWidget {
  const VoidcryptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voidcrypt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF081019),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const GamePage(),
    );
  }
}

enum TileType { wall, floor, exit }

class FloorData {
  final List<List<TileType>> tiles;
  final Point<int> playerStart;
  final Point<int> exit;
  final List<Point<int>> enemies;

  FloorData({
    required this.tiles,
    required this.playerStart,
    required this.exit,
    required this.enemies,
  });
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int visibleCols = 12;
  static const int visibleRows = 7;

  final Random random = Random();

  final List<List<String>> floors = const [
    [
      "################",
      "#P....#.......X#",
      "#.##.#.#####.#.#",
      "#....#...#...#.#",
      "####.###.#.#.#.#",
      "#......#.#.#...#",
      "#.######.#.###.#",
      "#...G..#.#...#.#",
      "#.####.#.###.#.#",
      "#......#.....#.#",
      "################",
    ],
    [
      "################",
      "#P..#......#..X#",
      "#.#.#.####.#.#.#",
      "#.#...#..G.#.#.#",
      "#.###.#.##.#.#.#",
      "#.....#....#...#",
      "###.#####.####.#",
      "#...#...#......#",
      "#.#.#.#.#.####.#",
      "#...#...#..G...#",
      "################",
    ],
  ];

  late List<List<TileType>> map;
  Point<int> player = const Point(1, 1);
  Point<int> exit = const Point(1, 1);
  List<Point<int>> enemies = [];

  int hp = 5;
  int steps = 0;
  int currentFloor = 0;
  String message = "Encontre a saída da cripta.";

  @override
  void initState() {
    super.initState();
    _loadFloor(0, fullReset: true, customMessage: "Entre em Voidcrypt.");
  }

  void _loadFloor(
    int floorIndex, {
    bool fullReset = false,
    String? customMessage,
  }) {
    final data = _parseFloor(floors[floorIndex]);

    setState(() {
      currentFloor = floorIndex;
      map = data.tiles;
      player = data.playerStart;
      exit = data.exit;
      enemies = List<Point<int>>.from(data.enemies);

      if (fullReset) {
        hp = 5;
        steps = 0;
      } else {
        hp = min(5, hp + 1);
      }

      message = customMessage ?? "Piso ${floorIndex + 1}: encontre a saída.";
    });
  }

  FloorData _parseFloor(List<String> raw) {
    final tiles = <List<TileType>>[];
    final parsedEnemies = <Point<int>>[];
    Point<int> start = const Point(1, 1);
    Point<int> parsedExit = const Point(1, 1);

    for (int y = 0; y < raw.length; y++) {
      final row = <TileType>[];

      for (int x = 0; x < raw[y].length; x++) {
        final char = raw[y][x];

        switch (char) {
          case '#':
            row.add(TileType.wall);
            break;
          case 'X':
            row.add(TileType.exit);
            parsedExit = Point(x, y);
            break;
          case 'P':
            row.add(TileType.floor);
            start = Point(x, y);
            break;
          case 'G':
            row.add(TileType.floor);
            parsedEnemies.add(Point(x, y));
            break;
          default:
            row.add(TileType.floor);
        }
      }

      tiles.add(row);
    }

    return FloorData(
      tiles: tiles,
      playerStart: start,
      exit: parsedExit,
      enemies: parsedEnemies,
    );
  }

  bool _isInside(Point<int> p) {
    return p.y >= 0 && p.y < map.length && p.x >= 0 && p.x < map[0].length;
  }

  bool _isWalkable(Point<int> p) {
    return _isInside(p) && map[p.y][p.x] != TileType.wall;
  }

  bool _canEnemyMoveTo(
    Point<int> p, {
    required int currentIndex,
    required List<Point<int>> updatedEnemies,
  }) {
    if (!_isInside(p)) return false;
    if (map[p.y][p.x] == TileType.wall) return false;
    if (p == player) return false;
    if (p == exit) return false;
    if (updatedEnemies.contains(p)) return false;

    for (int i = 0; i < enemies.length; i++) {
      if (i != currentIndex && enemies[i] == p) {
        return false;
      }
    }

    return true;
  }

  void _movePlayer(int dx, int dy) {
    final next = Point(player.x + dx, player.y + dy);

    if (!_isWalkable(next)) {
      setState(() {
        message = "Uma parede bloqueia seu caminho.";
      });
      return;
    }

    bool reachedExit = false;

    setState(() {
      steps++;

      final enemyIndex = enemies.indexOf(next);

      if (enemyIndex != -1) {
        enemies.removeAt(enemyIndex);
        message = "Você eliminou um espectro.";
      } else {
        player = next;
        reachedExit = player == exit;
        message = reachedExit
            ? "Você encontrou a saída do piso."
            : "Você avançou pela cripta.";
      }

      if (!reachedExit) {
        _enemyTurn();
      }
    });

    if (hp <= 0) {
      _loadFloor(
        0,
        fullReset: true,
        customMessage: "Você tombou na cripta e despertou na entrada.",
      );
      return;
    }

    if (reachedExit) {
      if (currentFloor + 1 >= floors.length) {
        _loadFloor(
          0,
          fullReset: true,
          customMessage: "Demo concluída. A run foi reiniciada.",
        );
      } else {
        _loadFloor(
          currentFloor + 1,
          customMessage: "Piso ${currentFloor + 2}: o ar ficou mais pesado.",
        );
      }
    }
  }

  void _attack() {
    final dirs = <Point<int>>[
      const Point(0, -1),
      const Point(1, 0),
      const Point(0, 1),
      const Point(-1, 0),
    ];

    int foundIndex = -1;

    for (final dir in dirs) {
      final target = Point(player.x + dir.x, player.y + dir.y);
      foundIndex = enemies.indexOf(target);
      if (foundIndex != -1) break;
    }

    setState(() {
      if (foundIndex != -1) {
        enemies.removeAt(foundIndex);
        steps++;
        message = "Seu golpe dissipou um inimigo.";
        _enemyTurn();
      } else {
        message = "Nenhum inimigo ao alcance.";
      }
    });

    if (hp <= 0) {
      _loadFloor(
        0,
        fullReset: true,
        customMessage: "Você tombou na cripta e despertou na entrada.",
      );
    }
  }

  void _waitTurn() {
    setState(() {
      steps++;
      message = "Você prende a respiração e observa o vazio.";
      _enemyTurn();
    });

    if (hp <= 0) {
      _loadFloor(
        0,
        fullReset: true,
        customMessage: "Você tombou na cripta e despertou na entrada.",
      );
    }
  }

  void _enemyTurn() {
    if (enemies.isEmpty) return;

    final updatedEnemies = <Point<int>>[];
    bool playerWasHit = false;

    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      final dx = player.x - enemy.x;
      final dy = player.y - enemy.y;

      if (dx.abs() + dy.abs() == 1) {
        updatedEnemies.add(enemy);
        playerWasHit = true;
        hp -= 1;
        continue;
      }

      Point<int> destination = enemy;
      final candidates = <Point<int>>[];

      if (dx.abs() >= dy.abs()) {
        if (dx != 0) {
          candidates.add(Point(enemy.x + dx.sign, enemy.y));
        }
        if (dy != 0) {
          candidates.add(Point(enemy.x, enemy.y + dy.sign));
        }
      } else {
        if (dy != 0) {
          candidates.add(Point(enemy.x, enemy.y + dy.sign));
        }
        if (dx != 0) {
          candidates.add(Point(enemy.x + dx.sign, enemy.y));
        }
      }

      final fallback = <Point<int>>[
        Point(enemy.x + 1, enemy.y),
        Point(enemy.x - 1, enemy.y),
        Point(enemy.x, enemy.y + 1),
        Point(enemy.x, enemy.y - 1),
      ]..shuffle(random);

      candidates.addAll(fallback);

      for (final candidate in candidates) {
        if (_canEnemyMoveTo(
          candidate,
          currentIndex: i,
          updatedEnemies: updatedEnemies,
        )) {
          destination = candidate;
          break;
        }
      }

      updatedEnemies.add(destination);
    }

    enemies = updatedEnemies;

    if (playerWasHit) {
      message = hp > 0
          ? "As sombras o feriram."
          : "O vazio consumiu sua última força.";
    }
  }

  Offset _viewportOrigin() {
    final maxStartCol = max(0, map[0].length - visibleCols);
    final maxStartRow = max(0, map.length - visibleRows);

    final startCol = min(max(0, player.x - (visibleCols ~/ 2)), maxStartCol);
    final startRow = min(max(0, player.y - (visibleRows ~/ 2)), maxStartRow);

    return Offset(startCol.toDouble(), startRow.toDouble());
  }

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

  Widget _buildBoard() {
    final origin = _viewportOrigin();
    final startCol = origin.dx.toInt();
    final startRow = origin.dy.toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / visibleCols;
        final cellHeight = constraints.maxHeight / visibleRows;
        final iconSize = min(cellWidth, cellHeight) * 0.52;

        final children = <Widget>[];

        for (int row = 0; row < visibleRows; row++) {
          for (int col = 0; col < visibleCols; col++) {
            final mapX = startCol + col;
            final mapY = startRow + row;
            final pos = Point(mapX, mapY);
            final tile = map[mapY][mapX];

            final isPlayer = player == pos;
            final isEnemy = enemies.contains(pos);
            final isExit = exit == pos;

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
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isExit)
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: iconSize,
                            color: const Color(0xFF72F0B5),
                          ),
                        if (isEnemy)
                          Container(
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
                        if (isPlayer)
                          Container(
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            _movePlayer(velocity > 0 ? 1 : -1, 0);
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            _movePlayer(0, velocity > 0 ? 1 : -1);
          },
          child: Stack(children: children),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildDirectionButton(
    IconData icon,
    VoidCallback onPressed, {
    double size = 64,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF1C2633),
        ),
        child: Icon(icon, size: size * 0.5),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final veryCompact = constraints.maxHeight < 430;
          final dpadSize = compact ? 54.0 : 68.0;
          final spacing = compact ? 8.0 : 12.0;
          final controlWidth = min(
            constraints.maxWidth,
            compact ? 250.0 : 300.0,
          );

          Widget iconControlButton({
            required IconData icon,
            required VoidCallback onPressed,
          }) {
            return SizedBox(
              width: dpadSize,
              height: dpadSize,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF1C2633),
                ),
                child: Icon(icon, size: dpadSize * 0.44),
              ),
            );
          }

          Widget controlCluster() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconControlButton(
                            icon: Icons.gavel_rounded,
                            onPressed: _attack,
                          ),
                          SizedBox(width: spacing + 4),
                          _buildDirectionButton(
                            Icons.keyboard_arrow_up_rounded,
                            () => _movePlayer(0, -1),
                            size: dpadSize,
                          ),
                          SizedBox(width: spacing + 4),
                          iconControlButton(
                            icon: Icons.hourglass_bottom_rounded,
                            onPressed: _waitTurn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDirectionButton(
                            Icons.keyboard_arrow_left_rounded,
                            () => _movePlayer(-1, 0),
                            size: dpadSize,
                          ),
                          SizedBox(width: spacing + 4),
                          _buildDirectionButton(
                            Icons.keyboard_arrow_down_rounded,
                            () => _movePlayer(0, 1),
                            size: dpadSize,
                          ),
                          SizedBox(width: spacing + 4),
                          _buildDirectionButton(
                            Icons.keyboard_arrow_right_rounded,
                            () => _movePlayer(1, 0),
                            size: dpadSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final title = Text(
            "Voidcrypt",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          );

          if (veryCompact) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: controlWidth,
                        child: controlCluster(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: controlWidth, child: controlCluster()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStatChip(Icons.favorite_rounded, "HP $hp/5"),
                        _buildStatChip(
                          Icons.layers_rounded,
                          "Piso ${currentFloor + 1}",
                        ),
                        _buildStatChip(
                          Icons.directions_walk_rounded,
                          "Passos $steps",
                        ),
                        _buildStatChip(
                          Icons.auto_awesome_rounded,
                          "Inimigos ${enemies.length}",
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B121B),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: visibleCols / visibleRows,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: _buildBoard(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: _buildControlPanel()),
            ],
          ),
        ),
      ),
    );
  }
}
