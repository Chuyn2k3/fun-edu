import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ui/layout/form_factor.dart';
import '../../../ui/theme/tokens.dart';

/// Toán nâng cao pictures, all drawn in code (no photos of real money).

/// [tens] bundles of ten sticks tied with a band, then [ones] single sticks.
class StickBundles extends StatelessWidget {
  const StickBundles({super.key, required this.tens, required this.ones});

  final int tens;
  final int ones;

  @override
  Widget build(BuildContext context) {
    final h = context.isTablet ? 120.0 : 84.0;
    return Semantics(
      label: '$tens bó mười que và $ones que lẻ',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < tens; i++)
            SizedBox(
              key: ValueKey('bundle-$i'),
              width: h * 0.42,
              height: h,
              child: const CustomPaint(painter: _SticksPainter(10, bundle: true)),
            ),
          if (ones > 0)
            SizedBox(
              key: const ValueKey('singles'),
              width: h * 0.16 * ones + 4,
              height: h,
              child: CustomPaint(painter: _SticksPainter(ones, bundle: false)),
            ),
        ],
      ),
    );
  }
}

class _SticksPainter extends CustomPainter {
  const _SticksPainter(this.count, {required this.bundle});

  final int count;
  final bool bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stick = Paint()
      ..color = MathColors.stick
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bundle ? w * 0.09 : h * 0.06;
    final edge = Paint()
      ..color = MathColors.stickEdge
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stick.strokeWidth + 2;
    for (var i = 0; i < count; i++) {
      final x = bundle ? w * (0.12 + 0.76 * i / (count - 1)) : (i + 0.5) * (w - 4) / count + 2;
      // A bundle fans out a little above and below the band.
      final lean = bundle ? (i - (count - 1) / 2) * w * 0.012 : 0.0;
      final top = Offset(x + lean, h * 0.05);
      final bottom = Offset(x - lean, h * 0.95);
      canvas.drawLine(top, bottom, edge);
      canvas.drawLine(top, bottom, stick);
    }
    if (bundle) {
      final band = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.44, w, h * 0.12), Radius.circular(h * 0.04));
      canvas.drawRRect(band, Paint()..color = MathColors.band);
    }
  }

  @override
  bool shouldRepaint(_SticksPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.bundle != bundle;
}

/// An analogue clock at [hour] o'clock or half past.
class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.hour, required this.half});

  final int hour;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final side = context.isTablet ? 240.0 : 170.0;
    return Semantics(
      label: 'Đồng hồ',
      excludeSemantics: true,
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(painter: ClockPainter(hour: hour, half: half)),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  ClockPainter({required this.hour, required this.half});

  final int hour;
  final bool half;

  /// Angle (radians, clockwise from 12) of the hour and minute hands.
  static (double hourAngle, double minuteAngle) angles(int hour, bool half) => (
        ((hour % 12) + (half ? 0.5 : 0)) / 12 * 2 * math.pi,
        half ? math.pi : 0.0,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = MathColors.clockFace);
    canvas.drawCircle(
        c,
        r - r * 0.04,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08
          ..color = MathColors.clockRim);
    for (var n = 1; n <= 12; n++) {
      final a = n / 12 * 2 * math.pi;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          // A painter does not inherit the theme: name the app font.
          style: TextStyle(
              fontFamily: 'Nunito', fontSize: r * 0.2, fontWeight: FontWeight.w900, color: AppColors.text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = c + Offset(math.sin(a), -math.cos(a)) * r * 0.72;
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    final (ha, ma) = angles(hour, half);
    Offset tip(double a, double len) => c + Offset(math.sin(a), -math.cos(a)) * len;
    canvas.drawLine(
        c,
        tip(ma, r * 0.6), // stops short of the numbers
        Paint()
          ..color = AppColors.primary
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.06);
    canvas.drawLine(
        c,
        tip(ha, r * 0.42),
        Paint()
          ..color = AppColors.text
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.1);
    canvas.drawCircle(c, r * 0.07, Paint()..color = AppColors.text);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) =>
      oldDelegate.hour != hour || oldDelegate.half != half;
}

/// Flat banknotes (values in nghìn đồng), in their real notes' colours.
class BanknoteRow extends StatelessWidget {
  const BanknoteRow({super.key, required this.notes});

  final List<int> notes;

  static (Color fill, Color edge) colorsOf(int value) => switch (value) {
        1 => (MathColors.note1Fill, MathColors.note1Edge),
        2 => (MathColors.note2Fill, MathColors.note2Edge),
        5 => (MathColors.note5Fill, MathColors.note5Edge),
        _ => (MathColors.note10Fill, MathColors.note10Edge),
      };

  @override
  Widget build(BuildContext context) {
    final w = context.isTablet ? 200.0 : 132.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < notes.length; i++)
          _Note(key: ValueKey('note-$i'), value: notes[i], width: w),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.value, required this.width});

  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final (fill, edge) = BanknoteRow.colorsOf(value);
    return Semantics(
      label: '$value nghìn đồng',
      excludeSemantics: true,
      child: Container(
        width: width,
        height: width * 0.5,
        padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: width * 0.03),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(width * 0.06),
          border: Border.all(color: edge, width: 3),
        ),
        child: Row(
          children: [
            Container(
              width: width * 0.16,
              height: width * 0.16,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: edge, width: 2)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$value.000',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.text),
                    ),
                    const Text(
                      'đồng',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
