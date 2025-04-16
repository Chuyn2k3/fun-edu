import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/core/services/recognizer.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/constants.dart';
import 'package:fun_edu/feature/digit_feature/number/drawing_painter.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction_widget.dart';
import 'package:meta/meta.dart';
import 'dart:ui' as ui;

/// {@template index}
/// DigitMath widget.
/// {@endtemplate}
class DigitMath extends StatefulWidget {
  /// {@macro index}
  const DigitMath({
    super.key, // ignore: unused_element
  });

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  @internal
  static _DigitMathState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_DigitMathState>();

  @override
  State<DigitMath> createState() => _DigitMathState();
}

/// State for widget DigitMath.
class _DigitMathState extends State<DigitMath> {
  final List<Offset> _points = [];
  final Recognizer _recognizer = Recognizer();
  final FlutterTts _flutterTts = FlutterTts();
  String? numberAiResult;
  List<Prediction> _prediction = [];
  int _targetNumber = 0;

  late int number1;
  late int number2;
  bool _isAddition = true; // Mặc định là phép cộng

  @override
  void initState() {
    super.initState();
    _initModel();
    _generateNewNumbers();
  }

  // Hàm tạo số ngẫu nhiên không trùng nhau từ 0 đến 5
  List<int> generateRandomNumbers() {
    List<int> numbers =
        List.generate(6, (index) => index); // [0, 1, 2, 3, 4, 5]
    numbers.shuffle(); // Trộn ngẫu nhiên
    return numbers.sublist(0, 2); // Lấy 2 số đầu tiên
  }

  void _generateNewNumbers() {
    List<int> randomNumbers = generateRandomNumbers();
    setState(() {
      number1 = randomNumbers[0];
      number2 = randomNumbers[1];

      // Xác định phép toán ngẫu nhiên (cộng hoặc trừ)
      _isAddition = Random().nextBool();

      if (_isAddition && (number1 + number2) <= 9) {
        _targetNumber = number1 + number2;
      } else if (!_isAddition && (number1 - number2) >= 0) {
        _targetNumber = number1 - number2;
      } else {
        _isAddition = true; // Nếu trừ không hợp lệ, đổi về cộng
        _targetNumber = number1 + number2;
      }
    });
  }

  void _generateNewQuestion() {
    setState(() {
      _generateNewNumbers(); // Tạo phép tính mới
      numberAiResult = null;
      _points.clear();
      _prediction.clear();
      setState(() {});
    });
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _prediction.clear();
      setState(() {});
    });
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
              const SizedBox(height: 10),
              _buildAppBar(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // const SizedBox(height: 10),
                  _buildBody(),
                ],
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 32,
          ),
          Expanded(
              child: _buildAction(
            'assets/images/bookmark2.png',
            "Kiểm tra",
            () async {
              try {
                _recognize();
                print("Đã xuất ảnh chữ ký!");
              } catch (e) {
                print(e);
              }
            },
          )),
          Expanded(
              child: _buildAction(
            'assets/images/change.png',
            "Đổi câu",
            _generateNewQuestion, // Gọi hàm đổi câu hỏi
          )),
          Expanded(
              child: _buildAction(
            'assets/images/clear.png',
            "Xóa",
            _clearSignature, // Gọi hàm xóa chữ ký
          )),
        ],
      ),
    );
  }

  Widget _buildAction(String image, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 41,
          decoration: BoxDecoration(
            color: ColorBase.secondary,
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
                SizedBox(
                  width: 4,
                ),
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

  Widget _buildBackground() {
    return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Scratchpad.png'),
            fit: BoxFit.fill, // Hiển thị toàn bộ ảnh nền
          ),
        ));
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent, // Màu nền của nút
                // shape: BoxShape.circle, // Hình dạng tròn
                borderRadius: BorderRadius.circular(32),
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
        ),
        // Column(
        //   crossAxisAlignment: CrossAxisAlignment.center,
        //   children: [
        //     const Text("Kết quả nhận diện từ AI",
        //         style: TextStyle(
        //           fontSize: 20,
        //           color: Colors.black,
        //         )),
        //     Container(
        //       width: 90,
        //       height: 90,
        //       decoration: BoxDecoration(
        //         border: Border.all(
        //             color: Colors.blueAccent, width: Constants.borderSize),
        //         borderRadius: BorderRadius.circular(10),
        //         color: Colors.white,
        //       ),
        //       child: Center(
        //         child: Text(numberAiResult ?? "",
        //             style: const TextStyle(
        //               fontSize: 60,
        //               color: Colors.black,
        //             )),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // const SizedBox(
          //   height: 106,
          //   child: FaIcon(
          //     FontAwesomeIcons.equals,
          //     color: Color(0xFF600584),
          //     size: 50,
          //   ),
          // ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Row(
              //   mainAxisSize: MainAxisSize.min,
              //   //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: [
              //         const Text("Kết quả nhận diện từ AI",
              //             style: TextStyle(
              //               fontSize: 20,
              //               color: Colors.black,
              //             )),
              //         Container(
              //           width: 90,
              //           height: 90,
              //           decoration: BoxDecoration(
              //             border: Border.all(
              //                 color: Colors.blueAccent,
              //                 width: Constants.borderSize),
              //             borderRadius: BorderRadius.circular(10),
              //             color: Colors.white,
              //           ),
              //           child: Center(
              //             child: Text(numberAiResult ?? "",
              //                 style: const TextStyle(
              //                   fontSize: 60,
              //                   color: Colors.black,
              //                 )),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("AI nhận diện",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            )),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.blueAccent,
                                width: Constants.borderSize),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(numberAiResult ?? "",
                                style: const TextStyle(
                                  fontSize: 60,
                                  color: Colors.black,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Flexible(
                    flex: 9,
                    child: Row(
                      children: [
                        FaIcon(
                          _isAddition
                              ? FontAwesomeIcons.plus
                              : FontAwesomeIcons.minus, // Cập nhật icon
                          color: const Color(0xFF600584),
                          size: 50,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$number1', // Số ngẫu nhiên 1
                              style: const TextStyle(
                                fontSize: 81,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF600584),
                              ),
                            ),
                            Text(
                              '$number2', // Số ngẫu nhiên 2
                              style: const TextStyle(
                                fontSize: 81,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF600584),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: 152,
                height: 12,
                color: const Color(0xFF600584),
              ),
              SizedBox(
                height: 16,
              ),
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
                  SizedBox(
                    width: 16,
                  ),
                  _drawCanvasWidget(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawCanvasWidget() {
    return Container(
      // width: 220,
      // height: 220,
      width: Constants.canvasSize + Constants.borderSize * 2,
      height: Constants.canvasSize + Constants.borderSize * 2,
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.blueAccent, width: Constants.borderSize),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x00FFFFFF),
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
        onPanEnd: (DragEndDetails details) {},
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
      setState(() {
        numberAiResult = _prediction[0].label;
      });
      print(_prediction[0].label);
      print(_targetNumber);
      if (_prediction.isNotEmpty &&
          _prediction[0].label == _targetNumber.toString()) {
        _showSuccessDialog(context, _targetNumber, () {
          _generateNewQuestion();

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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(
                  "Bé đã viết đúng số $targetNumber!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'LilitaOne',
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
                            fontFamily: 'LilitaOne',
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
                      fontFamily: 'LilitaOne',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Bé hãy thử lại nào!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'LilitaOne',
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
                            fontFamily: 'LilitaOne',
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
}
