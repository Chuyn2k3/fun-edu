// import 'dart:math';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
// import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
// import 'package:fun_edu/widget/menu/portal_master_layout.dart';
// import 'package:go_router/go_router.dart';

// class MatchImage extends StatefulWidget {
//   const MatchImage({super.key});

//   @override
//   State<MatchImage> createState() => _MatchImageState();
// }

// class _MatchImageState extends State<MatchImage> {
//   final AudioPlayer player = AudioPlayer();
//   final Map<String, bool> score = {};
//   final Map<String, Color> choices = {
//     '🍏': Colors.green,
//     '🍋': Colors.yellow,
//     '🍅': Colors.red,
//     '🍇': Colors.purple,
//     '🥥': Colors.brown,
//     '🥕': Colors.orange
//   };
//   late Map<String, String> number;
//   int seed = 0;

//   @override
//   void initState() {
//     super.initState();
//     // Thiết lập quay ngang và chế độ fullscreen immersiveSticky
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     Future.delayed(const Duration(milliseconds: 500));
//     _generateRandomNumbers();
//   }

//   Future<void> _playSound(String fileName) async {
//     await player.setSource(AssetSource('audio/$fileName.wav'));
//     await player.resume();
//   }

//   void _generateRandomNumbers() {
//     final random = Random();
//     final uniqueNumbers = List.generate(6, (index) => index + 1)
//       ..shuffle(random);
//     setState(() {
//       number = {
//         '🍏': uniqueNumbers[0].toString(),
//         '🍋': uniqueNumbers[1].toString(),
//         '🍅': uniqueNumbers[2].toString(),
//         '🍇': uniqueNumbers[3].toString(),
//         '🥥': uniqueNumbers[4].toString(),
//         '🥕': uniqueNumbers[5].toString(),
//       };
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     return Stack(
//       children: [
//         _buildAnimatedBackground(),
//         SafeArea(
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               _buildTopButtons(),
//               const SizedBox(height: 20),
//               _buildGameBoard(),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFB2F5EA), Color(0xFF81E6D9), Color(0xFF7FDBFF)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Moving Clouds
//           Positioned(
//             top: 40,
//             left: 10,
//             child: AnimatedCloud(
//               size: 100,
//               color: Colors.white.withOpacity(0.4),
//               duration: 25000,
//             ),
//           ),
//           Positioned(
//             top: 100,
//             right: 50,
//             child: AnimatedCloud(
//               size: 130,
//               color: Colors.white.withOpacity(0.5),
//               duration: 30000,
//             ),
//           ),
//           Positioned(
//             bottom: 150,
//             left: 40,
//             child: AnimatedCloud(
//               size: 90,
//               color: Colors.white.withOpacity(0.6),
//               duration: 20000,
//             ),
//           ),

//           // Flying Butterflies
//           const Positioned(
//             top: 300,
//             left: 40,
//             child: AnimatedButterfly(size: 40, duration: 16000),
//           ),

//           // Floating Balloons (Spread out more)
//           const Positioned(
//             bottom: 0,
//             left: 40,
//             child:
//                 AnimatedBalloon(color: Colors.red, size: 60, duration: 12000),
//           ),
//           const Positioned(
//             bottom: 0,
//             right: 40,
//             child:
//                 AnimatedBalloon(color: Colors.blue, size: 50, duration: 10000),
//           ),

//           // Sparkling Particles (More scattered)

//           const Positioned(
//             bottom: 200,
//             right: 200,
//             child: AnimatedStar(size: 25, duration: 14000),
//           ),
//           const Positioned(
//             bottom: 120,
//             left: 180,
//             child: AnimatedStar(size: 22, duration: 12000),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           if (!kIsWeb)
//             _buildNavButton(FontAwesomeIcons.house, "Về Trang Chủ", Colors.red,
//                 () => context.pop(context)),
//           _buildNavButton(
//               FontAwesomeIcons.arrowsRotate, "Đổi Câu Hỏi", Colors.blue, () {
//             score.clear();
//             _generateRandomNumbers();
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavButton(
//       IconData icon, String text, Color color, VoidCallback onTap) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [color.withOpacity(0.4), color],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.4),
//                   blurRadius: 12,
//                   spreadRadius: 2,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: FaIcon(icon, size: 30, color: Colors.white),
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           text,
//           style: TextStyle(color: color, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Widget _buildGameBoard() {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 // Cho phép cuộn dọc nếu tràn
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: choices.keys
//                       .map((emoji) => _buildDragTarget(emoji))
//                       .toList()
//                     ..shuffle(Random(seed)),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: SingleChildScrollView(
//                 // Cho phép cuộn dọc nếu tràn
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: choices.keys
//                       .map((emoji) => _buildDraggable(emoji))
//                       .toList(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDragTarget(String emoji) {
//     final count = int.parse(number[emoji]!);
//     final emojiList = List.generate(count, (index) => emoji);

//     return DragTarget<String>(
//       builder: (context, candidateData, rejectedData) {
//         return Container(
//           margin: const EdgeInsets.all(8),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.grey)],
//           ),
//           child: Wrap(
//             spacing: 6,
//             runSpacing: 6,
//             children: emojiList
//                 .map((e) => Text(e, style: const TextStyle(fontSize: 30)))
//                 .toList(),
//           ),
//         );
//       },
//       onWillAccept: (data) => data == emoji,
//       onAccept: (data) async {
//         if (data == emoji) {
//           await _playSound('correct-choice');
//           setState(() => score[emoji] = true);

//           if (score.length == choices.length) {
//             if (!mounted) return;
//             _showCongratsDialog(context);
//             Future.delayed(const Duration(seconds: 1), () {
//               context.pop(context);
//             });
//             score.clear();
//             _generateRandomNumbers();
//           }
//         } else {
//           await _playSound('wrong-choice');
//         }
//       },
//     );
//   }

//   Widget _buildDraggable(String emoji) {
//     if (score[emoji] == true) return const SizedBox();

//     return Draggable<String>(
//       data: emoji,
//       feedback: Material(
//         color: Colors.transparent,
//         child: _buildStyledNumber(number[emoji]??"1", isDragging: true),
//       ),
//       childWhenDragging: Opacity(
//         opacity: 0.3,
//         child: _buildStyledNumber(number[emoji]??"1", isDragging: false),
//       ),
//       child: _buildStyledNumber(number[emoji]??"1", isDragging: false),
//     );
//   }

//   Widget _buildStyledNumber(String numberText, {required bool isDragging}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: isDragging ? Colors.lightBlueAccent : Colors.yellow.shade300,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.3),
//             blurRadius: 8,
//             spreadRadius: 2,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Text(
//         numberText,
//         style: const TextStyle(
//           fontSize: 40,
//           fontWeight: FontWeight.bold,
//           color: Colors.redAccent,
//         ),
//       ),
//     );
//   }

//   void _showCongratsDialog(BuildContext context) async {
//     Future.delayed(
//       const Duration(milliseconds: 500),
//     );
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets/images/excellent.png',
//               height: 150,
//               width: 150,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Chúc mừng! Bạn đã sắp xếp đúng!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Trả lại chế độ quay dọc khi thoát màn hình
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     super.dispose();
//   }
// }

//////////////////////
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';
import 'package:fun_edu/widget/responsive.dart';

// Giả lập các import từ dự án gốc
class AnimatedCloud extends StatefulWidget {
  final double size;
  final Color color;
  final int duration;

  const AnimatedCloud({
    Key? key,
    required this.size,
    required this.color,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedCloud> createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<AnimatedCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Container(
        width: widget.size,
        height: widget.size / 2,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedButterfly extends StatefulWidget {
  final double size;
  final int duration;

  const AnimatedButterfly({
    Key? key,
    required this.size,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedButterfly> createState() => _AnimatedButterflyState();
}

class _AnimatedButterflyState extends State<AnimatedButterfly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Text(
        '🦋',
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedBalloon extends StatefulWidget {
  final Color color;
  final double size;
  final int duration;

  const AnimatedBalloon({
    Key? key,
    required this.color,
    required this.size,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedBalloon> createState() => _AnimatedBalloonState();
}

class _AnimatedBalloonState extends State<AnimatedBalloon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Column(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 2,
            height: widget.size / 2,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedStar extends StatefulWidget {
  final double size;
  final int duration;

  const AnimatedStar({
    Key? key,
    required this.size,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(
            Icons.star,
            color: Colors.yellow,
            size: widget.size * _animation.value,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Giả lập AudioPlayer
class AudioPlayer {
  Future<void> setSource(AssetSource source) async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> resume() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

class AssetSource {
  final String path;
  AssetSource(this.path);
}

// class PortalMasterLayout extends StatelessWidget {
//   final Widget body;
//   const PortalMasterLayout({Key? key, required this.body}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return body;
//   }
// }

// Lớp Confetti để tạo hiệu ứng pháo hoa
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;

  ConfettiPainter(this.confetti, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in confetti) {
      paint.color = particle.color.withOpacity(1 - progress);

      double currentX = particle.x + particle.vx * progress;
      double currentY =
          particle.y + particle.vy * progress + (50 * progress * progress);

      if (Random().nextBool()) {
        _drawStar(canvas, Offset(currentX, currentY),
            particle.size * (1 - progress * 0.5), paint);
      } else {
        canvas.drawCircle(
          Offset(currentX, currentY),
          particle.size * (1 - progress * 0.5),
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final double halfRadius = radius / 2;
    final double degreesPerStep = _degToRad(360 / 5);
    final double halfDegreesPerStep = degreesPerStep / 2;

    path.moveTo(center.dx, center.dy - radius);

    for (int i = 0; i < 5; i++) {
      path.lineTo(
          center.dx + halfRadius * sin(_degToRad(36) + degreesPerStep * i),
          center.dy - halfRadius * cos(_degToRad(36) + degreesPerStep * i));
      path.lineTo(
          center.dx + radius * sin(halfDegreesPerStep + degreesPerStep * i),
          center.dy - radius * cos(halfDegreesPerStep + degreesPerStep * i));
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Confetti {
  double x, y, vx, vy;
  Color color;
  double size;

  Confetti({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

// Lớp Theme cho trò chơi
class GameTheme {
  final String name;
  final List<Color> backgroundColors;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Map<String, Color> itemColors;
  final String backgroundAsset;

  GameTheme({
    required this.name,
    required this.backgroundColors,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.itemColors,
    required this.backgroundAsset,
  });
}

// Lớp chính của trò chơi
class EnhancedMatchImage extends StatefulWidget {
  const EnhancedMatchImage({Key? key}) : super(key: key);

  @override
  State<EnhancedMatchImage> createState() => _EnhancedMatchImageState();
}

class _EnhancedMatchImageState extends State<EnhancedMatchImage>
    with TickerProviderStateMixin {
  final AudioPlayer player = AudioPlayer();
  final Map<String, bool> score = {};

  // Danh sách các theme với màu sắc đẹp hơn
  final List<GameTheme> themes = [
    // Theme Trái cây - Màu sắc tươi sáng, hài hòa
    GameTheme(
      name: "Trái Cây",
      backgroundColors: [
        Color(0xFFE0F7FA), // Xanh nhạt
        Color(0xFF80DEEA), // Xanh ngọc
        Color(0xFF26C6DA), // Xanh đậm
      ],
      primaryColor: Color(0xFF00ACC1),
      secondaryColor: Color(0xFFFFAB40),
      accentColor: Color(0xFFFF6E40),
      itemColors: {
        '🍏': Colors.green,
        '🍋': Colors.yellow,
        '🍅': Colors.red,
        '🍇': Colors.purple,
        '🥥': Colors.brown,
        '🥕': Colors.orange,
      },
      backgroundAsset: 'assets/images/fruit_bg.png',
    ),
    // Theme Động vật - Màu sắc ấm áp, thân thiện
    GameTheme(
      name: "Động Vật",
      backgroundColors: [
        Color(0xFFFFF8E1), // Vàng nhạt
        Color(0xFFFFE0B2), // Cam nhạt
        Color(0xFFFFCC80), // Cam đậm
      ],
      primaryColor: Color(0xFFFB8C00),
      secondaryColor: Color(0xFF8D6E63),
      accentColor: Color(0xFF5D4037),
      itemColors: {
        '🐶': Colors.brown,
        '🐱': Colors.orange,
        '🐰': Colors.grey,
        '🐢': Colors.green,
        '🐬': Colors.blue,
        '🦁': Colors.amber,
      },
      backgroundAsset: 'assets/images/animal_bg.png',
    ),
    // Theme Vũ trụ - Màu sắc huyền bí, sâu thẳm
    GameTheme(
      name: "Vũ Trụ",
      backgroundColors: [
        Color(0xFF3949AB), // Xanh dương đậm
        Color(0xFF303F9F), // Xanh tím
        Color(0xFF1A237E), // Tím đậm
      ],
      primaryColor: Color(0xFF7986CB),
      secondaryColor: Color(0xFFFFD54F),
      accentColor: Color(0xFFFF4081),
      itemColors: {
        '🚀': Colors.red,
        '🌙': Colors.grey,
        '⭐': Colors.yellow,
        '🪐': Colors.orange,
        '👨‍🚀': Colors.white,
        '👽': Colors.green,
      },
      backgroundAsset: 'assets/images/space_bg.png',
    ),
    // Theme Kẹo ngọt - Màu sắc vui tươi, ngọt ngào
    GameTheme(
      name: "Kẹo Ngọt",
      backgroundColors: [
        Color(0xFFF8BBD0), // Hồng nhạt
        Color(0xFFF48FB1), // Hồng
        Color(0xFFEC407A), // Hồng đậm
      ],
      primaryColor: Color(0xFFD81B60),
      secondaryColor: Color(0xFF8E24AA),
      accentColor: Color(0xFF7B1FA2),
      itemColors: {
        '🍭': Colors.pink,
        '🍬': Colors.blue,
        '🍫': Colors.brown,
        '🧁': Colors.purple,
        '🍦': Colors.white,
        '🍩': Colors.orange,
      },
      backgroundAsset: 'assets/images/candy_bg.png',
    ),
  ];

  // Các biến trạng thái
  Map<String, String> number = {};
  int seed = 0;
  int currentThemeIndex = 0;
  int currentLevel = 1;
  int score_points = 0;
  int timeLeft = 60;
  bool isGameActive = false;
  bool showConfetti = false;
  bool isDragging = false;
  String? currentDragItem;

  // Controllers
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;
  late AnimationController _dragController;
  late Animation<double> _dragAnimation;
  Timer? _gameTimer;
  List<Confetti> _confetti = [];

  @override
  void initState() {
    super.initState();
    // Thiết lập quay ngang và chế độ fullscreen immersiveSticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Khởi tạo animation controller
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    _dragController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dragAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _dragController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _startGame();
    });
  }

  void _startGame() {
    setState(() {
      isGameActive = true;
      score.clear();
      timeLeft = _getLevelTime();
      score_points = 0;
    });

    _generateRandomNumbers();
    _startTimer();
  }

  int _getLevelTime() {
    switch (currentLevel) {
      case 1:
        return 60;
      case 2:
        return 45;
      case 3:
        return 30;
      default:
        return 60;
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        _showTimeUpDialog();
      }
    });
  }

  Future<void> _playSound(String fileName) async {
    await player.setSource(AssetSource('audio/$fileName.wav'));
    await player.resume();
  }

  void _generateRandomNumbers() {
    final random = Random();
    final currentTheme = themes[currentThemeIndex];
    final emojis = currentTheme.itemColors.keys.toList();

    // Tạo số ngẫu nhiên dựa trên cấp độ
    final maxNumber = currentLevel == 1 ? 5 : (currentLevel == 2 ? 8 : 10);
    final uniqueNumbers = List.generate(emojis.length, (index) {
      return random.nextInt(maxNumber) + 1;
    });

    setState(() {
      number =
          Map.fromIterables(emojis, uniqueNumbers.map((e) => e.toString()));
      seed = random.nextInt(1000);
    });
  }

  void _createConfetti() {
    _confetti.clear();
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 50; i++) {
      _confetti.add(Confetti(
        x: screenWidth / 2,
        y: screenHeight / 2,
        vx: (random.nextDouble() - 0.5) * 300,
        vy: (random.nextDouble() - 0.5) * 300,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ][random.nextInt(7)],
        size: random.nextDouble() * 10 + 5,
      ));
    }

    setState(() {
      showConfetti = true;
    });

    _confettiController.forward(from: 0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showConfetti = false;
        });
      }
    });
  }

  void _createMiniConfetti(String emoji) {
    final random = Random();
    List<Confetti> miniConfetti = [];

    for (int i = 0; i < 15; i++) {
      miniConfetti.add(Confetti(
        x: MediaQuery.of(context).size.width * 0.25,
        y: MediaQuery.of(context).size.height * 0.5,
        vx: (random.nextDouble() - 0.5) * 150,
        vy: (random.nextDouble() - 0.5) * 150,
        color: [Colors.green, Colors.yellow, Colors.blue][random.nextInt(3)],
        size: random.nextDouble() * 6 + 3,
      ));
    }

    setState(() {
      _confetti.addAll(miniConfetti);
      showConfetti = true;
    });

    _confettiController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          showConfetti = false;
          _confetti.clear();
        });
      }
    });
  }

  void _changeTheme() {
    setState(() {
      currentThemeIndex = (currentThemeIndex + 1) % themes.length;
      score.clear();
    });
    _generateRandomNumbers();
  }

  void _changeLevel() {
    setState(() {
      currentLevel = currentLevel == 3 ? 1 : currentLevel + 1;
      score.clear();
    });
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = themes[currentThemeIndex];

    return Scaffold(
      body: kIsWeb
          ? PortalMasterLayout(body: _buildBody(currentTheme))
          : _buildBody(currentTheme),
    );
  }

  Widget _buildBody(GameTheme theme) {
    return Stack(
      children: [
        _buildAnimatedBackground(theme),
        if (showConfetti) _buildConfetti(),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(theme),
              const SizedBox(height: 10),
              _buildGameBoard(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground(GameTheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.backgroundColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Moving Clouds
          Positioned(
            top: 40,
            left: 10,
            child: AnimatedCloud(
              size: 100,
              color: Colors.white.withOpacity(0.4),
              duration: 25000,
            ),
          ),
          Positioned(
            top: 100,
            right: 50,
            child: AnimatedCloud(
              size: 130,
              color: Colors.white.withOpacity(0.5),
              duration: 30000,
            ),
          ),
          Positioned(
            bottom: 150,
            left: 40,
            child: AnimatedCloud(
              size: 90,
              color: Colors.white.withOpacity(0.6),
              duration: 20000,
            ),
          ),

          // Flying Butterflies
          const Positioned(
            top: 300,
            left: 40,
            child: AnimatedButterfly(size: 40, duration: 16000),
          ),

          // Floating Balloons
          const Positioned(
            bottom: 0,
            left: 40,
            child:
                AnimatedBalloon(color: Colors.red, size: 60, duration: 12000),
          ),
          const Positioned(
            bottom: 0,
            right: 40,
            child:
                AnimatedBalloon(color: Colors.blue, size: 50, duration: 10000),
          ),

          // Sparkling Stars
          const Positioned(
            bottom: 200,
            right: 200,
            child: AnimatedStar(size: 25, duration: 14000),
          ),
          const Positioned(
            bottom: 120,
            left: 180,
            child: AnimatedStar(size: 22, duration: 12000),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_confetti, _confettiAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTopBar(GameTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút về trang chủ
          if (!kIsWeb)
            _buildActionButton(
              icon: FontAwesomeIcons.house,
              label: "Trang Chủ",
              color: theme.accentColor,
              onTap: () => Navigator.of(context).pop(),
            ),

          // Thông tin trò chơi
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Responsive(
                desktop: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem(
                      icon: Icons.timer,
                      value: timeLeft.toString(),
                      label: "Thời gian",
                      color: timeLeft > 10 ? Colors.green : Colors.red,
                    ),
                    _buildInfoItem(
                      icon: Icons.star,
                      value: score_points.toString(),
                      label: "Điểm",
                      color: theme.primaryColor,
                    ),
                    _buildInfoItem(
                      icon: Icons.trending_up,
                      value: "Cấp $currentLevel",
                      label: "Độ khó",
                      color: theme.secondaryColor,
                    ),
                    _buildInfoItem(
                      icon: Icons.palette,
                      value: theme.name,
                      label: "Chủ đề",
                      color: theme.accentColor,
                    ),
                  ],
                ),
                mobile: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        icon: Icons.timer,
                        value: timeLeft.toString(),
                        label: "Thời gian",
                        color: timeLeft > 10 ? Colors.green : Colors.red,
                      ),
                      _buildInfoItem(
                        icon: Icons.star,
                        value: score_points.toString(),
                        label: "Điểm",
                        color: theme.primaryColor,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        icon: Icons.trending_up,
                        value: "Cấp $currentLevel",
                        label: "Độ khó",
                        color: theme.secondaryColor,
                      ),
                      _buildInfoItem(
                        icon: Icons.palette,
                        value: theme.name,
                        label: "Chủ đề",
                        color: theme.accentColor,
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ),

          // Các nút hành động
          Row(
            children: [
              _buildActionButton(
                icon: FontAwesomeIcons.palette,
                label: "Đổi Chủ Đề",
                color: theme.secondaryColor,
                onTap: _changeTheme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: FontAwesomeIcons.gaugeHigh,
                label: "Đổi Cấp Độ",
                color: theme.primaryColor,
                onTap: _changeLevel,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: FontAwesomeIcons.arrowsRotate,
                label: "Làm Mới",
                color: theme.accentColor,
                onTap: () {
                  score.clear();
                  _generateRandomNumbers();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FaIcon(icon, size: 20, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard(GameTheme theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Cột bên trái - Các nhóm emoji
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: theme.itemColors.keys
                        .map((emoji) => _buildDragTarget(emoji, theme))
                        .toList()
                      ..shuffle(Random(seed)),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Cột bên phải - Các số để kéo
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: theme.itemColors.keys
                        .map((emoji) => _buildDraggable(emoji, theme))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragTarget(String emoji, GameTheme theme) {
    final count = int.parse(number[emoji] ?? "1");
    final emojiList = List.generate(count, (index) => emoji);
    final bool isCompleted = score[emoji] == true;
    final bool isCurrentTarget = currentDragItem == emoji && isDragging;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [Colors.green.shade300, Colors.green.shade600]
                    : isCurrentTarget
                        ? [
                            theme.primaryColor.withOpacity(0.7),
                            theme.primaryColor
                          ]
                        : candidateData.isNotEmpty
                            ? [
                                theme.secondaryColor.withOpacity(0.3),
                                theme.secondaryColor.withOpacity(0.6)
                              ]
                            : [Colors.white, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : isCurrentTarget || candidateData.isNotEmpty
                          ? theme.primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.5)
                    : isCurrentTarget
                        ? theme.primaryColor.withOpacity(0.8)
                        : candidateData.isNotEmpty
                            ? theme.secondaryColor.withOpacity(0.5)
                            : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Hiển thị trạng thái hoàn thành
                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Hoàn thành!",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hiển thị gợi ý khi đang kéo
                if (isCurrentTarget && !isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app,
                            color: theme.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Thả vào đây!",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hiển thị các emoji
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: emojiList
                      .map((e) => Text(e, style: const TextStyle(fontSize: 30)))
                      .toList(),
                ),
              ],
            ),
          );
        },
        onWillAccept: (data) {
          // Chỉ chấp nhận nếu emoji trùng khớp và chưa hoàn thành
          bool willAccept = data == emoji && score[emoji] != true;

          if (willAccept) {
            setState(() {
              currentDragItem = emoji;
              isDragging = true;
            });
          }

          return willAccept;
        },
        onAccept: (data) async {
          if (data == emoji) {
            // Rung mạnh để báo hiệu thành công
            HapticFeedback.heavyImpact();
            await _playSound('correct-choice');

            setState(() {
              score[emoji] = true;
              score_points += 10;
              isDragging = false;
              currentDragItem = null;
            });

            // Hiệu ứng pháo hoa nhỏ tại vị trí đích
            _createMiniConfetti(emoji);

            if (score.length == theme.itemColors.length) {
              _gameTimer?.cancel();
              _createConfetti();
              _showCongratsDialog(context);

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  score.clear();
                  _generateRandomNumbers();
                  _startTimer();
                }
              });
            }
          } else {
            // Rung nhẹ để báo hiệu sai
            HapticFeedback.selectionClick();
            await _playSound('wrong-choice');
            setState(() {
              isDragging = false;
              currentDragItem = null;
            });
          }
        },
        onLeave: (data) {
          setState(() {
            isDragging = false;
            currentDragItem = null;
          });
        },
      ),
    );
  }

  Widget _buildDraggable(String emoji, GameTheme theme) {
    // Nếu đã hoàn thành, hiển thị trạng thái hoàn thành đẹp
    if (score[emoji] == true) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Hoàn thành!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Draggable<String>(
      dragAnchorStrategy: pointerDragAnchorStrategy,
      // Dữ liệu được truyền đi
      data: emoji,

      // Widget hiển thị khi đang kéo
      feedback: Material(
        color: Colors.transparent,
        child:
            _buildStyledNumber(number[emoji] ?? "1", theme, isDragging: true),
      ),

      // Widget hiển thị tại vị trí gốc khi đang kéo
      childWhenDragging: Opacity(
        opacity: 0.3,
        child:
            _buildStyledNumber(number[emoji] ?? "1", theme, isDragging: false),
      ),

      // Widget hiển thị khi không kéo
      child: _buildStyledNumber(number[emoji] ?? "1", theme, isDragging: false),

      // Xử lý sự kiện kéo
      onDragStarted: () {
        HapticFeedback.lightImpact();
        setState(() {
          isDragging = true;
          currentDragItem = emoji;
        });
        _dragController.forward(from: 0);
      },

      onDragEnd: (details) {
        setState(() {
          isDragging = false;
          currentDragItem = null;
        });
      },

      onDraggableCanceled: (velocity, offset) {
        HapticFeedback.selectionClick();
        setState(() {
          isDragging = false;
          currentDragItem = null;
        });
      },
    );
  }

  Widget _buildStyledNumber(String numberText, GameTheme theme,
      {required bool isDragging}) {
    return AnimatedBuilder(
      animation: _dragAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isDragging ? _dragAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDragging
                    ? [theme.accentColor.withOpacity(0.8), theme.accentColor]
                    : [
                        theme.secondaryColor.withOpacity(0.7),
                        theme.secondaryColor
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDragging
                      ? theme.accentColor.withOpacity(0.6)
                      : theme.secondaryColor.withOpacity(0.4),
                  blurRadius: isDragging ? 15 : 10,
                  spreadRadius: isDragging ? 2 : 1,
                  offset: isDragging ? const Offset(0, 6) : const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDragging
                    ? Colors.white.withOpacity(0.8)
                    : Colors.transparent,
                width: isDragging ? 3 : 0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDragging ? Icons.touch_app : Icons.drag_indicator,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  numberText,
                  style: TextStyle(
                    fontSize: isDragging ? 40 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: isDragging
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCongratsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade300, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Tuyệt vời!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bạn đã hoàn thành xuất sắc!\nĐiểm số: $score_points",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeUpDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_off,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hết giờ!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bạn đã hoàn thành ${score.length}/${themes[currentThemeIndex].itemColors.length} câu.\nĐiểm số: $score_points",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Thử lại",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    _dragController.dispose();

    // Trả lại chế độ quay dọc khi thoát màn hình
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}

// Main app để chạy demo
class MatchImageApp extends StatelessWidget {
  const MatchImageApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Image Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const EnhancedMatchImage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(const MatchImageApp());
}
