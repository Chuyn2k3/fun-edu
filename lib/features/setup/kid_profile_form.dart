import 'package:flutter/material.dart';

import '../../profile/avatars.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/primary_button.dart';

const int maxNicknameLength = 20;
const List<int> kidAges = [3, 4, 5, 6, 7];

/// Nickname rule: trimmed, 1..20 characters.
bool isValidNickname(String raw) {
  final n = raw.trim().length;
  return n >= 1 && n <= maxNicknameLength;
}

/// "Tạo hồ sơ cho bé": nickname, avatar and age. Shared by the first-run
/// flow and the kid switcher's "Thêm bé".
class KidProfileForm extends StatefulWidget {
  const KidProfileForm({super.key, required this.onSubmit});

  /// Called with the trimmed nickname, chosen avatar asset and age. The form
  /// ignores further taps until the returned future completes.
  final Future<void> Function(String nickname, String avatar, int age) onSubmit;

  @override
  State<KidProfileForm> createState() => _KidProfileFormState();
}

class _KidProfileFormState extends State<KidProfileForm> {
  final _controller = TextEditingController();
  String? _avatar;
  int? _age;
  bool _touched = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid =>
      isValidNickname(_controller.text) && _avatar != null && _age != null;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_controller.text.trim(), _avatar!, _age!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError = _touched && !isValidNickname(_controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tạo hồ sơ cho bé',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            labelText: 'Tên gọi ở nhà',
            errorText:
                showError ? 'Nhập tên gọi ở nhà (tối đa 20 ký tự)' : null,
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
          ),
          onChanged: (_) => setState(() => _touched = true),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < kidAvatars.length; i++)
              _AvatarTile(
                index: i,
                path: kidAvatars[i],
                selected: _avatar == kidAvatars[i],
                onTap: () => setState(() => _avatar = kidAvatars[i]),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Bé mấy tuổi?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final age in kidAges)
              _AgeChip(
                label: age == kidAges.last ? '$age+' : '$age',
                selected: _age == age,
                onTap: () => setState(() => _age = age),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Xong',
          onPressed: _valid && !_busy ? _submit : null,
        ),
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.index,
    required this.path,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Ảnh đại diện ${index + 1}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.dot,
              width: selected ? 4 : 2,
            ),
          ),
          child: InkWell(
            key: ValueKey('avatar-$index'),
            borderRadius: BorderRadius.circular(AppRadii.tile),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
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
      label: '$label tuổi',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.card : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
