import 'dart:convert';
import 'package:funedu/online/api_client.dart';

/// In-memory copy of the server's /api/v1/sync rules (see
/// server/src/main/java/.../sync/SyncService.java): versions, stale-base
/// conflicts, tombstones and paging.
class FakeSyncServer {
  FakeSyncServer({
    this.page = 1000,
    this.dropResponseAfterSave = false,
    this.delay,
    this.failWith500 = false,
    this.failOnPage,
  });

  final int page;
  bool dropResponseAfterSave;
  Duration? delay;
  bool failWith500;
  int? failOnPage;

  int _seq = 0;
  final Map<String, ({Map<String, Object?>? payload, int version})> records = {};
  int calls = 0;

  Future<Map<String, Object?>?> handle(Map<String, Object?> body) async {
    calls++;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (failWith500) {
      throw const ApiException(500, 'server_error');
    }
    if (failOnPage != null && calls == failOnPage) {
      throw const ApiException(0, 'timeout');
    }

    // Round-trip through JSON like the real HTTP call.
    body = jsonDecode(jsonEncode(body)) as Map<String, Object?>;
    final since = (body['since'] as num).toInt();
    final conflicts = <String>[];
    for (final c in (body['changes'] as List).cast<Map<String, Object?>>()) {
      final key = c['key'] as String;
      final base = (c['baseVersion'] as num?)?.toInt();
      final current = records[key];
      final fresh = current == null ? base == null : current.version == base;
      if (!fresh) {
        conflicts.add(key);
        continue;
      }
      records[key] = (
        payload: c['deleted'] == true ? null : (c['payload'] as Map).cast<String, Object?>(),
        version: ++_seq,
      );
    }
    final newer = records.entries.where((e) => e.value.version > since).toList()
      ..sort((a, b) => a.value.version - b.value.version);
    final hasMore = newer.length > page;
    final out = newer.take(page).toList();
    final version = out.isEmpty ? since : out.last.value.version;
    final keys = out.map((e) => e.key).toSet();
    for (final k in conflicts) {
      if (!keys.contains(k)) out.add(MapEntry(k, records[k]!));
    }

    if (dropResponseAfterSave) {
      throw const ApiException(0, 'timeout');
    }

    return jsonDecode(jsonEncode({
      'version': version,
      'hasMore': hasMore,
      'conflicts': conflicts,
      'records': [
        for (final e in out)
          {
            'key': e.key,
            'payload': e.value.payload,
            'deleted': e.value.payload == null,
            'version': e.value.version,
          },
      ],
    })) as Map<String, Object?>;
  }
}
