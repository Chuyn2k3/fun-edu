import 'dart:math';

import 'package:flutter/material.dart';

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
  double _positionX = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat();
  }

  void _resetPosition(double screenWidth) {
    setState(() {
      _positionX = Random().nextDouble() * screenWidth;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_positionX == 0) _resetPosition(screenWidth);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double positionY = (1 - _controller.value) * screenHeight;
        double xWobble = sin(_controller.value * 2 * pi) * 20;

        return Positioned(
          left: _positionX + xWobble,
          top: positionY,
          child: Column(
            children: [
              // Balloon
              Container(
                height: widget.size,
                width: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.9),
                      widget.color.withOpacity(0.6)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: BalloonHighlightPainter(),
                ),
              ),
              // String
              Container(
                width: 2,
                height: 30,
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }
}

class BalloonHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.1,
        size.width * 0.5, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.5,
        size.width * 0.5, size.height * 0.6);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
