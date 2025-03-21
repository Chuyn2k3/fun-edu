import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomStack extends StatefulWidget {
  const CustomStack({
    super.key,
    required this.image,
    required this.text1,
    required this.color,
  });

  final String image;
  final String text1;
  final Color color;

  @override
  State<CustomStack> createState() => _CustomStackState();
}

class _CustomStackState extends State<CustomStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isLargeScreen = mq.width > 600;

    return Center(
      child: Container(
        // width: isLargeScreen ? 500 : 320,
        // height: isLargeScreen ? 280 : 220,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: widget.color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 4,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ảnh nhân vật
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  widget.image,
                  height: isLargeScreen ? 160 : 140,
                  width: isLargeScreen ? 160 : 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Text Box
            SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  widget.text1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredokaOne(
                    fontSize: isLargeScreen ? 22 : 18,
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

  Widget _buildAnimatedIcon(
      IconData icon, Color color, double size, double? top, double? left,
      {double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double animationValue =
              0.8 + 0.2 * _controller.value; // Co giãn nhịp nhàng
          return Transform.scale(
            scale: animationValue,
            child: FaIcon(
              icon,
              color: color.withOpacity(0.5),
              size: size,
            ),
          );
        },
      ),
    );
  }
}
