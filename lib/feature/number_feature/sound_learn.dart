import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:fun_edu/model/model_nums.dart';
import 'package:go_router/go_router.dart';

// Optimized state management
class SoundLearnState {
  final int currentIndex;
  final bool isAnimating;
  final bool isSpeaking;
  final List<String> randomImages;

  const SoundLearnState({
    this.currentIndex = 0,
    this.isAnimating = false,
    this.isSpeaking = false,
    this.randomImages = const [],
  });

  SoundLearnState copyWith({
    int? currentIndex,
    bool? isAnimating,
    bool? isSpeaking,
    List<String>? randomImages,
  }) {
    return SoundLearnState(
      currentIndex: currentIndex ?? this.currentIndex,
      isAnimating: isAnimating ?? this.isAnimating,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      randomImages: randomImages ?? this.randomImages,
    );
  }
}

// Constants for better performance
class SoundLearnConstants {
  static const Map<String, int> numbers = {
    "Số Không": 0,
    "Số Một": 1,
    "Số Hai": 2,
    "Số Ba": 3,
    "Số Bốn": 4,
    "Số Năm": 5,
    "Số Sáu": 6,
    "Số Bảy": 7,
    "Số Tám": 8,
    "Số Chín": 9,
  };

  static const Map<String, String> emojis = {
    "Số Không": "🍀",
    "Số Một": "🍎",
    "Số Hai": "🍊",
    "Số Ba": "🍌",
    "Số Bốn": "🍒",
    "Số Năm": "🍇",
    "Số Sáu": "🍉",
    "Số Bảy": "🍓",
    "Số Tám": "🍍",
    "Số Chín": "🥥",
  };

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

  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration speakDelay = Duration(milliseconds: 100);
}

// TTS Service for better management
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}

class SoundLearnScreen extends StatefulWidget {
  const SoundLearnScreen({super.key});

  @override
  State<SoundLearnScreen> createState() => _SoundLearnScreenState();
}

