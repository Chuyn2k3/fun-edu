import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';

class CompareImageScreen extends StatefulWidget {
  const CompareImageScreen({Key? key}) : super(key: key);

  @override
  State<CompareImageScreen> createState() => _CompareImageScreenState();
}

class _CompareImageScreenState extends State<CompareImageScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final List<String> exampleImages = [
    "assets/image_math/apple.png",
    "assets/image_math/banana.png",
    "assets/image_math/corgi.png",
    "assets/image_math/happy-face.png",
    "assets/image_math/monster.png",
    "assets/image_math/panda.png",
    "assets/image_math/pine-tree.png",
    "assets/image_math/strawberry.png",
    "assets/image_math/table.png",
  ];

  int leftNumber = 1;
  int rightNumber = 1;
  String? comparisonSign;
  final List<String> signs = ['>', '<', '='];
  bool isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _generateImages();
    _setupTTS();
  }

  void _setupTTS() async {
    await flutterTts.setLanguage('vi-VN');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _generateImages() {
    final random = Random();
    leftNumber = random.nextInt(9) + 1;
    rightNumber = random.nextInt(9) + 1;
    comparisonSign = null;
    isShowingDialog = false;
    setState(() {});
  }

  bool _checkCorrectness() {
    if (comparisonSign == null) {
      return false;
    }
    if (comparisonSign == '>') return leftNumber > rightNumber;
    if (comparisonSign == '<') return leftNumber < rightNumber;
    if (comparisonSign == '=') return leftNumber == rightNumber;
    return false;
  }

  void _resetDraggedItems() {
    setState(() {
      comparisonSign = null;
      isShowingDialog = false;
    });
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTopButtons(),
                  const SizedBox(height: 20),
                  _buildComparisonRow(),
                  const SizedBox(height: 20),
                  if (comparisonSign == null) _buildComparisonSigns(),
                ],
              ),
            ),
          ),
        ],
      ),
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
          Positioned(
              top: 40,
              left: 10,
              child: AnimatedCloud(
                  size: 100,
                  color: Colors.white.withOpacity(0.4),
                  duration: 25000)),
          Positioned(
              top: 100,
              right: 50,
              child: AnimatedCloud(
                  size: 130,
                  color: Colors.white.withOpacity(0.5),
                  duration: 30000)),
          Positioned(
              bottom: 150,
              left: 40,
              child: AnimatedCloud(
                  size: 90,
                  color: Colors.white.withOpacity(0.6),
                  duration: 20000)),
          const Positioned(
              top: 300,
              left: 40,
              child: AnimatedButterfly(size: 40, duration: 16000)),
          const Positioned(
              bottom: 0,
              left: 40,
              child: AnimatedBalloon(
                  color: Colors.red, size: 60, duration: 12000)),
          const Positioned(
              bottom: 0,
              right: 40,
              child: AnimatedBalloon(
                  color: Colors.blue, size: 50, duration: 10000)),
          const Positioned(
              bottom: 200,
              right: 200,
              child: AnimatedStar(size: 25, duration: 14000)),
          const Positioned(
              bottom: 120,
              left: 180,
              child: AnimatedStar(size: 22, duration: 12000)),
        ],
      ),
    );
  }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(FontAwesomeIcons.house, "Trang Chủ", Colors.red,
              () => Navigator.pop(context)),
          Row(
            children: [
              _buildNavButton(Icons.volume_up, "Nghe", Colors.pink,
                  () => _speak("Hãy chọn dấu phù hợp")),
              const SizedBox(width: 20),
              _buildNavButton(FontAwesomeIcons.arrowsRotate, "Đổi Câu",
                  Colors.blue, _generateImages),
            ],
          ),
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
            ),
            child: FaIcon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildComparisonRow() {
    String imagePath = exampleImages[Random().nextInt(exampleImages.length)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildImageBox(leftNumber,imagePath,),
        _buildComparisonTile(),
        _buildImageBox(rightNumber,imagePath,),
      ],
    );
  }

  Widget _buildImageBox(int number,String imagePath,) {
    //String imagePath = exampleImages[Random().nextInt(exampleImages.length)];
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent, width: 3),
      ),
      child: GridView.builder(
        itemCount: number,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemBuilder: (context, index) =>
            Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildComparisonTile() {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: comparisonSign == null
                ? Colors.grey[300]
                : Colors.lightBlueAccent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pinkAccent, width: 3),
          ),
          child: Center(
            child: Text(
              comparisonSign ?? '?',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: comparisonSign == null ? Colors.black54 : Colors.white,
              ),
            ),
          ),
        );
      },
      onWillAccept: (value) => comparisonSign == null,
      onAccept: (value) {
        setState(() => comparisonSign = value);
        checkCompletion(context);
      },
    );
  }

  Widget _buildComparisonSigns() {
    final List<Color> colors = [
      Colors.redAccent,
      Colors.green,
      Colors.blue,
      Colors.purple
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: signs.map((sign) {
        return Draggable<String>(
          data: sign,
          feedback: Material(
            color: Colors.transparent,
            child: _buildSignBox(sign, colors[Random().nextInt(colors.length)]),
          ),
          childWhenDragging: const SizedBox.shrink(),
          child: _buildSignBox(sign, colors[Random().nextInt(colors.length)]),
        );
      }).toList(),
    );
  }

  Widget _buildSignBox(String sign, Color color) {
    return Container(
      height: 90,
      width: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          sign,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showCongratsDialog(BuildContext context) async {
    setState(() => isShowingDialog = true);

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
              "Chúc mừng! Bạn đã chọn đúng!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    _speak("Tuyệt vời! Bạn đã chọn đúng!");
  }

  void _showWrongDialog(BuildContext context) async {
    setState(() => isShowingDialog = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/wrong.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              "Sai rồi! Thử lại nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    _speak("Ôi không! Bạn chọn sai rồi. Thử lại nào!");
  }

  void checkCompletion(BuildContext context) {
    if (_checkCorrectness()) {
      _showCongratsDialog(context);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
        _generateImages();
      });
    } else {
      _showWrongDialog(context);

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
        _resetDraggedItems();
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
