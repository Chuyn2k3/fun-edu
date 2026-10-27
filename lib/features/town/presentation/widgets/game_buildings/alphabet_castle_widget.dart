import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class AlphabetCastleBuildingWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;

  const AlphabetCastleBuildingWidget({
    super.key,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<AlphabetCastleBuildingWidget> createState() => _AlphabetCastleBuildingWidgetState();
}

class _AlphabetCastleBuildingWidgetState extends State<AlphabetCastleBuildingWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _flagController;

  @override
  void initState() {
    super.initState();
    _flagController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flagController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AudioManager().playSfx(AudioSfx.click);
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _isPressed = false);
        widget.onTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = 190.0 * widget.scale;
    final height = 240.0 * widget.scale;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Ground Shadow (Bóng lâu đài)
              Positioned(
                bottom: 4 * widget.scale,
                child: Container(
                  width: 170 * widget.scale,
                  height: 28 * widget.scale,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.all(Radius.elliptical(170 * widget.scale, 28 * widget.scale)),
                  ),
                ),
              ),

              // 2. Castle Central Keep (Tòa lâu đài đá trung tâm)
              Positioned(
                bottom: 16 * widget.scale,
                child: Container(
                  width: 154 * widget.scale,
                  height: 120 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
                    ),
                    borderRadius: BorderRadius.circular(20 * widget.scale),
                    border: Border.all(color: Colors.white, width: 3.5 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.4),
                        offset: Offset(0, 8 * widget.scale),
                        blurRadius: 10 * widget.scale,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glowing Magical Arched Gate
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 50 * widget.scale,
                          height: 64 * widget.scale,
                          margin: EdgeInsets.only(bottom: 2 * widget.scale),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFF59D), Color(0xFFFFB300)],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(25 * widget.scale)),
                            border: Border.all(color: Colors.white, width: 2.5 * widget.scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 10 * widget.scale,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'A B C',
                              style: TextStyle(
                                fontFamily: 'LilitaOne',
                                fontSize: 13 * widget.scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Left & Right Turrets (2 Tháp canh 2 bên với mái nhọn hoàng gia)
              Positioned(
                bottom: 30 * widget.scale,
                left: 6 * widget.scale,
                child: _buildTurret(widget.scale),
              ),
              Positioned(
                bottom: 30 * widget.scale,
                right: 6 * widget.scale,
                child: _buildTurret(widget.scale),
              ),

              // 4. Center High Tower & Fluttering Pennant Flag (Tháp chính và cờ đuôi nheo)
              Positioned(
                top: 26 * widget.scale,
                child: Column(
                  children: [
                    // Golden Pennant Flag fluttering
                    AnimatedBuilder(
                      animation: _flagController,
                      builder: (context, child) {
                        final wave = math.sin(_flagController.value * math.pi * 2) * 0.12;
                        return Transform.rotate(
                          angle: wave,
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: 28 * widget.scale,
                            height: 14 * widget.scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4 * widget.scale),
                                bottomRight: Radius.circular(8 * widget.scale),
                              ),
                            ),
                            child: Center(
                              child: Text('⭐', style: TextStyle(fontSize: 8 * widget.scale)),
                            ),
                          ),
                        );
                      },
                    ),
                    // Conical Roof
                    Container(
                      width: 58 * widget.scale,
                      height: 38 * widget.scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(29 * widget.scale)),
                        border: Border.all(color: Colors.white, width: 2.5 * widget.scale),
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Title Signboard (Biển tên Lâu Đài Chữ Cái)
              Positioned(
                top: 10 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 5 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    ),
                    borderRadius: BorderRadius.circular(14 * widget.scale),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.5 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0, 4 * widget.scale),
                        blurRadius: 6 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏰', style: TextStyle(fontSize: 16 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'Lâu Đài Chữ Cái',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 15 * widget.scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Action Button Pill (Nút sắp ra mắt)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: Colors.white, width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.6),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 12 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'SẮP RA MẮT',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 11 * widget.scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurret(double scale) {
    return Column(
      children: [
        Container(
          width: 32 * scale,
          height: 24 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16 * scale)),
            border: Border.all(color: Colors.white, width: 2 * scale),
          ),
        ),
        Container(
          width: 28 * scale,
          height: 60 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF64B5F6),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: Colors.white, width: 2 * scale),
          ),
        ),
      ],
    );
  }
}
