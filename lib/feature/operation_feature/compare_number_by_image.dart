import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:go_router/go_router.dart';

// Optimized state management
class CompareGameState {
  final int leftNumber;
  final int rightNumber;
  final String? comparisonSign;
  final String selectedImagePath;
  final bool isShowingDialog;
  final bool isSpeaking;

  const CompareGameState({
    this.leftNumber = 1,
    this.rightNumber = 1,
    this.comparisonSign,
    this.selectedImagePath = '',
    this.isShowingDialog = false,
    this.isSpeaking = false,
  });

  CompareGameState copyWith({
    int? leftNumber,
    int? rightNumber,
    String? comparisonSign,
    String? selectedImagePath,
    bool? isShowingDialog,
    bool? isSpeaking,
  }) {
    return CompareGameState(
      leftNumber: leftNumber ?? this.leftNumber,
      rightNumber: rightNumber ?? this.rightNumber,
      comparisonSign: comparisonSign,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      isShowingDialog: isShowingDialog ?? this.isShowingDialog,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  bool get isComplete => comparisonSign != null;

  bool get isCorrect {
    if (comparisonSign == null) return false;
    switch (comparisonSign) {
      case '>':
        return leftNumber > rightNumber;
      case '<':
        return leftNumber < rightNumber;
      case '=':
        return leftNumber == rightNumber;
      default:
        return false;
    }
  }
}

// Constants for better performance
class CompareGameConstants {
  static const List<String> exampleImages = [
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

  static const List<String> comparisonSigns = ['>', '<', '='];

  static const List<Color> signColors = [
    Colors.redAccent,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  static const Duration dialogDuration = Duration(seconds: 2);
  static const Duration speakDelay = Duration(milliseconds: 100);
}

// TTS Service for better resource management
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) return;

    if (!_isInitialized) await initialize();
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _flutterTts.stop();
  }

  bool get isSpeaking => _isSpeaking;
}

// Game logic service
class CompareGameLogic {
  static final Random _random = Random();

  static CompareGameState generateNewGame() {
    final leftNumber = _random.nextInt(9) + 1;
    final rightNumber = _random.nextInt(9) + 1;
    final imageIndex =
        _random.nextInt(CompareGameConstants.exampleImages.length);
    final selectedImagePath = CompareGameConstants.exampleImages[imageIndex];

    return CompareGameState(
      leftNumber: leftNumber,
      rightNumber: rightNumber,
      selectedImagePath: selectedImagePath,
      comparisonSign: null,
      isShowingDialog: false,
      isSpeaking: false,
    );
  }

  static Color getRandomSignColor() {
    return CompareGameConstants
        .signColors[_random.nextInt(CompareGameConstants.signColors.length)];
  }
}

class CompareImageScreen extends StatefulWidget {
  const CompareImageScreen({Key? key}) : super(key: key);

  @override
  State<CompareImageScreen> createState() => _CompareImageScreenState();
}

class _CompareImageScreenState extends State<CompareImageScreen> {
  late final TTSService _ttsService;
  CompareGameState _gameState = const CompareGameState();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _initializeServices();
    _generateNewGame();
  }

  void _initializeScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializeServices() {
    _ttsService = TTSService();
    _ttsService.initialize();
  }

  void _generateNewGame() {
    setState(() {
      _gameState = CompareGameLogic.generateNewGame();
    });
  }

  void _resetGame() {
    setState(() {
      _gameState = _gameState.copyWith(
        comparisonSign: null,
        isShowingDialog: false,
      );
    });
  }

  Future<void> _speak(String text) async {
    setState(() {
      _gameState = _gameState.copyWith(isSpeaking: true);
    });

    await _ttsService.speak(text);

    if (mounted) {
      setState(() {
        _gameState = _gameState.copyWith(isSpeaking: false);
      });
    }
  }

  void _onSignSelected(String sign) {
    if (_gameState.isShowingDialog) return;

    setState(() {
      _gameState = _gameState.copyWith(comparisonSign: sign);
    });

    _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    if (!_gameState.isComplete) return;

    setState(() {
      _gameState = _gameState.copyWith(isShowingDialog: true);
    });

    if (_gameState.isCorrect) {
      await _showCongratsDialog();
      await Future.delayed(CompareGameConstants.dialogDuration);
      if (mounted) {
        context.pop(context);
        _generateNewGame();
      }
    } else {
      await _showWrongDialog();
      await Future.delayed(CompareGameConstants.dialogDuration);
      if (mounted) {
        context.pop(context);
        _resetGame();
      }
    }
  }