class _SoundLearnScreenState extends State<SoundLearnScreen>
    with TickerProviderStateMixin {
  late final TTSService _ttsService;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  SoundLearnState _state = const SoundLearnState();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _generateRandomImages();
    _speakCurrentNumber();
  }

  void _initializeServices() {
    _ttsService = TTSService();
    _ttsService.initialize();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: SoundLearnConstants.animationDuration,
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }

  void _generateRandomImages() {
    final count = _extractNumber(numsList[_state.currentIndex].title);
    if (count == 0) {
      setState(() {
        _state = _state.copyWith(randomImages: []);
      });
      return;
    }

    final imageIndex =
        _random.nextInt(SoundLearnConstants.exampleImages.length);
    final images = List.generate(
      count,
      (_) => SoundLearnConstants.exampleImages[imageIndex],
    );

    setState(() {
      _state = _state.copyWith(randomImages: images);
    });
  }

  Future<void> _speakCurrentNumber() async {
    if (_state.isSpeaking) return;

    setState(() {
      _state = _state.copyWith(isSpeaking: true);
    });

    await Future.delayed(SoundLearnConstants.speakDelay);
    await _ttsService.speak(numsList[_state.currentIndex].title);

    if (mounted) {
      setState(() {
        _state = _state.copyWith(isSpeaking: false);
      });
    }
  }

  Future<void> _playShakeAnimation() async {
    if (_state.isAnimating) return;

    setState(() {
      _state = _state.copyWith(isAnimating: true);
    });

    await _shakeController.forward();
    await _speakCurrentNumber();
    await _shakeController.reverse();

    if (mounted) {
      setState(() {
        _state = _state.copyWith(isAnimating: false);
      });
    }
  }

  void _nextNumber() {
    if (_state.currentIndex < numsList.length - 1) {
      setState(() {
        _state = _state.copyWith(currentIndex: _state.currentIndex + 1);
      });
      _generateRandomImages();
      _speakCurrentNumber();
    }
  }

  void _previousNumber() {
    if (_state.currentIndex > 0) {
      setState(() {
        _state = _state.copyWith(currentIndex: _state.currentIndex - 1);
      });
      _generateRandomImages();
      _speakCurrentNumber();
    }
  }

  int _extractNumber(String title) {
    return SoundLearnConstants.numbers[title] ?? 0;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentNum = numsList[_state.currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          const _OptimizedAnimatedBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _TopButtonsWidget(
                  onHomePressed: () => context.pop(context),
                  onSpeakPressed: _speakCurrentNumber,
                  isDisabled: _state.isSpeaking,
                ),
                const SizedBox(height: 16),
                _NavigationRow(
                  currentNum: currentNum,
                  shakeAnimation: _shakeAnimation,
                  onPrevious: _previousNumber,
                  onNext: _nextNumber,
                  onTap: _playShakeAnimation,
                  canGoPrevious: _state.currentIndex > 0,
                  canGoNext: _state.currentIndex < numsList.length - 1,
                  isAnimating: _state.isAnimating,
                ),
                const SizedBox(height: 20),
                _TitleWidget(currentNum: currentNum),
                const SizedBox(height: 20),
                Expanded(
                  child: _ExamplesWidget(
                    currentNum: currentNum,
                    randomImages: _state.randomImages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized background widget with reduced animations
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
          // Reduced number of animated elements for better performance
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
  final bool isDisabled;

  const _TopButtonsWidget({
    required this.onHomePressed,
    required this.onSpeakPressed,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavButton(
            icon: Icons.home,
            text: "Quay Lại",
            color: Colors.red,
            onTap: onHomePressed,
          ),
          _NavButton(
            icon: Icons.volume_up,
            text: "Nghe",
            color: Colors.pink,
            onTap: isDisabled ? null : onSpeakPressed,
            isDisabled: isDisabled,
          ),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final CustomCardModel currentNum;
  final Animation<double> shakeAnimation;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isAnimating;

  const _NavigationRow({
    required this.currentNum,
    required this.shakeAnimation,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: kIsWeb ? 64 : 8),
        _NavButton(
          icon: Icons.chevron_left,
          text: "Lùi Lại",
          color: Colors.blue,
          onTap: canGoPrevious ? onPrevious : null,
          isDisabled: !canGoPrevious,
        ),
        Row(
          children: [
            _NumberDisplay(
              currentNum: currentNum,
              shakeAnimation: shakeAnimation,
              onTap: onTap,
              isAnimating: isAnimating,
            ),
            const SizedBox(width: kIsWeb ? 64 : 12),
            _SubImageDisplay(
              currentNum: currentNum,
              shakeAnimation: shakeAnimation,
              onTap: onTap,
              isAnimating: isAnimating,
            ),
          ],
        ),
        _NavButton(
          icon: Icons.chevron_right,
          text: "Tiến Lên",
          color: Colors.green,
          onTap: canGoNext ? onNext : null,
          isDisabled: !canGoNext,
        ),
        const SizedBox(width: kIsWeb ? 64 : 8),
      ],
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  effectiveColor.withOpacity(0.4),
                  effectiveColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: effectiveColor.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: FaIcon(
              icon,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            color: effectiveColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _NumberDisplay extends StatelessWidget {
  final CustomCardModel currentNum;
  final Animation<double> shakeAnimation;
  final VoidCallback onTap;
  final bool isAnimating;

  const _NumberDisplay({
    required this.currentNum,
    required this.shakeAnimation,
    required this.onTap,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: isAnimating ? sin(shakeAnimation.value * 4 * pi) * 0.1 : 0,
          child: GestureDetector(
            onTap: isAnimating ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                currentNum.image,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubImageDisplay extends StatelessWidget {
  final CustomCardModel currentNum;
  final Animation<double> shakeAnimation;
  final VoidCallback onTap;
  final bool isAnimating;

  const _SubImageDisplay({
    required this.currentNum,
    required this.shakeAnimation,
    required this.onTap,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: isAnimating ? sin(shakeAnimation.value * 4 * pi) * 0.1 : 0,
          child: GestureDetector(
            onTap: isAnimating ? null : onTap,
            child: Image.asset(
              currentNum.subImage,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

class _TitleWidget extends StatelessWidget {
  final CustomCardModel currentNum;

  const _TitleWidget({required this.currentNum});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentNum.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentNum.title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ExamplesWidget extends StatelessWidget {
  final CustomCardModel currentNum;
  final List<String> randomImages;

  const _ExamplesWidget({
    required this.currentNum,
    required this.randomImages,
  });

  @override
  Widget build(BuildContext context) {
    final count = SoundLearnConstants.numbers[currentNum.title] ?? 0;
    final emoji = SoundLearnConstants.emojis[currentNum.title] ?? "🍎";
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Emoji display
            SizedBox(
              width: size.width,
              child: Center(
                child: Wrap(
                  children: List.generate(
                    count,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Image display
            SizedBox(
              width: size.width,
              child: Center(
                child: Wrap(
                  children: randomImages.map((imagePath) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Image.asset(
                        imagePath,
                        width: 70,
                        fit: BoxFit.contain,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
