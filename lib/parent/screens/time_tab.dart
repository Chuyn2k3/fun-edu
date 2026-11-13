import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/kid_repository.dart';
import '../../screen_time/screen_time_service.dart';
import '../../ui/theme/tokens.dart';
import 'parent_card.dart';

const String _defaultBedtimeStart = '20:30';
const String _defaultBedtimeEnd = '06:30';

/// "Thời gian" tab: daily limit and bedtime of one kid.
class TimeTab extends ConsumerStatefulWidget {
  const TimeTab({super.key, required this.kidId});

  final int kidId;

  @override
  ConsumerState<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends ConsumerState<TimeTab> {
  bool _loaded = false;
  int _limit = defaultDailyLimitMinutes;
  int _usedMinutes = 0;
  String? _start;
  String? _end;

  KidRepository get _repo => ref.read(kidRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(screenTimeServiceProvider);
    final limit = await service.dailyLimitMinutes(widget.kidId);
    final used = (await service.usedToday(widget.kidId)).inMinutes;
    final start = await _repo.setting(bedtimeStartKey(widget.kidId));
    final end = await _repo.setting(bedtimeEndKey(widget.kidId));
    if (!mounted) return;
    setState(() {
      _limit = limit;
      _usedMinutes = used;
      _start = start;
      _end = end;
      _loaded = true;
    });
  }

  /// Limits and bedtime feed the screen-time guard; make it re-read.
  void _changed() => ref.invalidate(screenTimeStatusProvider);

  Future<void> _setLimit(int minutes) async {
    if (minutes == _limit) return;
    setState(() => _limit = minutes);
    await _repo.setSetting(dailyLimitKey(widget.kidId), '$minutes');
    _changed();
  }

  bool get _bedtimeOn => _start != null && _end != null;

  Future<void> _setBedtimeOn(bool on) async {
    final id = widget.kidId;
    if (on) {
      setState(() {
        _start = _defaultBedtimeStart;
        _end = _defaultBedtimeEnd;
      });
      await _repo.setSetting(bedtimeStartKey(id), _defaultBedtimeStart);
      await _repo.setSetting(bedtimeEndKey(id), _defaultBedtimeEnd);
    } else {
      setState(() {
        _start = null;
        _end = null;
      });
      await _repo.removeSetting(bedtimeStartKey(id));
      await _repo.removeSetting(bedtimeEndKey(id));
    }
    _changed();
  }

  Future<void> _pick({required bool start}) async {
    final current = (start ? _start : _end) ?? '00:00';
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
      helpText: start ? 'Giờ bắt đầu ngủ' : 'Giờ kết thúc ngủ',
      confirmText: 'Xong',
      cancelText: 'Hủy',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = text : _end = text);
    await _repo.setSetting(
      start ? bedtimeStartKey(widget.kidId) : bedtimeEndKey(widget.kidId),
      text,
    );
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentCard(
            title: 'Giới hạn mỗi ngày',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_limit phút',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Slider(
                  min: minDailyLimitMinutes.toDouble(),
                  max: maxDailyLimitMinutes.toDouble(),
                  divisions:
                      (maxDailyLimitMinutes - minDailyLimitMinutes) ~/ 15,
                  value: _limit.toDouble(),
                  activeColor: AppColors.primary,
                  onChanged: (v) => _setLimit(v.round()),
                ),
                Text(
                  'Hôm nay đã dùng $_usedMinutes phút',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Giờ đi ngủ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Switch(
                      value: _bedtimeOn,
                      activeColor: AppColors.primary,
                      onChanged: _setBedtimeOn,
                    ),
                  ],
                ),
                if (_bedtimeOn) ...[
                  const SizedBox(height: 8),
                  _TimeRow(
                    label: 'Bắt đầu',
                    value: _start!,
                    onTap: () => _pick(start: true),
                  ),
                  const SizedBox(height: 8),
                  _TimeRow(
                    label: 'Kết thúc',
                    value: _end!,
                    onTap: () => _pick(start: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(96, 48),
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.dot, width: 2),
          ),
          onPressed: onTap,
          child: Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
