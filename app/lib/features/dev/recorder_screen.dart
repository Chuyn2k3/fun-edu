import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../trace/trace_pad.dart';
import 'recorder_controller.dart';

/// Debug-only tool for recording reference strokes of a glyph.
class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  final _id = TextEditingController();
  final _label = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final json = ref
        .read(recorderProvider.notifier)
        .exportJson(_id.text.trim(), _label.text.trim());
    debugPrint(json);
    await Clipboard.setData(ClipboardData(text: json));
  }

  @override
  Widget build(BuildContext context) {
    final strokes = ref.watch(recorderProvider);
    final controller = ref.read(recorderProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi nét mẫu')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _id,
                      decoration: const InputDecoration(labelText: 'id'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _label,
                      decoration: const InputDecoration(labelText: 'label'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TracePad(
                  inked: strokes,
                  onStrokeEnd: controller.addStroke,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: controller.undo,
                    child: const Text('Hoàn tác'),
                  ),
                  OutlinedButton(
                    onPressed: controller.clear,
                    child: const Text('Xóa'),
                  ),
                  FilledButton(onPressed: _export, child: const Text('Xuất')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
