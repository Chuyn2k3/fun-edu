import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

/// 3D Stylized Market Building Widget ("Tiệm Tạp Hóa Nhí"):
/// Designed following the AAA educational game benchmark (media_1793089633531.jpg):
/// - Slanted timber roof with layered wooden shingles
/// - Striped red/cream fabric awning with scalloped depth
/// - Rustic hanging wooden sign suspended by rope
/// - Wooden produce crates with glossy red apples & pumpkins
/// - Warm interior light, cash register on counter
/// - Consistent 135° soft directional ambient shadow
class MarketBuildingWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;

  const MarketBuildingWidget({
    super.key,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<MarketBuildingWidget> createState() => _MarketBuildingWidgetState();
}

class _MarketBuildingWidgetState extends State<MarketBuildingWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _lanternPulseController;

  @override
  void initState() {
    super.initState();
    _lanternPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lanternPulseController.dispose();
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
    final height = 230.0 * s;

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
              // 1. Soft 135° Directional Ground Shadow
              Positioned(
                bottom: 2 * s,
                child: Container(
                  width: 195 * s,
                  height: 34 * s,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.elliptical(195 * s, 34 * s)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10 * s,
                        offset: Offset(-6 * s, 8 * s),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Wooden Shopfront Cabin
              Positioned(
                bottom: 16 * s,
                child: Container(
                  width: 172 * s,
                  height: 138 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF6D4C41), Color(0xFF4E342E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: const Color(0xFFBCAAA4), width: 2.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12 * s,
                        offset: Offset(-4 * s, 6 * s),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Warm glowing interior store window
                      Positioned(
                        top: 28 * s,
                        left: 18 * s,
                        right: 18 * s,
                        bottom: 30 * s,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
                              radius: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(10 * s),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFE082).withOpacity(0.5),
                                blurRadius: 12 * s,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Shelf with jars in the background
                              Positioned(
                                top: 6 * s,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMiniJar(const Color(0xFFEF5350), s),
                                    SizedBox(width: 6 * s),
                                    _buildMiniJar(const Color(0xFFFFB300), s),
                                    SizedBox(width: 6 * s),
                                    _buildMiniJar(const Color(0xFFAB47BC), s),
                                  ],
                                ),
                              ),
                              // Counter Cash Register
                              Positioned(
                                bottom: 4 * s,
                                right: 10 * s,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0288D1),
                                    borderRadius: BorderRadius.circular(4 * s),
                                    border: Border.all(color: Colors.white, width: 1.5 * s),
                                  ),
                                  child: Text('0', style: TextStyle(fontSize: 8 * s, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Wooden Front Counter / Service Bar
                      Positioned(
                        bottom: 0,
                        left: 12 * s,
                        right: 12 * s,
                        height: 32 * s,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA1887F), Color(0xFF8D6E63), Color(0xFF5D4037)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8 * s)),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5 * s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Striped Fabric Awning (Red & Cream) with 3D Depth
              Positioned(
                top: 50 * s,
                child: SizedBox(
                  width: 190 * s,
                  height: 44 * s,
                  child: Stack(
                    children: [
                      // Awning shadow
                      Positioned(
                        bottom: 0,
                        left: 6 * s,
                        right: 6 * s,
                        height: 8 * s,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8 * s),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6 * s),
                            ],
                          ),
                        ),
                      ),
                      // Awning stripes
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10 * s),
                        child: Row(
                          children: List.generate(
                            8,
                            (index) => Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: index % 2 == 0
                                        ? [const Color(0xFFE53935), const Color(0xFFC62828), const Color(0xFFB71C1C)]
                                        : [const Color(0xFFFFF9C4), const Color(0xFFFFF176), const Color(0xFFFFEE58)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(6 * s)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Overlapping 3D Timber Shingle Roof
              Positioned(
                top: 24 * s,
                child: Container(
                  width: 204 * s,
                  height: 38 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12 * s),
                    border: Border.all(color: const Color(0xFFFFCA28), width: 2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8 * s,
                        offset: Offset(0, 4 * s),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (i) => Container(
                        width: 34 * s,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: const Color(0xFF3E2723), width: 1.5 * s),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Rustic Hanging Wooden Sign ("Tiệm Tạp Hóa Nhí") - Reference Benchmark
              Positioned(
                top: 0,
                child: Column(
                  children: [
                    // Hanging ropes
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 2 * s, height: 8 * s, color: const Color(0xFF8D6E63)),
                        SizedBox(width: 80 * s),
                        Container(width: 2 * s, height: 8 * s, color: const Color(0xFF8D6E63)),
                      ],
                    ),
                    // Wooden Carved Plaque
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 5 * s),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF795548), Color(0xFF4E342E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10 * s),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2 * s),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            offset: Offset(0, 3 * s),
                            blurRadius: 6 * s,
                          ),
                        ],
                      ),
                      child: Text(
                        'Tiệm Tạp Hóa Nhí',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 12 * s,
                          color: const Color(0xFFFFF8E1),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 1.5 * s),
                              blurRadius: 3 * s,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Side Produce Display: Fruit Crates (Táo Đỏ & Bí Ngô)
              // Left: Crate with shiny red apples
              Positioned(
                bottom: 12 * s,
                left: 0,
                child: _buildProduceCrate(
                  label: '🍎🍎\n🍎🍎',
                  boxColor: const Color(0xFF8D6E63),
                  s: s,
                ),
              ),

              // Right: Crate with pumpkin
              Positioned(
                bottom: 12 * s,
                right: 0,
                child: _buildProduceCrate(
                  label: '🎃',
                  boxColor: const Color(0xFF795548),
                  s: s,
                  isPumpkin: true,
                ),
              ),

              // 7. Mini Star Pill Badge (Level / Progress)
              Positioned(
                bottom: -4 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(12 * s),
                    border: Border.all(color: Colors.white, width: 1.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4 * s,
                        offset: Offset(0, 2 * s),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 10 * s)),
                      SizedBox(width: 3 * s),
                      Text(
                        'Toán & Đếm số',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 9.5 * s,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  Widget _buildMiniJar(Color color, double s) {
    return Container(
      width: 10 * s,
      height: 12 * s,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3 * s),
        border: Border.all(color: Colors.white70, width: 1 * s),
      ),
    );
  }

  Widget _buildProduceCrate({
    required String label,
    required Color boxColor,
    required double s,
    bool isPumpkin = false,
  }) {
    return Container(
      width: 36 * s,
      height: 38 * s,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(6 * s),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 5 * s,
            offset: Offset(0, 3 * s),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isPumpkin ? 18 * s : 10 * s),
        ),
      ),
    );
  }
}
