import 'package:flutter/material.dart';

import 'game_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentLevel = 1;
  int diamonds = 0;

  void startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          level: currentLevel,
          onGameOver: (bool success) {
            if (success && currentLevel < 10) {
              setState(() {
                currentLevel++;
              });
            } else if (!success) {
              setState(() {
                currentLevel = 1;
              });
            }
          },
        ),
      ),
    );
  }

  List<LevelData> levels = [
    LevelData(1, 3, 4, 10, 2),
    LevelData(2, 3, 4, 9, 3),
    LevelData(3, 3, 4, 11, 1),
    LevelData(4, 4, 4, 14, 2),
    LevelData(5, 4, 4, 13, 3),
    LevelData(6, 4, 4, 12, 4),
    LevelData(7, 4, 4, 11, 5),
    LevelData(8, 3, 4, 10, 2),
    LevelData(9, 4, 4, 12, 3),
    LevelData(10, 3, 4, 9, 3),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLevelData = levels[currentLevel - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF1B1D28),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Saper Dimond',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            height: 30,
                            width: 30,
                            child: Image.asset('assets/diamond_s.png')),
                        const SizedBox(width: 8),
                        Text(
                          diamonds.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Level: $currentLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: currentLevelData.cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: List.generate(
                      currentLevelData.rows * currentLevelData.cols,
                      (index) => Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoRow(
                      'Diamonds', currentLevelData.diamonds.toString()),
                  _buildInfoRow('Bomb', currentLevelData.bombs.toString()),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                    height: 30,
                    width: 30,
                    child: Image.asset(title == 'Diamonds'
                        ? 'assets/diamond_s.png'
                        : 'assets/bomb_s.png')),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int level;
  final Function(bool) onGameOver;

  const GameScreen({
    Key? key,
    required this.level,
    required this.onGameOver,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<Cell>> grid;
  late int rows;
  late int cols;
  late int totalDiamonds;
  late int totalBombs;
  int remainingDiamonds = 0;
  int collectedDiamonds = 0;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  void initializeGame() {
    final levelData = getLevelData(widget.level);
    rows = levelData.rows;
    cols = levelData.cols;
    totalDiamonds = levelData.diamonds;
    totalBombs = levelData.bombs;
    remainingDiamonds = totalDiamonds;

    grid = List.generate(
      rows,
      (i) => List.generate(
        cols,
        (j) => Cell(
          row: i,
          col: j,
          isDiamond: false,
          isBomb: false,
          isRevealed: false,
        ),
      ),
    );

    placeDiamondsAndBombs();
  }

  void placeDiamondsAndBombs() {
    final random = Random();
    // Place diamonds
    int diamondsPlaced = 0;
    while (diamondsPlaced < totalDiamonds) {
      final row = (random.nextDouble() * rows).floor();
      final col = (random.nextDouble() * cols).floor();

      if (!grid[row][col].isDiamond && !grid[row][col].isBomb) {
        grid[row][col].isDiamond = true;
        diamondsPlaced++;
      }
    }

    // Place bombs
    int bombsPlaced = 0;
    while (bombsPlaced < totalBombs) {
      final row = (random.nextDouble() * rows).floor();
      final col = (random.nextDouble() * cols).floor();

      if (!grid[row][col].isDiamond && !grid[row][col].isBomb) {
        grid[row][col].isBomb = true;
        bombsPlaced++;
      }
    }
  }

  void revealCell(int row, int col) {
    if (gameOver || grid[row][col].isRevealed) return;

    setState(() {
      grid[row][col].isRevealed = true;

      if (grid[row][col].isBomb) {
        // Game over - hit a bomb
        gameOver = true;
        revealAllCells();
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameResultScreen(
                isWin: false,
                collectedDiamonds: collectedDiamonds,
                level: widget.level,
                onNextLevel: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        level: widget.level,
                        onGameOver: widget.onGameOver,
                      ),
                    ),
                  );
                },
                onRestart: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        level: widget.level,
                        onGameOver: widget.onGameOver,
                      ),
                    ),
                  );
                },
                onHome: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          );
        });
      } else if (grid[row][col].isDiamond) {
        remainingDiamonds--;
        collectedDiamonds++;

        if (remainingDiamonds == 0) {
          // Level completed
          gameOver = true;
          revealAllCells();
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameResultScreen(
                  isWin: true,
                  collectedDiamonds: collectedDiamonds,
                  level: widget.level,
                  onNextLevel: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          level: widget.level,
                          onGameOver: widget.onGameOver,
                        ),
                      ),
                    );
                  },
                  onRestart: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          level: widget.level,
                          onGameOver: widget.onGameOver,
                        ),
                      ),
                    );
                  },
                  onHome: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
            );
          });
        }
      }
    });
  }

  void revealAllCells() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        grid[i][j].isRevealed = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1D28),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Saper Dimond',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.diamond,
                          color: Color(0xFF90FF00),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          collectedDiamonds.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.diamond,
                      color: Color(0xFF90FF00),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diamonds left: $remainingDiamonds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: rows * cols,
                  itemBuilder: (context, index) {
                    final row = index ~/ cols;
                    final col = index % cols;
                    final cell = grid[row][col];

                    return GestureDetector(
                      onTap: () => revealCell(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cell.isRevealed
                              ? null
                              : Color.fromARGB(255, 17, 19, 26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: cell.isRevealed
                            ? Container(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(cell.isBomb
                                            ? 'assets/bg_2.png'
                                            : 'assets/bg_1.png'))),
                                child: Center(
                                  child: cell.isBomb
                                      ? Image.asset('assets/bomb_s.png')
                                      : cell.isDiamond
                                          ? Image.asset('assets/diamond_s.png')
                                          : null,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  LevelData getLevelData(int level) {
    final levels = [
      LevelData(1, 3, 4, 10, 2),
      LevelData(2, 3, 4, 9, 3),
      LevelData(3, 3, 4, 11, 1),
      LevelData(4, 4, 4, 14, 2),
      LevelData(5, 4, 4, 13, 3),
      LevelData(6, 4, 4, 12, 4),
      LevelData(7, 4, 4, 11, 5),
      LevelData(8, 3, 4, 10, 2),
      LevelData(9, 4, 4, 12, 3),
      LevelData(10, 3, 4, 9, 3),
    ];

    return levels[level - 1];
  }
}

class Cell {
  final int row;
  final int col;
  bool isDiamond;
  bool isBomb;
  bool isRevealed;

  Cell({
    required this.row,
    required this.col,
    required this.isDiamond,
    required this.isBomb,
    required this.isRevealed,
  });
}

class LevelData {
  final int level;
  final int rows;
  final int cols;
  final int diamonds;
  final int bombs;

  LevelData(this.level, this.rows, this.cols, this.diamonds, this.bombs);
}

class Math {
  static Random random = Random();
}

class Random {
  double nextDouble() {
    return DateTime.now().microsecondsSinceEpoch % 1000 / 1000;
  }
}
