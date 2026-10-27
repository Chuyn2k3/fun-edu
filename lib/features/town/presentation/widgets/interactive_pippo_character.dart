import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class InteractivePippoCharacter extends StatefulWidget {
  final double scale;

  const InteractivePippoCharacter({
    super.key,
    this.scale = 1.0,
  });

  @override
  State<InteractivePippoCharacter> createState() => _InteractivePippoCharacterState();
}

class _InteractivePippoCharacterState extends State<InteractivePippoCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  int _speechIndex = 0;
  bool _isJumping = false;
  bool _showBubble = false;
  Timer? _bubbleTimer;

  final List<String> _dialogues = [
    'Chào bạn nhỏ! Hôm nay mình đi siêu thị mua táo nhé! 🍎',
    'Cây Tri Thức sắp lớn rồi! Bé đã tưới nước chưa? 💧',
    'Vào Nhà Nấm làm phép tính kỳ diệu với Pippo nào! 🍄✨',
    'Gõ búa vào quả trứng rồng xem nở ra bạn gì nhé! 🐣🐉',
    'Pippo rất tự hào về bé! Cùng học vui nào! ⭐',
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapMascot() {
    AudioManager().playSfx(AudioSfx.correctTing);

    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _showBubble = false);
      }
    });

    setState(() {
      if (_showBubble) {
        _speechIndex = (_speechIndex + 1) % _dialogues.length;
      }
      _showBubble = true;
      _isJumping = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isJumping = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return GestureDetector(
      onTap: _onTapMascot,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Reactive Overhead Speech Bubble (Appears on tap, auto-dismisses after 3s)
          AnimatedScale(
            scale: _showBubble ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _showBubble ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: _showBubble
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: 220 * scale),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 8 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18 * scale),
                            border: Border.all(color: const Color(0xFFFFB300), width: 2.5 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                offset: Offset(0, 4 * scale),
                                blurRadius: 10 * scale,
                              ),
                            ],
                          ),
                          child: Text(
                            _dialogues[_speechIndex],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 12.5 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3E2723),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Pointer Triangle
                        CustomPaint(
                          size: Size(14 * scale, 7 * scale),
                          painter: _SpeechTrianglePainter(
                            color: Colors.white,
                            borderColor: const Color(0xFFFFB300),
                            borderWidth: 2.0 * scale,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // 2. Animated Pippo Bear Mascot with Ground Shadow
          SizedBox(
            width: 86 * scale,
            height: 96 * scale,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Ground Shadow
                Container(
                  width: 68 * scale,
                  height: 14 * scale,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.all(Radius.elliptical(68 * scale, 14 * scale)),
                  ),
                ),

                // Mascot Body with Idle Breathing / Happy Jump
                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    final idleOffset = _bounceController.value * 6 * scale;
                    final jumpOffset = _isJumping ? -18.0 * scale : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -idleOffset + jumpOffset),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 90 * scale,
                    height: 110 * scale,
                    child: Image.asset(
                      'assets/shop_game/characters/bear/bear_idle.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 74 * scale,
                          height: 74 * scale,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF8F00),
                          ),
                          child: Center(
                            child: Text('🐻', style: TextStyle(fontSize: 42 * scale)),
                          ),
                        );
                      },
                    ),
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

class _SpeechTrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  _SpeechTrianglePainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
