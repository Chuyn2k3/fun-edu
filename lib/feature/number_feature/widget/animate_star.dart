import 'dart:math';

import 'package:flutter/material.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double xPos = _controller.value * screenWidth;
        double yPos = sin(_controller.value * 2 * pi) * screenHeight / 2 +
            screenHeight / 2;

        return Positioned(
          left: xPos,
          top: yPos,
          child: Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: Icon(
              Icons.star,
              size: widget.size,
              color: Colors.yellowAccent,
            ),
          ),
        );
      },
    );
  }
}
