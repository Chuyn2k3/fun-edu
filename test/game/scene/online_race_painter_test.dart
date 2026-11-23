import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/online_race_painter.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/tokens.dart';

class _CircleCall {
  _CircleCall(this.center, this.radius, this.style, this.color);
  final Offset center;
  final double radius;
  final PaintingStyle style;
  final Color color;
}

class _ImageRectCall {
  _ImageRectCall(this.opacity);
  final double opacity;
}

class _SpyCanvas implements Canvas {
  _SpyCanvas(this._inner);

  final Canvas _inner;
  int saveLayerCount = 0;
  final List<_CircleCall> circles = [];
  final List<_ImageRectCall> imageRects = [];

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    saveLayerCount++;
    _inner.saveLayer(bounds, paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add(_CircleCall(c, radius, paint.style, paint.color));
    _inner.drawCircle(c, radius, paint);
  }

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    imageRects.add(_ImageRectCall(paint.color.opacity));
    _inner.drawImageRect(image, src, dst, paint);
  }

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {
    imageRects.add(_ImageRectCall(paint.color.opacity));
    _inner.drawImage(image, offset, paint);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('${invocation.memberName}');
  }

  @override
  void save() => _inner.save();

  @override
  void restore() => _inner.restore();

  @override
  void translate(double dx, double dy) => _inner.translate(dx, dy);

  @override
  void scale(double sx, [double? sy]) => _inner.scale(sx, sy);

  @override
  void rotate(double radians) => _inner.rotate(radians);

  @override
  void skew(double sx, double sy) => _inner.skew(sx, sy);

  @override
  void drawPath(Path path, Paint paint) => _inner.drawPath(path, paint);

  @override
  void drawRRect(RRect rrect, Paint paint) => _inner.drawRRect(rrect, paint);

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      _inner.clipRRect(rrect, doAntiAlias: doAntiAlias);

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      _inner.drawLine(p1, p2, paint);

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      _inner.drawParagraph(paragraph, offset);
}

Future<ui.Image> _makeTestImage() async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, 16, 16), Paint()..color = Colors.white);
  final pic = rec.endRecording();
  final img = await pic.toImage(16, 16);
  pic.dispose();
  return img;
}

