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
  String name; int position; Color color;
  Player({required this.name, this.position = 1, required this.color});
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
    Player(name: "یاریزان ٣", color: const Color(0xFF00FF66)),
    Player(name: "یاریزان ٤", color: const Color(0xFFFFCC00)),
  ];
  int currentPlayerIndex = 0; int diceValue = 1;
  bool isRolling = false; bool isMoving = false; bool gameFinished = false;
  String message = "بۆ هاویشتنی زار، کلیک لە بۆردەکە بکە! 🎲";
  int effectCell = -1; Color effectColor = Colors.transparent; double effectRadius = 0.0;

  late AnimationController _diceController, _bounceController, _liveBoardController;

  final Map<int, int> snakes = {17: 7, 54: 34, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78};
  final Map<int, int> ladders = {4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 51: 67, 63: 81, 71: 91};

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _bounceController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _liveBoardController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() { _diceController.dispose(); _bounceController.dispose(); _liveBoardController.dispose(); super.dispose(); }

  double _getBoardRotation() {
    switch (currentPlayerIndex) {
      case 0: return 0.0;
      case 1: return -math.pi / 2;
      case 2: return math.pi;
      case 3: return math.pi / 2;
      default: return 0.0;
    }
  }

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

  void _showEditPlayerDialog(int index) {
    final textController = TextEditingController(text: players[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11121C),
        title: Text("گۆڕینی ناوی ${players[index].name}", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: textController, 
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("پاشگەزمایەوە", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { 
              if (textController.text.trim().isNotEmpty) { 
                setState(() { players[index].name = textController.text.trim(); }); 
                Navigator.pop(context); 
              } 
            }, 
            child: const Text("تۆمارکردن")
          )
        ],
      ),
    );
  }

  Offset _getCellCoordinates(int pos, double cSize) {
    int idx = pos - 1; int row = idx ~/ 10; int col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    double padding = (cSize - (cSize * 0.45)) / 2;
    return Offset(col * cSize + padding, (9 - row) * cSize + padding);
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
    double currentTurns = _getBoardRotation() / (2 * math.pi);

    return Scaffold(
      backgroundColor: const Color(0xFF040508),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF0D0E15), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(players.length, (index) {
                  final p = players[index];
                  bool isCurrent = index == currentPlayerIndex;
                  return InkWell(
                    onTap: () => _showEditPlayerDialog(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: isCurrent ? p.color : Colors.transparent, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: isCurrent ? p.color.withOpacity(0.1) : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text("خانەی: ${p.position}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: isRolling || isMoving || gameFinished ? null : rollDice,
                  child: AnimatedRotation(
                    turns: currentTurns, 
                    duration: const Duration(milliseconds: 600), 
                    curve: Curves.easeInOutCubic,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: activePlayer.color.withOpacity(0.3), width: 2),
                        boxShadow: [BoxShadow(color: activePlayer.color.withOpacity(0.15), blurRadius: 25, spreadRadius: 2)]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bSize = constraints.maxWidth; final cSize = bSize / 10;
                              return Stack(
                                children: [
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(), 
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10), 
                                    itemCount: 100,
                                    itemBuilder: (context, idx) {
                                      int cellNum = _getDisplayCellNumber(idx);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: idx % 2 == 0 ? const Color(0xFF121424) : const Color(0xFF090A12), 
                                          border: Border.all(color: Colors.black45, width: 0.5), // ڕەنگی بۆردەر بۆ دروستکردنی قووڵایی چاککراوە
                                        ),
                                        child: Center(
                                          child: AnimatedRotation(
                                            turns: -currentTurns,
                                            duration: const Duration(milliseconds: 600),
                                            child: Text(
                                              "$cellNum",
                                              style: TextStyle(
                                                fontSize: cSize * 0.28,
                                                color: Colors.white.withOpacity(0.2),
                                                fontWeight: FontWeight.w600,
                                                shadows: [Shadow(color: Colors.black.withOpacity(0.8), offset: const Offset(1, 1), blurRadius: 2)]
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: AnimatedBuilder(
                                        animation: _liveBoardController, 
                                        builder: (context, child) => CustomPaint(
                                          painter: AdvancedBoardPainter(
                                            snakes: snakes, 
                                            ladders: ladders, 
                                            animationValue: _liveBoardController.value, 
                                            effectCell: effectCell, 
                                            effectColor: effectColor, 
                                            effectRadius: effectRadius
                                          )
                                        )
                                      )
                                    )
                                  ),
                                  
                                  ...List.generate(players.length, (index) {
                                    final p = players[index]; final coords = _getCellCoordinates(p.position, cSize);
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
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle, 
                                            gradient: RadialGradient(colors: [Colors.white, p.color, p.color.withOpacity(0.8)]),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                            boxShadow: [BoxShadow(color: p.color.withOpacity(0.8), blurRadius: 12, spreadRadius: 2)]
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
            ),
            
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(message, style: TextStyle(color: activePlayer.color, fontWeight: FontWeight.bold, fontSize: 14))),
            
            GestureDetector(
              onTap: isRolling || isMoving || gameFinished ? null : rollDice,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20), 
                width: 60, 
                height: 60, 
                decoration: BoxDecoration(
                  color: const Color(0xFF11121C),
                  border: Border.all(color: activePlayer.color, width: 2), 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: activePlayer.color.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)]
                ),
                child: Center(
                  child: isRolling 
                    ? RotationTransition(turns: _diceController, child: Icon(Icons.casino, size: 30, color: activePlayer.color))
                    : Text("$diceValue", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: activePlayer.color, shadows: [Shadow(color: activePlayer.color, blurRadius: 8)]))
                ),
              ),
            ),
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
      double dx = pE.dx - pS.dx; double dy = pE.dy - pS.dy;
      double len = math.sqrt(dx * dx + dy * dy);
      Offset _ox = Offset(-dy / len * 5, dx / len * 5);

      canvas.drawLine(pS + const Offset(3, 3), pE + const Offset(3, 3), Paint()..color = Colors.black45..strokeWidth = 6.0);
      canvas.drawLine(pS - _ox, pE - _ox, Paint()..color = const Color(0xFFFFCC00)..strokeWidth = 3.5);
      canvas.drawLine(pS + _ox, pE + _ox, Paint()..color = const Color(0xFFFFCC00)..strokeWidth = 3.5);

      int rungs = (len / 12).floor();
      for (int i = 0; i <= rungs; i++) {
        double t = i / rungs;
        Offset pR1 = Offset.lerp(pS - _ox, pE - _ox, t)!;
        Offset pR2 = Offset.lerp(pS + _ox, pE + _ox, t)!;
        canvas.drawLine(pR1, pR2, Paint()..color = Colors.white70..strokeWidth = 2.0);
      }
    });

    snakes.forEach((s, e) {
      Offset pS = _getCenter(s, size); Offset pE = _getCenter(e, size);
      Path snakePath = Path();
      snakePath.moveTo(pS.dx, pS.dy);

      double dx = pE.dx - pS.dx; double dy = pE.dy - pS.dy;
      double len = math.sqrt(dx * dx + dy * dy);
      int segments = 15;

      for (int i = 1; i <= segments; i++) {
        double t = i / segments;
        Offset loc = Offset.lerp(pS, pE, t)!;
        double wave = math.sin((t * math.pi * 3) - (animationValue * math.pi * 2)) * 8;
        Offset normal = Offset(-dy / len * wave, dx / len * wave);
        snakePath.lineTo(loc.dx + normal.dx, loc.dy + normal.dy);
      }

      canvas.drawPath(snakePath, Paint()..color = const Color(0xFFFF3366).withOpacity(0.25)..strokeWidth = 10.0..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(snakePath, Paint()..color = const Color(0xFFFF3366)..strokeWidth = 4.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

      canvas.drawCircle(pS, 6, Paint()..color = Colors.redAccent);
      canvas.drawCircle(pS, 2, Paint()..color = Colors.white);
    });

    if (effectCell != -1) canvas.drawCircle(_getCenter(effectCell, size), (size.width / 10) * 1.2 * effectRadius, Paint()..color = effectColor.withOpacity(1.0 - effectRadius)..style = PaintingStyle.stroke..strokeWidth = 3.0);
  }
  @override bool shouldRepaint(covariant AdvancedBoardPainter old) => true;
}
