import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/core/services/recognizer.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/constants.dart';
import 'package:fun_edu/feature/digit_feature/number/drawing_painter.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction.dart';
import 'package:go_router/go_router.dart';

// Enums for better type safety
enum MathOperation { addition, subtraction }

enum RecognitionState { idle, processing, success, failure }

// Data models for better structure
class MathProblem {
  final int operand1;
  final int operand2;
  final MathOperation operation;
  final int answer;

  const MathProblem({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.answer,
  });

  String get operationSymbol => operation == MathOperation.addition ? '+' : '-';

  IconData get operationIcon => operation == MathOperation.addition
      ? FontAwesomeIcons.plus
      : FontAwesomeIcons.minus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathProblem &&
          runtimeType == other.runtimeType &&
          operand1 == other.operand1 &&
          operand2 == other.operand2 &&
          operation == other.operation;

  @override
  int get hashCode =>
      operand1.hashCode ^ operand2.hashCode ^ operation.hashCode;
}

class DrawingState {
  final List<Offset> points;
  final bool isDrawing;

  const DrawingState({
    this.points = const [],
    this.isDrawing = false,
  });

  DrawingState copyWith({
    List<Offset>? points,
    bool? isDrawing,
  }) {
    return DrawingState(
      points: points ?? this.points,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }

  DrawingState addPoint(Offset point) {
    return copyWith(points: [...points, point]);
  }

  DrawingState clear() {
    return const DrawingState();
  }
}

class DigitMathState {
  final MathProblem currentProblem;
  final DrawingState drawingState;
  final RecognitionState recognitionState;
  final String? recognizedDigit;
  final List<Prediction> predictions;
  final bool isLoading;

  const DigitMathState({
    required this.currentProblem,
    this.drawingState = const DrawingState(),
    this.recognitionState = RecognitionState.idle,
    this.recognizedDigit,
    this.predictions = const [],
    this.isLoading = false,
  });

  DigitMathState copyWith({
    MathProblem? currentProblem,
    DrawingState? drawingState,
    RecognitionState? recognitionState,
    String? recognizedDigit,
    List<Prediction>? predictions,
    bool? isLoading,
  }) {
    return DigitMathState(
      currentProblem: currentProblem ?? this.currentProblem,
      drawingState: drawingState ?? this.drawingState,
      recognitionState: recognitionState ?? this.recognitionState,
      recognizedDigit: recognizedDigit ?? this.recognizedDigit,
      predictions: predictions ?? this.predictions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isCorrectAnswer =>
      recognizedDigit != null &&
      recognizedDigit == currentProblem.answer.toString();
}

// Service for generating math problems
class MathProblemGenerator {
  static final Random _random = Random();
  static const List<int> _availableNumbers = [0, 1, 2, 3, 4, 5];

  static MathProblem generateProblem() {
    final shuffledNumbers = List<int>.from(_availableNumbers)..shuffle(_random);
    final operand1 = shuffledNumbers[0];
    final operand2 = shuffledNumbers[1];

    // Determine operation based on validity
    final canSubtract = operand1 >= operand2;
    final canAdd = (operand1 + operand2) <= 9;

    MathOperation operation;
    if (canAdd && canSubtract) {
      operation = _random.nextBool()
          ? MathOperation.addition
          : MathOperation.subtraction;
    } else if (canAdd) {
      operation = MathOperation.addition;
    } else {
      operation = MathOperation.subtraction;
    }

    final answer = operation == MathOperation.addition
        ? operand1 + operand2
        : operand1 - operand2;

    return MathProblem(
      operand1: operand1,
      operand2: operand2,
      operation: operation,
      answer: answer,
    );
  }
}

// Service for TTS functionality
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

  void dispose() {
    _flutterTts.stop();
  }
}

// Service for digit recognition
class DigitRecognitionService {
  final Recognizer _recognizer = Recognizer();
  bool _isModelLoaded = false;

