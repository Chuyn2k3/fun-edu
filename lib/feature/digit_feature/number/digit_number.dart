import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fun_edu/core/services/recognizer.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/constants.dart';
import 'package:fun_edu/feature/digit_feature/number/drawing_painter.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DigitNumberScreen extends StatefulWidget {
  const DigitNumberScreen({super.key});

  @override
  _DigitNumberScreenState createState() => _DigitNumberScreenState();
}

class _DigitNumberScreenState extends State<DigitNumberScreen> {
  final List<Offset> _points = [];
  final Recognizer _recognizer = Recognizer();
  final FlutterTts _flutterTts = FlutterTts();
  List<Prediction> _prediction = [];
  int _targetNumber = 0;

  @override
  void initState() {
    super.initState();
    _initModel();
    _generateRandomNumber();
  }

  void _generateRandomNumber() {
    setState(() {
      _targetNumber = Random().nextInt(10);
      _speakNumber();
    });
  }

  Future<void> _speakNumber() async {
    await _flutterTts.speak("Hãy viết số $_targetNumber");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _buildBackground(),
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                elevation: 0,
                backgroundColor: ColorBase.secondaryBackground,
                leading: _buildAppBar(),
                centerTitle: true,
                title: const Text("Bé hãy viết số "),
                titleTextStyle: const TextStyle(
                    fontFamily: 'Sukhumvit Set',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 150,
                        width: 120,
                        padding: const EdgeInsets.only(right: 20, bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius:
                              BorderRadius.circular(12), // Bo góc mềm mại
                        ),
                        child: Center(
                          child: Text(
                            " $_targetNumber",
                            style: const TextStyle(
                              fontFamily: 'Sukhumvit Set',
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 32,
                      ),
                      _mnistPreviewImage(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _drawCanvasWidget(),
                  const SizedBox(height: 10),
                  PredictionWidget(predictions: _prediction),
                ],
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.green,
            child: const Icon(FontAwesomeIcons.volumeUp, color: Colors.white),
            onPressed: _speakNumber,
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(FontAwesomeIcons.eraser, color: Colors.white),
            onPressed: () {
              setState(() {
                _points.clear();
                _prediction.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    // return Padding(
    //   padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       InkWell(
    //         splashColor: Colors.transparent,
    //         focusColor: Colors.transparent,
    //         hoverColor: Colors.transparent,
    //         highlightColor: Colors.transparent,
    //         onTap: () {
    //           Navigator.pop(context);
    //         },
    //         child: const Icon(
    //           Icons.arrow_back_ios_new,
    //           color: ColorBase.primaryBackground,
    //           size: 24,
    //         ),
    //       ),
    //       const SizedBox(
    //         width: 4,
    //       ),
    //       const Text(
    //         'Trở lại ',
    //         style: TextStyle(
    //           fontFamily: 'Sukhumvit Set',
    //           color: ColorBase.primaryBackground,
    //           fontSize: 24,
    //           letterSpacing: 0.0,
    //           fontWeight: FontWeight.w600,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent, // Màu nền của nút
            shape: BoxShape.circle, // Hình dạng tròn
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(2, 4),
              )
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

  Widget _buildBackground() {
    return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/start.png'),
            fit: BoxFit.fill, // Hiển thị toàn bộ ảnh nền
          ),
        ));
  }

  Widget _drawCanvasWidget() {
    return Container(
      width: Constants.canvasSize + Constants.borderSize * 2,
      height: Constants.canvasSize + Constants.borderSize * 2,
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.blueAccent, width: Constants.borderSize),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          Offset _localPosition = details.localPosition;
          if (_localPosition.dx >= 0 &&
              _localPosition.dx <= Constants.canvasSize &&
              _localPosition.dy >= 0 &&
              _localPosition.dy <= Constants.canvasSize) {
            setState(() {
              _points.add(_localPosition);
            });
          }
        },
        onPanEnd: (DragEndDetails details) {
          //_points.add(); // Thêm điểm ngắt thay vì (0,0)
          _recognize();
        },
        child: CustomPaint(
          painter: DrawingPainter(_points),
        ),
      ),
    );
  }

  void _initModel() async {
    await _recognizer.loadModel();
  }

  void _recognize() async {
    List<dynamic>? pred = await _recognizer.recognize(_points);
    if (pred != null) {
      setState(() {
        _prediction = pred.map((json) => Prediction.fromJson(json)).toList();
      });

      if (_prediction.isNotEmpty &&
          _prediction[0].label == _targetNumber.toString()) {
        _showSuccessDialog(context, _targetNumber, () {
          _generateRandomNumber();
          _points.clear();
          _prediction.clear();
          setState(() {});
        });
      } else {
        _showTryAgainDialog(context, () {
          _points.clear();
          _prediction.clear();
          setState(() {});
        });
      }
    }
  }

  void _showSuccessDialog(
      BuildContext context, int targetNumber, VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 Chúc mừng!",
                  style: TextStyle(
                      fontFamily: 'Sukhumvit Set',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(
                  "Bé đã viết đúng số $targetNumber!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Sukhumvit Set',
                      fontSize: 18,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Tiếp tục",
                        style: TextStyle(
                            fontFamily: 'Sukhumvit Set',
                            fontSize: 18,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTryAgainDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "❌ Ôi không!",
                  style: TextStyle(
                      fontFamily: 'Sukhumvit Set',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Bé hãy thử lại nào!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Sukhumvit Set',
                      fontSize: 18,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Thử lại",
                        style: TextStyle(
                            fontFamily: 'Sukhumvit Set',
                            fontSize: 18,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mnistPreviewImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FutureBuilder<Uint8List?>(
        future: _previewImage(),
        builder: (BuildContext _, AsyncSnapshot<Uint8List?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(
                child: Text('No Image',
                    style: TextStyle(
                        fontFamily: 'Sukhumvit Set', color: Colors.white)));
          } else {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.fill,
            );
          }
        },
      ),
    );
  }

  Future<Uint8List?> _previewImage() async {
    return await _recognizer.previewImage(_points);
  }
}
