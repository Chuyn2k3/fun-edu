import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../online/auth/session_controller.dart';
import '../../online/net/network_status.dart';
import '../../online/online_config.dart';
import '../../online/room/room_controller.dart';
import '../../profile/kid_repository.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../parent/screens/parent_card.dart';
import 'room_widgets.dart';

/// `/game/room?mode=create|join`, opened after the parent gate: a parent
/// opens a room or types a friend's code, and can set the race nickname.
class RoomEntryScreen extends ConsumerStatefulWidget {
  const RoomEntryScreen({super.key, this.join = false});

  /// True: "Nhập mã". False: "Mời bạn đua" (create a room).
  final bool join;

  @override
  ConsumerState<RoomEntryScreen> createState() => _RoomEntryScreenState();
}

class _RoomEntryScreenState extends ConsumerState<RoomEntryScreen> {
  final _code = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _error;
  int? _kidId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNick);
  }

  Future<void> _loadNick() async {
    final repo = ref.read(kidRepositoryProvider);
    final id = await repo.currentKidId();
    if (id == null || !mounted) return;
    final kid = (await repo.kids()).where((k) => k.id == id).firstOrNull;
    final saved = await repo.setting(raceNicknameKey(id));
    if (!mounted) return;
    setState(() {
      _kidId = id;
      _nick.text = saved ?? kid?.nickname ?? '';
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (ref.read(networkStatusProvider) == NetState.offline) {
      setState(() => _error = 'Cần có mạng để đua với bạn nhé');
      return;
    }
    final code = _code.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (widget.join && code.length != 6) {
      setState(() => _error = 'Mã phòng có 6 ký tự');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(kidRepositoryProvider);
    final nick = _nick.text.trim();
    if (_kidId != null && nick.isNotEmpty) {
      await repo.setSetting(raceNicknameKey(_kidId!), nick);
    }
    final kid = await currentRoomKid(ref);
    if (kid == null) {
      setState(() {
        _busy = false;
        _error = 'Chưa có hồ sơ bé';
      });
      return;
    }
    final room = ref.read(roomControllerProvider.notifier);
    if (widget.join) {
      await room.join(code, kid);
    } else {
      await room.create(kid);
    }
    if (!mounted) return;
    final s = ref.read(roomControllerProvider);
    if (s.phase == RoomPhase.error) {
      setState(() {
        _busy = false;
        _error = roomErrorText(s.error);
      });
    } else if (s.phase != RoomPhase.connecting) {
      context.go('/game/room/lobby');
    }
    // Still connecting: the listener in build moves on (lobby or error).
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineConfigProvider).enabled;
    final signedIn = ref.watch(sessionProvider).valueOrNull != null;
    // Errors from the room arrive after the first answer (e.g. not_found).
    ref.listen(roomControllerProvider, (_, s) {
      if (_busy && s.phase != RoomPhase.connecting && s.phase != RoomPhase.error &&
          s.phase != RoomPhase.idle && mounted) {
        _busy = false;
        context.go('/game/room/lobby');
      }
      if (_busy && s.phase == RoomPhase.error && mounted) {
        setState(() {
          _busy = false;
          _error = roomErrorText(s.error);
        });
      }
    });

    Widget body;
    if (!online) {
      body = const ParentCard(
        child: Text('Sắp có', style: _body),
      );
    } else if (!signedIn) {
      body = ParentCard(
        title: 'Cần Tài khoản gia đình',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Để đua với bạn qua mạng, ba mẹ đăng nhập Tài khoản gia đình '
              'trong Góc ba mẹ → Cài đặt trước nhé.',
              style: _body,
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('open-parent'),
              style: _button,
              onPressed: () => context.push('/parent'),
              child: const Text('Mở Góc ba mẹ'),
            ),
          ],
        ),
      );
    } else {
      body = ParentCard(
        title: widget.join ? 'Nhập mã phòng' : 'Mời bạn đua',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.join
                  ? 'Nhập mã 6 ký tự mà ba mẹ của bạn gửi cho mình.'
                  : 'Tạo phòng rồi gửi mã cho ba mẹ của bạn (qua Zalo, tin nhắn). '
                      'Phòng có tối đa 4 bạn, trong 30 phút.',
              style: _body,
            ),
            const SizedBox(height: 14),
            if (widget.join) ...[
              TextField(
                key: const ValueKey('room-code'),
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                ],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: AppColors.text,
                ),
                decoration: const InputDecoration(labelText: 'Mã phòng'),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              key: const ValueKey('race-nickname'),
              controller: _nick,
              maxLength: raceNicknameMax,
              decoration: const InputDecoration(
                labelText: 'Biệt danh của bé khi đua',
                helperText: 'Các bạn trong phòng sẽ thấy tên này',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, key: const ValueKey('room-error'), style: _error_),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('room-go'),
              style: _button,
              onPressed: _busy ? null : _go,
              child: Text(_busy
                  ? 'Đang kết nối…'
                  : widget.join
                      ? 'Vào phòng'
                      : 'Tạo phòng'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đua với bạn')),
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [body],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const _error_ = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryOnTint,
  );
  static final _button = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    minimumSize: const Size.fromHeight(52),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
  );
}