void main() {
  test('layout puts the leader highest and spreads 2/3/4 racers', () {
    const area = Size(400, 600);

    // 2 racers
    final p2a = OnlineRaceLayout.rocketCenter(
        area: area, index: 0, count: 2, steps: 5, leaderSteps: 5);
    final p2b = OnlineRaceLayout.rocketCenter(
        area: area, index: 1, count: 2, steps: 3, leaderSteps: 5);
    expect(p2a.dx, closeTo(400 * 0.33, 0.01));
    expect(p2b.dx, closeTo(400 * 0.67, 0.01));
    expect(p2a.dy, closeTo(600 * 0.28, 0.01));
    expect(p2b.dy, closeTo(600 * 0.28 + 2 * 600 * 0.045, 0.01));
    expect(p2a.dy, lessThan(p2b.dy));

    // 3 racers
    final p3 = [
      for (var i = 0; i < 3; i++)
        OnlineRaceLayout.rocketCenter(
            area: area, index: i, count: 3, steps: 5, leaderSteps: 5).dx,
    ];
    expect(p3[0], closeTo(400 * 0.20, 0.01));
    expect(p3[1], closeTo(400 * 0.50, 0.01));
    expect(p3[2], closeTo(400 * 0.80, 0.01));

    // 4 racers + vertical clamp at 0.82
    final p4 = [
      for (var i = 0; i < 4; i++)
        OnlineRaceLayout.rocketCenter(
            area: area, index: i, count: 4, steps: 18 - i * 5, leaderSteps: 18),
    ];
    expect(p4[0].dx, closeTo(400 * 0.15, 0.01));
    expect(p4[1].dx, closeTo(400 * 0.38, 0.01));
    expect(p4[2].dx, closeTo(400 * 0.62, 0.01));
    expect(p4[3].dx, closeTo(400 * 0.85, 0.01));
    expect(p4[0].dy, closeTo(600 * 0.28, 0.01));
    expect(p4[3].dy, closeTo(600 * 0.82, 0.01));
  });

  testWidgets('away racer drawn faded with label and zero saveLayer',
      (tester) async {
    final img = await tester.runAsync(_makeTestImage);
    addTearDown(img!.dispose);

    final images = SceneImages();
    images[AppImages.rocketOrange].value = img;
    images[AppImages.rocketBlue].value = img;
    images[kidAvatars[0]].value = img;
    images[kidAvatars[1]].value = img;

    final labels = OnlineLabelCache();
    addTearDown(labels.dispose);
    final shaders = AvatarShaderCache();
    addTearDown(shaders.dispose);

    final painter = OnlineRacePainter(
      racers: [
        OnlineRacer(
          id: 'p1',
          name: 'Na',
          avatar: kidAvatars[0],
          rocket: 'rocket_orange',
          steps: 5,
          me: true,
        ),
        OnlineRacer(
          id: 'p2',
          name: 'Bo',
          avatar: kidAvatars[1],
          rocket: 'rocket_blue',
          steps: 3,
          away: true,
        ),
      ],
      images: images,
      shaderCache: shaders,
      labelCache: labels,
    );

    final rec = ui.PictureRecorder();
    final spy = _SpyCanvas(Canvas(rec));
    painter.paint(spy, const Size(390, 500));
    final pic = rec.endRecording();
    pic.dispose();

    expect(spy.saveLayerCount, 0);
    expect(spy.imageRects.any((r) => (r.opacity - 0.4).abs() < 0.02), isTrue);
    expect(spy.imageRects.any((r) => (r.opacity - 1.0).abs() < 0.02), isTrue);
    expect(labels.cachedTexts, contains('Đang chờ'));
  });

  testWidgets('me has gold ring and avatar ImageShader is cached once',
      (tester) async {
    final img = await tester.runAsync(_makeTestImage);
    addTearDown(img!.dispose);

    final images = SceneImages();
    images[AppImages.rocketOrange].value = img;
    images[AppImages.rocketBlue].value = img;
    images[kidAvatars[0]].value = img;
    images[kidAvatars[1]].value = img;

    final shaders = AvatarShaderCache();
    addTearDown(shaders.dispose);
    final labels = OnlineLabelCache();
    addTearDown(labels.dispose);

    final s1 = shaders.shaderFor(img);
    final s2 = shaders.shaderFor(img);
    expect(identical(s1, s2), isTrue);
    expect(shaders.cachedCount, 1);

    final painter = OnlineRacePainter(
      racers: [
        OnlineRacer(
          id: 'p1',
          name: 'Na',
          avatar: kidAvatars[0],
          rocket: 'rocket_orange',
          steps: 4,
          me: true,
        ),
        OnlineRacer(
          id: 'p2',
          name: 'Bo',
          avatar: kidAvatars[1],
          rocket: 'rocket_blue',
          steps: 6,
          me: false,
        ),
      ],
      images: images,
      shaderCache: shaders,
      labelCache: labels,
    );

    final rec = ui.PictureRecorder();
    final spy = _SpyCanvas(Canvas(rec));
    painter.paint(spy, const Size(390, 500));
    final pic = rec.endRecording();
    pic.dispose();

    // Only `me` gets the gold ring strokes around the cockpit porthole.
    final goldRings = spy.circles.where((c) =>
        c.style == PaintingStyle.stroke &&
        (c.color.value == GameColors.ringGlow.withOpacity(0.85).value ||
            c.color.value == GameColors.cometRim.value));
    expect(goldRings.length, greaterThanOrEqualTo(2));
  });

  testWidgets('position interpolates over 200 ms', (tester) async {
    Widget wrap(List<OnlineRacer> racers) => MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 390,
              height: 500,
              child: RaceScene(
                kidSteps: racers.first.steps,
                chipSteps: racers.last.steps,
                kidRocket: 'rocket_orange',
                kidTrail: 'trail_flame',
                boosting: false,
                won: false,
                onlineRacers: racers,
                raceSteps: 18,
              ),
            ),
          ),
        );

    final initial = [
      OnlineRacer(
        id: 'p1',
        name: 'Na',
        avatar: kidAvatars[0],
        rocket: 'rocket_orange',
        steps: 0,
        me: true,
      ),
      OnlineRacer(
        id: 'p2',
        name: 'Bo',
        avatar: kidAvatars[1],
        rocket: 'rocket_blue',
        steps: 0,
      ),
    ];

    await tester.pumpWidget(wrap(initial));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.onlineDisplayedSteps('p2'), 0.0);

    await tester.pumpWidget(wrap([
      initial[0],
      OnlineRacer(
        id: 'p2',
        name: 'Bo',
        avatar: kidAvatars[1],
        rocket: 'rocket_blue',
        steps: 4,
      ),
    ]));

    await tester.pump(const Duration(milliseconds: 100));
    expect(state.onlineDisplayedSteps('p2'), closeTo(2.0, 0.05));

    await tester.pump(const Duration(milliseconds: 100));
    expect(state.onlineDisplayedSteps('p2'), closeTo(4.0, 0.01));

    await tester.pumpWidget(const SizedBox());
  });
}
