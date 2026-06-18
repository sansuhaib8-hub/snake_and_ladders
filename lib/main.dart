import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const CyberSnakeLaddersApp());
}

class CyberSnakeLaddersApp extends StatelessWidget {
  const CyberSnakeLaddersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کایەی مار و پەیژە',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D0E15),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Segoe UI',
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
  int score;

  Player({required this.name, this.position = 1, required this.color, this.score = 0});
}

class CyberGamePage extends StatefulWidget {
  const CyberGamePage({super.key});

  @override
  State<CyberGamePage> createState() => _CyberGamePageState();
}

class _CyberGamePageState extends State<CyberGamePage> with TickerProviderStateMixin {
  List<Player> players = [
    Player(name: "یاریزان ١", color: const Color(0xFF00FFFF)),
    Player(name: "یاریزان ٢", color: const Color(0xFFFF00FF)),
  ];
  
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isRolling = false;
  bool isMoving = false;
  bool gameFinished = false;
  String message = "بۆ دەستکاریکردنی ناوەکان، کلیک لەسەر کارتەکانی سەرەوە بکە 🛠️";

  late AnimationController _diceController;
  late AnimationController _bounceController;
  late AnimationController _liveBoardController;
  late Animation<double> _bounceAnimation;

  final Map<int, int> snakes = {
    17: 7, 54: 34, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78,
  };

