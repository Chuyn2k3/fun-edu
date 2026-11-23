import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no raw AlertDialog, SnackBar or showSnackBar in lib/ outside lib/ui/feedback/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      // Skip files inside lib/ui/feedback/
      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized.startsWith('lib/ui/feedback/')) continue;

      final content = entity.readAsStringSync();
      final badPatterns = ['AlertDialog(', 'SnackBar(', 'showSnackBar('];

      for (final pattern in badPatterns) {
        if (content.contains(pattern)) {
          violations.add('${entity.path}: contains "$pattern"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Raw dialogs/snackbars found:\n${violations.join('\n')}',
    );
  });
}
