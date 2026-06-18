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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, fontFamily: 'Segoe UI'),
      home: const CyberGamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Player {
  String name; int position; Color color; int score;
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
  int currentPlayerIndex = 0; int diceValue = 1;
  bool isRolling = false; bool isMoving = false; bool gameFinished = false;
  String message = "بۆ هاویشتنی زار، کلیک لە بۆردەکە بکە! 🎲";
  int effectCell = -1; Color effectColor = Colors.transparent; double effectRadius = 0.0;

  late AnimationController _diceController, _bounceController, _liveBoardController;
  late Animation<double> _bounceAnimation;

  final Map<int, int> snakes = {17: 7, 54: 34, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78};
  final Map<int, int> ladders = {4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 51: 67, 63: 81, 71: 91};

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _bounceController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _liveBoardController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -15.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -15.0, end: 0.0).chain(CurveTween(curve: Curves.bounceIn)), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void dispose() { _diceController.dispose(); _bounceController.dispose(); _liveBoardController.dispose(); super.dispose(); }

  double _getRotationAngle() {
    switch (currentPlayerIndex) {
      case 0: return 0.0; 
      case 1: return math.pi / 2;
      case 2: return math.pi; 
      case 3: return -math.pi / 2;
      default: return 0.0;
    }
  }

  // دۆزینەوەی ژمارەی ڕاستەقینەی خانەکە بەپێی شێوازی دەستپێکردن لە خوارەوە بۆ سەرەوە (Boustrophedon)
  int _getDisplayCellNumber(int gridIndex) {
    int row = gridIndex ~/ 10;
    int col = gridIndex % 10;
    int actualRow = 9 - row;
    int actualCol = (actualRow % 2 == 1) ? (9 - col) : col;
    return (actualRow * 10) + actualCol + 1;
  }

  void _triggerCellEffect(int cell, Color color) {
    setState(() { effectCell = cell; effectColor = color; effectRadius = 0.0; });
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() { effectRadius += 0.08; if (effectRadius >= 1.0) { effectCell = -1; timer.cancel(); } });
    });
  }

  void _showAddPlayerDialog() {
    if (players.length >= 4) return;
    final textController = TextEditingController();
    Color pColor = players.length == 2 ? const Color(0xFF00FF66) : const Color(0xFFFFCC00);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        title: const Text("یاریزانی نوێ"),
        content: TextField(controller: textController, style: const TextStyle(color: Colors.white)),
        actions: [ElevatedButton(onPressed: () { if (textController.text.trim().isNotEmpty) { setState(() { players.add(Player(name: textController.text.trim(), color: pColor)); }); Navigator.pop(context); } }, child: const Text("زیادکردن"))],
      ),
    );
  }

  Offset _getCellCoordinates(int pos, double cSize, int pIndex) {
    int idx = pos - 1; int row = idx ~/ 10; int col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    double paddingX = (cSize - (cSize * 0.45)) / 2;
    double paddingY = (cSize - (cSize * 0.45)) / 2;
    return Offset(col * cSize + paddingX, (9 - row) * cSize + paddingY);
  }

  void rollDice() async {
    if (isRolling || isMoving || gameFinished) return;
    Player cp = players[currentPlayerIndex];
    setState(() { isRolling = true; message = "[ ${cp.name} ] زارەکە دەهاوێژێت... 🎲"; });
    _diceController.forward(from: 0.0); await Future.delayed(const Duration(milliseconds: 600));
    final res = math.Random().nextInt(6) + 1; setState(() { diceValue = res; isRolling = false; });
    int target = cp.position + diceValue;
    if (target > 100) { setState(() { message = "⚠️ ژمارەی دەقیقی دەوێت!"; _nextTurn(); }); return; }
    isMoving = true;
    for (int i = cp.position + 1; i <= target; i++) {
      setState(() { cp.position = i; }); _bounceController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 240));
    }
    if (ladders.containsKey(cp.position)) {
      _triggerCellEffect(cp.position, Colors.amberAccent); cp.position = ladders[cp.position]!;
      await Future.delayed(const Duration(milliseconds: 600));
    } else if (snakes.containsKey(cp.position)) {
      _triggerCellEffect(cp.position, Colors.redAccent); cp.position = snakes[cp.position]!;
      await Future.delayed(const Duration(milliseconds: 600));
    }
    if (cp.position == 100) { setState(() { gameFinished = true; message = "👑 [ ${cp.name} ] بردییەوە! 👑"; }); isMoving = false; return; }
    _nextTurn(); isMoving = false;
  }
  
  void _nextTurn() { setState(() { currentPlayerIndex = (currentPlayerIndex + 1) % players.length; }); }
  
  void resetGame() { setState(() { for (var p in players) { p.position = 1; } currentPlayerIndex = 0; diceValue = 1; gameFinished = false; message = "نۆرەی [ ${players[0].name} ] یە 🔥"; }); }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = players[currentPlayerIndex];
    double currentTurns = _getRotationAngle() / (2 * math.pi);

    return Scaffold(
      backgroundColor: const Color(0xFF040508),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("نۆرەی: ${activePlayer.name}", style: TextStyle(color: activePlayer.color, fontWeight: FontWeight.bold)),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.person_add, color: Colors.cyanAccent), onPressed: _showAddPlayerDialog),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.amber), onPressed: resetGame),
                  ])
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: isRolling || isMoving || gameFinished ? null : rollDice,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: activePlayer.color.withOpacity(0.25))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bSize = constraints.maxWidth; final cSize = bSize / 10;
                            return AnimatedRotation(
                              turns: currentTurns, 
                              duration: const Duration(milliseconds: 600), 
                              curve: Curves.easeInOutCubic,
                              child: Stack(
                                children: [
                                  // ١. خانەکانی بۆردەکە + نیشاندانی ژمارەکان تێیدا
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(), 
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10), 
                                    itemCount: 100,
                                    itemBuilder: (context, idx) {
                                      int cellNum = _getDisplayCellNumber(idx);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: idx % 2 == 0 ? const Color(0xFF10121E) : const Color(0xFF07080F), 
                                          border: Border.all(color: Colors.white10, width: 0.2)
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          // ژمارەکە دەخولێنینەوە بە شێوازی پێچەوانە تا هەمیشە ڕاست پیشان بدرێت
                                          child: AnimatedRotation(
                                            turns: -currentTurns,
                                            duration: const Duration(milliseconds: 600),
                                            child: Text(
                                              "$cellNum",
                                              style: TextStyle(
                                                fontSize: cSize * 0.26,
                                                color: Colors.white.withOpacity(0.25),
                                                fontWeight: FontWeight.w640
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // ٢. مار و پەیژەکان
                                  Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _liveBoardController, builder: (context, child) => CustomPaint(painter: AdvancedBoardPainter(snakes: snakes, ladders: ladders, animationValue: _liveBoardController.value, effectCell: effectCell, effectColor: effectColor, effectRadius: effectRadius))))),
                                  // ٣. مۆرەکان
                                  ...List.generate(players.length, (index) {
                                    final p = players[index]; final coords = _getCellCoordinates(p.position, cSize, index);
                                    return AnimatedPositioned(
                                      duration: Duration(milliseconds: (index == currentPlayerIndex && isMoving) ? 240 : 350), 
                                      curve: Curves.easeInOut, 
                                      left: coords.dx, 
                                      top: coords.dy, 
                                      width: cSize * 0.45, 
                                      height: cSize * 0.45,
                                      child: AnimatedRotation(
                                        turns: -currentTurns,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeInOutCubic,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle, 
                                            color: p.color, 
                                            border: Border.all(color: Colors.white),
                                            boxShadow: [BoxShadow(color: p.color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(message, style: TextStyle(color: activePlayer.color, fontWeight: FontWeight.bold))),
            Container(margin: const EdgeInsets.only(bottom: 20), width: 50, height: 50, decoration: BoxDecoration(border: Border.all(color: activePlayer.color), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(isRolling ? "?" : "$diceValue", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

class AdvancedBoardPainter extends CustomPainter {
  final Map<int, int> snakes, ladders; final double animationValue, effectRadius; final int effectCell; final Color effectColor;
  AdvancedBoardPainter({required this.snakes, required this.ladders, required this.animationValue, required this.effectCell, required this.effectColor, required this.effectRadius});

  Offset _getCenter(int cell, Size size) {
    double cw = size.width / 10, ch = size.height / 10; int idx = cell - 1, row = idx ~/ 10, col = idx % 10;
    if (row % 2 == 1) col = 9 - col; return Offset((col + 0.5) * cw, (9 - row + 0.5) * ch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    ladders.forEach((s, e) {
      Offset pS = _getCenter(s, size), pE = _getCenter(e, size);
      canvas.drawLine(pS, pE, Paint()..color = const Color(0xFF00FF66)..strokeWidth = 5.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      canvas.drawLine(pS, pE, Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    });
    snakes.forEach((s, e) {
      Offset pS = _getCenter(s, size), pE = _getCenter(e, size);
      canvas.drawLine(pS, pE, Paint()..color = const Color(0xFFFF3366)..strokeWidth = 5.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      canvas.drawCircle(pS, 6, Paint()..color = Colors.redAccent);
    });
    if (effectCell != -1) canvas.drawCircle(_getCenter(effectCell, size), (size.width / 10) * 1.2 * effectRadius, Paint()..color = effectColor.withOpacity(1.0 - effectRadius)..style = PaintingStyle.stroke..strokeWidth = 3.0);
  }
  @override bool shouldRepaint(covariant AdvancedBoardPainter old) => true;
}
