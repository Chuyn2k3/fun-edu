import 'dart:math';

import 'package:flutter/material.dart';

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

class _AnimatedButterflyState extends State<AnimatedButterfly> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double position = _controller.value * (screenWidth + widget.size) - widget.size;
        double verticalMovement = sin(_controller.value * 2 * pi) * 30; // Butterfly flying up and down

        return Positioned(
          left: position,
          top: 200 + verticalMovement,
          child: Transform.rotate(
            angle: pi / 8,
            child: Icon(
              Icons.flutter_dash,
              size: widget.size,
              color: Colors.purpleAccent,
            ),
          ),
        );
      },
    );
  }
}



