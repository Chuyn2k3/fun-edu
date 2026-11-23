import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/feedback/app_dialog.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/tokens.dart';

Widget _harness(Widget child, {Size size = const Size(375, 667)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  test('danger color meets WCAG AA contrast against card background', () {
    expect(contrastRatio(AppColors.danger, AppColors.card), greaterThanOrEqualTo(4.5));
  });

  testWidgets('dialog returns true/false/null on primary/secondary/outside tap', (t) async {
    bool? result;

    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showAppDialog(
                context,
                title: 'Xác nhận',
                message: 'Bạn có chắc chắn không?',
                primaryLabel: 'Đồng ý',
                secondaryLabel: 'Hủy',
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    // 1. Primary button returns true
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(find.text('Bạn có chắc chắn không?'), findsOneWidget);
    await t.tap(find.text('Đồng ý'));
    await t.pumpAndSettle();
    expect(result, isTrue);

    // 2. Secondary button returns false
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hủy'));
    await t.pumpAndSettle();
    expect(result, isFalse);

    // 3. Outside tap returns null
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(10, 10)); // Tap barrier
    await t.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('non-dismissible dialog ignores outside tap and back', (t) async {
    bool? result;

    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showAppDialog(
                context,
                title: 'Quan trọng',
                primaryLabel: 'Xong',
                dismissible: false,
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();

    // Tap outside should not dismiss
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('Quan trọng'), findsOneWidget);
    expect(result, isNull);

    // Pop attempt should not dismiss
    final nav = Navigator.of(t.element(find.text('Quan trọng')));
    await nav.maybePop();
    await t.pumpAndSettle();
    expect(find.text('Quan trọng'), findsOneWidget);
    expect(result, isNull);

    // Tap primary label dismisses
    await t.tap(find.text('Xong'));
    await t.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('kid audience buttons are at least 64 on phone, 80 on tablet; parent at least 48', (t) async {
    // Parent on phone
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppDialog(
              context,
              title: 'Phụ huynh',
              primaryLabel: 'Lưu',
              secondaryLabel: 'Hủy',
              audience: AppAudience.parent,
            ),
            child: const Text('Mở'),
          ),
        ),
        size: const Size(375, 667),
      ),
    );
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    final parentBtnSize = t.getSize(find.widgetWithText(ElevatedButton, 'Lưu'));
    expect(parentBtnSize.height, greaterThanOrEqualTo(48.0));
    await t.tap(find.text('Lưu'));
    await t.pumpAndSettle();

    // Kid on phone (>= 64)
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppDialog(
              context,
              title: 'Bé yêu',
              primaryLabel: 'Tiếp tục',
              audience: AppAudience.kid,
            ),
            child: const Text('Mở'),
          ),
        ),
        size: const Size(375, 667),
      ),
    );
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    final kidPhoneBtnSize = t.getSize(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
    expect(kidPhoneBtnSize.height, greaterThanOrEqualTo(64.0));
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    // Kid on tablet (>= 80)
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppDialog(
              context,
              title: 'Bé yêu tablet',
              primaryLabel: 'Tiếp tục',
              audience: AppAudience.kid,
            ),
            child: const Text('Mở'),
          ),
        ),
        size: const Size(1024, 768),
      ),
    );
    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();
    final kidTabletBtnSize = t.getSize(find.widgetWithText(ElevatedButton, 'Tiếp tục'));
    expect(kidTabletBtnSize.height, greaterThanOrEqualTo(80.0));
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();
  });

  testWidgets('danger tone shows the danger action as a red text button', (t) async {
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppDialog(
              context,
              title: 'Xóa tài khoản',
              message: 'Dữ liệu sẽ mất vĩnh viễn',
              primaryLabel: 'Giữ lại',
              secondaryLabel: 'Xóa vĩnh viễn',
              tone: AppDialogTone.danger,
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();

    // Primary button is the safe option
    expect(find.widgetWithText(ElevatedButton, 'Giữ lại'), findsOneWidget);

    // Danger button is the red secondary button
    final dangerBtnFinder = find.widgetWithText(TextButton, 'Xóa vĩnh viễn');
    expect(dangerBtnFinder, findsOneWidget);
    final textBtn = t.widget<TextButton>(dangerBtnFinder);
    final fg = textBtn.style?.foregroundColor?.resolve({});
    expect(fg, equals(AppColors.danger));
  });

  testWidgets('dialog is one card decoration with color and shadow', (t) async {
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppDialog(
              context,
              title: 'Thẻ kiểm tra',
              primaryLabel: 'Đóng',
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await t.tap(find.text('Mở'));
    await t.pumpAndSettle();

    final cardFinder = find.byWidgetPredicate((w) {
      if (w is Container && w.decoration is BoxDecoration) {
        final box = w.decoration as BoxDecoration;
        return box.color != null && box.boxShadow != null && box.boxShadow!.isNotEmpty;
      }
      if (w is DecoratedBox && w.decoration is BoxDecoration) {
        final box = w.decoration as BoxDecoration;
        return box.color != null && box.boxShadow != null && box.boxShadow!.isNotEmpty;
      }
      return false;
    });

    expect(cardFinder, findsAtLeastNWidgets(1));
  });
}