  Future<void> initializeModel() async {
    if (_isModelLoaded) return;
    await _recognizer.loadModel();
    _isModelLoaded = true;
  }

  Future<List<Prediction>?> recognizeDigit(List<Offset> points) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call initializeModel() first.');
    }

    final predictions = await _recognizer.recognize(points);
    return predictions?.map((json) => Prediction.fromJson(json)).toList();
  }
}

class DigitMath extends StatefulWidget {
  const DigitMath({super.key});

  @override
  State<DigitMath> createState() => _DigitMathState();
}

class _DigitMathState extends State<DigitMath> {
  late final DigitRecognitionService _recognitionService;
  late final TTSService _ttsService;

  DigitMathState _state = DigitMathState(
    currentProblem: MathProblemGenerator.generateProblem(),
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _recognitionService = DigitRecognitionService();
    _ttsService = TTSService();

    setState(() {
      _state = _state.copyWith(isLoading: true);
    });

    try {
      await Future.wait([
        _recognitionService.initializeModel(),
        _ttsService.initialize(),
      ]);
    } catch (e) {
      debugPrint('Error initializing services: $e');
    } finally {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
      }
    }
  }

  void _generateNewProblem() {
    setState(() {
      _state = DigitMathState(
        currentProblem: MathProblemGenerator.generateProblem(),
      );
    });
  }

  void _clearDrawing() {
    setState(() {
      _state = _state.copyWith(
        drawingState: _state.drawingState.clear(),
        recognitionState: RecognitionState.idle,
        recognizedDigit: null,
        predictions: [],
      );
    });
  }

  void _addDrawingPoint(Offset point) {
    setState(() {
      _state = _state.copyWith(
        drawingState: _state.drawingState.addPoint(point),
      );
    });
  }

  Future<void> _recognizeDigit() async {
    if (_state.drawingState.points.isEmpty) return;

    setState(() {
      _state = _state.copyWith(recognitionState: RecognitionState.processing);
    });

    try {
      final predictions = await _recognitionService.recognizeDigit(
        _state.drawingState.points,
      );

      if (predictions != null && predictions.isNotEmpty) {
        final recognizedDigit = predictions.first.label;

        setState(() {
          _state = _state.copyWith(
            recognizedDigit: recognizedDigit,
            predictions: predictions,
            recognitionState: _state.isCorrectAnswer
                ? RecognitionState.success
                : RecognitionState.failure,
          );
        });

        if (_state.isCorrectAnswer) {
          _showSuccessDialog();
        } else {
          _showTryAgainDialog();
        }
      }
    } catch (e) {
      debugPrint('Recognition error: $e');
      setState(() {
        _state = _state.copyWith(recognitionState: RecognitionState.failure);
      });
      _showTryAgainDialog();
    }
  }

  void _showSuccessDialog() {
    _showResultDialog(
      title: "🎉 Chúc mừng!",
      message: "Bé đã viết đúng số ${_state.currentProblem.answer}!",
      buttonText: "Tiếp tục",
      buttonColor: Colors.green,
      onPressed: () {
        Navigator.of(context).pop();
        _generateNewProblem();
      },
    );
  }

  void _showTryAgainDialog() {
    _showResultDialog(
      title: "❌ Ôi không!",
      message: "Bé hãy thử lại nào!",
      buttonText: "Thử lại",
      buttonColor: Colors.red,
      onPressed: () {
        Navigator.of(context).pop();
        _clearDrawing();
      },
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ResultDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        buttonColor: buttonColor,
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundWidget(),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _AppBarWidget(onBackPressed: () => context.pop(context)),
                _BodyWidget(
                  state: _state,
                  onDrawingUpdate: _addDrawingPoint,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AIRecognitionDisplay(
                      recognizedDigit: _state.recognizedDigit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ActionButtonsWidget(
        onCheck: _recognizeDigit,
        onNewQuestion: _generateNewProblem,
        onClear: _clearDrawing,
        isProcessing: _state.recognitionState == RecognitionState.processing,
      ),
    );
  }
}

// Separate widgets for better performance
class _BackgroundWidget extends StatelessWidget {
  const _BackgroundWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Scratchpad.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class _AppBarWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _AppBarWidget({required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: onBackPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyWidget extends StatelessWidget {
  final DigitMathState state;
  final Function(Offset) onDrawingUpdate;

  const _BodyWidget({
    required this.state,
    required this.onDrawingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flexible(
                  //   flex: 9,
                  //   child: _AIRecognitionDisplay(
                  //     recognizedDigit: state.recognizedDigit,
                  //   ),
                  // ),
                  //const Spacer(),
                  _MathProblemDisplay(problem: state.currentProblem),
                ],
              ),
              Container(
                width: 152,
                height: 12,
                color: const Color(0xFF600584),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 106,
                    child: FaIcon(
                      FontAwesomeIcons.equals,
                      color: Color(0xFF600584),
                      size: 50,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _DrawingCanvas(
                    points: state.drawingState.points,
                    onDrawingUpdate: onDrawingUpdate,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AIRecognitionDisplay extends StatelessWidget {
  final String? recognizedDigit;

  const _AIRecognitionDisplay({this.recognizedDigit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "AI nhận diện",
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blueAccent,
              width: Constants.borderSize,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              recognizedDigit ?? "",
              style: const TextStyle(
                fontSize: 60,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MathProblemDisplay extends StatelessWidget {
  final MathProblem problem;

  const _MathProblemDisplay({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(
          problem.operationIcon,
          color: const Color(0xFF600584),
          size: 50,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${problem.operand1}',
              style: const TextStyle(
                fontSize: 81,
                fontWeight: FontWeight.bold,
                color: Color(0xFF600584),
              ),
            ),
            Text(
              '${problem.operand2}',
              style: const TextStyle(
                fontSize: 81,
                fontWeight: FontWeight.bold,
                color: Color(0xFF600584),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DrawingCanvas extends StatelessWidget {
  final List<Offset> points;
  final Function(Offset) onDrawingUpdate;

  const _DrawingCanvas({
    required this.points,
    required this.onDrawingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Constants.canvasSize + Constants.borderSize * 2,
      height: Constants.canvasSize + Constants.borderSize * 2,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blueAccent,
          width: Constants.borderSize,
        ),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x00FFFFFF),
      ),
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          final localPosition = details.localPosition;
          if (localPosition.dx >= 0 &&
              localPosition.dx <= Constants.canvasSize &&
              localPosition.dy >= 0 &&
              localPosition.dy <= Constants.canvasSize) {
            onDrawingUpdate(localPosition);
          }
        },
        child: CustomPaint(
          painter: DrawingPainter(points),
        ),
      ),
    );
  }
}

class _ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onCheck;
  final VoidCallback onNewQuestion;
  final VoidCallback onClear;
  final bool isProcessing;

  const _ActionButtonsWidget({
    required this.onCheck,
    required this.onNewQuestion,
    required this.onClear,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: _ActionButton(
            image: 'assets/images/bookmark2.png',
            title: "Kiểm tra",
            onTap: isProcessing ? null : onCheck,
            isDisabled: isProcessing,
          ),
        ),
        Expanded(
          child: _ActionButton(
            image: 'assets/images/change.png',
            title: "Đổi câu",
            onTap: isProcessing ? null : onNewQuestion,
            isDisabled: isProcessing,
          ),
        ),
        Expanded(
          child: _ActionButton(
            image: 'assets/images/clear.png',
            title: "Xóa",
            onTap: isProcessing ? null : onClear,
            isDisabled: isProcessing,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String image;
  final String title;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _ActionButton({
    required this.image,
    required this.title,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 41,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey : ColorBase.secondary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.asset(
                    image,
                    width: 14,
                    height: 14,
                    fit: BoxFit.cover,
                    color: ColorBase.primaryBackground,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      color: ColorBase.primaryBackground,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _ResultDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: buttonColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'LilitaOne',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
