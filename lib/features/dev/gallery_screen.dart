import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/info_pill.dart';
import '../../ui/widgets/primary_button.dart';
import '../../ui/widgets/progress_ring.dart';

/// Dev-only page showing every shared widget on the cream dotted background.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _tab = 0;

  static const _items = [
    NavItem(icon: Icons.edit, label: 'Học'),
    NavItem(icon: Icons.extension, label: 'Chơi'),
    NavItem(icon: Icons.collections_bookmark, label: 'Sưu tập'),
    NavItem(icon: Icons.home, label: 'Nhà Chíp'),
  ];

  static const _labels = {
    Subject.viet: 'Viết',
    Subject.tiengViet: 'Tiếng Việt',
    Subject.toan: 'Toán',
    Subject.tiengAnh: 'Tiếng Anh',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const Text(
                      'Bộ giao diện',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoPill(
                          leading: Icon(Icons.local_fire_department,
                              color: AppColors.accent, size: 20),
                          label: '5 ngày',
                        ),
                        InfoPill(
                          leading: Icon(Icons.star, color: AppColors.accent, size: 20),
                          label: '120 sao',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hôm nay học gì?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cùng Chíp Chíp tập viết nhé',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(label: 'Bắt đầu', onPressed: () {}),
                          const SizedBox(height: 12),
                          const PrimaryButton(label: 'Chưa mở', onPressed: null),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        children: [
                          for (final s in Subject.values)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: s.tint,
                                  borderRadius: BorderRadius.circular(AppRadii.tile),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _labels[s]!,
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    ProgressRing(
                                      done: 6,
                                      total: 14,
                                      color: s.color,
                                      size: 48,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FloatingNavBar(
                  items: _items,
                  selected: _tab,
                  onSelect: (i) => setState(() => _tab = i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
