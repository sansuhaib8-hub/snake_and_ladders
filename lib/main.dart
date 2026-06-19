import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

void main() => runApp(const CyberSnakeLaddersApp());

class CyberSnakeLaddersApp extends StatelessWidget {
  const CyberSnakeLaddersApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کایەی مار و پەیژە',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xFF040508),
      ),
      home: const CyberGamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Player {
  String name;
  int position;
  Color color;
  bool isWinner;
  
  Player({
    required this.name,
    this.position = 0,
    required this.color,
    this.isWinner = false,
  });
}

class CyberGamePage extends StatefulWidget {
  const CyberGamePage({super.key});
  @override
  State<CyberGamePage> createState() => _CyberGamePageState();
}

class _CyberGamePageState extends State<CyberGamePage> 
    with TickerProviderStateMixin {
  
  List<Player> players = [
    Player(name: "یاریزان ١", color: const Color(0xFF00FFFF)),
    Player(name: "یاریزان ٢", color: const Color(0xFFFF00FF)),    Player(name: "یاریزان ٣", color: const Color(0xFF00FF66)),
    Player(name: "یاریزان ٤", color: const Color(0xFFFFCC00)),
  ];
  
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isRolling = false;
  bool isMoving = false;
  bool gameFinished = false;
  String message = "بۆ هاویشتنی زار، کلیک لە بۆردەکە بکە! 🎲";
  
  late AnimationController _diceController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _celebrationController;
  
  final Map<int, int> snakes = {
    17: 7, 54: 34, 62: 19, 64: 60, 
    87: 24, 93: 73, 95: 75, 99: 78
  };
  
  final Map<int, int> ladders = {
    4: 14, 9: 31, 20: 38, 28: 84, 
    40: 59, 51: 67, 63: 81, 71: 91
  };

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _diceController.dispose();    _bounceController.dispose();
    _glowController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  int _getDisplayCellNumber(int gridIndex) {
    int row = gridIndex ~/ 10;
    int col = gridIndex % 10;
    int actualRow = 9 - row;
    int actualCol = (actualRow % 2 == 1) ? (9 - col) : col;
    return (actualRow * 10) + actualCol + 1;
  }

  void _showEditPlayerDialog(int index) {
    final textController = TextEditingController(text: players[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: players[index].color.withOpacity(0.5), width: 2),
        ),
        title: Text(
          "گۆڕینی ناوی ${players[index].name}",
          style: TextStyle(
            color: players[index].color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: players[index].color),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: players[index].color, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "پاشگەزمایەوە",
              style: TextStyle(color: Colors.grey),            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  players[index].name = textController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: players[index].color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("تۆمارکردن"),
          ),
        ],
      ),
    );
  }

  Offset _getCellCoordinates(int pos, double cSize) {
    if (pos == 0) return Offset(cSize * 0.5, cSize * 0.5);
    int idx = pos - 1;
    int row = idx ~/ 10;
    int col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    double padding = (cSize - (cSize * 0.5)) / 2;
    return Offset(col * cSize + padding, (9 - row) * cSize + padding);
  }

  void rollDice() async {
    if (isRolling || isMoving || gameFinished) return;
    
    Player cp = players[currentPlayerIndex];
    setState(() {
      isRolling = true;
      message = "[ ${cp.name} ] زارەکە دەهاوێژێت... 🎲";
    });
    
    _diceController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 800));
    
    final res = math.Random().nextInt(6) + 1;
    setState(() {
      diceValue = res;      isRolling = false;
    });
    
    int target = cp.position + diceValue;
    
    if (target > 100) {
      setState(() {
        message = "⚠️ ژمارەی دەقیقی دەوێت!";
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      _nextTurn();
      return;
    }
    
    isMoving = true;
    
    // Move player step by step
    for (int i = cp.position + 1; i <= target; i++) {
      setState(() {
        cp.position = i;
      });
      _bounceController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    
    // Check for ladder
    if (ladders.containsKey(cp.position)) {
      setState(() {
        message = "🪜 [ ${cp.name} ] پەیژەیەکی دۆزییەوە! ⬆️";
      });
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        cp.position = ladders[cp.position]!;
      });
      await Future.delayed(const Duration(milliseconds: 600));
    } 
    // Check for snake
    else if (snakes.containsKey(cp.position)) {
      setState(() {
        message = "🐍 [ ${cp.name} ] بە مارەکە گیرا! ⬇️";
      });
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        cp.position = snakes[cp.position]!;
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }
    
    // Check for win
    if (cp.position == 100) {      setState(() {
        gameFinished = true;
        cp.isWinner = true;
        message = "👑 [ ${cp.name} ] بردییەوە! 👑";
      });
      _celebrationController.forward();
      _showWinDialog(cp);
      isMoving = false;
      return;
    }
    
    _nextTurn();
    isMoving = false;
  }

  void _showWinDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: winner.color, width: 3),
        ),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
            const SizedBox(height: 10),
            Text(
              "🎉 بردنەوە! 🎉",
              style: TextStyle(
                color: winner.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "[ ${winner.name} ] بردییەوە!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },            icon: const Icon(Icons.refresh),
            label: const Text("یاری نوێ"),
            style: ElevatedButton.styleFrom(
              backgroundColor: winner.color,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextTurn() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      message = "نۆرەی [ ${players[currentPlayerIndex].name} ] یە 🔥";
    });
  }

  void resetGame() {
    setState(() {
      for (var p in players) {
        p.position = 0;
        p.isWinner = false;
      }
      currentPlayerIndex = 0;
      diceValue = 1;
      gameFinished = false;
      message = "نۆرەی [ ${players[0].name} ] یە 🔥";
    });
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = players[currentPlayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF040508),
      body: SafeArea(
        child: Column(
          children: [
            // Player info bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(                color: const Color(0xFF0D0E15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activePlayer.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(players.length, (index) {
                  final p = players[index];
                  bool isCurrent = index == currentPlayerIndex;
                  return InkWell(
                    onTap: () => _showEditPlayerDialog(index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrent ? p.color : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isCurrent ? p.color.withOpacity(0.15) : Colors.transparent,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: p.color.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.color.withOpacity(0.6),                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.name,
                                style: TextStyle(
                                  color: isCurrent ? p.color : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "خانەی: ${p.position}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Game board
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: isRolling || isMoving || gameFinished ? null : rollDice,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: activePlayer.color.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activePlayer.color.withOpacity(0.2),
                          blurRadius: 30,                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bSize = constraints.maxWidth;
                            final cSize = bSize / 10;
                            return Stack(
                              children: [
                                // Grid cells
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 10,
                                  ),
                                  itemCount: 100,
                                  itemBuilder: (context, idx) {
                                    int cellNum = _getDisplayCellNumber(idx);
                                    bool isSnakeHead = snakes.containsKey(cellNum);
                                    bool isLadderBottom = ladders.containsKey(cellNum);
                                    
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: idx % 2 == 0
                                            ? const Color(0xFF121424)
                                            : const Color(0xFF090A12),
                                        border: Border.all(
                                          color: Colors.black45,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "$cellNum",
                                          style: TextStyle(
                                            fontSize: cSize * 0.3,
                                            color: isSnakeHead
                                                ? Colors.redAccent.withOpacity(0.6)
                                                : isLadderBottom
                                                    ? Colors.amber.withOpacity(0.6)
                                                    : Colors.white.withOpacity(0.25),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),                                    );
                                  },
                                ),

                                // Snakes and ladders
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: AnimatedBuilder(
                                      animation: _glowController,
                                      builder: (context, child) => CustomPaint(
                                        painter: AdvancedBoardPainter(
                                          snakes: snakes,
                                          ladders: ladders,
                                          animationValue: _glowController.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Players
                                ...List.generate(players.length, (index) {
                                  final p = players[index];
                                  final coords = _getCellCoordinates(p.position, cSize);
                                  return AnimatedPositioned(
                                    duration: Duration(
                                      milliseconds: (index == currentPlayerIndex && isMoving) ? 250 : 350,
                                    ),
                                    curve: Curves.easeInOut,
                                    left: coords.dx,
                                    top: coords.dy,
                                    width: cSize * 0.5,
                                    height: cSize * 0.5,
                                    child: AnimatedScale(
                                      scale: (index == currentPlayerIndex && isMoving) ? 1.2 : 1.0,
                                      duration: const Duration(milliseconds: 250),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white,
                                              p.color,
                                              p.color.withOpacity(0.8),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),                                          boxShadow: [
                                            BoxShadow(
                                              color: p.color.withOpacity(0.8),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Message
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                message,
                style: TextStyle(
                  color: activePlayer.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

            // Dice and reset button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                IconButton(
                  onPressed: gameFinished ? resetGame : null,
                  icon: Icon(
                    Icons.refresh,
                    color: gameFinished ? activePlayer.color : Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),                
                // Dice
                GestureDetector(
                  onTap: isRolling || isMoving || gameFinished ? null : rollDice,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11121C),
                      border: Border.all(
                        color: activePlayer.color,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: activePlayer.color.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isRolling
                          ? RotationTransition(
                              turns: _diceController,
                              child: Icon(
                                Icons.casino,
                                size: 36,
                                color: activePlayer.color,
                              ),
                            )
                          : Text(
                              "$diceValue",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: activePlayer.color,
                                shadows: [
                                  Shadow(
                                    color: activePlayer.color,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class AdvancedBoardPainter extends CustomPainter {
  final Map<int, int> snakes, ladders;
  final double animationValue;

  AdvancedBoardPainter({
    required this.snakes,
    required this.ladders,
    required this.animationValue,
  });

  Offset _getCenter(int cell, Size size) {
    double cw = size.width / 10;
    double ch = size.height / 10;
    int idx = cell - 1;
    int row = idx ~/ 10;
    int col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    return Offset((col + 0.5) * cw, (9 - row + 0.5) * ch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ladders
    ladders.forEach((s, e) {
      Offset pS = _getCenter(s, size);
      Offset pE = _getCenter(e, size);
      double dx = pE.dx - pS.dx;
      double dy = pE.dy - pS.dy;
      double len = math.sqrt(dx * dx + dy * dy);
      Offset ox = Offset(-dy / len * 6, dx / len * 6);

      // Shadow
      canvas.drawLine(
        pS + const Offset(3, 3),
        pE + const Offset(3, 3),
        Paint()
          ..color = Colors.black45
          ..strokeWidth = 8.0,
      );
      // Side rails
      canvas.drawLine(
        pS - ox,
        pE - ox,
        Paint()
          ..color = const Color(0xFFFFCC00)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        pS + ox,
        pE + ox,
        Paint()
          ..color = const Color(0xFFFFCC00)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round,
      );

      // Rungs
      int rungs = (len / 15).floor();
      for (int i = 1; i < rungs; i++) {
        double t = i / rungs;
        Offset pR1 = Offset.lerp(pS - ox, pE - ox, t)!;
        Offset pR2 = Offset.lerp(pS + ox, pE + ox, t)!;
        canvas.drawLine(
          pR1,
          pR2,
          Paint()
            ..color = Colors.white70
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    });

    // Draw snakes
    snakes.forEach((s, e) {
      Offset pS = _getCenter(s, size);
      Offset pE = _getCenter(e, size);
      Path snakePath = Path();
      snakePath.moveTo(pS.dx, pS.dy);

      double dx = pE.dx - pS.dx;
      double dy = pE.dy - pS.dy;
      double len = math.sqrt(dx * dx + dy * dy);
      int segments = 20;

      for (int i = 1; i <= segments; i++) {
        double t = i / segments;
        Offset loc = Offset.lerp(pS, pE, t)!;        double wave = math.sin((t * math.pi * 4) - (animationValue * math.pi * 2)) * 10;
        Offset normal = Offset(-dy / len * wave, dx / len * wave);
        snakePath.lineTo(loc.dx + normal.dx, loc.dy + normal.dy);
      }

      // Glow effect
      canvas.drawPath(
        snakePath,
        Paint()
          ..color = const Color(0xFFFF3366).withOpacity(0.3)
          ..strokeWidth = 12.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Main snake body
      canvas.drawPath(
        snakePath,
        Paint()
          ..color = const Color(0xFFFF3366)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Snake head
      canvas.drawCircle(
        pS,
        8,
        Paint()..color = Colors.redAccent,
      );
      canvas.drawCircle(
        pS,
        3,
        Paint()..color = Colors.white,
      );
    });
  }

  @override
  bool shouldRepaint(covariant AdvancedBoardPainter old) => true;
}