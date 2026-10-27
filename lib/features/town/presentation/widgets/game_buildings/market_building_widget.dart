import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

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

class _MarketBuildingWidgetState extends State<MarketBuildingWidget> {
  bool _isPressed = false;

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
              // 1. Ground Shadow (Bóng đổ trên mặt đất)
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

              // 2. Main Wooden Shop House (Ngôi nhà gỗ ấm áp)
              Positioned(
                bottom: 16 * widget.scale,
                child: Container(
                  width: 156 * widget.scale,
                  height: 150 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(24 * widget.scale),
                    border: Border.all(color: const Color(0xFFFFF3E0), width: 3.5 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBF360C).withOpacity(0.5),
                        offset: Offset(0, 8 * widget.scale),
                        blurRadius: 10 * widget.scale,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Arched Door
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 52 * widget.scale,
                          height: 64 * widget.scale,
                          margin: EdgeInsets.only(bottom: 4 * widget.scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4E342E),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(26 * widget.scale)),
                            border: Border.all(color: const Color(0xFFFFCC80), width: 2.5 * widget.scale),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: EdgeInsets.only(right: 6 * widget.scale),
                              width: 8 * widget.scale,
                              height: 8 * widget.scale,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD54F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Striped Awning (Mái hiên sọc đỏ trắng hoạt hình 3D)
              Positioned(
                top: 36 * widget.scale,
                child: Container(
                  width: 178 * widget.scale,
                  height: 52 * widget.scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, 6 * widget.scale),
                        blurRadius: 8 * widget.scale,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    child: Row(
                      children: List.generate(7, (index) {
                        final isRed = index.isEven;
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isRed
                                    ? [const Color(0xFFEF5350), const Color(0xFFC62828)]
                                    : [Colors.white, const Color(0xFFFFEBEE)],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // 4. Fruit Display Crate (Khay trái cây tươi ngon phía trước)
              Positioned(
                bottom: 22 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(12 * widget.scale),
                    border: Border.all(color: const Color(0xFFD7CCC8), width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🍎', style: TextStyle(fontSize: 18 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text('🍌', style: TextStyle(fontSize: 18 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text('🍉', style: TextStyle(fontSize: 18 * widget.scale)),
                    ],
                  ),
                ),
              ),

              // 5. Hanging Wooden Name Signboard (Biển tên Siêu Thị Pippo)
              Positioned(
                top: 10 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 5 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
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
                      Text('🏪', style: TextStyle(fontSize: 16 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'Siêu Thị Pippo',
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

              // 6. Action Button Pill (Nút bấm vào chơi)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: Colors.white, width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6F00).withOpacity(0.6),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🛒', style: TextStyle(fontSize: 12 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'CHƠI NGAY',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 11 * widget.scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3E2723),
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
}
