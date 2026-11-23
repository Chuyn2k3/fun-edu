import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/online_race_painter.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/ui/assets.dart';

class _ClipRecordingCanvas implements Canvas {
  _ClipRecordingCanvas(this._inner);

  final Canvas _inner;
  final List<Rect> clipRects = [];
  int saveLayerCount = 0;

  @override
  void clipRect(Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    clipRects.add(rect);
    _inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    saveLayerCount++;
    _inner.saveLayer(bounds, paint);
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
  void drawCircle(Offset c, double radius, Paint paint) =>
      _inner.drawCircle(c, radius, paint);
  @override
  void drawRRect(RRect rrect, Paint paint) => _inner.drawRRect(rrect, paint);
  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      _inner.clipRRect(rrect, doAntiAlias: doAntiAlias);
  @override
  void drawPath(Path path, Paint paint) => _inner.drawPath(path, paint);
  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      _inner.drawLine(p1, p2, paint);
  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) =>
      _inner.drawImageRect(image, src, dst, paint);
  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      _inner.drawParagraph(paragraph, offset);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('${invocation.memberName}');
  }
}

void main() {
  test('each sticker id maps to known fx', () {
    for (final id in roomStickers) {
      final kinds = fxKindsForSticker(id);
      expect(kinds, isNotEmpty, reason: 'missing fx kinds for $id');
    }

    expect(
      fxKindsForSticker('bubble'),
      [FxKind.arcFly, FxKind.popIn, FxKind.burst],
    );
    expect(fxKindsForSticker('tongue'), [FxKind.arcFly, FxKind.wobble]);
    expect(fxKindsForSticker('byebye'), [FxKind.wobble]);
    expect(fxKindsForSticker('rain'), [FxKind.popIn, FxKind.rain]);
    expect(fxKindsForSticker('sleepy'), [FxKind.floatUp]);
    expect(fxKindsForSticker('turtle'), [FxKind.arcFly, FxKind.wobble]);
    expect(fxKindsForSticker('smoke'), [FxKind.burst]);
    for (final q in quickPhraseTexts.keys) {
      expect(fxKindsForSticker(q), [FxKind.popIn]);
    }
  });

  test('three senders at the limit stay within the particle pool', () {
    final fx = StickerFx();
    addTearDown(fx.dispose);

    expect(fx.pool.capacity, 120);
    expect(fx.pool.allocations, 120);

    // Three opponents each send a heavy burst/rain sticker every 3 s over 9 s.
    var now = Duration.zero;
    const senders = [
      Offset(80, 180),
      Offset(200, 220),
      Offset(320, 200),
    ];
    const target = Offset(195, 160);
    const ids = ['bubble', 'party', 'rain'];

    for (var wave = 0; wave < 3; wave++) {
      for (var s = 0; s < senders.length; s++) {
        fx.play(
          ids[(wave + s) % ids.length],
          from: senders[s],
          to: target,
          now: now,
        );
      }
      // Step 60 fps across 3 s until the next wave arrives.
      for (var step = 0; step < 180; step++) {
        now += const Duration(milliseconds: 16);
        fx.update(now);
        expect(fx.pool.alive, lessThanOrEqualTo(120));
        expect(fx.pool.allocations, 120);
      }
    }

    // Even when 6 burst/rain stickers fire back-to-back at once, pool stays <= 120.
    for (var i = 0; i < 6; i++) {
      fx.play(
        i.isEven ? 'party' : 'bubble',
        from: senders[i % senders.length],
        to: target,
        now: now,
      );
      expect(fx.pool.alive, lessThanOrEqualTo(120));
      expect(fx.pool.allocations, 120);
    }
    fx.update(now + const Duration(milliseconds: 500));
    expect(fx.pool.alive, lessThanOrEqualTo(120));
    expect(fx.pool.allocations, 120);
  });

  testWidgets('stickers never paint over the question panel', (tester) async {
    final fx = StickerFx();
    addTearDown(fx.dispose);

    // Play a sticker near the bottom edge of the full screen (y = 700 > clipH = 500)
    // and a quick phrase bubble near the bottom.
    fx.play(
      'party',
      from: const Offset(195, 700),
      to: const Offset(195, 700),
      now: Duration.zero,
    );
    fx.play(
      'q_almost',
      from: const Offset(195, 720),
      now: Duration.zero,
      bubbleText: 'Tớ sắp tới rồi!',
    );
    fx.update(const Duration(milliseconds: 100));

    final labels = OnlineLabelCache();
    addTearDown(labels.dispose);
    final shaders = AvatarShaderCache();
    addTearDown(shaders.dispose);

    const canvasSize = Size(390, 844);
    const bottomInset = 344.0;
    const expectedClip = Rect.fromLTWH(0, 0, 390, 500);

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
          steps: 2,
        ),
      ],
      images: SceneImages(),
      shaderCache: shaders,
      labelCache: labels,
      bottomInset: bottomInset,
      stickerFx: fx,
    );

    final rec = ui.PictureRecorder();
    final spy = _ClipRecordingCanvas(Canvas(rec));
    painter.paint(spy, canvasSize);
    final pic = rec.endRecording();
    pic.dispose();

    expect(spy.saveLayerCount, 0);
    expect(spy.clipRects, contains(expectedClip));
    expect(AppImages.stickerParty, isNotEmpty);
  });
}
