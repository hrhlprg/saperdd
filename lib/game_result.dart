import 'package:flutter/material.dart';

class GameResultScreen extends StatelessWidget {
  final bool isWin;
  final int collectedDiamonds;
  final int level;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameResultScreen({
    Key? key,
    required this.isWin,
    required this.collectedDiamonds,
    required this.level,
    required this.onNextLevel,
    required this.onRestart,
    required this.onHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xBF1B1D28), // Semi-transparent background
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D28),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Win/Lose image
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  fit: BoxFit.contain,
                  isWin ? 'assets/win.png' : 'assets/lose.png',
                  height: 200,
                  width: 200,
                ),
              ),

              // Show diamonds collected if win
              if (isWin)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.diamond,
                        color: Color(0xFF90FF00),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$collectedDiamonds",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: isWin ? _buildWinButtons() : _buildLoseButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onNextLevel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90FF00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Next level',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoseButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF90FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Restart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: onHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