  final Map<int, int> ladders = {
    4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 51: 67, 63: 81, 71: 91,
  };

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _bounceController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _liveBoardController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -15.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -15.0, end: 0.0).chain(CurveTween(curve: Curves.bounceIn)), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _diceController.dispose();
    _bounceController.dispose();
    _liveBoardController.dispose();
    super.dispose();
  }

  void _showEditPlayerDialog(int index) {
    final textController = TextEditingController(text: players[index].name);
    Color playerColor = players[index].color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: playerColor.withOpacity(0.3))),
        title: Text("گۆڕینی ناوی ${players[index].name}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "ناوە نوێیەکە بنووسە...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: playerColor.withOpacity(0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: playerColor, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("پاشگەزبوونەوە", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: playerColor, foregroundColor: Colors.black),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  String oldName = players[index].name;
                  players[index].name = textController.text.trim();
                  message = "ناوی [ $oldName ] گۆڕدرا بۆ [ ${players[index].name} ] ✏️";
                });
                Navigator.pop(context);
              }
            },
            child: const Text("پاشەکەوت بکە", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog() {
    if (players.length >= 4) return;

    final textController = TextEditingController();
    final List<Color> availableColors = [const Color(0xFF00FF66), const Color(0xFFFFCC00)];
    Color playerColor = availableColors[players.length - 2];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: playerColor.withOpacity(0.3))),
        title: const Text("زیادکردنی یاریزانی نوێ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "ناوی یاریزان بنووسە...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: playerColor.withOpacity(0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: playerColor, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("پاشگەزبوونەوە", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: playerColor, foregroundColor: Colors.black),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  players.add(Player(name: textController.text.trim(), color: playerColor));
                  message = "${textController.text.trim()} هاتە ناو یارییەکەوە! 🎉";
                });
                Navigator.pop(context);
              }
            },
            child: const Text("زیادبکە", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Offset _getCellCoordinates(int position, double cellSize, int playerIndex) {
    int zeroIndexed = position - 1;
    int row = zeroIndexed ~/ 10;
    int col = zeroIndexed % 10;

    if (row % 2 == 1) col = 9 - col;

    double x = col * cellSize;
    double y = (9 - row) * cellSize;

    double offsetX = (playerIndex % 2 == 0) ? 1.5 : cellSize * 0.35;
    double offsetY = (playerIndex < 2) ? 1.5 : cellSize * 0.35;

    return Offset(x + offsetX, y + offsetY);
  }

  void rollDice() async {
    if (isRolling || isMoving || gameFinished) return;

    Player currentPlayer = players[currentPlayerIndex];

    setState(() {
      isRolling = true;
      message = "زارەکە بۆ [ ${currentPlayer.name} ] دەسوڕێتەوە... 🎲";
    });

    _diceController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 600));

    final randomResult = math.Random().nextInt(6) + 1;
    setState(() {
      diceValue = randomResult;
      isRolling = false;
    });

    int targetPos = currentPlayer.position + diceValue;

    if (targetPos > 100) {
      setState(() {
        message = "⚠️ ${currentPlayer.name} پێویستی بە ژمارەی تەواو هەیە! نۆرە گۆڕدرا.";
        _nextTurn();
      });
      return;
    }

    isMoving = true;

    for (int i = currentPlayer.position + 1; i <= targetPos; i++) {
      setState(() {
        currentPlayer.position = i;
        currentPlayer.score += 1;
      });
      _bounceController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 240));
    }

    if (ladders.containsKey(currentPlayer.position)) {
      int nextPos = ladders[currentPlayer.position]!;
      setState(() { message = "🪜⚡ بژیت ${currentPlayer.name}! بە پەیژەدا سەرکەوت بۆ $nextPos!"; });
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() { currentPlayer.position = nextPos; currentPlayer.score += 15; });
      _bounceController.forward(from: 0.0);
    } else if (snakes.containsKey(currentPlayer.position)) {
      int nextPos = snakes[currentPlayer.position]!;
      setState(() { message = "🐍💥 ئاخ مار پێوەی دا! [ ${currentPlayer.name} ] دابەزی بۆ $nextPos!"; });
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() { currentPlayer.position = nextPos; currentPlayer.score = math.max(0, currentPlayer.score - 10); });
      _bounceController.forward(from: 0.0);
    }

    if (currentPlayer.position == 100) {
      setState(() {
        gameFinished = true;
        message = "👑 پیرۆزە! [ ${currentPlayer.name} ] یارییەکەی بردەوە! 👑";
      });
      isMoving = false;
      return;
    }

    _nextTurn();
    isMoving = false;
  }

  void _nextTurn() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    });
  }

  void resetGame() {
    if (isMoving || isRolling) return;
    setState(() {
      for (var player in players) {
        player.position = 1;
        player.score = 0;
      }
      currentPlayerIndex = 0;
      diceValue = 1;
      gameFinished = false;
      message = "یاری نوێ دەستی پێکرد! نۆرەی [ ${players[0].name} ] یە 🔥";
    });
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = players[currentPlayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF06070B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06070B), Color(0xFF0E0F17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("مار و پەیژە", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                        Text("نۆرەی: ${activePlayer.name}", style: TextStyle(fontSize: 12, color: activePlayer.color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        if (players.length < 4 && !isMoving && !isRolling)
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.cyanAccent, size: 20),
                            onPressed: _showAddPlayerDialog,
                            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.03), padding: const EdgeInsets.all(8)),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.amber, size: 20),
                          onPressed: resetGame,
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.03), padding: const EdgeInsets.all(8)),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double itemWidth = (constraints.maxWidth - (12 * (players.length - 1))) / players.length;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(players.length, (index) {
                        bool isCurrent = index == currentPlayerIndex;
                        return GestureDetector(
                          onTap: () => _showEditPlayerDialog(index),
                          child: Container(
                            width: itemWidth,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isCurrent ? players[index].color.withOpacity(0.08) : Colors.white.withOpacity(0.01),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isCurrent ? players[index].color.withOpacity(0.8) : Colors.white.withOpacity(0.05), width: 1),
                              boxShadow: isCurrent ? [BoxShadow(color: players[index].color.withOpacity(0.1), blurRadius: 6)] : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  players[index].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: isCurrent ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "خانەی ${players[index].position}",
                                  style: TextStyle(fontSize: 11, color: players[index].color, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: activePlayer.color.withOpacity(0.2), width: 1.5),
                        boxShadow: [BoxShadow(color: activePlayer.color.withOpacity(0.03), blurRadius: 40, spreadRadius: 2)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final boardSize = constraints.maxWidth;
                              final cellSize = boardSize / 10;

                              return Stack(
                                children: [
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                                    itemCount: 100,
                                    itemBuilder: (context, index) {
                                      int vRow = index ~/ 10, vCol = index % 10, mathRow = 9 - vRow;
                                      int cellNum = (mathRow % 2 == 0) ? (mathRow * 10 + vCol + 1) : (mathRow * 10 + (9 - vCol) + 1);
                                      bool isSpecial = snakes.containsKey(cellNum) || ladders.containsKey(cellNum);

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isSpecial ? Colors.white.withOpacity(0.03) : (cellNum % 2 == 0 ? const Color(0xFF111322).withOpacity(0.5) : const Color(0xFF0A0B14).withOpacity(0.7)),
                                          border: Border.all(color: Colors.white.withOpacity(0.025), width: 0.3),
                                        ),
                                      );
                                    },
                                  ),

                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: AnimatedBuilder(
                                        animation: _liveBoardController,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            painter: LiveBoardPainter(
                                              snakes: snakes,
                                              ladders: ladders,
                                              animationValue: _liveBoardController.value,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                                    itemCount: 100,
                                    itemBuilder: (context, index) {
                                      int vRow = index ~/ 10, vCol = index % 10, mathRow = 9 - vRow;
                                      int cellNum = (mathRow % 2 == 0) ? (mathRow * 10 + vCol + 1) : (mathRow * 10 + (9 - vCol) + 1);
                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: 2, left: 3,
                                            child: Text("$cellNum", style: const TextStyle(fontSize: 7.5, color: Colors.white30, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  ...List.generate(players.length, (index) {
                                    final p = players[index];
                                    final coords = _getCellCoordinates(p.position, cellSize, index);
                                    bool isCurrentMoving = (index == currentPlayerIndex && isMoving);

                                    return AnimatedPositioned(
                                      duration: Duration(milliseconds: isCurrentMoving ? 240 : 350),
                                      curve: Curves.easeInOut,
                                      left: coords.dx,
                                      top: coords.dy,
                                      width: cellSize * 0.44,
                                      height: cellSize * 0.44,
                                      child: AnimatedBuilder(
                                        animation: _bounceAnimation,
                                        builder: (context, child) {
                                          double bValue = isCurrentMoving ? _bounceAnimation.value : 0.0;
                                          return Transform.translate(offset: Offset(0, bValue), child: child);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(colors: [p.color, p.color.withOpacity(0.5)]),
                                            border: Border.all(color: Colors.white, width: 1.2),
                                            boxShadow: [BoxShadow(color: p.color.withOpacity(0.6), blurRadius: 6, spreadRadius: 0.5)],
                                          ),
                                          child: Center(
                                            child: Text(
                                              p.name.characters.first,
                                              style: const TextStyle(fontSize: 8.5, color: Colors.black, fontWeight: FontWeight.bold),
                                            ),
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

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: activePlayer.color.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activePlayer.color.withOpacity(0.1)),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                child: Row(
                  children: [
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 2).animate(CurvedAnimation(parent: _diceController, curve: Curves.easeInOutBack)),
                      child: Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [activePlayer.color.withOpacity(0.4), const Color(0xFF0D0E15)]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: activePlayer.color.withOpacity(0.4)),
                          boxShadow: [BoxShadow(color: activePlayer.color.withOpacity(0.2), blurRadius: 8)],
                        ),
                        child: Center(
                          child: Text(isRolling ? "?" : "$diceValue", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRolling || isMoving || gameFinished ? null : rollDice,
                        icon: const Icon(Icons.casino_rounded, size: 20),
                        label: Text('[ ${activePlayer.name} ] زار بهاوێژە', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activePlayer.color,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LiveBoardPainter extends CustomPainter {
  final Map<int, int> snakes;
  final Map<int, int> ladders;
  final double animationValue;

  LiveBoardPainter({required this.snakes, required this.ladders, required this.animationValue});

  Offset _getCellCenter(int cellNum, Size size) {
    double cellW = size.width / 10;
    double cellH = size.height / 10;
    int zeroIndexed = cellNum - 1;
    int row = zeroIndexed ~/ 10;
    int col = zeroIndexed % 10;
    if (row % 2 == 1) col = 9 - col;
    return Offset((col + 0.5) * cellW, (9 - row + 0.5) * cellH);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintLadder = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    final paintRung = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;

    ladders.forEach((start, end) {
      Offset pStart = _getCellCenter(start, size);
      Offset pEnd = _getCellCenter(end, size);
      final goldShader = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(Rect.fromPoints(pStart, pEnd));
      paintLadder.shader = goldShader;
      paintRung.shader = goldShader;

      Offset dir = pEnd - pStart;
      Offset norm = Offset(-dir.dy, dir.dx) / dir.distance;
      double offsetDist = size.width * 0.011;

      Offset startL = pStart + norm * offsetDist, startR = pStart - norm * offsetDist;
      Offset endL = pEnd + norm * offsetDist, endR = pEnd - norm * offsetDist;

      canvas.drawLine(startL, endL, paintLadder);
      canvas.drawLine(startR, endR, paintLadder);

      int rungsCount = (dir.distance / 16).round();
      for (int i = 1; i < rungsCount; i++) {
        double t = i / rungsCount;
        canvas.drawLine(Offset.lerp(startL, endL, t)!, Offset.lerp(startR, endR, t)!, paintRung);
      }
    });

    snakes.forEach((start, end) {
      Offset headPos = _getCellCenter(start, size);
      Offset tailPos = _getCellCenter(end, size);
      Offset dir = tailPos - headPos;
      double dist = dir.distance;
      Offset norm = Offset(-dir.dy, dir.dx) / dist;

      Path snakePath = Path();
      int segments = 30;

      for (int i = 0; i <= segments; i++) {
        double t = i / segments;
        Offset basePt = Offset.lerp(headPos, tailPos, t)!;
        double wave = math.sin(t * math.pi * 5 - animationValue * math.pi * 3);
        double taper = math.sin(t * math.pi);
        double amplitude = size.width * 0.022;
        Offset pt = basePt + norm * wave * taper * amplitude;

        if (i == 0) {
          snakePath.moveTo(pt.dx, pt.dy);
        } else {
          snakePath.lineTo(pt.dx, pt.dy);
        }
      }

      canvas.drawPath(snakePath, Paint()..color = const Color(0xFFFF0055).withOpacity(0.25)..strokeWidth = 6..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawPath(snakePath, Paint()..shader = const LinearGradient(colors: [Color(0xFFFF0055), Color(0xFF800020)]).createShader(Rect.fromPoints(headPos, tailPos))..strokeWidth = 3.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      canvas.drawCircle(headPos, 4.5, Paint()..color = const Color(0xFFFF0055));
    });
  }

  @override
  bool shouldRepaint(covariant LiveBoardPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