  Future<void> _showCongratsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ResultDialog(
        isCorrect: true,
        imagePath: 'assets/images/excellent.png',
        message: "Chúc mừng! Bạn đã chọn đúng!",
      ),
    );
    _speak("Tuyệt vời! Bạn đã chọn đúng!");
  }

  Future<void> _showWrongDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ResultDialog(
        isCorrect: false,
        imagePath: 'assets/images/wrong.png',
        message: "Sai rồi! Thử lại nhé!",
      ),
    );
    _speak("Ôi không! Bạn chọn sai rồi. Thử lại nào!");
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _OptimizedAnimatedBackground(),
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _TopButtonsWidget(
                    onHomePressed: () => context.pop(context),
                    onSpeakPressed: () => _speak("Hãy chọn dấu phù hợp"),
                    onRefreshPressed: _generateNewGame,
                    isDisabled:
                        _gameState.isSpeaking || _gameState.isShowingDialog,
                  ),
                  const SizedBox(height: 20),
                  _ComparisonRow(
                    gameState: _gameState,
                    onSignSelected: _onSignSelected,
                  ),
                  const SizedBox(height: 20),
                  if (!_gameState.isComplete)
                    _ComparisonSigns(
                      onSignSelected: _onSignSelected,
                      isDisabled: _gameState.isShowingDialog,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized background widget
class _OptimizedAnimatedBackground extends StatelessWidget {
  const _OptimizedAnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5EA), Color(0xFF81E6D9), Color(0xFF7FDBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Stack(
        children: [
          // Reduced animated elements for better performance
          Positioned(
            top: 40,
            left: 10,
            child: AnimatedCloud(
              size: 100,
              color: Color(0x66FFFFFF),
              duration: 25000,
            ),
          ),
          Positioned(
            top: 100,
            right: 50,
            child: AnimatedCloud(
              size: 130,
              color: Color(0x80FFFFFF),
              duration: 30000,
            ),
          ),
          Positioned(
            top: 300,
            left: 40,
            child: AnimatedButterfly(size: 40, duration: 16000),
          ),
          Positioned(
            bottom: 0,
            left: 40,
            child: AnimatedBalloon(
              color: Colors.red,
              size: 60,
              duration: 12000,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 40,
            child: AnimatedBalloon(
              color: Colors.blue,
              size: 50,
              duration: 10000,
            ),
          ),
          Positioned(
            bottom: 200,
            right: 200,
            child: AnimatedStar(size: 25, duration: 14000),
          ),
        ],
      ),
    );
  }
}

class _TopButtonsWidget extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onSpeakPressed;
  final VoidCallback onRefreshPressed;
  final bool isDisabled;

  const _TopButtonsWidget({
    required this.onHomePressed,
    required this.onSpeakPressed,
    required this.onRefreshPressed,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: FontAwesomeIcons.house,
            text: "Trang Chủ",
            color: Colors.red,
            onTap: onHomePressed,
          ),
          Row(
            children: [
              _NavButton(
                icon: Icons.volume_up,
                text: "Nghe",
                color: Colors.pink,
                onTap: isDisabled ? null : onSpeakPressed,
                isDisabled: isDisabled,
              ),
              const SizedBox(width: 20),
              _NavButton(
                icon: FontAwesomeIcons.arrowsRotate,
                text: "Đổi Câu",
                color: Colors.blue,
                onTap: isDisabled ? null : onRefreshPressed,
                isDisabled: isDisabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _NavButton({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled ? Colors.grey : color;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [effectiveColor.withOpacity(0.4), effectiveColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FaIcon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            color: effectiveColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final CompareGameState gameState;
  final Function(String) onSignSelected;

  const _ComparisonRow({
    required this.gameState,
    required this.onSignSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ImageBox(
          number: gameState.leftNumber,
          imagePath: gameState.selectedImagePath,
        ),
        _ComparisonTile(
          comparisonSign: gameState.comparisonSign,
          onSignSelected: onSignSelected,
          isDisabled: gameState.isShowingDialog,
        ),
        _ImageBox(
          number: gameState.rightNumber,
          imagePath: gameState.selectedImagePath,
        ),
      ],
    );
  }
}

class _ImageBox extends StatelessWidget {
  final int number;
  final String imagePath;

  const _ImageBox({
    required this.number,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent, width: 3),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: number,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemBuilder: (context, index) => Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  final String? comparisonSign;
  final Function(String) onSignSelected;
  final bool isDisabled;

  const _ComparisonTile({
    required this.comparisonSign,
    required this.onSignSelected,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
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
      onWillAccept: (value) => comparisonSign == null && !isDisabled,
      onAccept: (value) => onSignSelected(value),
    );
  }
}

class _ComparisonSigns extends StatelessWidget {
  final Function(String) onSignSelected;
  final bool isDisabled;

  const _ComparisonSigns({
    required this.onSignSelected,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: CompareGameConstants.comparisonSigns.map((sign) {
        return Draggable<String>(
          data: sign,
          feedback: Material(
            color: Colors.transparent,
            child: _SignBox(
              sign: sign,
              color: CompareGameLogic.getRandomSignColor(),
            ),
          ),
          childWhenDragging: const SizedBox.shrink(),
          child: _SignBox(
            sign: sign,
            color: CompareGameLogic.getRandomSignColor(),
            isDisabled: isDisabled,
          ),
        );
      }).toList(),
    );
  }
}

class _SignBox extends StatelessWidget {
  final String sign;
  final Color color;
  final bool isDisabled;

  const _SignBox({
    required this.sign,
    required this.color,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled ? Colors.grey : color;

    return Container(
      height: 90,
      width: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDisabled
            ? null
            : [
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
}

class _ResultDialog extends StatelessWidget {
  final bool isCorrect;
  final String imagePath;
  final String message;

  const _ResultDialog({
    required this.isCorrect,
    required this.imagePath,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
