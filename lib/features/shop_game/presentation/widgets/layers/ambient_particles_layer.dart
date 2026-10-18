import 'dart:math';
import 'package:flutter/material.dart';

class AmbientParticlesLayer extends StatefulWidget {
  final int particleCount;

  const AmbientParticlesLayer({
    super.key,
    this.particleCount = 25,
  });

  @override
  State<AmbientParticlesLayer> createState() => _AmbientParticlesLayerState();
}

class _AmbientParticlesLayerState extends State<AmbientParticlesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 2,
        speed: _random.nextDouble() * 0.15 + 0.05,
        opacity: _random.nextDouble() * 0.4 + 0.2,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.y - (animationValue * p.speed)) % 1.0;
      final currentX = (p.x + sin(animationValue * 2 * pi + p.speed) * 0.02) % 1.0;

      paint.color = Colors.amberAccent.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
