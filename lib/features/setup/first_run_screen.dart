import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../parent/parent_gate_route.dart';
import '../../parent/screens/privacy_screen.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/primary_button.dart';
import 'kid_profile_form.dart';

const String consentAtKey = 'consentAt';

enum _Step { gate, consent, profile }

/// First launch: parent gate, consent, then the first kid's profile.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  _Step _step = _Step.gate;
  bool _agreed = false;
  bool _opening = false;

  Future<void> _openGate() async {
    if (_opening) return;
    _opening = true;
    try {
      final passed = await showParentGate(context);
      if (passed && mounted) setState(() => _step = _Step.consent);
    } finally {
      _opening = false;
    }
  }

  Future<void> _create(String nickname, String avatar, int age) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final repo = ref.read(kidRepositoryProvider);
      await repo.setSetting(consentAtKey, DateTime.now().toIso8601String());
      final id = await repo.addKid(
        nickname: nickname,
        avatar: avatar,
        age: age,
      );
      await repo.setCurrentKid(id);
      if (!mounted) return;
      refreshAfterKidChange(ref);
      router.go('/placement');
    } catch (e, st) {
      debugPrint('create first kid failed: $e\n$st');
      messenger.showSnackBar(
        const SnackBar(content: Text('Không lưu được hồ sơ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_step) {
      _Step.gate => _GateStep(onOpen: _openGate),
      _Step.consent => _ConsentStep(
          agreed: _agreed,
          onAgreed: (v) => setState(() => _agreed = v),
          onContinue: () => setState(() => _step = _Step.profile),
        ),
      _Step.profile => KidProfileForm(onSubmit: _create),
    };
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GateStep extends StatelessWidget {
  const _GateStep({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Image.asset(AppImages.chipMain, height: 140),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dành cho ba mẹ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ba mẹ làm giúp bé bước đầu tiên nhé.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Tôi là ba mẹ', onPressed: onOpen),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    required this.agreed,
    required this.onAgreed,
    required this.onContinue,
  });

  final bool agreed;
  final ValueChanged<bool> onAgreed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chào ba mẹ!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chíp Chíp chỉ lưu tên gọi ở nhà, ảnh đại diện có sẵn và tuổi của bé, '
          'ngay trên máy này. Không quảng cáo, không gửi dữ liệu của bé ra '
          'ngoài. Ba mẹ có thể xóa toàn bộ dữ liệu bất cứ lúc nào trong Góc '
          'ba mẹ.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
            child: const Text(
              'Xem chính sách quyền riêng tư',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          value: agreed,
          onChanged: (v) => onAgreed(v ?? false),
          title: const Text(
            'Tôi đồng ý',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Tiếp tục',
          onPressed: agreed ? onContinue : null,
        ),
      ],
    );
  }
}
