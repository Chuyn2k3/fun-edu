import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';
import 'package:go_router/go_router.dart';

class MatchImage extends StatefulWidget {
  const MatchImage({super.key});

  @override
  State<MatchImage> createState() => _MatchImageState();
}

class _MatchImageState extends State<MatchImage> {
  final AudioPlayer player = AudioPlayer();
  final Map<String, bool> score = {};
  final Map<String, Color> choices = {
    '🍏': Colors.green,
    '🍋': Colors.yellow,
    '🍅': Colors.red,
    '🍇': Colors.purple,
    '🥥': Colors.brown,
    '🥕': Colors.orange
  };
  late Map<String, String> number;
  int seed = 0;

  @override
  void initState() {
    super.initState();
    // Thiết lập quay ngang và chế độ fullscreen immersiveSticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.delayed(const Duration(milliseconds: 500));
    _generateRandomNumbers();
  }

  Future<void> _playSound(String fileName) async {
    await player.setSource(AssetSource('audio/$fileName.wav'));
    await player.resume();
  }

  void _generateRandomNumbers() {
    final random = Random();
    final uniqueNumbers = List.generate(6, (index) => index + 1)
      ..shuffle(random);
    setState(() {
      number = {
        '🍏': uniqueNumbers[0].toString(),
        '🍋': uniqueNumbers[1].toString(),
        '🍅': uniqueNumbers[2].toString(),
        '🍇': uniqueNumbers[3].toString(),
        '🥥': uniqueNumbers[4].toString(),
        '🥕': uniqueNumbers[5].toString(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildAnimatedBackground(),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTopButtons(),
              const SizedBox(height: 20),
              _buildGameBoard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5EA), Color(0xFF81E6D9), Color(0xFF7FDBFF)],
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

          // Floating Balloons (Spread out more)
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

          // Sparkling Particles (More scattered)

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

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (!kIsWeb)
            _buildNavButton(FontAwesomeIcons.house, "Về Trang Chủ", Colors.red,
                () => context.pop(context)),
          _buildNavButton(
              FontAwesomeIcons.arrowsRotate, "Đổi Câu Hỏi", Colors.blue, () {
            score.clear();
            _generateRandomNumbers();
          }),
        ],
      ),
    );
  }

  Widget _buildNavButton(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.4), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FaIcon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // Cho phép cuộn dọc nếu tràn
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: choices.keys
                      .map((emoji) => _buildDragTarget(emoji))
                      .toList()
                    ..shuffle(Random(seed)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                // Cho phép cuộn dọc nếu tràn
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: choices.keys
                      .map((emoji) => _buildDraggable(emoji))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragTarget(String emoji) {
    final count = int.parse(number[emoji]!);
    final emojiList = List.generate(count, (index) => emoji);

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.grey)],
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: emojiList
                .map((e) => Text(e, style: const TextStyle(fontSize: 30)))
                .toList(),
          ),
        );
      },
      onWillAccept: (data) => data == emoji,
      onAccept: (data) async {
        if (data == emoji) {
          await _playSound('correct-choice');
          setState(() => score[emoji] = true);

          if (score.length == choices.length) {
            if (!mounted) return;
            _showCongratsDialog(context);
            Future.delayed(const Duration(seconds: 1), () {
              context.pop(context);
            });
            score.clear();
            _generateRandomNumbers();
          }
        } else {
          await _playSound('wrong-choice');
        }
      },
    );
  }

  Widget _buildDraggable(String emoji) {
    if (score[emoji] == true) return const SizedBox();

    return Draggable<String>(
      data: emoji,
      feedback: Material(
        color: Colors.transparent,
        child: _buildStyledNumber(number[emoji]!, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildStyledNumber(number[emoji]!, isDragging: false),
      ),
      child: _buildStyledNumber(number[emoji]!, isDragging: false),
    );
  }

  Widget _buildStyledNumber(String numberText, {required bool isDragging}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDragging ? Colors.lightBlueAccent : Colors.yellow.shade300,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        numberText,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  void _showCongratsDialog(BuildContext context) async {
    Future.delayed(
      const Duration(milliseconds: 500),
    );
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/excellent.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              "Chúc mừng! Bạn đã sắp xếp đúng!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Trả lại chế độ quay dọc khi thoát màn hình
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
