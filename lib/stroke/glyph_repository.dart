import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'glyph.dart';

const String _glyphDir = 'assets/glyphs/';

/// Reads bundled glyph definitions from `assets/glyphs/*.json`.
class GlyphRepository {
  GlyphRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Ids (file names without extension) of all bundled glyphs, sorted.
  Future<List<String>> listIds() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final ids = [
      for (final path in manifest.listAssets())
        if (path.startsWith(_glyphDir) && path.endsWith('.json'))
          path.substring(_glyphDir.length, path.length - '.json'.length),
    ]..sort();
    return ids;
  }

  Future<Glyph> load(String id) async {
    final text = await _bundle.loadString('$_glyphDir$id.json');
    return Glyph.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}

final glyphRepositoryProvider = Provider<GlyphRepository>(
  (ref) => GlyphRepository(),
);

final glyphProvider = FutureProvider.family<Glyph, String>(
  (ref, id) => ref.watch(glyphRepositoryProvider).load(id),
);

final glyphListProvider = FutureProvider<List<Glyph>>((ref) async {
  final repo = ref.watch(glyphRepositoryProvider);
  final ids = await repo.listIds();
  return [for (final id in ids) await repo.load(id)];
});
