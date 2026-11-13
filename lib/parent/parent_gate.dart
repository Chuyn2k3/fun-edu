import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/theme/tokens.dart';
import '../ui/widgets/app_card.dart';
import '../ui/widgets/dotted_background.dart';
import '../ui/widgets/primary_button.dart';
import '../voice/voice_lines.dart';

/// Adult-only gate: a multiplication question written in words, answered on a
/// number keypad. The question is intentionally never spoken aloud.
class ParentGate extends StatefulWidget {
  const ParentGate({
    super.key,
    required this.onPassed,
    this.onCancel,
    this.random,
  });

  final VoidCallback onPassed;
  final VoidCallback? onCancel;
  final Random? random;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  static const _maxDigits = 3;

  late final Random _random = widget.random ?? Random();
  late int _a;
  late int _b;
  String _input = '';
  bool _wrong = false;

  /// One-shot latch: set once the answer is correct so a double tap during
  /// the route exit cannot fire [ParentGate.onPassed] twice.
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  /// Draws a new pair in 3..9, different from the current one when possible.
  void _newQuestion({bool differ = false}) {
    final oldA = differ ? _a : -1;
    final oldB = differ ? _b : -1;
    do {
      _a = 3 + _random.nextInt(7);
      _b = 3 + _random.nextInt(7);
    } while (_a == oldA && _b == oldB);
  }

  void _addDigit(String d) {
    if (_passed) return;
    if (_input.length >= _maxDigits) return;
    setState(() {
      _input += d;
      _wrong = false;
    });
  }

  void _delete() {
    if (_passed) return;
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _confirm() {
    if (_passed || _input.isEmpty) return;
    if (int.parse(_input) == _a * _b) {
      setState(() => _passed = true);
      widget.onPassed();
      return;
    }
    setState(() {
      _wrong = true;
      _input = '';
      _newQuestion(differ: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final question =
        'Nhập kết quả: ${numberToVietnamese(_a)} nhân ${numberToVietnamese(_b)}';
    // Shorter keys on small screens so Xác nhận stays reachable unscrolled.
    final compact = MediaQuery.of(context).size.height < 640;
    final keyHeight = compact ? 52.0 : 64.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 8 : 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Dành cho ba mẹ',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question,
                        key: const Key('parent-gate-question'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: compact ? 52 : 64,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                        ),
                        child: Text(
                          _input,
                          key: const Key('parent-gate-input'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: compact ? 20 : 28,
                        child: _wrong
                            ? const Center(
                                child: Text(
                                  'Chưa đúng, thử lại nhé',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      _Keypad(
                        keyHeight: keyHeight,
                        onDigit: _addDigit,
                        onDelete: _passed || _input.isEmpty ? null : _delete,
                        onClose: _passed ? null : widget.onCancel,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Xác nhận',
                        onPressed: _passed || _input.isEmpty ? null : _confirm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.keyHeight,
    required this.onDigit,
    required this.onDelete,
    required this.onClose,
  });

  final double keyHeight;
  final ValueChanged<String> onDigit;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    Widget row(List<String> digits) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (var i = 0; i < digits.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _GateKey(
                    key: Key('gate-key-${digits[i]}'),
                    label: digits[i],
                    height: keyHeight,
                    onTap: () => onDigit(digits[i]),
                  ),
                ),
              ],
            ],
          ),
        );
    return Column(
      children: [
        row(['1', '2', '3']),
        row(['4', '5', '6']),
        row(['7', '8', '9']),
        Row(
          children: [
            Expanded(
                child:
                    _GateKey(label: 'Xóa', height: keyHeight, onTap: onDelete)),
            const SizedBox(width: 8),
            Expanded(
              child: _GateKey(
                key: const Key('gate-key-0'),
                label: '0',
                height: keyHeight,
                onTap: () => onDigit('0'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _GateKey(label: 'Đóng', height: keyHeight, onTap: onClose)),
          ],
        ),
      ],
    );
  }
}

/// A white key (digits and secondary actions).
class _GateKey extends StatelessWidget {
  const _GateKey({
    super.key,
    required this.label,
    required this.height,
    required this.onTap,
  });

  final String label;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            boxShadow: const [AppShadows.card],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            onTap: onTap,
            child: Container(
              height: height,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
