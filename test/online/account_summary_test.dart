import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/online/link/account_summary.dart';

void main() {
  test('matches the shared fixture', () {
    final file = File('test/fixtures/summary_records.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final recordsList = json['records'] as List<dynamic>;
    final expectedList = (json['expected'] as List<dynamic>)
        .map((e) => KidSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    final recordsMap = <String, Map<String, Object?>?>{};
    for (final r in recordsList) {
      final key = r['key'] as String;
      final deleted = r['deleted'] as bool? ?? false;
      final payload = deleted ? null : (r['payload'] as Map<String, dynamic>?);
      recordsMap[key] = payload;
    }

    final summary = summarizeRecords(recordsMap);
    expect(summary, equals(expectedList));
  });
}
