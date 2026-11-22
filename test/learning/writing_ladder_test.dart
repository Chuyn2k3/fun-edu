import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/learning/writing_sections.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';
import 'package:funedu/stroke/grader.dart';

Glyph _load(String id) => Glyph.fromJson(
      jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

double _length(Stroke s) {
  var total = 0.0;
  for (var i = 1; i < s.points.length; i++) {
    final a = s.points[i - 1];
    final b = s.points[i];
    total += sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
  }
  return total;
}

void main() {
  test('writingLadder: 15 old ids, the 34 letters and marks, 29 capitals', () {
    expect(writingLadder, hasLength(78));
    expect(writingLadder.toSet(), hasLength(78));
    expect(writingLadder.take(15).toList(), [
      'net-ngang',
      'net-thang-dung',
      'net-xien',
      'net-cong',
      'net-moc',
      for (var i = 0; i < 10; i++) 'so-$i',
    ]);
    expect(writingLadder.skip(49).join(' '),
        'hoa-o hoa-oo hoa-ow hoa-c hoa-i hoa-l hoa-t hoa-h hoa-u hoa-uw hoa-v hoa-x hoa-n hoa-m hoa-a hoa-aw hoa-aa hoa-e hoa-ee hoa-s hoa-p hoa-r hoa-b hoa-d hoa-dd hoa-k hoa-q hoa-g hoa-y');
    expect(
      writingLadder.skip(15).take(34).join(' '),
      'chu-i chu-t chu-u chu-uw chu-n chu-m chu-v chu-r chu-s chu-o chu-oo '
      'chu-ow chu-c chu-x chu-e chu-ee chu-a chu-aw chu-aa chu-d chu-dd chu-q '
      'chu-l chu-b chu-h chu-k chu-g chu-y chu-p dau-huyen dau-sac dau-nang '
      'dau-hoi dau-nga',
    );
  });

  test('sections: prefixes and grouping keep ladder order', () {
    expect(sectionOf('net-xien'), WritingSection.strokes);
    expect(sectionOf('so-3'), WritingSection.digits);
    expect(sectionOf('chu-aa'), WritingSection.letters);
    expect(sectionOf('dau-sac'), WritingSection.marks);
    expect(sectionOf('hoa-aa'), WritingSection.capitals);
    expect(WritingSection.capitals.title, 'Chữ hoa');
    final g = groupLadder(writingLadder);
    expect(g.keys.toList(), WritingSection.values);
    expect(g.values.map((l) => l.length), [5, 10, 29, 5, 29]);
    expect(g[WritingSection.capitals]!.first, 'hoa-o');
    expect(g[WritingSection.letters]!.first, 'chu-i');
    expect(g[WritingSection.marks]!.last, 'dau-nga');
    expect(groupLadder(['so-1', 'net-ngang']).keys,
        [WritingSection.strokes, WritingSection.digits]);
    expect(groupLadder(['chu-a']).keys, [WritingSection.letters]);
    expect(WritingSection.values.map((s) => s.title),
        ['Nét cơ bản', 'Chữ số', 'Chữ cái', 'Dấu thanh', 'Chữ hoa']);
  });

  for (final id in writingLadder) {
    group(id, () {
      test('has a glyph file whose id matches', () {
        final file = File('assets/glyphs/$id.json');
        expect(file.existsSync(), isTrue);
        expect(_load(id).id, id);
      });

      test('submitting stroke 2 first is wrongOrder', () {
        final win = _load(id).inWindow();
        if (win.strokes.length < 2) return;
        final result = GlyphSession(win).submit(win.strokes[1]);
        expect(result.ok, isFalse);
        expect(result.error, StrokeError.wrongOrder);
      });

      test('every reversed stroke is rejected', () {
        final glyph = _load(id).inWindow();
        for (var i = 0; i < glyph.strokes.length; i++) {
          final stroke = glyph.strokes[i];
          if (_length(stroke) <= 0.05) continue;
          final reversed = Stroke(stroke.points.reversed.toList());
          final session = GlyphSession(glyph);
          for (var j = 0; j < i; j++) {
            session.submit(glyph.strokes[j]);
          }
          expect(session.submit(reversed).ok, isFalse,
              reason: 'reversed stroke $i of $id still grades ok');
        }
      });
    });
  }
}
