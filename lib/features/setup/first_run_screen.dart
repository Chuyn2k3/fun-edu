import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../online/auth/session_controller.dart';
import '../../online/link/link_controller.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_engine.dart';
import '../../parent/parent_gate_route.dart';
import '../../parent/screens/privacy_screen.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/message_card.dart';
import '../../ui/widgets/primary_button.dart';
import '../online/online_consent_dialog.dart';
import 'choose_mode_step.dart';
import 'kid_profile_form.dart';

enum _Step { gate, consent, chooseMode, profile }

/// First launch: parent gate, consent, optional sign-in / guest choose,
/// then the first kid's profile.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  _Step _step = _Step.gate;
  bool _agreed = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider).valueOrNull;
    if (session?.linked == true) {
      _step = _Step.profile;
    } else {
      ref.read(kidRepositoryProvider).setting(consentAtKey).then((val) {
        if (mounted && val != null && _step == _Step.gate) {
          final onlineEnabled = ref.read(onlineConfigProvider).enabled;
          setState(() {
            _step = onlineEnabled ? _Step.chooseMode : _Step.profile;
          });
        }
      });
    }
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

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

  Future<void> _signIn(String provider) async {
    final agreed = await showOnlineConsentDialog(context);
    if (!agreed || !mounted) return;
    try {
      final res = await ref.read(sessionProvider.notifier).signIn(provider);
      if (!mounted) return;
      await ref.read(linkControllerProvider.notifier).afterSignIn(res);
      if (!mounted) return;
      final kids = await ref.read(kidRepositoryProvider).kids();
      if (kids.isEmpty &&
          ref.read(sessionProvider).valueOrNull != null &&
          ref.read(linkControllerProvider) is! LinkRestoring) {
        setState(() => _step = _Step.profile);
      }
    } on SignInException catch (e) {
      if (!mounted) return;
      final why = kDebugMode && e.detail != null ? '\n(${e.detail})' : '';
      switch (e.failure) {
        case SignInFailure.cancelled:
          break;
        case SignInFailure.setup:
          _say('Chưa đăng nhập được với Google/Apple trên máy này, ba mẹ thử lại sau nhé$why');
        case SignInFailure.network:
          _say('Không kết nối được máy chủ, ba mẹ thử lại sau nhé$why');
        case SignInFailure.rejected:
          _say('Đăng nhập không thành công, ba mẹ thử lại nhé$why');
      }
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
      if (ref.read(sessionProvider).valueOrNull?.linked == true) {
        ref.read(syncControllerProvider.notifier).syncNow();
      }
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
    ref.listen(sessionProvider, (_, next) {
      if (_step == _Step.gate && next.valueOrNull?.linked == true) {
        setState(() => _step = _Step.profile);
      }
    });
    final onlineEnabled = ref.watch(onlineConfigProvider).enabled;
    final body = switch (_step) {
      _Step.gate => _GateStep(onOpen: _openGate),
      _Step.consent => _ConsentStep(
          agreed: _agreed,
          onAgreed: (v) => setState(() => _agreed = v),
          onContinue: () async {
            await ref.read(kidRepositoryProvider).setSetting(
                  consentAtKey,
                  DateTime.now().toIso8601String(),
                );
            ref.invalidate(consentAtProvider);
            if (mounted) {
              setState(() =>
                  _step = onlineEnabled ? _Step.chooseMode : _Step.profile);
            }
          },
        ),
      _Step.chooseMode => ChooseModeStep(
          onGuest: () => setState(() => _step = _Step.profile),
          onSignIn: _signIn,
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
                constraints: BoxConstraints(
                  maxWidth:
                      context.isTablet ? TabletSizes.messageMaxWidth : 560,
                ),
                child: MessageCard(child: body),
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
          child: Image.asset(
            AppImages.chipMain,
            height: context.isTablet ? 140 * tabletChipScale : 140,
          ),
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
          'Chíp Chíp chỉ lưu tên gọi ở nhà, ảnh đại diện và tuổi của bé. '
          'Dùng thử chỉ lưu trên máy; đăng nhập thì lưu lên máy chủ FunEdu. '
          'Không quảng cáo. Ba mẹ có thể xóa dữ liệu bất cứ lúc nào.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              foregroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
            child: const Text(
              'Xem chính sách quyền riêng tư',
              style: TextStyle(
                fontSize: 15,
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Tiếp tục',
          onPressed: agreed ? onContinue : null,
        ),
      ],
    );
  }
}
