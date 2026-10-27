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
    final s = widget.scale;
    final width = 210.0 * s;
    final height = 250.0 * s;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Soft 135° Directional Castle Ground Shadow
              Positioned(
                bottom: 2 * s,
                child: Container(
                  width: 185 * s,
                  height: 30 * s,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.elliptical(185 * s, 30 * s)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10 * s,
                        offset: Offset(-6 * s, 8 * s),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Central Fortress Keep (Tòa lâu đài đá tráng lệ)
              Positioned(
                bottom: 18 * s,
                child: Container(
                  width: 160 * s,
                  height: 126 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF90CAF9), // Đá xanh dương sáng
                        Color(0xFF1E88E5), // Đá cẩm thạch hoàng gia
                        Color(0xFF0D47A1), // Chân thành vững chãi
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24 * s),
                    border: Border.all(color: Colors.white, width: 3.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.55),
                        offset: Offset(0, 10 * s),
                        blurRadius: 14 * s,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Crenellations / Battlements at top
                      Positioned(
                        top: 4 * s,
                        left: 12 * s,
                        right: 12 * s,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (_) => Container(
                              width: 16 * s,
                              height: 10 * s,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBDEFB),
                                borderRadius: BorderRadius.circular(2 * s),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Glowing Golden Arched Gate
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 54 * s,
                          height: 70 * s,
                          margin: EdgeInsets.only(bottom: 2 * s),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFF9C4), Color(0xFFFFB300)],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(27 * s)),
                            border: Border.all(color: Colors.white, width: 2.8 * s),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.7),
                                blurRadius: 12 * s,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'A B C',
                              style: TextStyle(
                                fontFamily: 'LilitaOne',
                                fontSize: 14 * s,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Left & Right Sentry Turrets (Tháp canh hai bên)
              Positioned(
                bottom: 32 * s,
                left: 6 * s,
                child: _buildTurret(s),
              ),
              Positioned(
                bottom: 32 * s,
                right: 6 * s,
                child: _buildTurret(s),
              ),

              // 4. Center High Pinnacle Spire with Fluttering Flag
              Positioned(
                top: 28 * s,
                child: Column(
                  children: [
                    // Fluttering Golden Pennant
                    AnimatedBuilder(
                      animation: _flagController,
                      builder: (context, child) {
                        final wave = math.sin(_flagController.value * math.pi * 2) * 0.14;
                        return Transform.rotate(
                          angle: wave,
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: 30 * s,
                            height: 15 * s,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4 * s),
                                bottomRight: Radius.circular(10 * s),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 4 * s,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 5 * s,
                                height: 5 * s,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Conical Royal Sapphire Roof
                    Container(
                      width: 62 * s,
                      height: 42 * s,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(31 * s)),
                        border: Border.all(color: Colors.white, width: 2.8 * s),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4 * s),
                            blurRadius: 6 * s,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Carved Wooden Name Signboard: "Lâu Đài Chữ Cái"
              Positioned(
                top: 8 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 6 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                    ),
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        offset: Offset(0, 5 * s),
                        blurRadius: 8 * s,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF42A5F5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Text(
                        'Lâu Đài Chữ Cái',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 16 * s,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF42A5F5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Tactile 3D Jelly Action Button: "KHÁM PHÁ"
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF64B5F6), // Lam ngọc
                        Color(0xFF1E88E5), // Lam hoàng gia
                        Color(0xFF0D47A1), // Chân đế
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: Colors.white, width: 2.2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.65),
                        offset: Offset(0, 4 * s),
                        blurRadius: 6 * s,
                      ),
                      const BoxShadow(
                        color: Colors.white70,
                        offset: Offset(0, -1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6 * s,
                        height: 6 * s,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        'KHÁM PHÁ',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 12 * s,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
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

  Widget _buildTurret(double s) {
    return Column(
      children: [
        // Conical Roof
        Container(
          width: 38 * s,
          height: 28 * s,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(19 * s)),
            border: Border.all(color: Colors.white, width: 2 * s),
          ),
        ),
        // Tower Shaft
        Container(
          width: 32 * s,
          height: 52 * s,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBBDEFB), Color(0xFF64B5F6)],
            ),
            border: Border.all(color: Colors.white, width: 2 * s),
          ),
          child: Center(
            child: Container(
              width: 8 * s,
              height: 14 * s,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4 * s)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
