import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collection/notebook.dart';
import '../../collection/notebook_pdf.dart';
import '../../parent/parent_gate_route.dart';
import '../../profile/kid_repository.dart';
import '../../stroke/glyph.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import '../../worksheet/worksheet_pdf.dart';
import '../../worksheet/worksheet_printer.dart';
import '../writing/ruled_paper.dart';

/// "Vở của bé" tab of Sưu tập: the kid's best writing of every glyph they
/// finished, on ô li paper, in ladder order. Parents can print it.
class NotebookSliver extends ConsumerWidget {
  const NotebookSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final pages = ref.watch(notebookProvider).valueOrNull;
    final pad = EdgeInsets.fromLTRB(tablet ? 8 : 16, 4, tablet ? 28 : 16, 8);

    if (pages == null) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200));
    }
    if (pages.isEmpty) {
      return SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: Container(
            key: const ValueKey('notebook-empty'),
            padding: const EdgeInsets.all(20),
            decoration: raisedDecoration(),
            child: Row(
              children: [
                Image.asset(AppImages.chipWrite, width: tablet ? 110 : 84),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Vở của bé còn trống. Bé viết xong chữ nào, chữ đẹp nhất '
                    'sẽ được dán vào đây!',
                    style: TextStyle(
                      fontSize: tablet ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final columns = switch (ff) {
      FormFactor.phone => 3,
      FormFactor.tabletPortrait => 4,
      FormFactor.tabletLandscape => 6,
    };
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${pages.length} trang vở',
                    style: TextStyle(
                      fontSize: tablet ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                _PrintButton(pages: pages),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: pad,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: tablet ? 16 : 12,
              crossAxisSpacing: tablet ? 16 : 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PageTile(page: pages[i]),
              childCount: pages.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// One notebook page: the kid's strokes on the glyph's ô li paper.
class NotebookPageView extends StatelessWidget {
  const NotebookPageView({super.key, required this.page});

  final NotebookPage page;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.tile - 6),
        child: ColoredBox(
          color: AppColors.card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RuledPaper(ruling: page.glyph?.ruling),
              CustomPaint(painter: NotebookInkPainter(page.strokes)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The kid's strokes, in the pad's [0,1] square, in the app's crayon orange.
class NotebookInkPainter extends CustomPainter {
  NotebookInkPainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = side * 0.05;
    for (final s in strokes) {
      final pts = s.points;
      if (pts.isEmpty) continue;
      if (pts.length == 1) {
        canvas.drawCircle(Offset(pts.first.x * side, pts.first.y * side),
            side * 0.035, Paint()..color = AppColors.accent);
        continue;
      }
      final path = Path()..moveTo(pts.first.x * side, pts.first.y * side);
      for (final p in pts.skip(1)) {
        path.lineTo(p.x * side, p.y * side);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(NotebookInkPainter oldDelegate) =>
      !identical(oldDelegate.strokes, strokes);
}

class _PageTile extends ConsumerWidget {
  const _PageTile({required this.page});

  final NotebookPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablet = context.isTablet;
    final label = page.glyph?.label ?? '';
    return Pressable(
      key: ValueKey('notebook-${page.glyph?.id}'),
      semanticsLabel: '$label bé viết',
      onTap: () {
        ref
            .read(speakerProvider)
            .speak('${page.glyph?.spokenName ?? label} bé viết đẹp quá!');
        showDialog<void>(
          context: context,
          builder: (_) => _PageDialog(page: page),
        );
      },
      builder: (pressed) => Container(
        padding: const EdgeInsets.all(6),
        decoration: raisedDecoration(pressed: pressed, radius: AppRadii.tile),
        child: Column(
          children: [
            NotebookPageView(page: page),
            const SizedBox(height: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 18 : 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDialog extends StatelessWidget {
  const _PageDialog({required this.page});

  final NotebookPage page;

  @override
  Widget build(BuildContext context) {
    final d = page.writtenAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                page.glyph?.label ?? '',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text),
              ),
              const SizedBox(height: 10),
              NotebookPageView(page: page),
              const SizedBox(height: 10),
              Text(
                page.mistakes == 0
                    ? 'Viết đúng hết các nét! · $date'
                    : 'Viết ngày $date',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 64)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "In vở" behind the parent gate: it opens the system share sheet.
class _PrintButton extends ConsumerStatefulWidget {
  const _PrintButton({required this.pages});

  final List<NotebookPage> pages;

  @override
  ConsumerState<_PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends ConsumerState<_PrintButton> {
  bool _busy = false;

  Future<void> _print() async {
    if (_busy) return;
    if (!await showParentGate(context) || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(kidRepositoryProvider);
      final id = await repo.currentKidId();
      final kid = (await repo.kids()).where((k) => k.id == id).firstOrNull;
      final bytes = await buildNotebookPdf(
        pages: widget.pages,
        kidName: kid?.nickname ?? 'Bé',
        fonts: await WorksheetPdfFonts.loadFromAssets(),
      );
      await ref
          .read(worksheetPrinterProvider)
          .sharePdf(bytes, fileName: 'vo-cua-be.pdf');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const ValueKey('notebook-print'),
      style: TextButton.styleFrom(minimumSize: const Size(64, 64)),
      onPressed: _busy ? null : _print,
      icon: const Icon(Icons.print_rounded, color: AppColors.primaryOnTint),
      label: const Text(
        'In vở',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryOnTint),
      ),
    );
  }
}
