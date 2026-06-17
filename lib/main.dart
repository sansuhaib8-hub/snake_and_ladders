import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const SnakeAndLaddersApp());
}

class SnakeAndLaddersApp extends StatelessWidget {
  const SnakeAndLaddersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مار و پەیژە',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial', // Default font for simplicity
      ),
      home: const GamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int playerPosition = 0;
  int diceValue = 1;
  bool isRolling = false;
  String message = "بەخێربێیت بۆ یاری مار و پەیژە!";

  // Snakes: Start -> End
  final Map<int, int> snakes = {
    16: 5,
    46: 24,
    48: 29,
    61: 18,
    63: 59,
    86: 23,
    92: 72,
    94: 74,
    97: 77,
    98: 78,
  };

  // Ladders: Start -> End
  final Map<int, int> ladders = {
    1: 37,
    3: 13,
    7: 30,
    20: 41,
    27: 83,
    35: 43,
    50: 66,
    70: 90,
    79: 99,
  };

  void rollDice() {
    if (isRolling) return;

    setState(() {
      isRolling = true;
      message = "خەریکی هاوێشتنی زارەکە...";
    });

    Timer(const Duration(milliseconds: 600), () {
      setState(() {
        diceValue = Random().nextInt(6) + 1;
        int nextPosition = playerPosition + diceValue;

        if (nextPosition > 99) {
          message = "پێویستت بە ژمارەی تەواو هەیە بۆ بردنەوە!";
        } else {
          playerPosition = nextPosition;
          message = "زارەکە: $diceValue";

          // Check for Ladders
          if (ladders.containsKey(playerPosition)) {
            playerPosition = ladders[playerPosition]!;
            message += " - دەستخۆش! بە پەیژەکەدا سەرکەوتیت!";
          }
          // Check for Snakes
          else if (snakes.containsKey(playerPosition)) {
            playerPosition = snakes[playerPosition]!;
            message += " - ئای! مارەکە گەستی!";
          }

          if (playerPosition == 99) {
            message = "پیرۆزە! تۆ یارییەکەت بردەوە!";
          }
        }
        isRolling = false;
      });
    });
  }

  void resetGame() {
    setState(() {
      playerPosition = 0;
      diceValue = 1;
      message = "بەخێربێیت بۆ یاری مار و پەیژە!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('یاری مار و پەیژە'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                reverse: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  int cellIndex = index;
                  // Handle Boustrophedon (snake-like) numbering
                  int row = index ~/ 10;
                  int col = index % 10;
                  if (row % 2 == 1) {
                    cellIndex = (row * 10) + (9 - col);
                  }

                  bool isPlayerHere = cellIndex == playerPosition;
                  bool isSnake = snakes.containsKey(cellIndex);
                  bool isLadder = ladders.containsKey(cellIndex);

                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: (cellIndex % 2 == 0) ? Colors.green[100] : Colors.green[200],
                      border: Border.all(color: Colors.green[800]!, width: 0.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${cellIndex + 1}',
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        if (isSnake)
                          const Icon(Icons.bug_report, color: Colors.red, size: 16),
                        if (isLadder)
                          const Icon(Icons.stairs, color: Colors.blue, size: 16),
                        if (isPlayerHere)
                          const Icon(Icons.person, color: Colors.deepPurple, size: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Center(
                        child: Text(
                          isRolling ? "?" : "$diceValue",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: isRolling || playerPosition == 99 ? null : rollDice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text('زارەکە بهاوێژە', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
