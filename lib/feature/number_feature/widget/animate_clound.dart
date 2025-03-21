import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedCloud extends StatefulWidget {
  final double size;
  final Color color;
  final int duration;

  const AnimatedCloud({
    Key? key,
    required this.size,
    required this.color,
    required this.duration,
  }) : super(key: key);

  @override
  _AnimatedCloudState createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<AnimatedCloud>
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double position =
            _controller.value * (screenWidth + widget.size) - widget.size;
        return Positioned(
          left: position,
          child: Icon(
            Icons.cloud,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
