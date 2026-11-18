import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/writing_ladder.dart';
import '../../learning/writing_sections.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../worksheet/worksheet_model.dart';
import '../../worksheet/worksheet_pdf.dart';
import '../../worksheet/worksheet_preview.dart';
import '../../worksheet/worksheet_printer.dart';

/// Parent-corner screen for building, previewing, printing, and sharing
/// offline A4 Vietnamese ô li writing worksheets.
class WorksheetScreen extends ConsumerStatefulWidget {
  const WorksheetScreen({
    super.key,
    required this.kidName,
    required this.stats,
    this.now,
  });

  final String kidName;
  final Map<String, GlyphStat> stats;
  final DateTime? now;

  @override
  ConsumerState<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends ConsumerState<WorksheetScreen> {
  WorksheetSelectionMode _mode = WorksheetSelectionMode.weak;
  WritingSection _section = WritingSection.letters;
  WorksheetStyle _style = WorksheetStyle.guided;
  late final Set<String> _customIds = weakGlyphIds(widget.stats).toSet();
  late final Set<String> _mistakeIds = mistakeGlyphIds(widget.stats);
  int _page = 0;
  bool _busy = false;
  WorksheetPdfFonts? _cachedFonts;

  DateTime get _date => widget.now ?? DateTime.now();

  List<String> get _selectedIds => switch (_mode) {
        WorksheetSelectionMode.weak => weakGlyphIds(widget.stats),
        WorksheetSelectionMode.section => [
            for (final id in writingLadder)
              if (sectionOf(id) == _section) id,
          ],
        WorksheetSelectionMode.custom => [
            for (final id in writingLadder)
              if (_customIds.contains(id)) id,
          ],
      };

  WorksheetConfig get _config => WorksheetConfig(
        kidName: widget.kidName,
        glyphIds: _selectedIds,
        style: _style,
        date: _date,
      );

  int _pageCountFor(Map<String, Glyph> glyphs) {
    final count = _selectedIds.where(glyphs.containsKey).length;
    if (count == 0) return 1;
    return (count / WorksheetConfig.rowsPerPage).ceil();
  }

  void _setPage(int p, int pageCount) {
    setState(() => _page = p.clamp(0, pageCount - 1));
  }

  void _toggleCustom(String id) {
    setState(() {
      if (_customIds.contains(id)) {
        _customIds.remove(id);
      } else if (_customIds.length < WorksheetConfig.maxSelectableGlyphs) {
        _customIds.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tối đa ${WorksheetConfig.maxSelectableGlyphs} mục mỗi lần in '
              '(5 trang A4).',
            ),
          ),
        );
      }
      _page = 0;
    });
  }

  Future<void> _export(
    Map<String, Glyph> glyphs, {
    required bool share,
  }) async {
    if (_busy || _selectedIds.isEmpty) return;
    setState(() => _busy = true);
    try {
      final fonts = _cachedFonts ??= await WorksheetPdfFonts.loadFromAssets();
      final bytes = await buildWorksheetPdf(
        config: _config,
        glyphs: glyphs,
        fonts: fonts,
      );
      final printer = ref.read(worksheetPrinterProvider);
      final fileName = worksheetFileName(widget.kidName, _date);
      if (share) {
        await printer.sharePdf(bytes, fileName: fileName);
      } else {
        await printer.printPdf(
          bytes,
          jobName: 'Phiếu tập tô — ${_config.displayKidName}',
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tạo được file PDF lúc này, ba mẹ thử lại nhé.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openFullPreview(Map<String, Glyph> glyphs, int safePage) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Xem trước trang A4',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: WorksheetPreview(
                    config: _config,
                    glyphs: glyphs,
                    pageIndex: safePage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glyphList = ref.watch(glyphListProvider);
    final list = glyphList.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('In phiếu tập tô (PDF)'),
      ),
      body: DottedBackground(
        child: list == null
            ? Center(
                child: glyphList.hasError
                    ? const Text('Không tải được bộ nét chữ')
                    : const CircularProgressIndicator(),
              )
            : _buildLoaded(context, {for (final g in list) g.id: g}),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Map<String, Glyph> glyphs) {
    final pageCount = _pageCountFor(glyphs);
    final safePage = _page.clamp(0, pageCount - 1);
    final canExport = _selectedIds.isNotEmpty && !_busy;

    if (context.isTablet) {
      return SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 390,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                      child: _controls(glyphs),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
                    child: _actionButtons(glyphs, canExport),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 24, 16),
                child: Column(
                  children: [
                    _previewBar(glyphs, safePage, pageCount),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Center(
                        child: WorksheetPreview(
                          config: _config,
                          glyphs: glyphs,
                          pageIndex: safePage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        decoration: raisedDecoration(),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _previewBar(glyphs, safePage, pageCount),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: WorksheetPreview(
                                    config: _config,
                                    glyphs: glyphs,
                                    pageIndex: safePage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _controls(glyphs),
                    ],
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _actionButtons(glyphs, canExport),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBar(
    Map<String, Glyph> glyphs,
    int safePage,
    int pageCount,
  ) {
    final total = _selectedIds.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Xem trước · $total mục ($pageCount trang A4)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (pageCount > 1) ...[
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed:
                safePage > 0 ? () => _setPage(safePage - 1, pageCount) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Trang trước',
          ),
          Text(
            '${safePage + 1}/$pageCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: safePage < pageCount - 1
                ? () => _setPage(safePage + 1, pageCount)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Trang sau',
          ),
        ],
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => _openFullPreview(glyphs, safePage),
          icon: const Icon(Icons.zoom_in_rounded),
          tooltip: 'Phóng to xem trước',
        ),
      ],
    );
  }

  Widget _controls(Map<String, Glyph> glyphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: '1. Chọn chữ cần luyện',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in WorksheetSelectionMode.values)
                    _ModeChip(
                      label: m.label,
                      selected: _mode == m,
                      onTap: () => setState(() {
                        _mode = m;
                        _page = 0;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_mode == WorksheetSelectionMode.weak)
                Text(
                  _mistakeIds.isEmpty
                      ? 'Gợi ý 6 mục tiếp theo phù hợp với ${_config.displayKidName}.'
                      : 'Tự động ưu tiên các chữ ${_config.displayKidName} hay viết nhầm nhất.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              if (_mode == WorksheetSelectionMode.section)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in WritingSection.values)
                      _ModeChip(
                        label: s.title,
                        selected: _section == s,
                        onTap: () => setState(() {
                          _section = s;
                          _page = 0;
                        }),
                      ),
                  ],
                ),
              if (_mode == WorksheetSelectionMode.custom)
                _customPicker(glyphs),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '2. Mức gợi ý trên phiếu',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in WorksheetStyle.values) ...[
                _StyleTile(
                  style: s,
                  selected: _style == s,
                  onTap: () => setState(() => _style = s),
                ),
                if (s != WorksheetStyle.values.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _customPicker(Map<String, Glyph> glyphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Đã chọn ${_customIds.length}/${WorksheetConfig.maxSelectableGlyphs} mục',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => setState(() {
                _customIds
                  ..clear()
                  ..addAll(weakGlyphIds(widget.stats));
                _page = 0;
              }),
              child: const Text(
                'Chọn chữ yếu',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.textMuted,
              ),
              onPressed: _customIds.isEmpty
                  ? null
                  : () => setState(() {
                        _customIds.clear();
                        _page = 0;
                      }),
              child: const Text(
                'Bỏ hết',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final entry in groupLadder(writingLadder).entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              entry.key.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in entry.value)
                _GlyphPickChip(
                  label: glyphs[id]?.label ?? id,
                  selected: _customIds.contains(id),
                  hasMistake: _mistakeIds.contains(id),
                  onTap: () => _toggleCustom(id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _actionButtons(Map<String, Glyph> glyphs, bool canExport) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 52),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.tile),
              ),
            ),
            onPressed: canExport ? () => _export(glyphs, share: true) : null,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text(
              'Chia sẻ PDF',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.tile),
              ),
            ),
            onPressed: canExport ? () => _export(glyphs, share: false) : null,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.card,
                    ),
                  )
                : const Icon(Icons.print_rounded),
            label: Text(
              _busy ? 'Đang tạo...' : 'In phiếu',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: raisedDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.dot,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.card : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final WorksheetStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Subject.viet.tint : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.dot,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        style.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlyphPickChip extends StatelessWidget {
  const _GlyphPickChip({
    required this.label,
    required this.selected,
    required this.hasMistake,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool hasMistake;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.tile),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dot,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.card : AppColors.text,
                ),
              ),
              if (hasMistake) ...[
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.card : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
