import 'dart:math' as math;
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
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapMascot() {
    AudioManager().playSfx(AudioSfx.correctTing);
    setState(() {
      _speechIndex = (_speechIndex + 1) % _dialogues.length;
      _isJumping = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Comic Speech Bubble (Bong bóng lời thoại hoạt hình có đuôi chỉ vào Pippo)
          Container(
            constraints: BoxConstraints(maxWidth: 240 * scale),
            margin: EdgeInsets.only(bottom: 6 * scale),
            padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(color: const Color(0xFFFFB300), width: 2.5 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  offset: Offset(0, 4 * scale),
                  blurRadius: 8 * scale,
                ),
              ],
            ),
            child: Text(
              _dialogues[_speechIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 13 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3E2723),
                letterSpacing: 0.3,
              ),
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
                  child: Container(
                    width: 74 * scale,
                    height: 74 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.2, -0.3),
                        colors: [Color(0xFFFFCC80), Color(0xFFFF8F00), Color(0xFFE65100)],
                      ),
                      border: Border.all(color: Colors.white, width: 3.5 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFBF360C).withOpacity(0.4),
                          offset: Offset(0, 6 * scale),
                          blurRadius: 8 * scale,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '🐻',
                        style: TextStyle(fontSize: 42 * scale),
                      ),
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
