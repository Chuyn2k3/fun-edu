// Writes website/src/content/privacy-app.json from the app's privacy text,
// so the website shows exactly the same policy. Run with UPDATE_FIXTURES=1
// to rewrite after the policy changes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/parent/screens/privacy_screen.dart';

const _path = 'website/src/content/privacy-app.json';

void main() {
  test('website privacy text matches the app', () {
    final data = [
      for (final (title, lines) in privacySections)
        {'title': title, 'lines': lines},
    ];
    final text = '${const JsonEncoder.withIndent('  ').convert(data)}\n';
    expect(text, contains('phamdoan060801@gmail.com'));
    final file = File(_path);
    if (Platform.environment['UPDATE_FIXTURES'] == '1') {
      file.writeAsStringSync(text);
    }
    expect(file.existsSync(), isTrue, reason: 'run with UPDATE_FIXTURES=1');
    expect(file.readAsStringSync(), text,
        reason: 'privacy policy changed: rerun with UPDATE_FIXTURES=1');
  });
}
